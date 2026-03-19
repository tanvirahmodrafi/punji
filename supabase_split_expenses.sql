-- Punji: Split Expenses + One-to-One Expense Connections
-- Run in Supabase SQL Editor.
-- This script is designed to be rerunnable.

-- Required for gen_random_uuid()
create extension if not exists pgcrypto;

-- 1) expense_connections table (one-to-one connection workflow)
create table if not exists public.expense_connections (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references auth.users(id) on delete cascade,
  receiver_id uuid not null references auth.users(id) on delete cascade,
  status text not null check (status in ('pending', 'accepted', 'rejected', 'cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_expense_connections_requester_id
  on public.expense_connections(requester_id);
create index if not exists idx_expense_connections_receiver_id
  on public.expense_connections(receiver_id);
create index if not exists idx_expense_connections_status
  on public.expense_connections(status);

-- Prevent duplicate pending invites between same two users (either direction)
create unique index if not exists uq_expense_connections_pending_pair
  on public.expense_connections(
    least(requester_id::text, receiver_id::text),
    greatest(requester_id::text, receiver_id::text),
    status
  )
  where status = 'pending';

-- Allow at most one accepted connection per user
create unique index if not exists uq_expense_connections_accepted_requester
  on public.expense_connections(requester_id)
  where status = 'accepted';

create unique index if not exists uq_expense_connections_accepted_receiver
  on public.expense_connections(receiver_id)
  where status = 'accepted';

-- updated_at trigger
create or replace function public.set_expense_connections_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_expense_connections_updated_at on public.expense_connections;
create trigger trg_expense_connections_updated_at
before update on public.expense_connections
for each row
execute function public.set_expense_connections_updated_at();

-- 2) Extend expenses table for split metadata
alter table public.expenses add column if not exists is_split boolean not null default false;
alter table public.expenses add column if not exists split_group_id uuid;
alter table public.expenses add column if not exists split_created_by uuid;
alter table public.expenses add column if not exists split_partner_id uuid;
alter table public.expenses add column if not exists split_total_amount integer;
alter table public.expenses add column if not exists split_share_amount integer;

create index if not exists idx_expenses_split_group_id on public.expenses(split_group_id);
create index if not exists idx_expenses_split_created_by on public.expenses(split_created_by);

-- Optional FKs (keep nullable to preserve legacy rows)
do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'expenses_split_created_by_fkey'
  ) then
    alter table public.expenses
      add constraint expenses_split_created_by_fkey
      foreign key (split_created_by) references auth.users(id) on delete set null;
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'expenses_split_partner_id_fkey'
  ) then
    alter table public.expenses
      add constraint expenses_split_partner_id_fkey
      foreign key (split_partner_id) references auth.users(id) on delete set null;
  end if;
end $$;

-- 3) RLS for expense_connections
alter table public.expense_connections enable row level security;

drop policy if exists expense_connections_select_own on public.expense_connections;
create policy expense_connections_select_own
on public.expense_connections
for select
to authenticated
using (auth.uid() = requester_id or auth.uid() = receiver_id);

drop policy if exists expense_connections_insert_own on public.expense_connections;
create policy expense_connections_insert_own
on public.expense_connections
for insert
to authenticated
with check (auth.uid() = requester_id);

drop policy if exists expense_connections_update_own on public.expense_connections;
create policy expense_connections_update_own
on public.expense_connections
for update
to authenticated
using (auth.uid() = requester_id or auth.uid() = receiver_id)
with check (auth.uid() = requester_id or auth.uid() = receiver_id);

-- 4) Utility: resolve user id by email from public.users (supports userId/userid variants)
create or replace function public.resolve_user_id_by_email(p_email text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_receiver uuid;
begin
  select
    coalesce(
      nullif(to_jsonb(u)->>'userId', '')::uuid,
      nullif(to_jsonb(u)->>'userid', '')::uuid
    )
  into v_receiver
  from public.users u
  where lower(coalesce(to_jsonb(u)->>'email', '')) = lower(trim(p_email))
  limit 1;

  return v_receiver;
end;
$$;

revoke all on function public.resolve_user_id_by_email(text) from public;
grant execute on function public.resolve_user_id_by_email(text) to authenticated;

-- 5) Connection RPCs

create or replace function public.send_expense_connection_invite(receiver_email text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_me uuid := auth.uid();
  v_receiver uuid;
  v_has_connection boolean;
begin
  if v_me is null then
    raise exception 'Not authenticated';
  end if;

  v_receiver := public.resolve_user_id_by_email(receiver_email);
  if v_receiver is null then
    raise exception 'No user found with this email';
  end if;

  if v_receiver = v_me then
    raise exception 'You cannot invite yourself';
  end if;

  -- one active accepted connection per user
  select exists(
    select 1
    from public.expense_connections c
    where c.status = 'accepted'
      and (c.requester_id = v_me or c.receiver_id = v_me)
  ) into v_has_connection;

  if v_has_connection then
    raise exception 'You already have an accepted connection';
  end if;

  select exists(
    select 1
    from public.expense_connections c
    where c.status = 'accepted'
      and (c.requester_id = v_receiver or c.receiver_id = v_receiver)
  ) into v_has_connection;

  if v_has_connection then
    raise exception 'Target user already has an accepted connection';
  end if;

  -- prevent duplicate pending invite in either direction
  if exists(
    select 1
    from public.expense_connections c
    where c.status = 'pending'
      and (
        (c.requester_id = v_me and c.receiver_id = v_receiver)
        or
        (c.requester_id = v_receiver and c.receiver_id = v_me)
      )
  ) then
    raise exception 'A pending invite already exists between these users';
  end if;

  insert into public.expense_connections(requester_id, receiver_id, status)
  values (v_me, v_receiver, 'pending');
end;
$$;

revoke all on function public.send_expense_connection_invite(text) from public;
grant execute on function public.send_expense_connection_invite(text) to authenticated;

create or replace function public.respond_expense_connection_invite(connection_id uuid, accept_invite boolean)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_me uuid := auth.uid();
  v_connection public.expense_connections%rowtype;
  v_has_connection boolean;
begin
  if v_me is null then
    raise exception 'Not authenticated';
  end if;

  select *
  into v_connection
  from public.expense_connections
  where id = connection_id
    and status = 'pending'
  for update;

  if not found then
    raise exception 'Pending invite not found';
  end if;

  if v_connection.receiver_id <> v_me then
    raise exception 'Only receiver can accept/reject invite';
  end if;

  if accept_invite then
    -- Ensure one-to-one accepted uniqueness for both users
    select exists(
      select 1 from public.expense_connections c
      where c.status = 'accepted'
        and (c.requester_id = v_connection.requester_id or c.receiver_id = v_connection.requester_id)
    ) into v_has_connection;

    if v_has_connection then
      raise exception 'Requester already has an accepted connection';
    end if;

    select exists(
      select 1 from public.expense_connections c
      where c.status = 'accepted'
        and (c.requester_id = v_connection.receiver_id or c.receiver_id = v_connection.receiver_id)
    ) into v_has_connection;

    if v_has_connection then
      raise exception 'Receiver already has an accepted connection';
    end if;

    update public.expense_connections
    set status = 'accepted', updated_at = now()
    where id = connection_id;
  else
    update public.expense_connections
    set status = 'rejected', updated_at = now()
    where id = connection_id;
  end if;
end;
$$;

revoke all on function public.respond_expense_connection_invite(uuid, boolean) from public;
grant execute on function public.respond_expense_connection_invite(uuid, boolean) to authenticated;

create or replace function public.cancel_expense_connection_invite(connection_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_me uuid := auth.uid();
  v_requester uuid;
begin
  if v_me is null then
    raise exception 'Not authenticated';
  end if;

  select requester_id into v_requester
  from public.expense_connections
  where id = connection_id
    and status = 'pending'
  for update;

  if v_requester is null then
    raise exception 'Pending invite not found';
  end if;

  if v_requester <> v_me then
    raise exception 'Only requester can cancel pending invite';
  end if;

  update public.expense_connections
  set status = 'cancelled', updated_at = now()
  where id = connection_id;
end;
$$;

revoke all on function public.cancel_expense_connection_invite(uuid) from public;
grant execute on function public.cancel_expense_connection_invite(uuid) to authenticated;

create or replace function public.disconnect_expense_connection(connection_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_me uuid := auth.uid();
  v_connection public.expense_connections%rowtype;
begin
  if v_me is null then
    raise exception 'Not authenticated';
  end if;

  select *
  into v_connection
  from public.expense_connections
  where id = connection_id
    and status = 'accepted'
  for update;

  if not found then
    raise exception 'Accepted connection not found';
  end if;

  if v_connection.requester_id <> v_me and v_connection.receiver_id <> v_me then
    raise exception 'Only connected users can disconnect';
  end if;

  update public.expense_connections
  set status = 'cancelled', updated_at = now()
  where id = connection_id;
end;
$$;

revoke all on function public.disconnect_expense_connection(uuid) from public;
grant execute on function public.disconnect_expense_connection(uuid) to authenticated;

-- 6) Split expense pair RPCs

create or replace function public.create_split_expense_pair(
  p_expense_id text,
  p_category_id text,
  p_date timestamptz,
  p_total_amount integer,
  p_partner_share_amount integer,
  p_partner_user_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_me uuid := auth.uid();
  v_group_id uuid := gen_random_uuid();
  v_my_share integer;
begin
  if v_me is null then
    raise exception 'Not authenticated';
  end if;

  if p_total_amount is null or p_total_amount <= 0 then
    raise exception 'Total amount must be greater than 0';
  end if;

  if p_partner_share_amount is null or p_partner_share_amount <= 0 or p_partner_share_amount > p_total_amount then
    raise exception 'Partner share must be > 0 and <= total amount';
  end if;

  if p_partner_user_id = v_me then
    raise exception 'Partner must be different from current user';
  end if;

  if not exists(
    select 1
    from public.expense_connections c
    where c.status = 'accepted'
      and (
        (c.requester_id = v_me and c.receiver_id = p_partner_user_id)
        or
        (c.requester_id = p_partner_user_id and c.receiver_id = v_me)
      )
  ) then
    raise exception 'Users are not connected with accepted status';
  end if;

  v_my_share := p_total_amount - p_partner_share_amount;
  if v_my_share <= 0 then
    raise exception 'Current user share must be greater than 0';
  end if;

  insert into public.expenses(
    "expenseId", "categoryId", date, amount, userid,
    is_split, split_group_id, split_created_by, split_partner_id,
    split_total_amount, split_share_amount
  ) values (
    p_expense_id,
    p_category_id,
    p_date,
    v_my_share,
    v_me,
    true,
    v_group_id,
    v_me,
    p_partner_user_id,
    p_total_amount,
    p_partner_share_amount
  );

  insert into public.expenses(
    "expenseId", "categoryId", date, amount, userid,
    is_split, split_group_id, split_created_by, split_partner_id,
    split_total_amount, split_share_amount
  ) values (
    gen_random_uuid()::text,
    p_category_id,
    p_date,
    p_partner_share_amount,
    p_partner_user_id,
    true,
    v_group_id,
    v_me,
    v_me,
    p_total_amount,
    p_partner_share_amount
  );
end;
$$;

revoke all on function public.create_split_expense_pair(text, text, timestamptz, integer, integer, uuid) from public;
grant execute on function public.create_split_expense_pair(text, text, timestamptz, integer, integer, uuid) to authenticated;

create or replace function public.update_split_expense_pair(
  p_split_group_id uuid,
  p_category_id text,
  p_date timestamptz,
  p_total_amount integer,
  p_partner_share_amount integer
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_me uuid := auth.uid();
  v_partner_row public.expenses%rowtype;
  v_my_share integer;
begin
  if v_me is null then
    raise exception 'Not authenticated';
  end if;

  if p_total_amount is null or p_total_amount <= 0 then
    raise exception 'Total amount must be greater than 0';
  end if;

  if p_partner_share_amount is null or p_partner_share_amount <= 0 or p_partner_share_amount > p_total_amount then
    raise exception 'Partner share must be > 0 and <= total amount';
  end if;

  if not exists(
    select 1
    from public.expenses e
    where e.split_group_id = p_split_group_id
      and e.is_split = true
      and e.split_created_by = v_me
  ) then
    raise exception 'Only split creator can update this split pair';
  end if;

  select *
  into v_partner_row
  from public.expenses e
  where e.split_group_id = p_split_group_id
    and e.userid <> v_me
  limit 1;

  if not found then
    raise exception 'Partner split row not found';
  end if;

  v_my_share := p_total_amount - p_partner_share_amount;
  if v_my_share <= 0 then
    raise exception 'Current user share must be greater than 0';
  end if;

  -- Update creator row
  update public.expenses
  set
    "categoryId" = p_category_id,
    date = p_date,
    amount = v_my_share,
    split_total_amount = p_total_amount,
    split_share_amount = p_partner_share_amount,
    split_partner_id = v_partner_row.userid
  where split_group_id = p_split_group_id
    and userid = v_me;

  -- Update partner row
  update public.expenses
  set
    "categoryId" = p_category_id,
    date = p_date,
    amount = p_partner_share_amount,
    split_total_amount = p_total_amount,
    split_share_amount = p_partner_share_amount,
    split_partner_id = v_me
  where split_group_id = p_split_group_id
    and userid = v_partner_row.userid;
end;
$$;

revoke all on function public.update_split_expense_pair(uuid, text, timestamptz, integer, integer) from public;
grant execute on function public.update_split_expense_pair(uuid, text, timestamptz, integer, integer) to authenticated;

create or replace function public.delete_split_expense_pair(p_split_group_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_me uuid := auth.uid();
begin
  if v_me is null then
    raise exception 'Not authenticated';
  end if;

  if not exists(
    select 1
    from public.expenses e
    where e.split_group_id = p_split_group_id
      and e.is_split = true
      and e.split_created_by = v_me
  ) then
    raise exception 'Only split creator can delete this split pair';
  end if;

  delete from public.expenses
  where split_group_id = p_split_group_id;
end;
$$;

revoke all on function public.delete_split_expense_pair(uuid) from public;
grant execute on function public.delete_split_expense_pair(uuid) to authenticated;
