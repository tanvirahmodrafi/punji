import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_repository/expense_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'split_expense_connection_event.dart';
part 'split_expense_connection_state.dart';

class SplitExpenseConnectionBloc
    extends Bloc<SplitExpenseConnectionEvent, SplitExpenseConnectionState> {
  final ExpenseRepository expenseRepository;

  SplitExpenseConnectionBloc(this.expenseRepository)
    : super(const SplitExpenseConnectionState()) {
    on<LoadSplitExpenseConnection>(_onLoad);
    on<SendSplitExpenseInvite>(_onSendInvite);
    on<AcceptSplitExpenseInvite>(_onAcceptInvite);
    on<RejectSplitExpenseInvite>(_onRejectInvite);
    on<CancelOutgoingSplitExpenseInvite>(_onCancelInvite);
    on<DisconnectSplitExpenseConnection>(_onDisconnect);
    on<ClearSplitExpenseConnectionMessage>(_onClearMessage);
  }

  Future<void> _onLoad(
    LoadSplitExpenseConnection event,
    Emitter<SplitExpenseConnectionState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      final accepted = await expenseRepository.getAcceptedConnection();
      final incoming = await expenseRepository.getIncomingPendingConnections();
      final outgoing = await expenseRepository.getOutgoingPendingConnection();

      String? partnerUserId;
      Map<String, String?>? partnerProfile;
      if (accepted != null && userId != null) {
        partnerUserId = accepted.partnerIdFor(userId);
        partnerProfile = await expenseRepository.getUserProfileSummary(
          partnerUserId,
        );
      }

      emit(
        state.copyWith(
          isLoading: false,
          acceptedConnection: accepted,
          incomingInvites: incoming,
          outgoingInvite: outgoing,
          partnerUserId: partnerUserId,
          partnerProfile: partnerProfile,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to load split connection data: $e',
        ),
      );
    }
  }

  Future<void> _onSendInvite(
    SendSplitExpenseInvite event,
    Emitter<SplitExpenseConnectionState> emit,
  ) async {
    emit(
      state.copyWith(isSubmitting: true, errorMessage: null, infoMessage: null),
    );
    try {
      await expenseRepository.sendExpenseConnectionInviteByEmail(event.email);
      emit(
        state.copyWith(
          isSubmitting: false,
          infoMessage: 'Invitation sent successfully.',
        ),
      );
      add(const LoadSplitExpenseConnection());
    } catch (e) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: 'Failed to send invite: $e',
        ),
      );
    }
  }

  Future<void> _onAcceptInvite(
    AcceptSplitExpenseInvite event,
    Emitter<SplitExpenseConnectionState> emit,
  ) async {
    emit(
      state.copyWith(isSubmitting: true, errorMessage: null, infoMessage: null),
    );
    try {
      await expenseRepository.respondToExpenseConnection(
        connectionId: event.connectionId,
        accept: true,
      );
      emit(
        state.copyWith(
          isSubmitting: false,
          infoMessage: 'Connection accepted.',
        ),
      );
      add(const LoadSplitExpenseConnection());
    } catch (e) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: 'Failed to accept invite: $e',
        ),
      );
    }
  }

  Future<void> _onRejectInvite(
    RejectSplitExpenseInvite event,
    Emitter<SplitExpenseConnectionState> emit,
  ) async {
    emit(
      state.copyWith(isSubmitting: true, errorMessage: null, infoMessage: null),
    );
    try {
      await expenseRepository.respondToExpenseConnection(
        connectionId: event.connectionId,
        accept: false,
      );
      emit(
        state.copyWith(isSubmitting: false, infoMessage: 'Invite rejected.'),
      );
      add(const LoadSplitExpenseConnection());
    } catch (e) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: 'Failed to reject invite: $e',
        ),
      );
    }
  }

  Future<void> _onCancelInvite(
    CancelOutgoingSplitExpenseInvite event,
    Emitter<SplitExpenseConnectionState> emit,
  ) async {
    emit(
      state.copyWith(isSubmitting: true, errorMessage: null, infoMessage: null),
    );
    try {
      await expenseRepository.cancelOutgoingExpenseConnection(
        event.connectionId,
      );
      emit(
        state.copyWith(
          isSubmitting: false,
          infoMessage: 'Outgoing invite cancelled.',
        ),
      );
      add(const LoadSplitExpenseConnection());
    } catch (e) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: 'Failed to cancel invite: $e',
        ),
      );
    }
  }

  Future<void> _onDisconnect(
    DisconnectSplitExpenseConnection event,
    Emitter<SplitExpenseConnectionState> emit,
  ) async {
    emit(
      state.copyWith(isSubmitting: true, errorMessage: null, infoMessage: null),
    );
    try {
      await expenseRepository.disconnectExpenseConnection(event.connectionId);
      emit(
        state.copyWith(
          isSubmitting: false,
          infoMessage: 'Disconnected successfully.',
        ),
      );
      add(const LoadSplitExpenseConnection());
    } catch (e) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: 'Failed to disconnect: $e',
        ),
      );
    }
  }

  Future<void> _onClearMessage(
    ClearSplitExpenseConnectionMessage event,
    Emitter<SplitExpenseConnectionState> emit,
  ) async {
    emit(state.copyWith(errorMessage: null, infoMessage: null));
  }
}
