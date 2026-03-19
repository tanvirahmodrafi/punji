# punji
 A smart Expanse tracker app. Available for both android and iOS.

 cd "/Applications/PlayGround/Complete Projects/Punji/punji" && flutter run -d 00008130-001E6C6C340B803A

## Multi-user Supabase Setup

Run the SQL below in Supabase SQL Editor to support multi-user data.

```sql
-- 1) App users table (linked to Supabase auth.users)
create table if not exists public.users (
	"userId" uuid primary key references auth.users(id) on delete cascade,
	email text,
	"fullName" text,
	"photoUrl" text,
	"createdAt" timestamptz not null default now(),
	"updatedAt" timestamptz not null default now()
);

-- 2) Add userId to app data tables
alter table public.categories add column if not exists "userId" uuid;
alter table public.expenses add column if not exists "userId" uuid;
alter table public.incomes add column if not exists "userId" uuid;

-- 3) Backfill existing rows to a known user if needed (optional, do manually)
-- update public.categories set "userId" = '<some-auth-user-uuid>' where "userId" is null;
-- update public.expenses set "userId" = '<some-auth-user-uuid>' where "userId" is null;
-- update public.incomes set "userId" = '<some-auth-user-uuid>' where "userId" is null;

-- 4) Add FK constraints after backfill
do $$
begin
	if not exists (
		select 1 from pg_constraint where conname = 'categories_userid_fkey'
	) then
		alter table public.categories
			add constraint categories_userid_fkey
			foreign key ("userId") references public.users("userId") on delete cascade;
	end if;
end $$;

do $$
begin
	if not exists (
		select 1 from pg_constraint where conname = 'expenses_userid_fkey'
	) then
		alter table public.expenses
			add constraint expenses_userid_fkey
			foreign key ("userId") references public.users("userId") on delete cascade;
	end if;
end $$;

do $$
begin
	if not exists (
		select 1 from pg_constraint where conname = 'incomes_userid_fkey'
	) then
		alter table public.incomes
			add constraint incomes_userid_fkey
			foreign key ("userId") references public.users("userId") on delete cascade;
	end if;
end $$;

-- 5) Helpful indexes
create index if not exists idx_categories_userid on public.categories("userId");
create index if not exists idx_expenses_userid on public.expenses("userId");
create index if not exists idx_incomes_userid on public.incomes("userId");

-- 6) Enable RLS
alter table public.users enable row level security;
alter table public.categories enable row level security;
alter table public.expenses enable row level security;
alter table public.incomes enable row level security;

-- 7) RLS policies (safe to rerun)
drop policy if exists users_select_own on public.users;
drop policy if exists users_insert_own on public.users;
drop policy if exists users_update_own on public.users;

create policy users_select_own
on public.users for select
using (auth.uid() = "userId");

create policy users_insert_own
on public.users for insert
with check (auth.uid() = "userId");

create policy users_update_own
on public.users for update
using (auth.uid() = "userId")
with check (auth.uid() = "userId");

drop policy if exists categories_all_own on public.categories;
create policy categories_all_own
on public.categories for all
using (auth.uid() = "userId")
with check (auth.uid() = "userId");

drop policy if exists expenses_all_own on public.expenses;
create policy expenses_all_own
on public.expenses for all
using (auth.uid() = "userId")
with check (auth.uid() = "userId");

drop policy if exists incomes_all_own on public.incomes;
create policy incomes_all_own
on public.incomes for all
using (auth.uid() = "userId")
with check (auth.uid() = "userId");
```