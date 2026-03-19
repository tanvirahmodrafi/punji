import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../expense_repository.dart';

class SupabaseExpenseRepo implements ExpenseRepository {
  final SupabaseClient _client = Supabase.instance.client;

  ExpenseConnection _connectionFromRow(Map<String, dynamic> row) {
    return ExpenseConnection.fromEntity(
      ExpenseConnectionEntity.fromDocument(row),
    );
  }

  String _requireUserId() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user found.');
    }
    return user.id;
  }

  Future<void> _insertByUser(
    String table,
    Map<String, Object?> payload,
    String userId,
  ) async {
    await _client.from(table).insert({...payload, 'userid': userId});
  }

  Future<List<Map<String, dynamic>>> _selectByUser(
    String table,
    String userId, {
    String? orderBy,
  }) async {
    dynamic query = _client.from(table).select().eq('userid', userId);
    if (orderBy != null) {
      query = query.order(orderBy, ascending: false);
    }
    final data = await query;
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> _deleteByIdAndUser(
    String table,
    String idColumn,
    String idValue,
    String userId,
  ) async {
    await _client
        .from(table)
        .delete()
        .eq(idColumn, idValue)
        .eq('userid', userId);
  }

  Future<void> _updateByIdAndUser(
    String table,
    String idColumn,
    String idValue,
    Map<String, Object?> payload,
    String userId,
  ) async {
    await _client
        .from(table)
        .update(payload)
        .eq(idColumn, idValue)
        .eq('userid', userId);
  }

  Future<void> _ensureUserProfile(String userId) async {
    try {
      final user = _client.auth.currentUser;
      final metadata = user?.userMetadata;
      final fullName = metadata?['fullName'] ??
          metadata?['full_name'] ??
          user?.email?.split('@').first ??
          'User';
      await _client.from('users').upsert({
        'userid': userId,
        'email': user?.email,
        'fullname': fullName,
      });
    } catch (e) {
      log('_ensureUserProfile failed (non-fatal): $e');
    }
  }

  Map<String, Object?> _incomePayloadForDb(Income income) {
    final payload = income.toEntity().toDocument();
    // incomes.date is a DATE column (not timestamptz)
    payload['date'] = income.date.toIso8601String().split('T').first;
    return payload;
  }

  // ── Categories (global table — no userid column) ─────────────────────────

  @override
  Future<void> createCategory(Category category) async {
    try {
      await _client.from('categories').insert(category.toEntity().toDocument());
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  @override
  Future<List<Category>> getCategory() async {
    try {
      final data = await _client.from('categories').select();
      final categories = <Category>[];
      for (final row in data) {
        try {
          categories.add(Category.fromEntity(
              CategoryEntity.fromDocument(Map<String, dynamic>.from(row))));
        } catch (e) {
          log('Skipping invalid category row: $e');
        }
      }
      return categories;
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  // ── Expenses ──────────────────────────────────────────────────────────────

  @override
  Future<void> createExpense(Expense expense) async {
    try {
      final userId = _requireUserId();
      await _ensureUserProfile(userId);
      await _insertByUser('expenses', expense.toEntity().toDocument(), userId);
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  @override
  Future<List<Expense>> getExpenses() async {
    try {
      final userId = _requireUserId();
      final expenseData =
          await _selectByUser('expenses', userId, orderBy: 'date');
      final categories = await getCategory();
      final categoryMap = {for (var cat in categories) cat.categoryId: cat};
      final expenses = <Expense>[];
      for (final doc in expenseData) {
        try {
          final entity = ExpenseEntity.fromDocument(doc);
          final category = categoryMap[entity.categoryId] ?? Category.empty;
          expenses.add(Expense.fromEntity(entity, category));
        } catch (e) {
          log('Skipping invalid expense row: $e');
        }
      }
      return expenses;
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  @override
  Future<void> deleteExpense(String expenseId) async {
    try {
      final userId = _requireUserId();
      await _deleteByIdAndUser('expenses', 'expenseId', expenseId, userId);
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    try {
      final userId = _requireUserId();
      await _updateByIdAndUser(
        'expenses',
        'expenseId',
        expense.expenseId,
        expense.toEntity().toDocument(),
        userId,
      );
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  // ── Expense connections (one-to-one partner system) ─────────────────────

  @override
  Future<ExpenseConnection?> getAcceptedConnection() async {
    try {
      final userId = _requireUserId();
      final row = await _client
          .from('expense_connections')
          .select()
          .eq('status', 'accepted')
          .or('requester_id.eq.$userId,receiver_id.eq.$userId')
          .limit(1)
          .maybeSingle();
      if (row == null) {
        return null;
      }
      return _connectionFromRow(Map<String, dynamic>.from(row));
    } catch (e) {
      log('getAcceptedConnection failed: $e');
      rethrow;
    }
  }

  @override
  Future<List<ExpenseConnection>> getIncomingPendingConnections() async {
    try {
      final userId = _requireUserId();
      final data = await _client
          .from('expense_connections')
          .select()
          .eq('receiver_id', userId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data)
          .map(_connectionFromRow)
          .toList();
    } catch (e) {
      log('getIncomingPendingConnections failed: $e');
      rethrow;
    }
  }

  @override
  Future<ExpenseConnection?> getOutgoingPendingConnection() async {
    try {
      final userId = _requireUserId();
      final row = await _client
          .from('expense_connections')
          .select()
          .eq('requester_id', userId)
          .eq('status', 'pending')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (row == null) {
        return null;
      }
      return _connectionFromRow(Map<String, dynamic>.from(row));
    } catch (e) {
      log('getOutgoingPendingConnection failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> sendExpenseConnectionInviteByEmail(String email) async {
    try {
      await _client.rpc(
        'send_expense_connection_invite',
        params: {'receiver_email': email.trim()},
      );
    } catch (e) {
      log('sendExpenseConnectionInviteByEmail failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> respondToExpenseConnection({
    required String connectionId,
    required bool accept,
  }) async {
    try {
      await _client.rpc(
        'respond_expense_connection_invite',
        params: {
          'connection_id': connectionId,
          'accept_invite': accept,
        },
      );
    } catch (e) {
      log('respondToExpenseConnection failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> cancelOutgoingExpenseConnection(String connectionId) async {
    try {
      await _client.rpc(
        'cancel_expense_connection_invite',
        params: {'connection_id': connectionId},
      );
    } catch (e) {
      log('cancelOutgoingExpenseConnection failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> disconnectExpenseConnection(String connectionId) async {
    try {
      await _client.rpc(
        'disconnect_expense_connection',
        params: {'connection_id': connectionId},
      );
    } catch (e) {
      log('disconnectExpenseConnection failed: $e');
      rethrow;
    }
  }

  // ── Split expense pair operations (secured by database RPC) ─────────────

  @override
  Future<void> createSplitExpensePair({
    required Expense myExpense,
    required String partnerUserId,
    required int totalAmount,
    required int partnerShareAmount,
  }) async {
    try {
      await _client.rpc(
        'create_split_expense_pair',
        params: {
          'p_expense_id': myExpense.expenseId,
          'p_category_id': myExpense.category.categoryId,
          'p_date': myExpense.date.toIso8601String(),
          'p_total_amount': totalAmount,
          'p_partner_share_amount': partnerShareAmount,
          'p_partner_user_id': partnerUserId,
        },
      );
    } catch (e) {
      log('createSplitExpensePair failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateSplitExpensePair({
    required Expense myExpense,
    required int totalAmount,
    required int partnerShareAmount,
  }) async {
    try {
      final splitGroupId = myExpense.splitGroupId;
      if (splitGroupId == null || splitGroupId.isEmpty) {
        throw StateError('Missing split_group_id for split expense update.');
      }

      await _client.rpc(
        'update_split_expense_pair',
        params: {
          'p_split_group_id': splitGroupId,
          'p_category_id': myExpense.category.categoryId,
          'p_date': myExpense.date.toIso8601String(),
          'p_total_amount': totalAmount,
          'p_partner_share_amount': partnerShareAmount,
        },
      );
    } catch (e) {
      log('updateSplitExpensePair failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteSplitExpensePair(String splitGroupId) async {
    try {
      await _client.rpc(
        'delete_split_expense_pair',
        params: {'p_split_group_id': splitGroupId},
      );
    } catch (e) {
      log('deleteSplitExpensePair failed: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, String?>> getUserProfileSummary(String userId) async {
    try {
      Map<String, dynamic>? row;
      try {
        row = await _client
            .from('users')
            .select('email, fullName, photoUrl')
            .eq('userId', userId)
            .maybeSingle();
      } catch (_) {
        row = await _client
            .from('users')
            .select('email, fullname, photourl')
            .eq('userid', userId)
            .maybeSingle();
      }

      return {
        'email': (row?['email'])?.toString(),
        'fullName': (row?['fullName'] ?? row?['fullname'])?.toString(),
        'photoUrl': (row?['photoUrl'] ?? row?['photourl'])?.toString(),
      };
    } catch (e) {
      log('getUserProfileSummary failed: $e');
      return {'email': null, 'fullName': null, 'photoUrl': null};
    }
  }

  // ── Incomes ───────────────────────────────────────────────────────────────

  @override
  Future<void> createIncome(Income income) async {
    try {
      final userId = _requireUserId();
      await _insertByUser('incomes', _incomePayloadForDb(income), userId);
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  @override
  Future<List<Income>> getIncomes() async {
    try {
      final userId = _requireUserId();
      final incomeData =
          await _selectByUser('incomes', userId, orderBy: 'date');
      final incomes = <Income>[];
      for (final doc in incomeData) {
        try {
          final entity = IncomeEntity.fromDocument(doc);
          incomes.add(Income.fromEntity(entity));
        } catch (e) {
          log('Skipping invalid income row: $e');
        }
      }
      return incomes;
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  @override
  Future<void> deleteIncome(String incomeId) async {
    try {
      final userId = _requireUserId();
      await _deleteByIdAndUser('incomes', 'incomeId', incomeId, userId);
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  @override
  Future<void> updateIncome(Income income) async {
    try {
      final userId = _requireUserId();
      await _updateByIdAndUser(
        'incomes',
        'incomeId',
        income.incomeId,
        _incomePayloadForDb(income),
        userId,
      );
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }
}
