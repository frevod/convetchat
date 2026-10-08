class const RtcCredentials({
  required final String url,
  required final String jwt,
}) {
  factory fromJson(Map<String, Object?> json) =>
      RtcCredentials(
        url: json['url'] as String? ?? '',
        jwt: json['jwt'] as String? ?? '',
      );
}
