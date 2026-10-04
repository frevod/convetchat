import 'dart:io';

import 'package:convetchat/app/adaptive/adaptive_buttons.dart';
import 'package:convetchat/app/adaptive/adaptive_loading_indicator.dart';
import 'package:convetchat/app/adaptive/adaptive_snackbar.dart';
import 'package:convetchat/app/adaptive/adaptive_text_field.dart';
import 'package:convetchat/features/chats/ui/cubit/create_group_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:system_asset_picker/system_asset_picker.dart';

class const CreateGroupPageAndr({super.key}) extends StatelessWidget {
  Future<void> _pickAvatar(BuildContext context) async {
    final cubit = context.read<CreateGroupCubit>();
    try {
      final file = await SystemAssetPicker.pickImage();
      if (!context.mounted || file == null) return;
      final bytes = await file.readAsBytes();
      if (!context.mounted) return;
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

    return Scaffold(
      appBar: M3EAppBar.top(
        shapeFamily: .round,
        density: .compact,
        automaticallyImplyLeading: true,
        title: Text('Создание группы'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            Center(
              child: _GroupAvatar(
                path: state.avatarPath,
                onTap: () => _pickAvatar(context),
              ),
            ),
            SizedBox(height: 10),
            AdaptiveTextField(
              controller: cubit.nameController,
              label: 'Название группы',
              textInputAction: .done,
              onChanged: cubit.onNameChanged,
              onSubmitted: (_) => cubit.submit(),
            ),
            SizedBox(height: 10),
            ListTile(
              title: Text('Публичная группа'),
              trailing: M3ESwitch(
                value: state.isPublic,
                onChanged: state.isCreating ? null : cubit.setPublic,
              ),
            ),
            SizedBox(height: 5),
            ListTile(
              title: Text('Показывать в каталоге комнат'),
              trailing: M3ESwitch(
                value: state.showInDirectory,
                onChanged: state.isPublic && !state.isCreating
                    ? cubit.setShowInDirectory
                    : null,
              ),
            ),
            ListTile(
              title: Text('Сквозное шифрование'),
              subtitle: Text(
                state.isPublic
                    ? 'Недоступно для публичных групп'
                    : 'Будет включено автоматически',
              ),
              trailing: M3ESwitch(value: !state.isPublic, onChanged: null),
            ),
            SizedBox(height: 16),
            if (state.isCreating)
              const Center(child: AdaptiveLoadingIndicator())
            else
              AdaptiveButton.filled(
                onPressed: cubit.submit,
                child: Text('Создать группу'),
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
    final scheme = Theme.of(context).colorScheme;
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
                errorBuilder: (_, _, _) => _fallback(scheme),
              ),
            )
          else
            _fallback(scheme),
          Positioned(
            right: 0,
            bottom: 2,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.surface, width: 2),
              ),
              child: Icon(
                Icons.photo_camera,
                size: 18,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback(ColorScheme scheme) {
    return CircleAvatar(
      radius: 50,
      backgroundColor: scheme.primaryContainer,
      child: Icon(
        Icons.group_rounded,
        size: 44,
        color: scheme.onPrimaryContainer,
      ),
    );
  }
}
