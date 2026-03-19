# Punji LLM Context README

This file is an onboarding + operational context pack for another LLM working on this repository.
It aims to describe the current architecture, runtime behavior, data model, key flows, and known caveats.

## 1) Project Identity

- App name: Punji
- Type: Flutter mobile app (Android + iOS; web and desktop folders exist from Flutter scaffold)
- Domain: Personal finance tracker (expenses + incomes + categories + profile)
- Backend: Supabase (Auth + PostgREST + Storage)
- State management: BLoC (`bloc`, `flutter_bloc`, `equatable`)

## 2) Runtime Entry + App Shell

- Entry point initializes Supabase and bootstraps app:
  - `lib/main.dart`
- Dependency injection for repository + top-level blocs:
  - `lib/app.dart`
- Auth-gated root view (login if signed out, home if signed in):
  - `lib/app_view.dart`

Auth behavior in `app_view.dart`:
- Uses `Supabase.instance.client.auth.onAuthStateChange` stream.
- If user is null -> shows Login page.
- If user exists -> dispatches `GetExpenses` + `GetIncomes` once per user session.

## 3) Feature Map

### Authentication
- Login page: `lib/screens/auth/views/login_page.dart`
- Signup page: `lib/screens/auth/views/signup_page.dart`
- On successful login/signup, app upserts profile row into `users` table.

### Home + Navigation
- Home container with bottom nav (Home + Stats):
  - `lib/screens/home/views/home_screen.dart`
- Main dashboard:
  - `lib/screens/home/views/main_screen.dart`
- Stats page:
  - `lib/screens/stats/stats.dart`

### Expenses
- Add/Edit expense form:
  - `lib/screens/addEpense/views/addExpense.dart`
- Category creation dialog is embedded inside AddExpense.
- Swipe actions on transactions in main screen:
  - Edit -> opens AddExpense prefilled
  - Delete -> confirmation dialog -> deletes expense

### Incomes
- Add/Edit income form:
  - `lib/screens/addIncome/views/addIncome.dart`
- Income categories are hardcoded in UI (`Salary`, `Business`, `Bank`, `Freelance`, `Gift`, `Other`).
- Swipe actions for incomes in main screen:
  - Edit -> opens AddIncome prefilled
  - Delete -> confirmation dialog -> deletes income

### Transactions Views
- Combined transactions list (expenses + incomes):
  - `lib/screens/home/views/all_transactions_screen.dart`

### Profile
- Settings side panel is opened from gear icon in main screen.
- Edit profile page:
  - `lib/screens/profile/views/edit_profile_page.dart`
- Supports name/email changes + profile image upload to Supabase Storage bucket `User Image`.

### Reports
- Stats chart:
  - `lib/screens/stats/chart.dart`
- PDF export screen:
  - `lib/screens/stats/download_pdf_screen.dart`

## 4) Data Layer Architecture

Repository package path:
- `packages/expense_repository/`

Public contract:
- `packages/expense_repository/lib/src/expense_repo.dart`

Supabase implementation:
- `packages/expense_repository/lib/src/supabase_expense_repo.dart`

### Repository Interface Methods
- Categories:
  - `createCategory(Category category)`
  - `getCategory()`
- Expenses:
  - `createExpense(Expense expense)`
  - `getExpenses()`
  - `deleteExpense(String expenseId)`
  - `updateExpense(Expense expense)`
- Incomes:
  - `createIncome(Income income)`
  - `getIncomes()`
  - `deleteIncome(String incomeId)`
  - `updateIncome(Income income)`

### Supabase Repo Behavior Notes
- Requires authenticated user for expense/income operations.
- Expense and income rows are scoped by `userid` in DB queries.
- Category operations currently call `categories` directly without user scoping (global behavior).
- Incomes date field is normalized to `YYYY-MM-DD` string for DB compatibility.

## 5) Domain Models and Entity Serialization

Model files:
- `packages/expense_repository/lib/src/models/category.dart`
- `packages/expense_repository/lib/src/models/expense.dart`
- `packages/expense_repository/lib/src/models/income.dart`

Entity files:
- `packages/expense_repository/lib/src/entities/category_entity.dart`
- `packages/expense_repository/lib/src/entities/expense_entity.dart`
- `packages/expense_repository/lib/src/entities/income_entity.dart`

Common DB field naming currently used in code paths:
- Expenses: `expenseId`, `categoryId`, `date`, `amount`, plus `userid` at persistence layer.
- Incomes: `incomeId`, `category`, `date`, `amount`, plus `userid` at persistence layer.
- Users table values are read/written using mixed fallbacks:
  - Camel case and lowercase variants (`userId`/`userid`, `fullName`/`fullname`, `photoUrl`/`photourl`).

## 6) BLoC Topology

### Home data fetch blocs
- Expenses:
  - `lib/screens/home/blocs/get_expenses/get_expenses_bloc.dart`
- Incomes:
  - `lib/screens/home/blocs/get_incomes/get_incomes_bloc.dart`

Both support load + delete flow and emit success/failure states.

### Expense creation/editing
- `lib/screens/addEpense/blocs/create_expense/create_expense_bloc.dart`
- Supports:
  - `CreateExpense`
  - `UpdateExpense`

### Income creation
- `lib/screens/addIncome/blocs/create_income/create_income_bloc.dart`
- Currently handles `CreateIncome` event.

### Category creation and load
- Create:
  - `lib/screens/addEpense/blocs/create_category/create_category_bloc.dart`
- Get:
  - `lib/screens/addEpense/blocs/get_categories/get_category_bloc.dart`

## 7) Supabase Setup Summary

Supabase project URL is initialized in `lib/main.dart`.

The root `README.md` contains SQL for:
- multi-user app tables and RLS
- storage bucket + storage policies for profile image upload

Important: app code and SQL use a mixture of field-name styles across history.
The code tries to tolerate this in some places with fallback queries.

## 8) Profile Image Upload Pipeline

From `edit_profile_page.dart`:
1. User picks image using `image_picker`.
2. App uploads bytes to Storage bucket `User Image` at path:
   - `<userId>/profile_<timestamp>.<ext>`
3. App obtains public URL.
4. App updates:
   - Supabase auth user (`updateUser`) with email/name metadata
   - `users` table with name, email, photo URL

If upload fails with RLS error:
- Run storage RLS SQL from root `README.md`.

## 9) UI/UX Notes

- Home summary card is tappable and opens Add Income screen.
- Floating action button opens Add Expense screen.
- Transactions list supports swipe-to-actions via bottom sheet choices.
- Settings panel is right-side slide-over dialog.

## 10) Dependencies (Current)

From `pubspec.yaml`:
- Backend/Auth: `supabase_flutter`
- State: `bloc`, `flutter_bloc`, `equatable`
- Forms/utility: `intl`, `uuid`, `flutter_colorpicker`, `font_awesome_flutter`
- Reports: `pdf`, `printing`
- Media input: `image_picker`
- Charts: `fl_chart`

## 11) Build/Run

Typical local commands:
- `flutter pub get`
- `flutter run`
- `flutter analyze`

The current repository has historical iOS setup churn; if simulator issues appear, regenerate iOS project or re-run pod install workflows as needed.

## 12) Known Caveats / Technical Debt

1. Naming inconsistency in DB columns
- Some code paths assume lowercase columns (`userid`, `fullname`, `photourl`) while SQL examples use camelCase quoted identifiers (`"userId"`, `"fullName"`, `"photoUrl"`).
- This can break queries depending on actual deployed schema.

2. Category ownership mismatch risk
- Repo comments imply categories are global and category queries are unscoped.
- Multi-user SQL in root README introduces user ownership and RLS for categories.
- If RLS is fully enforced for categories, current create/get category logic may need user scoping.

3. Income edit event architecture mismatch
- `AddIncome` supports edit mode in UI.
- `CreateIncomeBloc` currently exposes only `CreateIncome` event in the event file.
- Behavior works for create, but update semantics should be revisited and aligned with `updateIncome` repository method.

4. Analyzer warnings exist
- Project currently has non-blocking warnings (naming/deprecations/async context).

## 13) Recommended Next Engineering Tasks

- Normalize all DB identifiers to one style and remove fallback branching.
- Align categories with per-user model consistently in SQL and repository.
- Add dedicated `UpdateIncome` event and flow to BLoC for true edit semantics.
- Add integration tests for:
  - auth -> users row upsert
  - profile update and image upload
  - expense/income CRUD roundtrip
- Add robust error mapping from Supabase exceptions to user-friendly messages.

## 14) File Landmarks (Quick Navigation)

- Bootstrap:
  - `lib/main.dart`
  - `lib/app.dart`
  - `lib/app_view.dart`
- Home/UI:
  - `lib/screens/home/views/home_screen.dart`
  - `lib/screens/home/views/main_screen.dart`
  - `lib/screens/home/views/all_transactions_screen.dart`
- Auth:
  - `lib/screens/auth/views/login_page.dart`
  - `lib/screens/auth/views/signup_page.dart`
- Expense:
  - `lib/screens/addEpense/views/addExpense.dart`
- Income:
  - `lib/screens/addIncome/views/addIncome.dart`
- Profile:
  - `lib/screens/profile/views/edit_profile_page.dart`
- Stats/report:
  - `lib/screens/stats/stats.dart`
  - `lib/screens/stats/chart.dart`
  - `lib/screens/stats/download_pdf_screen.dart`
- Repository:
  - `packages/expense_repository/lib/src/expense_repo.dart`
  - `packages/expense_repository/lib/src/supabase_expense_repo.dart`
- Supabase setup docs:
  - `README.md`

---

If you are an LLM agent modifying this repo, start from sections 4, 6, and 12 first.
They describe data flow, state flow, and risk zones that most often cause regressions.
