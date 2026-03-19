import 'dart:math';
import 'package:expense_repository/expense_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:punji/screens/addEpense/blocs/create_category/create_category_bloc.dart';
import 'package:punji/screens/addEpense/blocs/create_expense/create_expense_bloc.dart';
import 'package:punji/screens/addEpense/blocs/get_categories/get_category_bloc.dart';
import 'package:punji/screens/addEpense/views/addExpense.dart';
import 'package:punji/screens/home/blocs/get_expenses/get_expenses_bloc.dart';
import 'package:punji/screens/home/blocs/get_incomes/get_incomes_bloc.dart';
import 'package:punji/screens/home/views/all_transactions_screen.dart';
import 'package:punji/screens/addIncome/blocs/create_income/create_income_bloc.dart';
import 'package:punji/screens/addIncome/views/addIncome.dart';
import 'package:punji/screens/profile/views/edit_profile_page.dart';
import 'package:punji/screens/split_expenses/views/split_expenses_screen.dart';
import 'package:punji/theme/app_ui_style.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Map<String, Color> incomeCategoryColors = {
  'Salary': Colors.amber,
  'Business': Colors.green,
  'Bank': Colors.redAccent,
  'Freelance': Colors.blueAccent,
  'Gift': Colors.purple,
  'Other': Colors.teal,
};

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String? _profileImageUrl;
  String? _displayName;
  bool _profileLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final metadata = user.userMetadata;
      final fullName =
          metadata?['fullName'] ??
          metadata?['full_name'] ??
          user.email?.split('@').first ??
          'User';

      final imageUrl = await _loadProfileImageUrl(user.id);

      if (mounted) {
        setState(() {
          _displayName = fullName;
          _profileImageUrl = imageUrl;
          _profileLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _profileLoading = false;
        });
      }
    }
  }

  Future<String?> _loadProfileImageUrl(String userId) async {
    final client = Supabase.instance.client;
    try {
      final row =
          await client
              .from('users')
              .select('photourl')
              .eq('userid', userId)
              .maybeSingle();
      final raw = row?['photourl'];
      if (raw is String && raw.trim().isNotEmpty) {
        final candidate = raw.trim();
        final parsed = Uri.tryParse(candidate);
        if (parsed != null && parsed.hasScheme && parsed.host.isNotEmpty) {
          return candidate;
        }
      }
    } catch (_) {
      // Keep avatar fallback if profile URL lookup fails.
    }
    return null;
  }

  Future<void> _openSettingsPanel() async {
    final user = Supabase.instance.client.auth.currentUser;
    final metadata = user?.userMetadata;
    final displayName =
        metadata?['fullName'] ??
        metadata?['full_name'] ??
        user?.email?.split('@').first ??
        'User';
    final email = user?.email ?? 'No email';
    final userId = user?.id;
    final profileImageUrl =
        userId == null ? null : await _loadProfileImageUrl(userId);

    showGeneralDialog<void>(
      context: context,
      barrierLabel: 'Settings',
      barrierDismissible: true,
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (ctx, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: SafeArea(
              child: SizedBox(
                width: MediaQuery.of(ctx).size.width * 0.83,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppUiStyle.cardElevated(context),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      bottomLeft: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF1F2937), Color(0xFF111827)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(24),
                            bottomLeft: Radius.circular(24),
                          ),
                        ),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 46,
                              backgroundColor: Colors.white24,
                              child:
                                  (profileImageUrl != null)
                                      ? ClipOval(
                                        child: Image.network(
                                          profileImageUrl,
                                          width: 92,
                                          height: 92,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(
                                                    CupertinoIcons.person_fill,
                                                    size: 42,
                                                    color: Colors.white,
                                                  ),
                                        ),
                                      )
                                      : const Icon(
                                        CupertinoIcons.person_fill,
                                        size: 42,
                                        color: Colors.white,
                                      ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              displayName.toString(),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFFD1D5DB),
                                fontWeight: FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                          children: [
                            _settingsItem(
                              context: ctx,
                              icon: CupertinoIcons.person_crop_circle,
                              title: 'Edit Profile',
                              onTap: () async {
                                Navigator.of(ctx).pop();
                                final updated = await Navigator.of(
                                  context,
                                ).push<bool>(
                                  MaterialPageRoute<bool>(
                                    builder: (_) => const EditProfilePage(),
                                  ),
                                );

                                if (updated == true && mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Profile updated successfully.',
                                      ),
                                    ),
                                  );
                                  _loadUserProfile();
                                }
                              },
                            ),
                            _settingsItem(
                              context: ctx,
                              icon: CupertinoIcons.arrow_left_right,
                              title: 'Split Expenses',
                              onTap: () async {
                                Navigator.of(ctx).pop();
                                await Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const SplitExpensesScreen(),
                                  ),
                                );
                              },
                            ),
                            _settingsItem(
                              context: ctx,
                              icon: CupertinoIcons.star,
                              title: 'Rate Us',
                              onTap: () {},
                            ),
                            _settingsItem(
                              context: ctx,
                              icon: CupertinoIcons.exclamationmark_bubble,
                              title: 'Report a Problem',
                              onTap: () {},
                            ),
                            const SizedBox(height: 12),
                            _settingsItem(
                              context: ctx,
                              icon: CupertinoIcons.square_arrow_right,
                              title: 'Log Out',
                              isDanger: true,
                              onTap: () async {
                                Navigator.of(ctx).pop();
                                await Supabase.instance.client.auth.signOut();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, animation, secondaryAnimation, child) {
        final slideAnimation = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );

        return SlideTransition(position: slideAnimation, child: child);
      },
    );
  }

  Widget _settingsItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final itemColor =
        isDanger
            ? Colors.redAccent
            : (isDark ? const Color(0xFFE5E7EB) : const Color(0xFF1F2937));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppUiStyle.card(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            offset: const Offset(0, 4),
            color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.06),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: itemColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: itemColor, size: 18),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: itemColor,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        trailing: Icon(
          CupertinoIcons.chevron_right,
          size: 16,
          color: itemColor.withValues(alpha: 0.6),
        ),
        onTap: onTap,
      ),
    );
  }

  Future<bool> _showSwipeActions(BuildContext context, Expense expense) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  '${expense.category.name} - ${expense.amount}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(
                    CupertinoIcons.pencil,
                    color: Colors.blueAccent,
                  ),
                  title: const Text('Edit'),
                  onTap: () => Navigator.pop(ctx, 'edit'),
                ),
                ListTile(
                  leading: const Icon(
                    CupertinoIcons.trash,
                    color: Colors.redAccent,
                  ),
                  title: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onTap: () => Navigator.pop(ctx, 'delete'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Delete Expense'),
              content: Text(
                'Are you sure you want to delete this ${expense.category.name} expense of ${expense.amount}?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Delete'),
                ),
              ],
            ),
      );
      if (confirmed == true && mounted) {
        final currentUserId = Supabase.instance.client.auth.currentUser?.id;
        if (expense.isSplit &&
            expense.splitCreatedBy != null &&
            expense.splitCreatedBy != currentUserId) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Only split creator can delete this split expense.',
              ),
            ),
          );
          return false;
        }
        context.read<GetExpensesBloc>().add(DeleteExpense(expense));
      }
    } else if (action == 'edit') {
      if (mounted) {
        final currentUserId = Supabase.instance.client.auth.currentUser?.id;
        if (expense.isSplit &&
            expense.splitCreatedBy != null &&
            expense.splitCreatedBy != currentUserId) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Only split creator can edit this split expense.'),
            ),
          );
          return false;
        }
        final expenseRepository = context.read<ExpenseRepository>();
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder:
                (BuildContext context) => MultiBlocProvider(
                  providers: [
                    BlocProvider(
                      create:
                          (context) => CreateCategoryBloc(expenseRepository),
                    ),
                    BlocProvider(
                      create:
                          (context) =>
                              GetCategoryBloc(expenseRepository)
                                ..add(GetCategories()),
                    ),
                    BlocProvider(
                      create: (context) => CreateExpenseBloc(expenseRepository),
                    ),
                  ],
                  child: AddExpense(existingExpense: expense),
                ),
          ),
        );
        if (mounted) {
          context.read<GetExpensesBloc>().add(GetExpenses());
        }
      }
    }

    return false; // never actually dismiss the item
  }

  Future<bool> _showIncomeSwipeActions(
    BuildContext context,
    Income income,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  '${income.category} - ${income.amount}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(
                    CupertinoIcons.pencil,
                    color: Colors.blueAccent,
                  ),
                  title: const Text('Edit'),
                  onTap: () => Navigator.pop(ctx, 'edit'),
                ),
                ListTile(
                  leading: const Icon(
                    CupertinoIcons.trash,
                    color: Colors.redAccent,
                  ),
                  title: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onTap: () => Navigator.pop(ctx, 'delete'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Delete Income'),
              content: Text(
                'Are you sure you want to delete this ${income.category} income of ${income.amount}?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Delete'),
                ),
              ],
            ),
      );
      if (confirmed == true && mounted) {
        context.read<GetIncomesBloc>().add(DeleteIncome(income.incomeId));
      }
    } else if (action == 'edit') {
      if (mounted) {
        final expenseRepository = context.read<ExpenseRepository>();
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder:
                (BuildContext context) => BlocProvider(
                  create: (context) => CreateIncomeBloc(expenseRepository),
                  child: AddIncome(existingIncome: income),
                ),
          ),
        );
        if (mounted) {
          context.read<GetIncomesBloc>().add(GetIncomes());
        }
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10),
        child: BlocBuilder<GetExpensesBloc, GetExpensesState>(
          builder: (context, state) {
            if (state is GetExpensesLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is GetExpensesFailure) {
              return const Center(child: Text("Error loading expenses"));
            }

            final expenses =
                state is GetExpensesSuccess ? state.expenses : <Expense>[];
            final totalExpenses = expenses.fold<int>(
              0,
              (sum, e) => sum + e.amount,
            );

            return BlocBuilder<GetIncomesBloc, GetIncomesState>(
              builder: (context, incomeState) {
                final incomes =
                    incomeState is GetIncomesSuccess
                        ? incomeState.incomes
                        : <Income>[];
                final totalIncome = incomes.fold<int>(
                  0,
                  (sum, i) => sum + i.amount,
                );
                final totalBalance = totalIncome - totalExpenses;
                final isDark =
                    Theme.of(context).brightness == Brightness.dark;

                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.yellow[700],
                                  ),
                                  child:
                                      _profileLoading
                                          ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                          : _profileImageUrl != null
                                          ? ClipOval(
                                            child: Image.network(
                                              _profileImageUrl!,
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover,
                                              errorBuilder: (
                                                context,
                                                error,
                                                stackTrace,
                                              ) {
                                                return Icon(
                                                  CupertinoIcons.person_fill,
                                                  color: Colors.yellow[800],
                                                );
                                              },
                                            ),
                                          )
                                          : Icon(
                                            CupertinoIcons.person_fill,
                                            color: Colors.yellow[800],
                                          ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Welcome!",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        Theme.of(context).colorScheme.outline,
                                  ),
                                ),
                                Text(
                                  _displayName ?? 'User',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(
                            CupertinoIcons.settings,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          onPressed: _openSettingsPanel,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () async {
                        final expenseRepository =
                            context.read<ExpenseRepository>();
                        await Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder:
                                (BuildContext context) => BlocProvider(
                                  create:
                                      (context) =>
                                          CreateIncomeBloc(expenseRepository),
                                  child: const AddIncome(),
                                ),
                          ),
                        );
                        if (mounted) {
                          context.read<GetIncomesBloc>().add(GetIncomes());
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: min(MediaQuery.of(context).size.width / 2, 240),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors:
                                isDark
                                    ? const [
                                      Color(0xFF2A1F3D),
                                      Color(0xFF1F2940),
                                      Color(0xFF13263D),
                                    ]
                                    : [
                                      Theme.of(context).colorScheme.tertiary,
                                      Theme.of(context).colorScheme.secondary,
                                      Theme.of(context).colorScheme.primary,
                                    ],
                            transform: const GradientRotation(pi / 4),
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: isDark ? 18 : 4,
                              color:
                                  isDark
                                      ? Colors.black.withValues(alpha: 0.45)
                                      : Colors.grey.shade400,
                              offset: isDark
                                  ? const Offset(0, 10)
                                  : const Offset(5, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Total Balance",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${totalBalance.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 40,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 20,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 25,
                                        height: 25,
                                        decoration: const BoxDecoration(
                                          color: Colors.white30,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            CupertinoIcons.arrow_down,
                                            size: 12,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Income",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                          Text(
                                            '${totalIncome.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        width: 25,
                                        height: 25,
                                        decoration: const BoxDecoration(
                                          color: Colors.white30,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            CupertinoIcons.arrow_up,
                                            size: 12,
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Expenses",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                          Text(
                                            '${totalExpenses.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ), // GestureDetector for balance card
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Transactions',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => AllTransactionsScreen(
                                      expenses: expenses,
                                      incomes: incomes,
                                    ),
                              ),
                            );
                          },
                          child: Text(
                            'View All',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.outline,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: () {
                        final currentUserId =
                            Supabase.instance.client.auth.currentUser?.id;

                        // Merge expenses and incomes into a unified list
                        final List<dynamic> transactions = [
                          ...expenses,
                          ...incomes,
                        ];
                        transactions.sort((a, b) {
                          final dateA =
                              a is Expense ? a.date : (a as Income).date;
                          final dateB =
                              b is Expense ? b.date : (b as Income).date;
                          return dateB.compareTo(dateA); // newest first
                        });

                        if (transactions.isEmpty) {
                          return const Center(
                            child: Text(
                              "No transactions yet.\nTap + to add one!",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: min(transactions.length, 4),
                          itemBuilder: (context, int i) {
                            final item = transactions[i];
                            final bool isExpense = item is Expense;

                            // Common fields
                            final String name;
                            final int amount;
                            final DateTime date;
                            final Color circleColor;
                            final Widget circleChild;
                            final String amountPrefix;
                            final Color amountColor;
                            bool isSplit = false;
                            bool isPartnerTransaction = false;

                            if (isExpense) {
                              final expense = item;
                              name = expense.category.name;
                              amount = expense.amount;
                              date = expense.date;
                              circleColor = Color(
                                int.tryParse(expense.category.color) ??
                                    0xFF9E9E9E,
                              );
                              circleChild = Image.asset(
                                'assets/${expense.category.icon}.png',
                                width: 28,
                                height: 28,
                                color: Colors.white,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.category,
                                    color: Colors.white,
                                  );
                                },
                              );
                              amountPrefix = '-';
                              amountColor = Colors.red;
                              isSplit = expense.isSplit;
                              isPartnerTransaction =
                                  expense.isSplit &&
                                  currentUserId != null &&
                                  expense.splitCreatedBy != null &&
                                  expense.splitCreatedBy != currentUserId;
                            } else {
                              final income = item as Income;
                              name = income.category;
                              amount = income.amount;
                              date = income.date;
                              circleColor =
                                  incomeCategoryColors[income.category] ??
                                  Colors.teal;
                              circleChild = const Icon(
                                FontAwesomeIcons.dollarSign,
                                color: Colors.white,
                                size: 20,
                              );
                              amountPrefix = '+';
                              amountColor = Colors.green;
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child:
                                  isExpense
                                      ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Dismissible(
                                          key: ValueKey(item.expenseId),
                                          direction:
                                              DismissDirection.endToStart,
                                          background: Container(
                                            decoration: BoxDecoration(
                                              color:
                                                  Theme.of(context).brightness ==
                                                          Brightness.dark
                                                      ? AppUiStyle.cardMuted(
                                                        context,
                                                      )
                                                      : Colors.grey.shade200,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                _SwipeActionButton(
                                                  icon: CupertinoIcons.pencil,
                                                  color: Colors.blueAccent,
                                                  onTap: () {},
                                                ),
                                                _SwipeActionButton(
                                                  icon: CupertinoIcons.trash,
                                                  color: Colors.redAccent,
                                                  onTap: () {},
                                                ),
                                              ],
                                            ),
                                          ),
                                          confirmDismiss: (direction) async {
                                            return await _showSwipeActions(
                                              context,
                                              item,
                                            );
                                          },
                                          child: _buildTransactionTile(
                                            context,
                                            name,
                                            amount,
                                            date,
                                            circleColor,
                                            circleChild,
                                            amountPrefix,
                                            amountColor,
                                            isSplit: isSplit,
                                            isPartnerTransaction:
                                                isPartnerTransaction,
                                          ),
                                        ),
                                      )
                                      : ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Dismissible(
                                          key: ValueKey(
                                            (item as Income).incomeId,
                                          ),
                                          direction:
                                              DismissDirection.endToStart,
                                          background: Container(
                                            decoration: BoxDecoration(
                                              color:
                                                  Theme.of(context).brightness ==
                                                          Brightness.dark
                                                      ? AppUiStyle.cardMuted(
                                                        context,
                                                      )
                                                      : Colors.grey.shade200,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                _SwipeActionButton(
                                                  icon: CupertinoIcons.pencil,
                                                  color: Colors.blueAccent,
                                                  onTap: () {},
                                                ),
                                                _SwipeActionButton(
                                                  icon: CupertinoIcons.trash,
                                                  color: Colors.redAccent,
                                                  onTap: () {},
                                                ),
                                              ],
                                            ),
                                          ),
                                          confirmDismiss: (direction) async {
                                            return await _showIncomeSwipeActions(
                                              context,
                                              item,
                                            );
                                          },
                                          child: _buildTransactionTile(
                                            context,
                                            name,
                                            amount,
                                            date,
                                            circleColor,
                                            circleChild,
                                            amountPrefix,
                                            amountColor,
                                            isSplit: false,
                                          ),
                                        ),
                                      ),
                            );
                          },
                        );
                      }(),
                    ),
                  ],
                );
              },
            ); // BlocBuilder<GetIncomesBloc>
          },
        ),
      ),
    );
  }

  Widget _buildTransactionTile(
    BuildContext context,
    String name,
    int amount,
    DateTime date,
    Color circleColor,
    Widget circleChild,
    String amountPrefix,
    Color amountColor, {
    bool isSplit = false,
    bool isPartnerTransaction = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppUiStyle.card(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppUiStyle.cardShadow(context),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: circleColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    circleChild,
                  ],
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isSplit)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isPartnerTransaction
                                  ? Colors.deepPurple.withValues(alpha: 0.16)
                                  : Colors.blue.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPartnerTransaction
                                  ? Icons.people_alt_rounded
                                  : Icons.swap_horiz_rounded,
                              size: 12,
                              color:
                                  isPartnerTransaction
                                      ? Colors.deepPurple
                                      : Colors.blue,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isPartnerTransaction ? 'Partner' : 'Split',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color:
                                    isPartnerTransaction
                                        ? Colors.deepPurple
                                        : Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$amountPrefix $amount',
                  style: TextStyle(
                    fontSize: 14,
                    color: amountColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  DateFormat('dd/MM/yyyy').format(date),
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.outline,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SwipeActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        alignment: Alignment.center,
        color: color,
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}
