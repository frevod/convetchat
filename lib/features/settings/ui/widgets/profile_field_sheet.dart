import 'package:convetchat/app/adaptive/adaptive_buttons.dart';
import 'package:convetchat/app/adaptive/adaptive_text_field.dart';
import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/matrix/server_capabilities.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:cupertino_ui/cupertino_ui.dart' as cup;
import 'package:material_ui/material_ui.dart';

String profileFieldLabel(String field) {
  if (field == 'm.tz') return 'Часовой пояс';
  final dot = field.lastIndexOf('.');
  if (dot < 0 || dot == field.length - 1) return field;
  return field.substring(dot + 1);
}

Future<String?> editProfileFieldSheet({
  required BuildContext context,
  required String field,
  required String initialValue,
  String? label,
}) {
  final sheet = _ProfileFieldSheet(
    field: field,
    initialValue: initialValue,
    label: label,
  );
  if (getIt<PlatformStyle>().isCupertino) {
    return cup.showCupertinoModalPopup<String>(
      context: context,
      builder: (_) => sheet,
    );
  }
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => sheet,
  );
}

Future<({String key, String value})?> addProfileFieldSheet({
  required BuildContext context,
  required List<String>? addable,
}) {
  final sheet = _AddProfileFieldSheet(addable: addable);
  if (getIt<PlatformStyle>().isCupertino) {
    return cup.showCupertinoModalPopup<({String key, String value})>(
      context: context,
      builder: (_) => sheet,
    );
  }
  return showModalBottomSheet<({String key, String value})>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => sheet,
  );
}

class const _ProfileFieldSheet({
  required final String field,
  required final String initialValue,
  final String? label,
}) extends StatefulWidget {
  @override
  State<_ProfileFieldSheet> createState() => _ProfileFieldSheetState();
}

class _ProfileFieldSheetState() extends State<_ProfileFieldSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          children: [
            AdaptiveTextField(
              controller: _controller,
              label: widget.label ?? profileFieldLabel(widget.field),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 12),
            AdaptiveButton.filled(
              onPressed: _save,
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    Navigator.of(context).pop(_controller.text);
  }
}

class const _AddProfileFieldSheet({required final List<String>? addable})
    extends StatefulWidget {
  @override
  State<_AddProfileFieldSheet> createState() => _AddProfileFieldSheetState();
}

class _AddProfileFieldSheetState() extends State<_AddProfileFieldSheet> {
  late final TextEditingController _keyController = TextEditingController();
  late final TextEditingController _valueController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _save() {
    final key = _keyController.text.trim();
    final value = _valueController.text.trim();
    final error = _validate(key, value);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop((key: key, value: value));
  }

  String? _validate(String key, String value) {
    if (key.isEmpty) return 'Введите имя поля';
    if (!ServerCapabilities.isValidProfileFieldKey(key)) {
      return 'Имя вида com.example.поле, только латиница и точки';
    }
    final addable = widget.addable;
    if (addable != null && !addable.contains(key)) {
      return 'Сервер не разрешает это поле';
    }
    if (value.isEmpty) return 'Введите значение';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          children: [
            AdaptiveTextField(
              controller: _keyController,
              label: 'Имя поля',
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 12),
            AdaptiveTextField(
              controller: _valueController,
              label: 'Значение',
              onSubmitted: (_) => _save(),
            ),
            if (_error != null) ...[const SizedBox(height: 8), Text(_error!)],
            const SizedBox(height: 12),
            AdaptiveButton.filled(
              onPressed: _save,
              child: const Text('Добавить'),
            ),
          ],
        ),
      ),
    );
  }
}
