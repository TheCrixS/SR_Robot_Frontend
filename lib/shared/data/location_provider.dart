import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class GeoPoint {
  final double lat;
  final double lng;
  const GeoPoint(this.lat, this.lng);
}

/// Ubicación del dispositivo. Devuelve null si el permiso se niega
/// o el servicio está apagado (la app sigue funcionando sin distancia).
final locationProvider = FutureProvider<GeoPoint?>((ref) async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return null;
    }
    final last = await Geolocator.getLastKnownPosition();
    final pos = last ??
        await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 10),
          ),
        );
    return GeoPoint(pos.latitude, pos.longitude);
  } catch (_) {
    return null;
  }
});
