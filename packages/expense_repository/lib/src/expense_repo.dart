import 'package:expense_repository/expense_repository.dart';

abstract class ExpenseRepository {
  Future<void> createCategory(Category category);

  Future<List<Category>> getCategory();

  Future<void> createExpense(Expense expense);

  Future<List<Expense>> getExpenses();

  Future<void> deleteExpense(String expenseId);

  Future<void> updateExpense(Expense expense);

  Future<ExpenseConnection?> getAcceptedConnection();

  Future<List<ExpenseConnection>> getIncomingPendingConnections();

  Future<ExpenseConnection?> getOutgoingPendingConnection();

  Future<void> sendExpenseConnectionInviteByEmail(String email);

  Future<void> respondToExpenseConnection({
    required String connectionId,
    required bool accept,
  });

  Future<void> cancelOutgoingExpenseConnection(String connectionId);

  Future<void> disconnectExpenseConnection(String connectionId);

  Future<void> createSplitExpensePair({
    required Expense myExpense,
    required String partnerUserId,
    required int totalAmount,
    required int partnerShareAmount,
  });

  Future<void> updateSplitExpensePair({
    required Expense myExpense,
    required int totalAmount,
    required int partnerShareAmount,
  });

  Future<void> deleteSplitExpensePair(String splitGroupId);

  Future<Map<String, String?>> getUserProfileSummary(String userId);

  Future<void> createIncome(Income income);

  Future<List<Income>> getIncomes();

  Future<void> deleteIncome(String incomeId);

  Future<void> updateIncome(Income income);
}
