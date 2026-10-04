import 'package:convetchat/features/encryption/domain/entities/verified_device.dart';
import 'package:convetchat/features/encryption/ui/widgets/device_icon_data.dart';
import 'package:convetchat/features/encryption/ui/widgets/last_active_text.dart';
import 'package:material_ui/material_ui.dart';

class const RestoreDevicesListAndr({
  super.key,
  required final List<VerifiedDevice> devices,
  required final ScrollController scrollController,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainer,
      clipBehavior: .hardEdge,
      borderRadius: .circular(18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 128),
        child: Scrollbar(
          thumbVisibility: true,
          trackVisibility: true,
          controller: scrollController,
          child: ListView.builder(
            controller: scrollController,
            shrinkWrap: true,
            itemCount: devices.length,
            itemBuilder: (context, i) {
              final device = devices[i];
              return ListTile(
                leading: CircleAvatar(
                  foregroundColor: theme.colorScheme.onPrimary,
                  backgroundColor: theme.colorScheme.primary,
                  child: Icon(
                    deviceIconData(device.displayName, cupertino: false),
                  ),
                ),
                title: Text(
                  device.displayName,
                  maxLines: 1,
                  overflow: .ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: Text(
                  lastActiveText(device.lastActive),
                  style: const TextStyle(fontSize: 11),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
