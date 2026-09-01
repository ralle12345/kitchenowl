import 'dart:convert';

class CustomServerHeader {
  final String name;
  final String value;

  const CustomServerHeader({
    required this.name,
    required this.value,
  });

  factory CustomServerHeader.fromJson(Map<String, dynamic> json) =>
      CustomServerHeader(
        name: (json['name'] ?? '').toString(),
        value: (json['value'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'value': value,
      };

  CustomServerHeader normalized() => CustomServerHeader(
        name: name.trim(),
        value: value.trim(),
      );

  static String encodeList(List<CustomServerHeader> headers) => jsonEncode(
        headers.map((header) => header.normalized().toJson()).toList(),
      );

  static List<CustomServerHeader> decodeList(String? value) {
    if (value == null || value.isEmpty) return const [];

    try {
      final data = jsonDecode(value);
      if (data is! List) return const [];

      return data
          .whereType<Map>()
          .map((entry) => CustomServerHeader.fromJson(
                entry.map(
                  (key, value) => MapEntry(key.toString(), value),
                ),
              ))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Map<String, String> toHeaderMap(List<CustomServerHeader> headers) {
    final result = <String, String>{};

    for (final header in headers.map((h) => h.normalized())) {
      if (header.name.isEmpty) continue;

      final duplicateKey = result.keys.firstWhere(
        (key) => key.toLowerCase() == header.name.toLowerCase(),
        orElse: () => '',
      );
      if (duplicateKey.isNotEmpty) continue;

      result[header.name] = header.value;
    }

    return result;
  }
}
