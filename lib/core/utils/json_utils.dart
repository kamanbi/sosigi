import 'dart:convert';

String encodeJsonList(List<Map<String, dynamic>> value) => jsonEncode(value);

List<dynamic> decodeJsonList(String raw) => jsonDecode(raw) as List<dynamic>;