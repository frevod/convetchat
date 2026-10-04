import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/telegram/telegram_feedback_service.dart';
import 'package:convetchat/features/settings/ui/cubit/feedback_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:matrix/matrix.dart';

class FeedbackCubit(final TelegramFeedbackService _service)
    extends Cubit<FeedbackState> {
  this : super(const FeedbackState());

  Future<void> send(
    String message, {
    List<FeedbackAttachment> attachments = const [],
    bool includeLogs = false,
  }) async {
    if (isClosed) return;
    final hasContent =
        message.trim().isNotEmpty || attachments.isNotEmpty || includeLogs;
    if (!hasContent) return;

    emit(
      state.copyWith(
        isSending: () => true,
        sent: () => false,
        errorMessage: () => null,
      ),
    );

    final result = await _service.sendBugReport(
      message,
      userId: _currentUserId,
      attachments: attachments,
      includeLogs: includeLogs,
    );
    if (isClosed) return;

    result.ok
        ? emit(state.copyWith(isSending: () => false, sent: () => true))
        : emit(
            state.copyWith(
              isSending: () => false,
              errorMessage: () => result.error ?? 'Не удалось отправить',
            ),
          );
  }

  void reset() {
    if (isClosed) return;
    emit(const FeedbackState());
  }

  void clearError() {
    emit(state.copyWith(errorMessage: () => null));
  }

  String? get _currentUserId {
    try {
      if (getIt.isReadySync<Client>() && getIt<Client>().isLogged()) {
        return getIt<Client>().userID;
      }
    } catch (_) {}
    return null;
  }
}
