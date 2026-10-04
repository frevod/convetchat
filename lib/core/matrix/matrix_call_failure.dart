import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:matrix/matrix.dart';

class const MatrixCallFailure({
  required final String method,

  required final String path,

  required final int? statusCode,

  final String? errcode,

  final String? error,

  final String? body,
}) implements Exception {
  bool get isNotMatrixResponse => statusCode != null && errcode == null;

  bool get isNetworkFailure => statusCode == null && errcode == null;

  String get userMessage => switch (errcode) {
    'M_TOO_LARGE' => 'Файл слишком большой: ${error ?? 'слишком большой'}',
    'M_FORBIDDEN' => 'Сервер запретил операцию: ${error ?? 'нет деталей'}',
    'M_NOT_FOUND' ||
    'M_UNKNOWN' => 'Приглашение недействительно или комната недоступна',
    'M_UNAUTHORIZED' || 'M_UNKNOWN_TOKEN' => 'Сессия истекла, войдите заново',
    'M_LIMIT_EXCEEDED' ||
    'M_RESOURCE_LIMIT_EXCEEDED' => 'Слишком частое действие, попробуйте позже',
    _ => _fallbackMessage,
  };

  String get _fallbackMessage {
    if (isNetworkFailure) {
      return 'Нет связи с сервером: ${error ?? 'проверьте интернет'}';
    }
    if (isNotMatrixResponse) {
      return 'Сервер ответил не-Matrix ответом (HTTP $statusCode) — '
          'соединение перехватывает прокси или DPI';
    }
    return error ?? 'Ошибка сервера (${errcode ?? 'HTTP $statusCode'})';
  }

  static MatrixCallFailure fromHttp(
    http.Response response, {
    required String method,
    required String path,
  }) {
    final raw = _decodeBody(response);
    return MatrixCallFailure(
      method: method,
      path: path,
      statusCode: response.statusCode,
      errcode: _stringField(raw, 'errcode'),
      error: _stringField(raw, 'error') ?? _preview(response.body),
      body: _preview(response.body),
    );
  }

  static MatrixCallFailure from(
    Object failure, {
    required String method,
    required String path,
  }) {
    if (failure is MatrixCallFailure) return failure;
    if (failure is MatrixException) {
      return MatrixCallFailure(
        method: method,
        path: path,
        statusCode: failure.response?.statusCode,
        errcode: failure.errcode,
        error: failure.errorMessage,
        body: _preview(failure.response?.body),
      );
    }
    return MatrixCallFailure(
      method: method,
      path: path,
      statusCode: null,
      error: failure is http.ClientException
          ? failure.message
          : failure.toString(),
    );
  }

  static Object? _decodeBody(http.Response response) {
    try {
      return json.decode(utf8.decode(response.bodyBytes));
    } on FormatException {
      return null;
    }
  }

  static String? _stringField(Object? raw, String key) {
    if (raw is! Map) return null;
    final value = raw[key];
    return value is String && value.isNotEmpty ? value : null;
  }

  static String? _preview(String? body, {int limit = 300}) {
    if (body == null) return null;
    final flat = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (flat.isEmpty) return null;
    return flat.length <= limit ? flat : '${flat.substring(0, limit)}…';
  }

  @override
  String toString() {
    final head = '$method $path → ${statusCode ?? 'нет ответа'}';
    final code = errcode;
    final text = error;
    if (code == null && text == null) return head;
    return '$head: ${code == null ? '' : '$code: '}$text';
  }
}
