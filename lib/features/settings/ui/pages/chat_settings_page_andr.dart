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
  bool _newCameraApi = false;
  bool _cameraMirror = true;
  bool _cameraAutofocus = true;
  int _cameraFps = 30;

  static const _fpsOptions = [24, 30, 60];

  @override
  void initState() {
    super.initState();
    _loadMarkdown();
    _loadBigEmojis();
    _loadHideFlags();
    _loadAutoplay();
    _loadInteraction();
    _loadCircleQuality();
    _loadCameraApi();
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
    await _setCircleQuality(selected.first.value);
  }

  Future<void> _setCircleQuality(String quality) async {
    setState(() => _circleQuality = quality);
    try {
      await getIt<ChatRepository>().setCircleVideoQuality(quality);
    } catch (e, s) {
      getIt<Talker>().error('[settings] save circle quality failed', e, s);
    }
  }

  Future<void> _loadCameraApi() async {
    try {
      final chat = getIt<ChatRepository>();
      final api = await chat.isNewCameraApiEnabled();
      final mirror = await chat.isCameraMirrorEnabled();
      final focus = await chat.isCameraAutofocusEnabled();
      final fps = await chat.getCameraFps();
      if (!mounted) return;
      setState(() {
        _newCameraApi = api;
        _cameraMirror = mirror;
        _cameraAutofocus = focus;
        _cameraFps = fps;
      });
    } catch (e, s) {
      getIt<Talker>().error('[settings] read camera api failed', e, s);
    }
  }

  Future<void> _setNewCameraApi(bool value) async {
    setState(() => _newCameraApi = value);
    try {
      await getIt<ChatRepository>().setNewCameraApiEnabled(value);
    } catch (e, s) {
      getIt<Talker>().error('[settings] save camera api failed', e, s);
    }
  }

  Future<void> _setCameraMirror(bool value) async {
    setState(() => _cameraMirror = value);
    try {
      await getIt<ChatRepository>().setCameraMirrorEnabled(value);
    } catch (e, s) {
      getIt<Talker>().error('[settings] save camera mirror failed', e, s);
    }
  }

  Future<void> _setCameraAutofocus(bool value) async {
    setState(() => _cameraAutofocus = value);
    try {
      await getIt<ChatRepository>().setCameraAutofocusEnabled(value);
    } catch (e, s) {
      getIt<Talker>().error('[settings] save camera focus failed', e, s);
    }
  }

  Future<void> _onCameraFpsChanged(
    List<M3EDropdownItem<String>> selected,
  ) async {
    if (selected.isEmpty) return;
    final fps = int.tryParse(selected.first.value) ?? 30;
    setState(() => _cameraFps = fps);
    try {
      await getIt<ChatRepository>().setCameraFps(fps);
    } catch (e, s) {
      getIt<Talker>().error('[settings] save camera fps failed', e, s);
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
      _switchRow(
        icon: Icons.camera_alt_rounded,
        headline: 'Новый движок камеры',
        supportingText: 'Экспериментальный движок записи видеосообщений',
        value: _newCameraApi,
        onChanged: _setNewCameraApi,
      ),
      M3EListItem(
        leading: const Icon(Icons.high_quality_rounded),
        headline: 'Качество',
        trailing: SizedBox(
          width: 180,
          child: M3EDropdownMenu<String>(
            singleSelect: true,
            showChipAnimation: false,
            searchEnabled: false,
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
        ),
      ),
      if (_newCameraApi)
        _switchRow(
          icon: Icons.flip_camera_android_rounded,
          headline: 'Зеркалирование фронтальной камеры',
          value: _cameraMirror,
          onChanged: _setCameraMirror,
        ),
      if (_newCameraApi)
        M3EListItem(
          leading: const Icon(Icons.speed_rounded),
          headline: 'Частота кадров',
          trailing: SizedBox(
            width: 140,
            child: M3EDropdownMenu<String>(
              singleSelect: true,
              showChipAnimation: false,
              searchEnabled: false,
              items: [
                for (final fps in _fpsOptions)
                  M3EDropdownItem(
                    label: '$fps fps',
                    value: '$fps',
                    selected: _cameraFps == fps,
                  ),
              ],
              onSelectionChanged: _onCameraFpsChanged,
            ),
          ),
        ),
      if (_newCameraApi)
        _switchRow(
          icon: Icons.center_focus_strong_rounded,
          headline: 'Автофокус',
          value: _cameraAutofocus,
          onChanged: _setCameraAutofocus,
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
            _rowsList(videoRows),
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
