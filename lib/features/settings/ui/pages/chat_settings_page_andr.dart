import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/features/chat/domain/repositories/chat_repository.dart';
import 'package:convetchat/features/chat/domain/services/circle_video_service.dart';
import 'package:convetchat/features/chat/ui/widgets/reaction_picker.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:talker_flutter/talker_flutter.dart';

class const ChatSettingsPageAndr({super.key}) extends StatefulWidget {
  @override
  State<ChatSettingsPageAndr> createState() => _ChatSettingsPageAndrState();
}

class _ChatSettingsPageAndrState() extends State<ChatSettingsPageAndr> {
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
  String _circleQuality = CircleVideoService.defaultQualityName;

  @override
  void initState() {
    super.initState();
    _loadMarkdown();
    _loadBigEmojis();
    _loadHideFlags();
    _loadAutoplay();
    _loadInteraction();
    _loadCircleQuality();
  }

  Future<void> _loadMarkdown() async {
    try {
      final enabled = await getIt<ChatRepository>().isMarkdownEnabled();
      if (!mounted) return;
      setState(() => _formattedMessages = enabled);
    } catch (e, s) {
      getIt<Talker>().error('[settings] read markdown failed', e, s);
    }
  }

  Future<void> _setMarkdown(bool value) async {
    setState(() => _formattedMessages = value);
    try {
      await getIt<ChatRepository>().setMarkdownEnabled(value);
    } catch (e, s) {
      getIt<Talker>().error('[settings] save markdown failed', e, s);
    }
  }

  Future<void> _loadBigEmojis() async {
    try {
      final enabled = await getIt<ChatRepository>().isBigEmojisEnabled();
      if (!mounted) return;
      setState(() => _bigEmojis = enabled);
    } catch (e, s) {
      getIt<Talker>().error('[settings] read big emojis failed', e, s);
    }
  }

  Future<void> _setBigEmojis(bool value) async {
    setState(() => _bigEmojis = value);
    try {
      await getIt<ChatRepository>().setBigEmojisEnabled(value);
    } catch (e, s) {
      getIt<Talker>().error('[settings] save big emojis failed', e, s);
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
      getIt<Talker>().error('[settings] read hide flags failed', e, s);
    }
  }

  Future<void> _setHideUnknown(bool value) async {
    setState(() => _hideUnknownFormats = value);
    try {
      await getIt<ChatRepository>().setHideUnknownFormatsEnabled(value);
    } catch (e, s) {
      getIt<Talker>().error('[settings] save hide flags failed', e, s);
    }
  }

  Future<void> _setHideDeleted(bool value) async {
    setState(() => _hideDeletedMessages = value);
    try {
      await getIt<ChatRepository>().setHideDeletedEnabled(value);
    } catch (e, s) {
      getIt<Talker>().error('[settings] save hide flags failed', e, s);
    }
  }

  Future<void> _setHideUndecryptable(bool value) async {
    setState(() => _hideUndecryptable = value);
    try {
      await getIt<ChatRepository>().setHideUndecryptableEnabled(value);
    } catch (e, s) {
      getIt<Talker>().error('[settings] save hide flags failed', e, s);
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
      getIt<Talker>().error('[settings] read autoplay failed', e, s);
    }
  }

  Future<void> _setAutoplay(bool value) async {
    setState(() => _autoplayMedia = value);
    try {
      await getIt<ChatRepository>().setAutoplayEnabled(value);
    } catch (e, s) {
      getIt<Talker>().error('[settings] save autoplay failed', e, s);
    }
  }

  Future<void> _setVoiceAutoplay(bool value) async {
    setState(() => _voiceAutoplay = value);
    try {
      await getIt<ChatRepository>().setVoiceAutoplayEnabled(value);
    } catch (e, s) {
      getIt<Talker>().error('[settings] save autoplay failed', e, s);
    }
  }

  Future<void> _setVideoAutoplay(bool value) async {
    setState(() => _videoAutoplay = value);
    try {
      await getIt<ChatRepository>().setVideoAutoplayEnabled(value);
    } catch (e, s) {
      getIt<Talker>().error('[settings] save autoplay failed', e, s);
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
      getIt<Talker>().error('[settings] read interaction failed', e, s);
    }
  }

  Future<void> _setSendOnEnter(bool value) async {
    setState(() => _sendOnEnter = value);
    try {
      await getIt<ChatRepository>().setSendOnEnterEnabled(value);
    } catch (e, s) {
      getIt<Talker>().error('[settings] save interaction failed', e, s);
    }
  }

  Future<void> _setSwipeToReply(bool value) async {
    setState(() => _swipeToReply = value);
    try {
      await getIt<ChatRepository>().setSwipeToReplyEnabled(value);
    } catch (e, s) {
      getIt<Talker>().error('[settings] save interaction failed', e, s);
    }
  }

  Future<void> _setQuickReaction(bool value) async {
    setState(() => _quickReaction = value);
    try {
      await getIt<ChatRepository>().setQuickReactionEnabled(value);
    } catch (e, s) {
      getIt<Talker>().error('[settings] save interaction failed', e, s);
    }
  }

  Future<void> _pickQuickEmoji() async {
    final picked = await showExtraReactionsSheet(context);
    if (picked == null || picked.isEmpty) return;
    setState(() => _quickEmoji = picked);
    try {
      await getIt<ChatRepository>().setQuickReactionEmoji(picked);
    } catch (e, s) {
      getIt<Talker>().error('[settings] save quick reaction failed', e, s);
    }
  }

  Future<void> _loadCircleQuality() async {
    try {
      final quality = await getIt<ChatRepository>().getCircleVideoQuality();
      if (!mounted) return;
      setState(() => _circleQuality = quality);
    } catch (e, s) {
      getIt<Talker>().error('[settings] read circle quality failed', e, s);
    }
  }

  Future<void> _onCircleQualityChanged(
    List<M3EDropdownItem<String>> selected,
  ) async {
    if (selected.isEmpty) return;
    final quality = selected.first.value;
    setState(() => _circleQuality = quality);
    try {
      await getIt<ChatRepository>().setCircleVideoQuality(quality);
    } catch (e, s) {
      getIt<Talker>().error('[settings] save circle quality failed', e, s);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedRows = [
      _switchRow(
        icon: Icons.text_fields_rounded,
        headline: 'Markdown',
        supportingText: 'Отображать отформатированные сообщения в Markdown',
        value: _formattedMessages,
        onChanged: _setMarkdown,
      ),
      _switchRow(
        icon: Icons.emoji_emotions_rounded,
        headline: 'Большие эмодзи',
        value: _bigEmojis,
        onChanged: _setBigEmojis,
      ),
    ];
    final hiddenRows = [
      _switchRow(
        icon: Icons.help_outline_rounded,
        headline: 'Скрывать неизвестные форматы',
        value: _hideUnknownFormats,
        onChanged: _setHideUnknown,
      ),
      _switchRow(
        icon: Icons.delete_outline_rounded,
        headline: 'Скрывать удаленные сообщения',
        value: _hideDeletedMessages,
        onChanged: _setHideDeleted,
      ),
      _switchRow(
        icon: Icons.lock_outline_rounded,
        headline: 'Скрывать нерасшифрованные сообщения',
        value: _hideUndecryptable,
        onChanged: _setHideUndecryptable,
      ),
    ];
    final autoplayRows = [
      _switchRow(
        icon: Icons.play_circle_rounded,
        headline: 'Автовоспроизведение',
        supportingText:
            'Автовоспроизведение следующего голосового или видеосообщения',
        value: _autoplayMedia,
        onChanged: _setAutoplay,
      ),
      if (_autoplayMedia)
        _switchRow(
          icon: Icons.mic_rounded,
          headline: 'Голосовые сообщения',
          value: _voiceAutoplay,
          onChanged: _setVoiceAutoplay,
        ),
      if (_autoplayMedia)
        _switchRow(
          icon: Icons.videocam_rounded,
          headline: 'Видеосообщения',
          value: _videoAutoplay,
          onChanged: _setVideoAutoplay,
        ),
    ];
    final otherRows = [
      _switchRow(
        icon: Icons.keyboard_return_rounded,
        headline: 'Отправлять по Enter',
        value: _sendOnEnter,
        onChanged: _setSendOnEnter,
      ),
      _switchRow(
        icon: Icons.swipe_left_rounded,
        headline: 'Свайп для ответа',
        value: _swipeToReply,
        onChanged: _setSwipeToReply,
      ),
      _switchRow(
        icon: Icons.bolt_rounded,
        headline: 'Быстрая реакция',
        value: _quickReaction,
        onChanged: _setQuickReaction,
      ),
      if (_quickReaction)
        M3EListItem(
          leading: const Icon(Icons.favorite_rounded),
          headline: 'Реакция',
          trailing: Text(_quickEmoji),
          onTap: _pickQuickEmoji,
        ),
    ];
    final videoRows = [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Row(
              spacing: 16,
              children: [
                const Icon(Icons.videocam_rounded),
                Text(
                  'Качество видеосообщений',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Разрешение записи кружков. Выше качество — тяжелее файлы.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            M3EDropdownMenu<String>(
              singleSelect: true,
              showChipAnimation: false,
              items: [
                for (final name in CircleVideoService.qualityNames)
                  M3EDropdownItem(
                    label: CircleVideoService.qualityLabel(name),
                    value: name,
                    selected: _circleQuality == name,
                  ),
              ],
              onSelectionChanged: _onCircleQualityChanged,
            ),
          ],
        ),
      ),
    ];
    return Scaffold(
      appBar: M3EAppBar.top(
        shapeFamily: .round,
        density: .compact,
        title: const Text('Чат'),
        automaticallyImplyLeading: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(8.0),
          children: [
            _rowsList(formattedRows),
            const SizedBox(height: 12),
            _rowsList(hiddenRows),
            const SizedBox(height: 12),
            _rowsList(autoplayRows),
            const SizedBox(height: 12),
            M3EList(
              itemCount: videoRows.length,
              itemBuilder: (context, index) => videoRows[index],
            ),
            const SizedBox(height: 12),
            _rowsList(otherRows),
          ],
        ),
      ),
    );
  }

  M3EList _rowsList(List<M3EListItem> rows) {
    return M3EList(
      itemCount: rows.length,
      onTap: (index) => rows[index].onTap?.call(),
      itemBuilder: (context, index) => rows[index],
    );
  }

  M3EListItem _switchRow({
    required IconData icon,
    required String headline,
    String? supportingText,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return M3EListItem(
      leading: Icon(icon),
      headline: headline,
      supportingText: supportingText,
      trailing: M3ESwitch(value: value, onChanged: onChanged),
      onTap: () => onChanged(!value),
    );
  }
}
