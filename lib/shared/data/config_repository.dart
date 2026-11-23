import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../l10n/app_localizations.dart';
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

/// Nombre visible de una categoría del backend en el idioma de la interfaz.
/// El backend envía el nombre en español; si llega uno nuevo se muestra tal cual.
final Map<String, String Function(AppLocalizations)> _categoryLabels = {
  'Smartphones': (l) => l.catSmartphones,
  'Laptops': (l) => l.catLaptops,
  'Tablets': (l) => l.catTablets,
  'Consolas': (l) => l.catConsoles,
  'Televisores': (l) => l.catTvs,
  'Electrodomésticos': (l) => l.catAppliances,
  'Audio': (l) => l.catAudio,
  'Cámaras': (l) => l.catCameras,
  'Smartwatches': (l) => l.catSmartwatches,
  'TV/Audio': (l) => l.catTvAudio,
  'Pantallas': (l) => l.catScreens,
  'Baterías': (l) => l.catBatteries,
  'Flex y conectores': (l) => l.catFlex,
  'Insumos': (l) => l.catSupplies,
};

String categoryLabel(AppLocalizations l, String category) =>
    _categoryLabels[category]?.call(l) ?? category;
