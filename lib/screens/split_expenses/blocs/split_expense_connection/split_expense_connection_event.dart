part of 'split_expense_connection_bloc.dart';

sealed class SplitExpenseConnectionEvent extends Equatable {
  const SplitExpenseConnectionEvent();

  @override
  List<Object?> get props => [];
}

class LoadSplitExpenseConnection extends SplitExpenseConnectionEvent {
  const LoadSplitExpenseConnection();
}

class SendSplitExpenseInvite extends SplitExpenseConnectionEvent {
  final String email;

  const SendSplitExpenseInvite(this.email);

  @override
  List<Object?> get props => [email];
}

class AcceptSplitExpenseInvite extends SplitExpenseConnectionEvent {
  final String connectionId;

  const AcceptSplitExpenseInvite(this.connectionId);

  @override
  List<Object?> get props => [connectionId];
}

class RejectSplitExpenseInvite extends SplitExpenseConnectionEvent {
  final String connectionId;

  const RejectSplitExpenseInvite(this.connectionId);

  @override
  List<Object?> get props => [connectionId];
}

class CancelOutgoingSplitExpenseInvite extends SplitExpenseConnectionEvent {
  final String connectionId;

  const CancelOutgoingSplitExpenseInvite(this.connectionId);

  @override
  List<Object?> get props => [connectionId];
}

class DisconnectSplitExpenseConnection extends SplitExpenseConnectionEvent {
  final String connectionId;

  const DisconnectSplitExpenseConnection(this.connectionId);

  @override
  List<Object?> get props => [connectionId];
}

class ClearSplitExpenseConnectionMessage extends SplitExpenseConnectionEvent {
  const ClearSplitExpenseConnectionMessage();
}
