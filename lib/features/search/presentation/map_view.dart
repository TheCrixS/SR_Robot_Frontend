import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/data/location_provider.dart';
import '../../../shared/models/technician_model.dart';
import '../../../shared/widgets/technician_cards.dart';

/// Mapa interactivo (OpenStreetMap) con pines de técnicos.
class TechniciansMapView extends StatefulWidget {
  const TechniciansMapView({
    super.key,
    required this.technicians,
    required this.center,
    required this.onOpen,
    this.showUser = true,
  });

  final List<TechnicianModel> technicians;
  final GeoPoint center;
  final ValueChanged<TechnicianModel> onOpen;

  /// Dibuja el punto azul del usuario (solo si la ubicación es real).
  final bool showUser;

  @override
  State<TechniciansMapView> createState() => _TechniciansMapViewState();
}

class _TechniciansMapViewState extends State<TechniciansMapView> {
  TechnicianModel? _selected;

  @override
  Widget build(BuildContext context) {
    final withLocation =
        widget.technicians.where((t) => t.lat != null && t.lng != null).toList();

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(widget.center.lat, widget.center.lng),
            initialZoom: 13,
            onTap: (_, __) => setState(() => _selected = null),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.srrobot.sr_robot_app',
            ),
            MarkerLayer(
              markers: [
                if (widget.showUser)
                Marker(
                  point: LatLng(widget.center.lat, widget.center.lng),
                  width: 22,
                  height: 22,
                  child: Container(
                    decoration: BoxDecoration(
                      color: SrRobotColors.infoBlue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                  ),
                ),
                for (final t in withLocation)
                  Marker(
                    point: LatLng(t.lat!, t.lng!),
                    width: 46,
                    height: 54,
                    alignment: Alignment.topCenter,
                    child: GestureDetector(
                      onTap: () => setState(() => _selected = t),
                      child: _Pin(
                        label: t.rating.toStringAsFixed(1),
                        selected: _selected?.id == t.id,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        if (_selected != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: TechnicianListTile(
              tech: _selected!,
              onTap: () => widget.onOpen(_selected!),
            ),
          ),
      ],
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin({required this.label, required this.selected});
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? SrRobotColors.textInk : SrRobotColors.primaryTeal;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
            boxShadow: SrRobotColors.cardShadow,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded,
                  size: 12, color: SrRobotColors.yellowAccent),
              Text(label,
                  style: AppText.tag.copyWith(color: Colors.white)),
            ],
          ),
        ),
        Icon(Icons.arrow_drop_down_rounded, color: color, size: 22),
      ],
    );
  }
}
