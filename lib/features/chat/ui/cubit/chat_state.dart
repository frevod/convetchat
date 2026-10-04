import 'package:convetchat/features/chat/domain/entities/chat_message.dart';
import 'package:convetchat/features/chat/domain/entities/chat_send_restriction.dart';
import 'package:convetchat/features/chat/domain/entities/pending_media.dart';
import 'package:convetchat/features/chat/domain/entities/record_mode.dart';
import 'package:equatable/equatable.dart';

class const ChatState({
  final String roomName = 'Чат',
  final String? avatarMxc,
  final List<ChatMessage> messages = const [],
  final bool isLoading = true,
  final bool isLoadingMore = false,
  final String? errorMessage,

  final ChatMessage? replyTo,

  final ChatMessage? editing,

  final String? scrollToEventId,
  final int scrollNonce = 0,

  final String? highlightEventId,

  final Set<String> expandedEventIds = const <String>{},

  final bool isRecording = false,
  final Duration recordElapsed = Duration.zero,
  final List<double> recordLevels = const <double>[],

  final bool recordLocked = false,

  final RecordMode recordMode = RecordMode.voice,

  final bool circleReady = false,

  final String? partnerUserId,
  final bool partnerOnline = false,
  final DateTime? partnerLastActive,
  final List<({String id, String name})> typingUsers = const [],

  final ChatSendRestriction sendRestriction = ChatSendRestriction.none,

  final List<PendingMedia> pendingMedia = const [],

  final Set<String> selectedEventIds = const <String>{},

  final List<({String id, String name})> forwardTargets = const [],

  final bool forwardPickerOpen = false,

  final List<String> pinnedEventIds = const [],
}) extends Equatable {
  ChatState copyWith({
    String Function()? roomName,
    String? Function()? avatarMxc,
    List<ChatMessage> Function()? messages,
    bool Function()? isLoading,
    bool Function()? isLoadingMore,
    String? Function()? errorMessage,
    ChatMessage? Function()? replyTo,

    ChatMessage? Function()? editing,
    String? Function()? scrollToEventId,
    int Function()? scrollNonce,
    String? Function()? highlightEventId,
    Set<String> Function()? expandedEventIds,
    bool Function()? isRecording,
    Duration Function()? recordElapsed,
    List<double> Function()? recordLevels,
    bool Function()? recordLocked,
    RecordMode Function()? recordMode,
    bool Function()? circleReady,
    String? Function()? partnerUserId,
    bool Function()? partnerOnline,
    DateTime? Function()? partnerLastActive,
    List<({String id, String name})> Function()? typingUsers,
    ChatSendRestriction Function()? sendRestriction,
    List<PendingMedia> Function()? pendingMedia,
    Set<String> Function()? selectedEventIds,
    List<({String id, String name})> Function()? forwardTargets,
    bool Function()? forwardPickerOpen,
    List<String> Function()? pinnedEventIds,
  }) {
    return ChatState(
      roomName: roomName != null ? roomName() : this.roomName,
      avatarMxc: avatarMxc != null ? avatarMxc() : this.avatarMxc,
      messages: messages != null ? messages() : this.messages,
      isLoading: isLoading != null ? isLoading() : this.isLoading,
      isLoadingMore: isLoadingMore != null
          ? isLoadingMore()
          : this.isLoadingMore,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      replyTo: replyTo != null ? replyTo() : this.replyTo,
      editing: editing != null ? editing() : this.editing,
      scrollToEventId: scrollToEventId != null
          ? scrollToEventId()
          : this.scrollToEventId,
      scrollNonce: scrollNonce != null ? scrollNonce() : this.scrollNonce,
      highlightEventId: highlightEventId != null
          ? highlightEventId()
          : this.highlightEventId,
      expandedEventIds: expandedEventIds != null
          ? expandedEventIds()
          : this.expandedEventIds,
      isRecording: isRecording != null ? isRecording() : this.isRecording,
      recordElapsed: recordElapsed != null
          ? recordElapsed()
          : this.recordElapsed,
      recordLevels: recordLevels != null ? recordLevels() : this.recordLevels,
      recordLocked: recordLocked != null ? recordLocked() : this.recordLocked,
      recordMode: recordMode != null ? recordMode() : this.recordMode,
      circleReady: circleReady != null ? circleReady() : this.circleReady,
      partnerUserId: partnerUserId != null
          ? partnerUserId()
          : this.partnerUserId,
      partnerOnline: partnerOnline != null
          ? partnerOnline()
          : this.partnerOnline,
      partnerLastActive: partnerLastActive != null
          ? partnerLastActive()
          : this.partnerLastActive,
      typingUsers: typingUsers != null ? typingUsers() : this.typingUsers,
      sendRestriction: sendRestriction != null
          ? sendRestriction()
          : this.sendRestriction,
      pendingMedia: pendingMedia != null ? pendingMedia() : this.pendingMedia,
      selectedEventIds: selectedEventIds != null
          ? selectedEventIds()
          : this.selectedEventIds,
      forwardTargets: forwardTargets != null
          ? forwardTargets()
          : this.forwardTargets,
      forwardPickerOpen: forwardPickerOpen != null
          ? forwardPickerOpen()
          : this.forwardPickerOpen,
      pinnedEventIds: pinnedEventIds != null
          ? pinnedEventIds()
          : this.pinnedEventIds,
    );
  }

  @override
  List<Object?> get props => [
    roomName,
    avatarMxc,
    messages,
    isLoading,
    isLoadingMore,
    errorMessage,
    replyTo,
    editing,
    scrollToEventId,
    scrollNonce,
    highlightEventId,
    expandedEventIds,
    isRecording,
    recordElapsed,
    recordLevels,
    recordLocked,
    recordMode,
    circleReady,
    partnerUserId,
    partnerOnline,
    partnerLastActive,
    typingUsers,
    sendRestriction,
    pendingMedia,
    selectedEventIds,
    forwardTargets,
    forwardPickerOpen,
    pinnedEventIds,
  ];
}
