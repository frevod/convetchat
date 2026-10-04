import 'dart:io';

import 'package:convetchat/app/adaptive/adaptive_buttons.dart';
import 'package:convetchat/app/adaptive/adaptive_loading_indicator.dart';
import 'package:convetchat/app/adaptive/adaptive_snackbar.dart';
import 'package:convetchat/app/adaptive/adaptive_text_field.dart';
import 'package:convetchat/features/chats/ui/cubit/create_group_cubit.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class const CreateGroupPageCup({super.key}) extends StatelessWidget {
  Future<void> _pickAvatar(BuildContext context) async {
    final cubit = context.read<CreateGroupCubit>();
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (!context.mounted || file == null) return;
      final bytes = await cubit.readAvatarFile(file.path);
      if (!context.mounted || bytes == null) return;
      cubit.setAvatar(file.path, bytes);
    } catch (_) {
      if (!context.mounted) return;
      AdaptiveSnackbar.show(
        context: context,
        message: 'Не удалось выбрать фотографию',
        type: .error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<CreateGroupCubit>();
    final state = cubit.state;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Создать группу'),
      ),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(25),
          children: [
            Center(
              child: _GroupAvatar(
                path: state.avatarPath,
                onTap: () => _pickAvatar(context),
              ),
            ),
            const SizedBox(height: 16),
            AdaptiveTextField(
              controller: cubit.nameController,
              label: 'Название группы',
              textInputAction: .done,
              onChanged: cubit.onNameChanged,
              onSubmitted: (_) => cubit.submit(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(child: Text('Публичная группа')),
                CupertinoSwitch(
                  value: state.isPublic,
                  onChanged: state.isCreating ? null : cubit.setPublic,
                ),
              ],
            ),
            Row(
              children: [
                const Expanded(child: Text('Показывать в каталоге комнат')),
                CupertinoSwitch(
                  value: state.showInDirectory,
                  onChanged: state.isPublic && !state.isCreating
                      ? cubit.setShowInDirectory
                      : null,
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      const Text('Сквозное шифрование'),
                      Text(
                        state.isPublic
                            ? 'Недоступно для публичных групп'
                            : 'Будет включено автоматически',
                        style: TextStyle(
                          fontSize: 13,
                          color: CupertinoColors.secondaryLabel.resolveFrom(
                            context,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                CupertinoSwitch(value: !state.isPublic, onChanged: null),
              ],
            ),
            const SizedBox(height: 24),
            if (state.isCreating)
              const Center(child: AdaptiveLoadingIndicator())
            else
              AdaptiveButton.filled(
                onPressed: cubit.submit,
                child: const Text('Создать группу'),
              ),
          ],
        ),
      ),
    );
  }
}

class const _GroupAvatar({
  required final String? path,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final avatarPath = path;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (avatarPath != null)
            ClipOval(
              child: Image.file(
                File(avatarPath),
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _fallback(context),
              ),
            )
          else
            _fallback(context),
          Positioned(
            right: 0,
            bottom: 2,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey.resolveFrom(context),
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
        ],
      ),
    );
  }

  Widget _fallback(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: CupertinoColors.systemBlue.resolveFrom(context),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        CupertinoIcons.group,
        size: 44,
        color: CupertinoColors.white,
      ),
    );
  }
}
