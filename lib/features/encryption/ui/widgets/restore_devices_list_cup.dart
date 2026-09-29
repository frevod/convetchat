import 'package:convetchat/features/encryption/domain/entities/verified_device.dart';
import 'package:convetchat/features/encryption/ui/widgets/device_icon_data.dart';
import 'package:convetchat/features/encryption/ui/widgets/last_active_text.dart';
import 'package:cupertino_ui/cupertino_ui.dart';

class const RestoreDevicesListCup({
  super.key,
  required final List<VerifiedDevice> devices,
  required final ScrollController scrollController,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final background = CupertinoColors.secondarySystemBackground.resolveFrom(
      context,
    );
    return Container(
      decoration: BoxDecoration(color: background, borderRadius: .circular(16)),
      padding: EdgeInsets.zero,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 128),
        child: CupertinoScrollbar(
          controller: scrollController,
          child: ListView.builder(
            controller: scrollController,
            shrinkWrap: true,
            itemCount: devices.length,
            itemBuilder: (context, i) {
              final device = devices[i];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      deviceIconData(device.displayName, cupertino: true),
                      color: CupertinoColors.activeBlue.resolveFrom(context),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: .start,
                        children: [
                          Text(
                            device.displayName,
                            maxLines: 1,
                            overflow: .ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            lastActiveText(device.lastActive),
                            style: TextStyle(
                              fontSize: 11,
                              color: CupertinoColors.systemGrey.resolveFrom(
                                context,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
