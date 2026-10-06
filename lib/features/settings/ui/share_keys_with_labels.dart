import 'package:matrix/matrix.dart';

extension ShareKeysWithLabels on ShareKeysWith {
  String get label => switch (this) {
    ShareKeysWith.all => 'Все устройства',
    ShareKeysWith.crossVerifiedIfEnabled =>
      'Кросс-верифицированные устройства, если они включены',
    ShareKeysWith.crossVerified => 'Кросс-верифицированные устройства',
    ShareKeysWith.directlyVerifiedOnly => 'Только проверенные устройства',
  };

  String get description => switch (this) {
    ShareKeysWith.all => 'Ключи отправляются всем устройствам, кроме заблокированных',
    ShareKeysWith.crossVerifiedIfEnabled =>
      'Если у собеседника включён кросс-подпись — только проверенным устройствам, иначе всем',
    ShareKeysWith.crossVerified =>
      'Только устройствам с действующей цепочкой кросс-подписи',
    ShareKeysWith.directlyVerifiedOnly =>
      'Только устройствам, проверенным вручную',
  };
}
