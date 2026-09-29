import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/features/encryption/domain/entities/verified_device.dart';
import 'package:convetchat/features/encryption/ui/widgets/restore_devices_list_andr.dart';
import 'package:convetchat/features/encryption/ui/widgets/restore_devices_list_cup.dart';
import 'package:flutter/widgets.dart';

class const RestoreDevicesList({
  super.key,
  required final List<VerifiedDevice> devices,
  required final ScrollController scrollController,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (getIt<PlatformStyle>().isCupertino) {
      return RestoreDevicesListCup(
        devices: devices,
        scrollController: scrollController,
      );
    }
    return RestoreDevicesListAndr(
      devices: devices,
      scrollController: scrollController,
    );
  }
}
