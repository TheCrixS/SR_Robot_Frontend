import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/json_utils.dart';

/// Emoji por categoría del backend (dato visual, no texto de interfaz).
const categoryEmoji = <String, String>{
  'Smartphones': '📱',
  'Laptops': '💻',
  'Consolas': '🎮',
  'Tablets': '📟',
  'Smartwatches': '⌚',
  'Televisores': '📺',
  'TV/Audio': '📺',
  'Audio': '🎧',
  'Electrodomésticos': '🔌',
  'Cámaras': '📷',
};

String emojiFor(String category) => categoryEmoji[category] ?? '🔧';

/// Categorías desde `GET /config/categories` (no se dejan fijas en el front).
final categoriesProvider = FutureProvider<List<String>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final body = await api.get(ApiEndpoints.categories);
  return asStrList(body['data']);
});
