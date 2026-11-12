import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../core/guliston_route_data.dart';

/// Yandex Bus uslubidagi aqlli xarita vidjeti:
/// - Faqat yashil yo'l chizig'i (bekatlar belgilanmaydi, toza xarita).
/// - 1-yo'nalish (GulDU) va 2-yo'nalish (2-mavze: TYB ↔ Nurafshon) qo'llab-quvvatlanadi.
/// - Avtobus 11 km/soat tezlikda harakatlanadi.
/// - Har bir bekatda 1 daqiqa (60 soniya) to'xtab turadi.
/// - Oxirgi bekatga yetganda avtomatik ravishda orqaga qaytadi (uzluksiz aylanma).
class GulistonRouteMapWidget extends StatefulWidget {
  final String routeNumber; // '1' yoki '2'
  final VoidCallback? onExpand;
  final Function(BusPositionState busState)? onBusStateChanged;
  final Function(String routeNumber)? onRouteChanged;

  const GulistonRouteMapWidget({
    super.key,
    this.routeNumber = '1',
    this.onExpand,
    this.onBusStateChanged,
    this.onRouteChanged,
  });

  @override
  State<GulistonRouteMapWidget> createState() => _GulistonRouteMapWidgetState();
}

class _GulistonRouteMapWidgetState extends State<GulistonRouteMapWidget>
    with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  Timer? _simTimer;
  late final AnimationController _pulseController;

  late String _activeRoute; // '1' yoki '2'
  bool _isForward = true;
  int _currentSegIndex = 0;
  double _segProgress = 0.0;
  bool _isWaitingAtStop = false;
  double _waitRemainingSec = 60.0;
  double _simSpeedMultiplier = 1.0;

  static const double _targetSpeedKmH = 11.0; // 11 km/soat tezlik

  late double _busLat;
  late double _busLng;
  double _busHeading = 0.0;
  bool _followBus = true; // Xaritani avtobus bilan birga markazda ushlab turish

  @override
  void initState() {
    super.initState();
    _activeRoute = widget.routeNumber;
    _mapController = MapController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _initBusForRoute();
    _startSimulationTimer();
  }

  @override
  void didUpdateWidget(covariant GulistonRouteMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routeNumber != widget.routeNumber && widget.routeNumber != _activeRoute) {
      _setRoute(widget.routeNumber);
    }
  }

  void _initBusForRoute() {
    final stops = GulistonRoutes.getStops(_activeRoute, isForward: _isForward);
    final firstStop = stops.first;
    _busLat = firstStop.latitude;
    _busLng = firstStop.longitude;
    _currentSegIndex = 0;
    _segProgress = 0.0;
    _isWaitingAtStop = false;
    _waitRemainingSec = 60.0;

    // Harakat boshlanganda yo'nalish burchagini aniqlash
    if (stops.length > 1) {
      final next = stops[1];
      final dLat = next.latitude - firstStop.latitude;
      final dLng = next.longitude - firstStop.longitude;
      _busHeading = (math.atan2(dLng, dLat) * 180.0 / math.pi + 360.0) % 360.0;
    }
  }

  void _setRoute(String newRoute) {
    setState(() {
      _activeRoute = newRoute;
      _isForward = true;
      _followBus = true;
      _initBusForRoute();
    });
    widget.onRouteChanged?.call(newRoute);
    // Avtobus turgan yo'l nuqtasiga darhol silliq o'tish (ochiq joyda qolib ketmaslik uchun)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _mapController.move(LatLng(_busLat, _busLng), 14.8);
      }
    });
  }

  void _startSimulationTimer() {
    _simTimer?.cancel();
    _simTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      _tickSimulation(0.05 * _simSpeedMultiplier);
    });
  }

  void _tickSimulation(double deltaSec) {
    if (!mounted) return;

    final stops = GulistonRoutes.getStops(_activeRoute, isForward: _isForward);
    final totalSegs = stops.length - 1;

    if (_isWaitingAtStop) {
      // Bekatda 1 daqiqa (60 soniya) to'xtash
      _waitRemainingSec -= deltaSec;
      if (_waitRemainingSec <= 0) {
        _isWaitingAtStop = false;
        _waitRemainingSec = 60.0;
        _currentSegIndex++;
        _segProgress = 0.0;

        // Oxirgi bekatga yetganda qaytish
        if (_currentSegIndex >= totalSegs) {
          _isForward = !_isForward;
          _currentSegIndex = 0;
          _segProgress = 0.0;
        }
      }
    } else {
      if (_currentSegIndex >= totalSegs) {
        _isWaitingAtStop = true;
        _waitRemainingSec = 60.0;
        return;
      }

      final curStop = stops[_currentSegIndex];
      final nextStop = stops[_currentSegIndex + 1];

      final segDistanceKm = haversineDistanceKm(
        curStop.latitude,
        curStop.longitude,
        nextStop.latitude,
        nextStop.longitude,
      );

      const kmPerSec = _targetSpeedKmH / 3600.0;
      final distTraveledKm = kmPerSec * deltaSec;

      if (segDistanceKm > 0.0001) {
        _segProgress += distTraveledKm / segDistanceKm;
      } else {
        _segProgress = 1.0;
      }

      final clampedP = _segProgress.clamp(0.0, 1.0);
      _busLat = curStop.latitude + (nextStop.latitude - curStop.latitude) * clampedP;
      _busLng = curStop.longitude + (nextStop.longitude - curStop.longitude) * clampedP;

      final dLat = nextStop.latitude - curStop.latitude;
      final dLng = nextStop.longitude - curStop.longitude;
      final angleRad = math.atan2(dLng, dLat);
      _busHeading = (angleRad * 180.0 / math.pi + 360.0) % 360.0;

      if (_segProgress >= 1.0) {
        _busLat = nextStop.latitude;
        _busLng = nextStop.longitude;
        _isWaitingAtStop = true;
        _waitRemainingSec = 60.0; // Bekatda 1 daqiqa to'xtash
      }
    }

    final curStop = stops[math.min(_currentSegIndex, totalSegs)];
    final nextStop = stops[math.min(_currentSegIndex + 1, totalSegs)];
    final distToNext = haversineDistanceKm(_busLat, _busLng, nextStop.latitude, nextStop.longitude);
    final etaToNext = math.max(1, ((distToNext / _targetSpeedKmH) * 60).round());

    final state = BusPositionState(
      latitude: _busLat,
      longitude: _busLng,
      headingDegrees: _busHeading,
      currentStop: curStop,
      nextStop: nextStop,
      etaMinutesToNext: _isWaitingAtStop ? 1 : etaToNext,
      speedKmH: _isWaitingAtStop ? 0.0 : _targetSpeedKmH,
      progress: (_currentSegIndex + _segProgress) / totalSegs,
      isWaitingAtStop: _isWaitingAtStop,
      waitSecondsRemaining: _waitRemainingSec.round(),
      isForward: _isForward,
    );

    widget.onBusStateChanged?.call(state);

    if (_followBus) {
      _mapController.move(LatLng(_busLat, _busLng), _mapController.camera.zoom);
    }

    setState(() {});
  }

  @override
  void dispose() {
    _simTimer?.cancel();
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _skipStopWait() {
    setState(() {
      _isWaitingAtStop = false;
      _waitRemainingSec = 60.0;
      final stops = GulistonRoutes.getStops(_activeRoute, isForward: _isForward);
      _currentSegIndex++;
      _segProgress = 0.0;
      if (_currentSegIndex >= stops.length - 1) {
        _isForward = !_isForward;
        _currentSegIndex = 0;
      }
    });
  }

  void _toggleSpeedMultiplier() {
    setState(() {
      if (_simSpeedMultiplier == 1.0) {
        _simSpeedMultiplier = 5.0;
      } else if (_simSpeedMultiplier == 5.0) {
        _simSpeedMultiplier = 15.0;
      } else {
        _simSpeedMultiplier = 1.0;
      }
    });
  }

  void _toggleDirectionManually() {
    setState(() {
      _isForward = !_isForward;
      _currentSegIndex = 0;
      _segProgress = 0.0;
      _isWaitingAtStop = false;
      _waitRemainingSec = 60.0;
      final stops = GulistonRoutes.getStops(_activeRoute, isForward: _isForward);
      _busLat = stops.first.latitude;
      _busLng = stops.first.longitude;
    });
  }

  void _centerOnBus() {
    setState(() => _followBus = true);
    _mapController.move(LatLng(_busLat, _busLng), 15.0);
  }

  void _centerEntireRoute() {
    setState(() => _followBus = false);
    final stops = GulistonRoutes.getStops(_activeRoute, isForward: _isForward);
    if (stops.isNotEmpty) {
      double minLat = stops.first.latitude;
      double maxLat = stops.first.latitude;
      double minLng = stops.first.longitude;
      double maxLng = stops.first.longitude;
      for (final s in stops) {
        if (s.latitude < minLat) minLat = s.latitude;
        if (s.latitude > maxLat) maxLat = s.latitude;
        if (s.longitude < minLng) minLng = s.longitude;
        if (s.longitude > maxLng) maxLng = s.longitude;
      }
      final centerLat = (minLat + maxLat) / 2.0;
      final centerLng = (minLng + maxLng) / 2.0;
      _mapController.move(LatLng(centerLat, centerLng), 13.2);
    }
  }

  /// Avtobus bosilganda Yandex uslubidagi ETA oynasi
  void _showBusEtaSheet(BuildContext context) {
    final stops = GulistonRoutes.getStops(_activeRoute, isForward: _isForward);
    final totalSegs = stops.length - 1;
    final curStop = stops[math.min(_currentSegIndex, totalSegs)];
    final nextStop = stops[math.min(_currentSegIndex + 1, totalSegs)];
    final busCode = GulistonRoutes.getBusCode(_activeRoute);
    final driverName = GulistonRoutes.getDriverName(_activeRoute);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.78,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isWaitingAtStop
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF10B981),
                          boxShadow: [
                            BoxShadow(
                              color: (_isWaitingAtStop
                                      ? const Color(0xFFF59E0B)
                                      : const Color(0xFF10B981))
                                  .withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 20),
                              const SizedBox(width: 2),
                              Text(
                                _activeRoute,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Outfit',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '$_activeRoute-avtobus',
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _isWaitingAtStop
                                        ? const Color(0xFFFEF3C7)
                                        : const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _isWaitingAtStop
                                        ? 'Bekatda (${_waitRemainingSec.round()}s)'
                                        : 'Harakatda · 11 km/s',
                                    style: TextStyle(
                                      color: _isWaitingAtStop
                                          ? const Color(0xFFD97706)
                                          : const Color(0xFF16A34A),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$busCode · $driverName · ${GulistonRoutes.getRouteName(_activeRoute, isForward: _isForward)}',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Status Banner
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isWaitingAtStop
                          ? const Color(0xFFFFFBEB)
                          : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isWaitingAtStop
                            ? const Color(0xFFFDE68A)
                            : const Color(0xFFBBF7D0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _isWaitingAtStop
                                ? const Color(0xFFD97706)
                                : const Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isWaitingAtStop
                                ? Icons.timer_outlined
                                : Icons.navigation_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isWaitingAtStop
                                    ? "BEKATDA TO'XTAB TURIBDI (1 DAQ)"
                                    : "KEYINGI BEKATGA KELISH VAQTI",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: _isWaitingAtStop
                                      ? const Color(0xFFB45309)
                                      : const Color(0xFF15803D),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isWaitingAtStop ? curStop.name : nextStop.name,
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_isWaitingAtStop) ...[
                          TextButton.icon(
                            onPressed: () {
                              _skipStopWait();
                              setModalState(() {});
                            },
                            icon: const Icon(Icons.fast_forward_rounded, size: 16),
                            label: const Text('Yurish', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFD97706),
                              backgroundColor: const Color(0xFFFEF3C7),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Text(
                              '~2 daq',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Metrics
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildYandexMetric(
                          icon: Icons.speed_rounded,
                          title: 'Tezlik',
                          value: _isWaitingAtStop ? '0 km/s (To\'xtash)' : '11 km/soat',
                          color: const Color(0xFF0284C7),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildYandexMetric(
                          icon: Icons.hourglass_top_rounded,
                          title: 'Bekatda turish',
                          value: '1 daqiqa',
                          color: const Color(0xFFD97706),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildYandexMetric(
                          icon: Icons.repeat_rounded,
                          title: 'Reys',
                          value: 'Aylanma (Doimiy)',
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Stops list header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Text(
                        'Yo\'nalish bekatlari va kelish vaqtlari:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${stops.length} ta bekat',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                // Stops List
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    itemCount: stops.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (ctx, idx) {
                      final stop = stops[idx];
                      final etaMin = GulistonRoutes.calculateEta(
                        _activeRoute,
                        busLat: _busLat,
                        busLng: _busLng,
                        targetStopIndex: idx,
                        speedKmH: _targetSpeedKmH,
                        isForward: _isForward,
                      );

                      final isCurrent = stop.index == curStop.index;
                      final isNext = stop.index == nextStop.index && !_isWaitingAtStop;

                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        leading: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCurrent
                                ? const Color(0xFF10B981)
                                : (isNext ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9)),
                          ),
                          child: Center(
                            child: Text(
                              '${idx + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: (isCurrent || isNext) ? Colors.white : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          stop.name,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: (isCurrent || isNext) ? FontWeight.w800 : FontWeight.w600,
                            color: isCurrent
                                ? const Color(0xFF10B981)
                                : (isNext ? const Color(0xFF1D4ED8) : const Color(0xFF1E293B)),
                          ),
                        ),
                        subtitle: Text(
                          isCurrent
                              ? (_isWaitingAtStop ? "To'xtab turibdi (${_waitRemainingSec.round()}s qoldi)" : 'Hozir shu bekatda')
                              : (isNext ? 'Keyingi bekat' : '${stop.distanceKm} km masofa'),
                          style: TextStyle(
                            fontSize: 11,
                            color: isCurrent
                                ? const Color(0xFF059669)
                                : (isNext ? const Color(0xFF2563EB) : const Color(0xFF94A3B8)),
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? const Color(0xFFDCFCE7)
                                : (etaMin == 0
                                    ? const Color(0xFFDCFCE7)
                                    : const Color(0xFFF8FAFC)),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isCurrent
                                  ? const Color(0xFF86EFAC)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Text(
                            isCurrent ? 'Bekatda' : '~$etaMin daq',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isCurrent ? const Color(0xFF16A34A) : const Color(0xFF334155),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildYandexMetric({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(fontSize: 10.5, color: color, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stops = GulistonRoutes.getStops(_activeRoute, isForward: _isForward);
    final polylinePoints = stops.map((s) => LatLng(s.latitude, s.longitude)).toList();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // ── 1. Asosiy Xarita (FlutterMap) ──
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(_busLat, _busLng),
              initialZoom: 14.8,
              minZoom: 11.0,
              maxZoom: 18.0,
              onPositionChanged: (pos, hasGesture) {
                // Agar foydalanuvchi xaritani o'zi sursa, avtomatik ergashishni to'xtatish
                if (hasGesture && _followBus) {
                  setState(() => _followBus = false);
                }
              },
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              // OpenStreetMap plitalari
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.smartbus.guliston',
              ),

              // Foydalanuvchi talabi: "faqat yashil chiziq bilan bo'lsin, bekatlar belgilanmasin"
              PolylineLayer(
                polylines: [
                  // Tashqi yumshoq yashil kontur
                  Polyline(
                    points: polylinePoints,
                    strokeWidth: 8.0,
                    color: const Color(0xFF10B981).withOpacity(0.25),
                  ),
                  // Asosiy toza yashil Yandex yo'l chizig'i
                  Polyline(
                    points: polylinePoints,
                    strokeWidth: 4.8,
                    color: const Color(0xFF059669),
                  ),
                ],
              ),

              // Faqat harakatlanayotgan avtobus belgisi (bekat nuqtalari yo'q, yo'lga moslangan)
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(_busLat, _busLng),
                    width: 44.0,
                    height: 44.0,
                    child: GestureDetector(
                      onTap: () => _showBusEtaSheet(context),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Radar nuri (pulsatsiya)
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, _) {
                              final scale = 1.0 + _pulseController.value * 0.3;
                              final opacity = (1.0 - _pulseController.value) * 0.35;
                              return Transform.scale(
                                scale: scale,
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: (_isWaitingAtStop
                                            ? const Color(0xFFF59E0B)
                                            : const Color(0xFF10B981))
                                        .withOpacity(opacity),
                                  ),
                                ),
                              );
                            },
                          ),

                          // Harakat yo'nalishidagi ko'rsatkich (strelka)
                          if (!_isWaitingAtStop)
                            Transform.rotate(
                              angle: (_busHeading * math.pi / 180.0),
                              child: Container(
                                width: 36,
                                height: 36,
                                alignment: Alignment.topCenter,
                                child: const Icon(
                                  Icons.navigation_rounded,
                                  size: 13,
                                  color: Color(0xFF047857),
                                ),
                              ),
                            ),

                          // Avtobus aylanma ixcham nishoni (Yandex Bus badge, yo'lga sig'adigan)
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: _isWaitingAtStop
                                    ? const [Color(0xFFF59E0B), Color(0xFFD97706)]
                                    : const [Color(0xFF10B981), Color(0xFF059669)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(color: Colors.white, width: 2.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.28),
                                  blurRadius: 5,
                                  offset: const Offset(0, 1.5),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _isWaitingAtStop ? '🛑' : _activeRoute,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11.5,
                                  fontFamily: 'Outfit',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── 2. Top Controls: Route Selector (1-yo'nalish & 2-mavze) + Direction Switcher ──
          Positioned(
            top: 10,
            left: 10,
            right: 60,
            child: Row(
              children: [
                // Route Tabs (1 / 2)
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.96),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 6,
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      _buildRouteTab('1', '1-yo\'l'),
                      const SizedBox(width: 4),
                      _buildRouteTab('2', '2-mavze'),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                // Direction switcher button
                Expanded(
                  child: GestureDetector(
                    onTap: _toggleDirectionManually,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.96),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 6,
                          ),
                        ],
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              GulistonRoutes.getRouteName(_activeRoute, isForward: _isForward),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.sync_alt_rounded, size: 14, color: Color(0xFF10B981)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── 3. Bottom-left: Status Pill (Tezlik 11 km/s yoki Bekatda 1 daq) ──
          Positioned(
            bottom: 10,
            left: 10,
            child: GestureDetector(
              onTap: () => _showBusEtaSheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withOpacity(0.88),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isWaitingAtStop ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isWaitingAtStop
                          ? 'Bekatda: ${_waitRemainingSec.round()}s qoldi'
                          : '$_activeRoute-avtobus · 11 km/s',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_isWaitingAtStop) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: _skipStopWait,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Yurish ▶',
                            style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // ── 4. Right Controls ──
          Positioned(
            right: 10,
            top: 10,
            bottom: 10,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMapPillButton(
                  label: '${_simSpeedMultiplier.round()}x',
                  tooltip: "Simulyatsiya tezligi",
                  color: _simSpeedMultiplier > 1.0 ? const Color(0xFF10B981) : const Color(0xFF64748B),
                  onTap: _toggleSpeedMultiplier,
                ),
                _buildMapIconButton(
                  icon: Icons.directions_bus_rounded,
                  tooltip: "Avtobusga o'tish",
                  color: const Color(0xFF10B981),
                  onTap: _centerOnBus,
                ),
                _buildMapIconButton(
                  icon: Icons.map_rounded,
                  tooltip: "Butun yo'l",
                  onTap: _centerEntireRoute,
                ),
                _buildMapIconButton(
                  icon: Icons.info_outline_rounded,
                  tooltip: "ETA va Bekatlar",
                  onTap: () => _showBusEtaSheet(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteTab(String rNum, String label) {
    final isSelected = _activeRoute == rNum;
    return GestureDetector(
      onTap: () => _setRoute(rNum),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF475569),
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildMapPillButton({
    required String label,
    required String tooltip,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color color = const Color(0xFF334155),
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 18, color: color),
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        onPressed: onTap,
      ),
    );
  }
}
