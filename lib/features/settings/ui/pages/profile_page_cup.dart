import 'dart:io';

import 'package:convetchat/app/adaptive/adaptive_loading_indicator.dart';
import 'package:convetchat/app/adaptive/adaptive_snackbar.dart';
import 'package:convetchat/app/adaptive/adaptive_text_field.dart';
import 'package:convetchat/core/utils/message_format.dart';
import 'package:convetchat/core/widgets/mxc_avatar.dart';
import 'package:convetchat/features/settings/ui/cubit/settings_cubit.dart';
import 'package:convetchat/features/settings/ui/cubit/settings_state.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class const ProfilePageCup({super.key}) extends StatefulWidget {
  @override
  State<ProfilePageCup> createState() => _ProfilePageCupState();
}

class _ProfilePageCupState() extends State<ProfilePageCup> {
  late final TextEditingController _nameController;
  bool _userEdited = false;
  String? _syncedName;

  @override
  void initState() {
    super.initState();
    final initial = context.read<SettingsCubit>().state.displayName ?? '';
    _nameController = TextEditingController(text: initial)
      ..addListener(_onNameChanged);
  }

  void _onNameChanged() {
    setState(() => _userEdited = true);
  }

  void _syncNameFromState(SettingsState state) {
    final name = state.displayName;
    if (_userEdited || name == null || name.isEmpty) return;
    if (_nameController.text == name || _syncedName == name) return;
    _syncedName = name;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_userEdited && _nameController.text != name) {
        _nameController.text = name;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool _canSave(SettingsState state) =>
      _nameController.text.trim().isNotEmpty &&
      _nameController.text.trim() != (state.displayName ?? '') &&
      !state.profileSaving;

  Future<void> _onSaveName() async {
    await context.read<SettingsCubit>().updateDisplayName(_nameController.text);
  }

  Widget _buildNameButton(SettingsState state) {
    if (state.profileSaving) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: AdaptiveLoadingIndicator(color: CupertinoColors.white),
        ),
      );
    }
    final canSave = _canSave(state);
    if (!canSave) return const SizedBox.shrink();
    return CupertinoButton(
      onPressed: _onSaveName,
      child: const Icon(CupertinoIcons.checkmark, size: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        _syncNameFromState(state);
        return CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(middle: const Text('Профиль')),
          child: SafeArea(
            child: ListView(
              padding: EdgeInsets.all(10),
              children: [
                const SizedBox(height: 12),
                const Center(child: _ProfileAvatar()),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: AdaptiveTextField(
                        controller: _nameController,
                        label: 'Имя',
                        enabled: !state.profileSaving,
                        onSubmitted: (_) => _onSaveName(),
                      ),
                    ),
                    _buildNameButton(state),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class const _ProfileAvatar() extends StatefulWidget {
  @override
  State<_ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState() extends State<_ProfileAvatar> {
  String? _previewPath;
  bool _avatarBusy = false;

  Future<void> _pickAvatar() async {
    final cubit = context.read<SettingsCubit>();
    if (cubit.state.profileSaving) return;
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (!mounted || file == null) return;
      setState(() {
        _previewPath = file.path;
        _avatarBusy = true;
      });
      await cubit.updateAvatar(
        file.path,
        name: file.name.isNotEmpty ? file.name : 'avatar.jpg',
      );
      if (!mounted) return;
      setState(() {
        _previewPath = null;
        _avatarBusy = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _previewPath = null;
        _avatarBusy = false;
      });
      AdaptiveSnackbar.show(
        context: context,
        message: 'Не удалось выбрать фотографию',
        type: .error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SettingsCubit>().state;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: state.profileSaving ? null : _pickAvatar,
          child: _buildAvatarImage(context, state),
        ),
        if (_avatarBusy)
          Positioned.fill(
            child: Center(
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: CupertinoColors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: AdaptiveLoadingIndicator(color: CupertinoColors.white),
                ),
              ),
            ),
          ),
        Positioned(
          right: 0,
          bottom: 2,
          child: GestureDetector(
            onTap: state.profileSaving ? null : _pickAvatar,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey5.resolveFrom(context),
                shape: BoxShape.circle,
                border: Border.all(
                  color: CupertinoColors.secondarySystemBackground.resolveFrom(
                    context,
                  ),
                  width: 2,
                ),
              ),
              child: const Icon(
                CupertinoIcons.photo_camera,
                size: 18,
                color: CupertinoColors.label,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarImage(BuildContext context, SettingsState state) {
    final preview = _previewPath;
    if (preview != null) {
      return ClipOval(
        child: Image.file(
          File(preview),
          width: 110,
          height: 110,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallbackAvatar(context, state, 110),
        ),
      );
    }
    return MxcAvatar(
      mxc: state.avatarMxc,
      fallback: avatarInitial(state.displayName ?? ''),
      size: 110,
      showLoadingRing: true,
      context: context,
    );
  }

  Widget _buildFallbackAvatar(
    BuildContext context,
    SettingsState state,
    double size,
  ) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: CupertinoColors.systemBlue.resolveFrom(context),
        shape: BoxShape.circle,
      ),
      child: Text(
        avatarInitial(state.displayName ?? ''),
        style: TextStyle(fontSize: size * 0.42, color: CupertinoColors.white),
      ),
    );
  }
}
