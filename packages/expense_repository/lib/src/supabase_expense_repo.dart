import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../expense_repository.dart';

class SupabaseExpenseRepo implements ExpenseRepository {
  final SupabaseClient _client = Supabase.instance.client;

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
      return data
          .map((e) => Category.fromEntity(CategoryEntity.fromDocument(e)))
          .toList();
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  @override
  Future<void> createExpense(Expense expense) async {
    try {
      await _client.from('expenses').insert(expense.toEntity().toDocument());
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  @override
  Future<List<Expense>> getExpenses() async {
    try {
      final expenseData = await _client
          .from('expenses')
          .select()
          .order('date', ascending: false);

      final categories = await getCategory();
      final categoryMap = {for (var cat in categories) cat.categoryId: cat};

      return expenseData.map((doc) {
        final entity = ExpenseEntity.fromDocument(doc);
        final category = categoryMap[entity.categoryId] ?? Category.empty;
        return Expense.fromEntity(entity, category);
      }).toList();
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  @override
  Future<void> deleteExpense(String expenseId) async {
    try {
      await _client.from('expenses').delete().eq('expenseId', expenseId);
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    try {
      await _client
          .from('expenses')
          .update(expense.toEntity().toDocument())
          .eq('expenseId', expense.expenseId);
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  @override
  Future<void> createIncome(Income income) async {
    try {
      await _client.from('incomes').upsert(income.toEntity().toDocument());
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  @override
  Future<List<Income>> getIncomes() async {
    try {
      final incomeData = await _client
          .from('incomes')
          .select()
          .order('date', ascending: false);
      return incomeData.map((doc) {
        final entity = IncomeEntity.fromDocument(doc);
        return Income.fromEntity(entity);
      }).toList();
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  @override
  Future<void> deleteIncome(String incomeId) async {
    try {
      await _client.from('incomes').delete().eq('incomeId', incomeId);
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  @override
  Future<void> updateIncome(Income income) async {
    try {
      await _client
          .from('incomes')
          .update(income.toEntity().toDocument())
          .eq('incomeId', income.incomeId);
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }
}
