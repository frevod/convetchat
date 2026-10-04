import 'package:convetchat/features/encryption/ui/widgets/sas_compare.dart';
import 'package:flutter/widgets.dart';
import 'package:matrix/encryption.dart';

class const VerificationSasBody({
  super.key,
  required final KeyVerification request,
  required final List<dynamic>? sasEmoji,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SasCompare(request: request, sasEmoji: sasEmoji);
  }
}
