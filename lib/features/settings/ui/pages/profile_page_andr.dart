import 'dart:io';

import 'package:convetchat/app/adaptive/adaptive_loading_indicator.dart';
import 'package:convetchat/app/adaptive/adaptive_snackbar.dart';
import 'package:convetchat/app/adaptive/adaptive_text_field.dart';
import 'package:convetchat/core/presence/presence_mode.dart';
import 'package:convetchat/core/utils/message_format.dart';
import 'package:convetchat/core/widgets/mxc_avatar.dart';
import 'package:convetchat/features/settings/ui/cubit/presence_cubit.dart';
import 'package:convetchat/features/settings/ui/cubit/presence_state.dart';
import 'package:convetchat/features/settings/ui/cubit/settings_cubit.dart';
import 'package:convetchat/features/settings/ui/cubit/settings_state.dart';
import 'package:convetchat/features/settings/ui/widgets/profile_field_sheet.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:system_asset_picker/system_asset_picker.dart';

class const ProfilePageAndr({super.key}) extends StatefulWidget {
  @override
  State<ProfilePageAndr> createState() => _ProfilePageAndrState();
}

class _ProfilePageAndrState() extends State<ProfilePageAndr> {
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
          child: AdaptiveLoadingIndicator(),
        ),
      );
    }
    if (!_canSave(state)) return const SizedBox.shrink();
    return M3EIconButton(
      icon: const Icon(Icons.check),
      onPressed: _onSaveName,
      tooltip: 'Сохранить имя',
      variant: .filled,
      size: M3EIconButtonSize.md,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        _syncNameFromState(state);
        return Scaffold(
          appBar: M3EAppBar.top(
            shapeFamily: .round,
            density: .compact,
            title: const Text('Профиль'),
            automaticallyImplyLeading: true,
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            children: [
              const SizedBox(height: 24),
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
                  const SizedBox(width: 12),
                  _buildNameButton(state),
                ],
              ),
              if (state.profileFieldsSupported &&
                  state.customFields.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Дополнительно',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                _CustomFieldsList(state: state),
              ],
              BlocBuilder<PresenceCubit, PresenceState>(
                builder: (context, presence) {
                  if (presence.isLoading || !presence.supported) {
                    return const SizedBox.shrink();
                  }
                  final cubit = context.read<PresenceCubit>();
                  return Column(
                    crossAxisAlignment: .start,
                    children: [
                      const SizedBox(height: 24),
                      Text(
                        'Статус',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: M3ESegmentedButton<PresenceMode>(
                          segments: const [
                            M3ESegment(
                              value: PresenceMode.online,
                              label: 'В сети',
                            ),
                            M3ESegment(
                              value: PresenceMode.busy,
                              label: 'Занят',
                            ),
                            M3ESegment(
                              value: PresenceMode.offline,
                              label: 'Невидимка',
                            ),
                          ],
                          selected: {presence.mode},
                          enabled: !presence.isSaving,
                          onSelectionChanged: (selected) =>
                              cubit.setMode(selected.single),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class const _CustomFieldsList({required final SettingsState state})
    extends StatelessWidget {
  Future<void> _edit(BuildContext context, String field, String value) async {
    final updated = await editProfileFieldSheet(
      context: context,
      field: field,
      initialValue: value,
    );
    if (updated == null || !context.mounted) return;
    await context.read<SettingsCubit>().updateProfileField(field, updated);
  }

  Future<void> _add(BuildContext context) async {
    final created = await addProfileFieldSheet(
      context: context,
      addable: state.addableProfileFields,
    );
    if (created == null || !context.mounted) return;
    await context.read<SettingsCubit>().updateProfileField(
      created.key,
      created.value,
    );
  }

  bool get _canAdd {
    if (!state.profileFieldsSupported) return false;
    final addable = state.addableProfileFields;
    return addable == null || addable.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final entries = state.customFields.entries.toList();
    final canAdd = _canAdd;
    return M3EList(
      itemCount: entries.length + (canAdd ? 1 : 0),
      onTap: (index) {
        if (index >= entries.length) {
          _add(context);
          return;
        }
        final entry = entries[index];
        if (state.editableProfileFields.contains(entry.key)) {
          _edit(context, entry.key, entry.value);
        }
      },
      itemBuilder: (context, index) {
        if (index >= entries.length) {
          return const M3EListItem(
            headline: 'Добавить поле',
            trailing: Icon(Icons.add_rounded),
          );
        }
        final entry = entries[index];
        final editable = state.editableProfileFields.contains(entry.key);
        return M3EListItem(
          headline: profileFieldLabel(entry.key),
          supportingText: entry.value,
          trailing: editable ? const Icon(Icons.edit_rounded) : null,
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
      final XFile? file = await SystemAssetPicker.pickImage();
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
                decoration: const BoxDecoration(
                  color: Color(0x66000000),
                  shape: BoxShape.circle,
                ),
                child: const Center(child: AdaptiveLoadingIndicator()),
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
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.photo_camera,
                size: 18,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
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
        color: Theme.of(context).colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Text(
        avatarInitial(state.displayName ?? ''),
        style: TextStyle(fontSize: size * 0.42),
      ),
    );
  }
}
