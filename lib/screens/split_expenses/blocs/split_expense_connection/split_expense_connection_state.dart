part of 'split_expense_connection_bloc.dart';

class SplitExpenseConnectionState extends Equatable {
  final bool isLoading;
  final bool isSubmitting;
  final ExpenseConnection? acceptedConnection;
  final List<ExpenseConnection> incomingInvites;
  final ExpenseConnection? outgoingInvite;
  final String? partnerUserId;
  final Map<String, String?>? partnerProfile;
  final String? errorMessage;
  final String? infoMessage;

  const SplitExpenseConnectionState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.acceptedConnection,
    this.incomingInvites = const [],
    this.outgoingInvite,
    this.partnerUserId,
    this.partnerProfile,
    this.errorMessage,
    this.infoMessage,
  });

  SplitExpenseConnectionState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    ExpenseConnection? acceptedConnection,
    bool clearAcceptedConnection = false,
    List<ExpenseConnection>? incomingInvites,
    ExpenseConnection? outgoingInvite,
    bool clearOutgoingInvite = false,
    String? partnerUserId,
    bool clearPartnerUserId = false,
    Map<String, String?>? partnerProfile,
    bool clearPartnerProfile = false,
    String? errorMessage,
    String? infoMessage,
  }) {
    return SplitExpenseConnectionState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      acceptedConnection:
          clearAcceptedConnection
              ? null
              : (acceptedConnection ?? this.acceptedConnection),
      incomingInvites: incomingInvites ?? this.incomingInvites,
      outgoingInvite:
          clearOutgoingInvite ? null : (outgoingInvite ?? this.outgoingInvite),
      partnerUserId:
          clearPartnerUserId ? null : (partnerUserId ?? this.partnerUserId),
      partnerProfile:
          clearPartnerProfile ? null : (partnerProfile ?? this.partnerProfile),
      errorMessage: errorMessage,
      infoMessage: infoMessage,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isSubmitting,
    acceptedConnection,
    incomingInvites,
    outgoingInvite,
    partnerUserId,
    partnerProfile,
    errorMessage,
    infoMessage,
  ];
}
