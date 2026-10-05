import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/features/chat/domain/repositories/chat_repository.dart';
import 'package:convetchat/features/chat/ui/widgets/reaction_picker.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:talker_flutter/talker_flutter.dart';

class const ChatSettingsPageCup({super.key}) extends StatefulWidget {
  @override
  State<ChatSettingsPageCup> createState() => _ChatSettingsPageCupState();
}

class _ChatSettingsPageCupState() extends State<ChatSettingsPageCup> {
  bool _formattedMessages = true;
  bool _bigEmojis = true;
  bool _hideUnknownFormats = false;
  bool _hideDeletedMessages = false;
  bool _hideUndecryptable = false;
  bool _autoplayMedia = true;
  bool _voiceAutoplay = true;
  bool _videoAutoplay = true;
  bool _sendOnEnter = false;
  bool _swipeToReply = true;
  bool _quickReaction = true;
  String _quickEmoji = '❤️';

  @override
  void initState() {
    super.initState();
    _loadMarkdown();
    _loadBigEmojis();
    _loadHideFlags();
    _loadAutoplay();
    _loadInteraction();
  }

  Future<void> _loadMarkdown() async {
    try {
      final enabled = await getIt<ChatRepository>().isMarkdownEnabled();
      if (!mounted) return;
      setState(() => _formattedMessages = enabled);
    } catch (e, s) {
      getIt<Talker>().error('[settings] Не удалось прочитать markdown', e, s);
    }
  }

  Future<void> _setMarkdown(bool value) async {
    setState(() => _formattedMessages = value);
    try {
      await getIt<ChatRepository>().setMarkdownEnabled(value);
    } catch (e, s) {
      getIt<Talker>().error('[settings] Не удалось сохранить markdown', e, s);
    }
  }

  Future<void> _loadBigEmojis() async {
    try {
      final enabled = await getIt<ChatRepository>().isBigEmojisEnabled();
      if (!mounted) return;
      setState(() => _bigEmojis = enabled);
    } catch (e, s) {
      getIt<Talker>().error('[settings] Не удалось прочитать эмодзи', e, s);
    }
  }

  Future<void> _setBigEmojis(bool value) async {
    setState(() => _bigEmojis = value);
    try {
      await getIt<ChatRepository>().setBigEmojisEnabled(value);
    } catch (e, s) {
      getIt<Talker>().error('[settings] Не удалось сохранить эмодзи', e, s);
    }
  }

  Future<void> _loadHideFlags() async {
    try {
      final chat = getIt<ChatRepository>();
      final hideUnknown = await chat.isHideUnknownFormatsEnabled();
      final hideDeleted = await chat.isHideDeletedEnabled();
      final hideUndecryptable = await chat.isHideUndecryptableEnabled();
      if (!mounted) return;
      setState(() {
        _hideUnknownFormats = hideUnknown;
        _hideDeletedMessages = hideDeleted;
        _hideUndecryptable = hideUndecryptable;
      });
    } catch (e, s) {
      getIt<Talker>().error('[settings] Не удалось прочитать скрытие', e, s);
    }
  }

  Future<void> _setHideUnknown(bool value) async {
    setState(() => _hideUnknownFormats = value);
    try {
      await getIt<ChatRepository>().setHideUnknownFormatsEnabled(value);
    } catch (e, s) {
      getIt<Talker>().error('[settings] Не удалось сохранить скрытие', e, s);
    }
  }

  Future<void> _setHideDeleted(bool value) async {
    setState(() => _hideDeletedMessages = value);
    try {
      await getIt<ChatRepository>().setHideDeletedEnabled(value);
    } catch (e, s) {
      getIt<Talker>().error('[settings] Не удалось сохранить скрытие', e, s);
    }
  }

  Future<void> _setHideUndecryptable(bool value) async {
    setState(() => _hideUndecryptable = value);
    try {
      await getIt<ChatRepository>().setHideUndecryptableEnabled(value);
    } catch (e, s) {
      getIt<Talker>().error('[settings] Не удалось сохранить скрытие', e, s);
    }
  }

  Future<void> _loadAutoplay() async {
    try {
      final chat = getIt<ChatRepository>();
      final autoplay = await chat.isAutoplayEnabled();
      final voice = await chat.isVoiceAutoplayEnabled();
      final video = await chat.isVideoAutoplayEnabled();
      if (!mounted) return;
      setState(() {
        _autoplayMedia = autoplay;
        _voiceAutoplay = voice;
        _videoAutoplay = video;
      });
    } catch (e, s) {
      getIt<Talker>().error('[settings] Не удалось прочитать автоплей', e, s);
    }
  }

  Future<void> _setAutoplay(bool value) async {
    setState(() => _autoplayMedia = value);
    try {
      await getIt<ChatRepository>().setAutoplayEnabled(value);
    } catch (e, s) {
      getIt<Talker>().error('[settings] Не удалось сохранить автоплей', e, s);
    }
  }

  Future<void> _setVoiceAutoplay(bool value) async {
    setState(() => _voiceAutoplay = value);
    try {
      await getIt<ChatRepository>().setVoiceAutoplayEnabled(value);
    } catch (e, s) {
      getIt<Talker>().error('[settings] Не удалось сохранить автоплей', e, s);
    }
  }

  Future<void> _setVideoAutoplay(bool value) async {
    setState(() => _videoAutoplay = value);
    try {
      await getIt<ChatRepository>().setVideoAutoplayEnabled(value);
    } catch (e, s) {
      getIt<Talker>().error('[settings] Не удалось сохранить автоплей', e, s);
    }
  }

  Future<void> _loadInteraction() async {
    try {
      final chat = getIt<ChatRepository>();
      final sendOnEnter = await chat.isSendOnEnterEnabled();
      final swipe = await chat.isSwipeToReplyEnabled();
      final quick = await chat.isQuickReactionEnabled();
      final emoji = await chat.getQuickReactionEmoji();
      if (!mounted) return;
      setState(() {
        _sendOnEnter = sendOnEnter;
        _swipeToReply = swipe;
        _quickReaction = quick;
        _quickEmoji = emoji;
      });
    } catch (e, s) {
      getIt<Talker>().error('[settings] Не удалось прочитать ввод', e, s);
    }
  }

  Future<void> _setSendOnEnter(bool value) async {
    setState(() => _sendOnEnter = value);
    try {
      await getIt<ChatRepository>().setSendOnEnterEnabled(value);
    } catch (e, s) {
      getIt<Talker>().error('[settings] Не удалось сохранить ввод', e, s);
    }
  }

  Future<void> _setSwipeToReply(bool value) async {
    setState(() => _swipeToReply = value);
    try {
      await getIt<ChatRepository>().setSwipeToReplyEnabled(value);
    } catch (e, s) {
      getIt<Talker>().error('[settings] Не удалось сохранить ввод', e, s);
    }
  }

  Future<void> _setQuickReaction(bool value) async {
    setState(() => _quickReaction = value);
    try {
      await getIt<ChatRepository>().setQuickReactionEnabled(value);
    } catch (e, s) {
      getIt<Talker>().error('[settings] Не удалось сохранить ввод', e, s);
    }
  }

  Future<void> _pickQuickEmoji() async {
    final picked = await showExtraReactionsSheet(context);
    if (picked == null || picked.isEmpty) return;
    setState(() => _quickEmoji = picked);
    try {
      await getIt<ChatRepository>().setQuickReactionEmoji(picked);
    } catch (e, s) {
      getIt<Talker>().error('[settings] Не удалось сохранить реакцию', e, s);
    }
  }

  CupertinoListTile _switchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return CupertinoListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: CupertinoSwitch(value: value, onChanged: onChanged),
      onTap: () => onChanged(!value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: const Text('Чат')),
      child: SafeArea(
        child: ListView(
          children: [
            CupertinoListSection.insetGrouped(
              backgroundColor: CupertinoColors.transparent,
              children: [
                _switchTile(
                  icon: CupertinoIcons.textformat,
                  title: 'Форматированные сообщения',
                  value: _formattedMessages,
                  onChanged: _setMarkdown,
                ),
                _switchTile(
                  icon: CupertinoIcons.smiley,
                  title: 'Большие эмодзи',
                  value: _bigEmojis,
                  onChanged: _setBigEmojis,
                ),
              ],
            ),
            CupertinoListSection.insetGrouped(
              backgroundColor: CupertinoColors.transparent,
              children: [
                _switchTile(
                  icon: CupertinoIcons.eye_slash,
                  title: 'Скрывать неизвестные форматы сообщений',
                  value: _hideUnknownFormats,
                  onChanged: _setHideUnknown,
                ),
                _switchTile(
                  icon: CupertinoIcons.trash,
                  title: 'Скрывать удаленные сообщения',
                  value: _hideDeletedMessages,
                  onChanged: _setHideDeleted,
                ),
                _switchTile(
                  icon: CupertinoIcons.lock,
                  title: 'Скрывать нерасшифрованные сообщения',
                  value: _hideUndecryptable,
                  onChanged: _setHideUndecryptable,
                ),
              ],
            ),
            CupertinoListSection.insetGrouped(
              backgroundColor: CupertinoColors.transparent,
              children: [
                _switchTile(
                  icon: CupertinoIcons.play_circle,
                  title: 'Автовоспроизведение',
                  value: _autoplayMedia,
                  onChanged: _setAutoplay,
                ),
                if (_autoplayMedia)
                  _switchTile(
                    icon: CupertinoIcons.mic_fill,
                    title: 'Голосовые сообщения',
                    value: _voiceAutoplay,
                    onChanged: _setVoiceAutoplay,
                  ),
                if (_autoplayMedia)
                  _switchTile(
                    icon: CupertinoIcons.videocam_fill,
                    title: 'Видеосообщения',
                    value: _videoAutoplay,
                    onChanged: _setVideoAutoplay,
                  ),
              ],
            ),
            CupertinoListSection.insetGrouped(
              backgroundColor: CupertinoColors.transparent,
              children: [
                _switchTile(
                  icon: CupertinoIcons.return_icon,
                  title: 'Отправлять по Enter',
                  value: _sendOnEnter,
                  onChanged: _setSendOnEnter,
                ),
                _switchTile(
                  icon: CupertinoIcons.reply,
                  title: 'Свайп для ответа',
                  value: _swipeToReply,
                  onChanged: _setSwipeToReply,
                ),
                _switchTile(
                  icon: CupertinoIcons.bolt_fill,
                  title: 'Быстрая реакция',
                  value: _quickReaction,
                  onChanged: _setQuickReaction,
                ),
                if (_quickReaction)
                  CupertinoListTile(
                    leading: const Icon(CupertinoIcons.heart_fill),
                    title: const Text('Реакция'),
                    trailing: Text(
                      _quickEmoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                    onTap: _pickQuickEmoji,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
