import 'dart:math' as math;

/// NMEA koordinatalarni o'nlik darajalarga (Decimal Degrees) o'tkazish
/// Masalan: 4028.524041 -> 40.475401
double nmeaToDecimal(double nmea) {
  final deg = (nmea / 100).truncate();
  final min = nmea - (deg * 100);
  return deg + (min / 60.0);
}

/// Ikki GPS nuqta orasidagi masofani hisoblash (Haversine formulasi, km)
double haversineDistanceKm(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371.0; // Yer radiusi km
  final dLat = (lat2 - lat1) * math.pi / 180.0;
  final dLon = (lon2 - lon1) * math.pi / 180.0;
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1 * math.pi / 180.0) *
          math.cos(lat2 * math.pi / 180.0) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return r * c;
}

class BusStopPoint {
  final int index;
  final String name;
  final double latitude;
  final double longitude;
  final String stationType; // 'Start', 'Common', 'End'
  final String audioFile;
  final double distanceKm; // Boshlang'ich bekatdan masofa

  const BusStopPoint({
    required this.index,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.stationType,
    required this.audioFile,
    required this.distanceKm,
  });

  bool get isStart => stationType == 'Start';
  bool get isEnd => stationType == 'End';
}

class BusPositionState {
  final double latitude;
  final double longitude;
  final double headingDegrees;
  final BusStopPoint currentStop;
  final BusStopPoint nextStop;
  final int etaMinutesToNext;
  final double speedKmH;
  final double progress;
  final bool isWaitingAtStop;
  final int waitSecondsRemaining;
  final bool isForward;

  const BusPositionState({
    required this.latitude,
    required this.longitude,
    required this.headingDegrees,
    required this.currentStop,
    required this.nextStop,
    required this.etaMinutesToNext,
    required this.speedKmH,
    required this.progress,
    this.isWaitingAtStop = false,
    this.waitSecondsRemaining = 0,
    this.isForward = true,
  });
}

/// Guliston 1-yo'nalish avtobusi ma'lumotlar bazasi va hisoblash xizmati
class GulistonRoute1 {
  static const String routeNumber = '1';
  static const String routeName = '1-yo\'nalish: Yangi bozor ↔ GulDU';
  static const String defaultBusCode = 'GUL-101';
  static const String defaultDriver = 'Sardor Rahimov';

  /// 1-yo'nalish: To'g'ri yo'nalish (Yangi bozor1 -> GulDU) - 31 ta bekat
  static final List<BusStopPoint> forwardStops = _buildStops([
    [0, 'Yangi bozor1', 4028.5240410801985, 6846.847648373365, 'Start', 'Yangi bozor1.mp3'],
    [1, 'Dehqon bozori', 4028.5155076734636, 6846.636752593744, 'Common', 'Dehqon bozori.mp3'],
    [2, 'Yangi O‘zbekiston massivi', 4028.507714251441, 6846.641012259104, 'Common', 'Yangi O‘zbekiston massivi.mp3'],
    [3, 'Ko\'rkam diyor Bekat 1', 4028.43724, 6847.04024, 'Common', 'Ko\'rkam diyor Bekat 1.mp3'],
    [4, 'Ko\'rkam diyor Bekat 2', 4028.42572, 6847.25504, 'Common', 'Ko\'rkam diyor Bekat 2.mp3'],
    [5, 'Ko\'rkam diyor Bekat 3', 4028.4163, 6847.43708, 'Common', 'Ko\'rkam diyor Bekat 3.mp3'],
    [6, 'Ko\'rkam diyor Bekat 4', 4028.40286, 6847.62428, 'Common', 'Ko\'rkam diyor Bekat 4.mp3'],
    [7, 'Do\'stlik 2 bekati', 4028.539, 6847.68542, 'Common', 'Do\'stlik 2 bekati.mp3'],
    [8, 'Qarapchi bekati', 4028.63512, 6847.6802, 'Common', 'Qarapchi bekati.mp3'],
    [9, 'Baxtiyor bekati', 4028.84848, 6847.70618, 'Common', 'Baxtiyor bekati.mp3'],
    [10, '18-mavze bekati', 4028.9945492459638, 6847.654291019362, 'Common', '18-mavze bekati.mp3'],
    [11, 'Shiroq ko\'chasi bekat 5', 4028.999583169727, 6847.520588636662, 'Common', 'Shiroq ko\'chasi bekat 5.mp3'],
    [12, 'Shiroq ko\'chasi Bekat 6', 4029.007537489174, 6847.3937585812555, 'Common', 'Shiroq ko\'chasi Bekat 6.mp3'],
    [13, 'Sulton 2 bekati', 4029.0157, 6847.33454, 'Common', 'Sulton 2 bekati.mp3'],
    [14, 'Darhon bekati', 4029.183432193002, 6847.310427379558, 'Common', 'Darhon bekati.mp3'],
    [15, 'Turgun Axmedov Bekat 7', 4029.2266592934843, 6847.077573735461, 'Common', 'Turgun Axmedov Bekat 7.mp3'],
    [16, '6-maktab 2-bekat', 4029.363499734453, 6847.072993553012, 'Common', '6-maktab 2-bekat.mp3'],
    [17, 'S.Alimov bekati', 4029.472444287689, 6847.038530535643, 'Common', 'S.Alimov bekati.mp3'],
    [18, 'Red market 2-bekat', 4029.584596217352, 6847.0042537634945, 'Common', 'Red market 2-bekat.mp3'],
    [19, 'Istirohat bog\'i bekati', 4029.79468, 6846.92342, 'Common', 'Istirohat bog\'i bekati.mp3'],
    [20, 'Uzonline bekati', 4029.752371642825, 6846.676339379184, 'Common', 'Uzonline bekati.mp3'],
    [21, 'Navoiy bekati', 4029.73498, 6846.57992, 'Common', 'Navoiy bekati.mp3'],
    [22, 'O\'zmilliybank bekati', 4029.749613515766, 6846.425599906494, 'Common', 'O\'zmilliybank bekati.mp3'],
    [23, 'BRB 2 bekati', 4029.9462900123704, 6846.366133053904, 'Common', 'BRB 2 bekati.mp3'],
    [24, 'MObiuz bekati', 4030.04272, 6846.33374, 'Common', 'MObiuz bekati.mp3'],
    [25, 'Saxovat SM bekati', 4030.166513358068, 6846.2960185290885, 'Common', 'Saxovat SM bekati.mp3'],
    [26, 'Birlashgan ko\'chasi 172', 4030.436676097162, 6846.212637768463, 'Common', 'Birlashgan ko\'chasi 172.mp3'],
    [27, 'Temurbek', 4030.622968, 6846.45656, 'Common', 'Temurbek.mp3'],
    [28, 'Milliy gvardiya', 4030.78597, 6846.927926, 'Common', 'Milliy gvardiya.mp3'],
    [29, 'Buyuk turon ko\'chasi 121', 4030.6456, 6847.03118, 'Common', 'Buyuk turon ko\'chasi 121.mp3'],
    [30, 'GulDU', 4030.46398, 6846.99644, 'End', 'GulDU.mp3'],
  ]);

  /// 1-yo'nalish: Qaytish yo'nalishi (GulDU -> Yangi bozor1) - 33 ta bekat
  static final List<BusStopPoint> backwardStops = _buildStops([
    [0, 'GulDU', 4030.46398, 6846.99644, 'Start', 'GulDU.mp3'],
    [1, 'Nurota ko\'chasi 122', 4030.66318, 6847.03418, 'Common', 'Nurota ko\'chasi 122.mp3'],
    [2, 'TTY', 4030.8538099569614, 6847.10919082404, 'Common', 'TTY.mp3'],
    [3, 'GulDPI', 4030.9276621478703, 6847.299982313713, 'Common', 'GulDPI.mp3'],
    [4, 'Musiqa maktabi', 4030.9563223786035, 6847.320803346509, 'Common', 'Musiqa maktabi.mp3'],
    [5, 'Bo\'ston avenyu', 4030.8527338497797, 6847.057662224844, 'Common', 'Bo\'ston avenyu.mp3'],
    [6, 'Oilaviy poliklinika', 4030.755526, 6846.812858, 'Common', 'Oilaviy poliklinika.mp3'],
    [7, 'Bog‘ishamol bekati', 4030.63102, 6846.42047, 'Common', 'Bog‘ishamol bekati.mp3'],
    [8, 'Alpomish sport majmuasi', 4030.5446802340075, 6846.168291795947, 'Common', 'Alpomish sport majmuasi.mp3'],
    [9, 'Shahar ichki ishlar bo‘limi', 4030.414246019573, 6846.208411273229, 'Common', 'Shahar ichki ishlar bo‘limi.mp3'],
    [10, 'Saxovat bekati', 4030.1255896929692, 6846.297236647899, 'Common', 'Saxovat bekati.mp3'],
    [11, 'Cinema bekati', 4030.02004, 6846.33164, 'Common', 'Cinema bekati.mp3'],
    [12, 'Agrobank bekati', 4029.88648, 6846.37208, 'Common', 'Agrobank bekati.mp3'],
    [13, 'Periantal bekati', 4029.73822, 6846.4124, 'Common', 'Periantal bekati.mp3'],
    [14, 'Navoiy 2 bekati', 4029.7296622996614, 6846.5823895022895, 'Common', 'Navoiy 2 bekati.mp3'],
    [15, 'SQB bekati', 4029.75328, 6846.73154, 'Common', 'SQB bekati.mp3'],
    [16, 'Istiroxat bog\'i 2 bekati', 4029.759262384962, 6846.941053332487, 'Common', 'Istiroxat bog\'i 2 bekati.mp3'],
    [17, 'Xondamir bekati', 4029.54424, 6847.0091, 'Common', 'Xondamir bekati.mp3'],
    [18, 'S.Alimov 2 bekati', 4029.445858935213, 6847.039837920989, 'Common', 'S.Alimov 2 bekati.mp3'],
    [19, '6-maktab bekati', 4029.2937580900666, 6847.076358350903, 'Common', '6-maktab bekati.mp3'],
    [20, 'Sahovat ko\'chasi bekati', 4029.19102, 6847.09094, 'Common', 'Sahovat ko\'chasi bekati.mp3'],
    [21, 'Bodomzor bekati', 4029.1775307873286, 6847.315700426414, 'Common', 'Bodomzor bekati.mp3'],
    [22, 'Sulton bekati', 4029.032168529669, 6847.327490618113, 'Common', 'Sulton bekati.mp3'],
    [23, '18-mavze bekati', 4028.9981537623735, 6847.491597146074, 'Common', '18-mavze bekati.mp3'],
    [24, 'Akmal Ikromov bekati', 4028.988991395674, 6847.629503155774, 'Common', 'Akmal Ikromov bekati.mp3'],
    [25, '19-mavze bekati', 4028.8458580079005, 6847.699696614508, 'Common', '19-mavze bekati.mp3'],
    [26, 'Jome masjidi bekati', 4028.5842333589103, 6847.681963097081, 'Common', 'Jome masjidi bekati.mp3'],
    [27, 'Do\'stlik bekati', 4028.5151653372495, 6847.6774759203245, 'Common', 'Do\'stlik bekati.mp3'],
    [28, 'Ko\'rkam diyor Bekat 4', 4028.415300142145, 6847.665686931775, 'Common', 'Ko\'rkam diyor Bekat 4.mp3'],
    [29, 'Ko\'rkam diyor bekat 5', 4028.42344, 6847.41368, 'Common', 'Ko\'rkam diyor bekat 5.mp3'],
    [30, 'Ko\'rkam diyor bekat 6', 4028.4318409428697, 6847.2609210888395, 'Common', 'Ko\'rkam diyor bekat 6.mp3'],
    [31, 'Ko\'rkam diyor bekat 7', 4028.445776058737, 6846.994091918301, 'Common', 'Ko\'rkam diyor bekat 7.mp3'],
    [32, 'Yangi bozor1', 4028.5240410801985, 6846.847648373365, 'End', 'Yangi bozor1.mp3'],
  ]);

  static List<BusStopPoint> _buildStops(List<List<dynamic>> raw) {
    double totalKm = 0.0;
    final list = <BusStopPoint>[];

    for (int i = 0; i < raw.length; i++) {
      final item = raw[i];
      final lat = nmeaToDecimal((item[2] as num).toDouble());
      final lng = nmeaToDecimal((item[3] as num).toDouble());

      if (i > 0) {
        final prevLat = list[i - 1].latitude;
        final prevLng = list[i - 1].longitude;
        totalKm += haversineDistanceKm(prevLat, prevLng, lat, lng);
      }

      list.add(BusStopPoint(
        index: (item[0] as num).toInt(),
        name: item[1].toString(),
        latitude: lat,
        longitude: lng,
        stationType: item[4].toString(),
        audioFile: item[5].toString(),
        distanceKm: double.parse(totalKm.toStringAsFixed(2)),
      ));
    }
    return List.unmodifiable(list);
  }

  /// Avtobus progressiga (0.0 dan 1.0 gacha) qarab hozirgi GPS koordinata va holatini hisoblash
  static BusPositionState getBusPositionAtProgress(
    double progress, {
    bool isForward = true,
  }) {
    final stops = isForward ? forwardStops : backwardStops;
    if (stops.isEmpty) {
      throw StateError('Stops cannot be empty');
    }

    final clamped = progress.clamp(0.0, 1.0);
    final totalStops = stops.length;
    final totalSegments = totalStops - 1;

    // Segment aniqlash
    final exactSeg = clamped * totalSegments;
    int segIndex = exactSeg.floor();
    if (segIndex >= totalSegments) segIndex = totalSegments - 1;

    final segProgress = exactSeg - segIndex;
    final curStop = stops[segIndex];
    final nextStop = stops[math.min(segIndex + 1, totalStops - 1)];

    // Koordinatalar interpolyatsiyasi
    final lat = curStop.latitude + (nextStop.latitude - curStop.latitude) * segProgress;
    final lng = curStop.longitude + (nextStop.longitude - curStop.longitude) * segProgress;

    // Heading (burchak) hisoblash
    final dLat = nextStop.latitude - curStop.latitude;
    final dLng = nextStop.longitude - curStop.longitude;
    final angleRad = math.atan2(dLng, dLat);
    final heading = (angleRad * 180.0 / math.pi + 360.0) % 360.0;

    // Keyingi bekatgacha masofa va ETA
    final distToNextKm = haversineDistanceKm(lat, lng, nextStop.latitude, nextStop.longitude);
    const avgSpeedKmH = 28.0;
    final etaMinutes = math.max(1, ((distToNextKm / avgSpeedKmH) * 60).round());

    return BusPositionState(
      latitude: lat,
      longitude: lng,
      headingDegrees: heading,
      currentStop: curStop,
      nextStop: nextStop,
      etaMinutesToNext: etaMinutes,
      speedKmH: 26.0 + math.sin(clamped * 10) * 8.0, // jonli o'zgaruvchan tezlik (22-34 km/h)
      progress: clamped,
    );
  }

  /// Avtobus joylashuvidan istalgan bekatgacha bo'lgan ETA (daqiqalarda) ni hisoblash
  static int calculateEtaToStop({
    required double busLat,
    required double busLng,
    required int targetStopIndex,
    double busSpeedKmH = 11.0,
    bool isForward = true,
  }) {
    final stops = isForward ? forwardStops : backwardStops;
    if (targetStopIndex < 0 || targetStopIndex >= stops.length) return 5;

    final targetStop = stops[targetStopIndex];

    // Avtobus qaysi bekatlar oralig'ida ekanini topish (eng yaqin oldingi bekat)
    int closestStopIdx = 0;
    double minDistance = double.infinity;

    for (int i = 0; i < stops.length; i++) {
      final d = haversineDistanceKm(busLat, busLng, stops[i].latitude, stops[i].longitude);
      if (d < minDistance) {
        minDistance = d;
        closestStopIdx = i;
      }
    }

    // Agar avtobus tanlangan bekatdan o'tib ketgan bo'lsa (keyingi aylanmada keladi)
    int stopCount;
    double roadDistanceKm = 0.0;

    if (closestStopIdx <= targetStopIndex) {
      stopCount = targetStopIndex - closestStopIdx;
      // Avtobusdan keyingi bekatgacha to'g'ridan-to'g'ri masofa
      final nextIdx = math.min(closestStopIdx + 1, targetStopIndex);
      roadDistanceKm = haversineDistanceKm(busLat, busLng, stops[nextIdx].latitude, stops[nextIdx].longitude);

      // Va oraliqdagi barcha segmentlar yig'indisi
      for (int i = nextIdx; i < targetStopIndex; i++) {
        roadDistanceKm += haversineDistanceKm(
          stops[i].latitude,
          stops[i].longitude,
          stops[i + 1].latitude,
          stops[i + 1].longitude,
        );
      }
    } else {
      // Reys oxirigacha + keyingi aylanma
      stopCount = (stops.length - closestStopIdx) + targetStopIndex;
      roadDistanceKm = haversineDistanceKm(busLat, busLng, targetStop.latitude, targetStop.longitude) + 4.0;
    }

    if (roadDistanceKm < 0.04) {
      return 0; // Bekatda
    }

    final speed = busSpeedKmH > 3.0 ? busSpeedKmH : 11.0;
    // Vaqt = (Masofa / Tezlik) * 60 + (har bir oraliq bekat uchun 1 daqiqa to'xtash vaqti)
    final travelMinutes = (roadDistanceKm / speed) * 60.0;
    final dwellMinutes = stopCount * 1.0; // har bir bekatda 1 daqiqa to'xtab turish
    final totalMinutes = (travelMinutes + dwellMinutes).round();

    return math.max(1, totalMinutes);
  }

  /// Eng yaqin bekatni aniqlash
  static BusStopPoint getClosestStop(double lat, double lng, {bool isForward = true}) {
    final stops = isForward ? forwardStops : backwardStops;
    BusStopPoint closest = stops.first;
    double minD = double.infinity;

    for (final s in stops) {
      final d = haversineDistanceKm(lat, lng, s.latitude, s.longitude);
      if (d < minD) {
        minD = d;
        closest = s;
      }
    }
    return closest;
  }
}

/// Guliston 2-yo'nalish (2-mavze) avtobusi ma'lumotlar bazasi va hisoblash xizmati
class GulistonRoute2 {
  static const String routeNumber = '2';
  static const String routeName = '2-yo\'nalish (2-mavze): TYB ↔ Nurafshon';
  static const String defaultBusCode = 'GUL-102';
  static const String defaultDriver = 'Jasur Karimov';

  /// 2-yo'nalish: To'g'ri yo'nalish (TYB -> Nurafshon bekati) - 24 ta bekat
  static final List<BusStopPoint> forwardStops = _buildStops([
    [0, 'TYB', 4029.73336, 6845.955404, 'Start', 'TYB.mp3'],
    [1, 'Yarmarka bekati', 4029.75454, 6846.065318, 'Common', 'Yarmarka bekati.mp3'],
    [2, '5-maktab bekati', 4029.777634, 6846.251108, 'Common', '5-maktab bekati.mp3'],
    [3, 'Stomatologiya 1', 4029.682136, 6846.31386, 'Common', 'Stomatologiya 1.mp3'],
    [4, 'Bosmaxona', 4029.693824, 6846.382914, 'Common', 'Bosmaxona.mp3'],
    [5, 'Drama teatr', 4029.7063204191318, 6846.52347224693, 'Common', 'Drama teatr.mp3'],
    [6, 'Kutubxona bekati', 4029.574906, 6846.560414, 'Common', 'Kutubxona bekati.mp3'],
    [7, 'Viloyat televideniyasi bekati', 4029.44308, 6846.5987, 'Common', 'Viloyat televideniyasi bekati.mp3'],
    [8, 'Taraqqiyot bekati', 4029.258586, 6846.628334, 'Common', 'Taraqqiyot bekati.mp3'],
    [9, 'Ahillik mahallasi bekati', 4028.989036, 6846.604616, 'Common', 'Ahillik mahallasi bekati.mp3'],
    [10, '11-maktab', 4028.887366, 6846.596468, 'Common', '11-maktab.mp3'],
    [11, 'Samarqand bekati', 4028.720764, 6846.579248, 'Common', 'Samarqand bekati.mp3'],
    [12, 'Yangi O‘zbekiston massivi', 4028.507714251441, 6846.641012259104, 'Common', 'Yangi O‘zbekiston massivi.mp3'],
    [13, 'Aziya bekati', 4028.65816, 6846.98408, 'Common', 'Aziya bekati.mp3'],
    [14, 'Olchazor bekati', 4028.67868, 6847.13918, 'Common', 'Olchazor bekati.mp3'],
    [15, '17-maktab bekati', 4028.88796, 6847.18592, 'Common', '17-maktab bekati.mp3'],
    [16, 'Avaz O\'tar bekati', 4028.87428, 6847.47644, 'Common', 'Avaz O\'tar bekati.mp3'],
    [17, '18-kvartal bekati', 4028.8657, 6847.65656, 'Common', '18-kvartal bekati.mp3'],
    [18, 'Nuroniylar bekati', 4028.8123, 6847.9982, 'Common', 'Nuroniylar bekati.mp3'],
    [19, 'Kimyogar bekati', 4028.79214, 6848.33294, 'Common', 'Kimyogar bekati.mp3'],
    [20, 'Barkamol avlod bekati', 4028.76202, 6848.62772, 'Common', 'Barkamol avlod bekati.mp3'],
    [21, 'Nurafshon Bekat 1', 4028.7403334448045, 6848.952969842147, 'Common', 'Nurafshon Bekat 1.mp3'],
    [22, '19-kvartal', 4028.70724, 6849.35774, 'Common', '19-kvartal.mp3'],
    [23, 'Nurafshon bekati', 4028.698209596632, 6849.559800590176, 'End', 'Nurafshon bekati.mp3'],
  ]);

  /// 2-yo'nalish: Qaytish yo'nalishi (Nurafshon bekati -> TYB) - 25 ta bekat
  static final List<BusStopPoint> backwardStops = _buildStops([
    [0, 'Nurafshon bekati', 4028.698209596632, 6849.559800590176, 'Start', 'Nurafshon bekati.mp3'],
    [1, 'Nurafshon Bekat 2', 4028.71162, 6849.37202, 'Common', 'Nurafshon Bekat 2.mp3'],
    [2, 'Nurafshon Bekat 3', 4028.74816, 6848.94776, 'Common', 'Nurafshon Bekat 3.mp3'],
    [3, 'Shams bekati', 4028.78332, 6848.5823, 'Common', 'Shams bekati.mp3'],
    [4, 'Shabboda bekati', 4028.80408, 6848.28128, 'Common', 'Shabboda bekati.mp3'],
    [5, 'Nuroniylar 2 bekati', 4028.821, 6847.967, 'Common', 'Nuroniylar 2 bekati.mp3'],
    [6, '18-kvartal 2 bekati', 4028.88268, 6847.69022, 'Common', '18-kvartal 2 bekati.mp3'],
    [7, 'Baxtiyor ko\'chasi Farg\'ona bekati', 4028.88274, 6847.44818, 'Common', 'Baxtiyor ko\'chasi Farg\'ona bekati.mp3'],
    [8, 'Baxtiyor ko\'chasi 102', 4028.89078, 6847.30928, 'Common', 'Baxtiyor ko\'chasi 102.mp3'],
    [9, '17-maktab 2 bekati', 4028.87752, 6847.14146, 'Common', '17-maktab 2 bekati.mp3'],
    [10, 'Olchazor 2 bekati', 4028.6626, 6847.10516, 'Common', 'Olchazor 2 bekati.mp3'],
    [11, 'Aziya 2 bekati', 4028.64622, 6846.92252, 'Common', 'Aziya 2 bekati.mp3'],
    [12, 'Dehqon bozori', 4028.5155076734636, 6846.636752593744, 'Common', 'Dehqon bozori.mp3'],
    [13, 'Yangi hayot bekati', 4028.744717, 6846.60248, 'Common', 'Yangi hayot bekati.mp3'],
    [14, '11-maktab-2', 4028.893636, 6846.613856, 'Common', '11-maktab-2.mp3'],
    [15, 'Ahillik mahallasi-2', 4029.061851, 6846.631328, 'Common', 'Ahillik mahallasi-2.mp3'],
    [16, 'Navbahor bekati', 4029.279286, 6846.650678, 'Common', 'Navbahor bekati.mp3'],
    [17, 'Oltin vodiy', 4029.40402, 6846.63524, 'Common', 'Oltin vodiy.mp3'],
    [18, 'Amfiteatr bekati', 4029.51435814045, 6846.596563541112, 'Common', 'Amfiteatr bekati.mp3'],
    [19, 'Uchrashuv bekati', 4029.65428, 6846.5597, 'Common', 'Uchrashuv bekati.mp3'],
    [20, 'Dinamo bekati', 4029.704842, 6846.40216, 'Common', 'Dinamo bekati.mp3'],
    [21, 'Sayhun bekati', 4029.70125, 6846.28622, 'Common', 'Sayhun bekati.mp3'],
    [22, 'Belayn bekati', 4029.899962, 6846.1835, 'Common', 'Belayn bekati.mp3'],
    [23, 'Avtostansiya', 4029.835552, 6845.940254, 'Common', 'Avtostansiya.mp3'],
    [24, 'TYB', 4029.73336, 6845.955404, 'End', 'TYB.mp3'],
  ]);

  static List<BusStopPoint> _buildStops(List<List<dynamic>> raw) {
    double totalKm = 0.0;
    final list = <BusStopPoint>[];

    for (int i = 0; i < raw.length; i++) {
      final item = raw[i];
      final lat = nmeaToDecimal((item[2] as num).toDouble());
      final lng = nmeaToDecimal((item[3] as num).toDouble());

      if (i > 0) {
        final prevLat = list[i - 1].latitude;
        final prevLng = list[i - 1].longitude;
        totalKm += haversineDistanceKm(prevLat, prevLng, lat, lng);
      }

      list.add(BusStopPoint(
        index: (item[0] as num).toInt(),
        name: item[1].toString(),
        latitude: lat,
        longitude: lng,
        stationType: item[4].toString(),
        audioFile: item[5].toString(),
        distanceKm: double.parse(totalKm.toStringAsFixed(2)),
      ));
    }
    return List.unmodifiable(list);
  }

  /// Avtobus joylashuvidan istalgan bekatgacha bo'lgan ETA (daqiqalarda) ni hisoblash
  static int calculateEtaToStop({
    required double busLat,
    required double busLng,
    required int targetStopIndex,
    double busSpeedKmH = 11.0,
    bool isForward = true,
  }) {
    final stops = isForward ? forwardStops : backwardStops;
    if (targetStopIndex < 0 || targetStopIndex >= stops.length) return 5;

    final targetStop = stops[targetStopIndex];

    int closestStopIdx = 0;
    double minDistance = double.infinity;

    for (int i = 0; i < stops.length; i++) {
      final d = haversineDistanceKm(busLat, busLng, stops[i].latitude, stops[i].longitude);
      if (d < minDistance) {
        minDistance = d;
        closestStopIdx = i;
      }
    }

    int stopCount;
    double roadDistanceKm = 0.0;

    if (closestStopIdx <= targetStopIndex) {
      stopCount = targetStopIndex - closestStopIdx;
      final nextIdx = math.min(closestStopIdx + 1, targetStopIndex);
      roadDistanceKm = haversineDistanceKm(busLat, busLng, stops[nextIdx].latitude, stops[nextIdx].longitude);

      for (int i = nextIdx; i < targetStopIndex; i++) {
        roadDistanceKm += haversineDistanceKm(
          stops[i].latitude,
          stops[i].longitude,
          stops[i + 1].latitude,
          stops[i + 1].longitude,
        );
      }
    } else {
      stopCount = (stops.length - closestStopIdx) + targetStopIndex;
      roadDistanceKm = haversineDistanceKm(busLat, busLng, targetStop.latitude, targetStop.longitude) + 4.0;
    }

    if (roadDistanceKm < 0.04) {
      return 0; // Bekatda
    }

    final speed = busSpeedKmH > 3.0 ? busSpeedKmH : 11.0;
    final travelMinutes = (roadDistanceKm / speed) * 60.0;
    final dwellMinutes = stopCount * 1.0;
    final totalMinutes = (travelMinutes + dwellMinutes).round();

    return math.max(1, totalMinutes);
  }

  /// Eng yaqin bekatni aniqlash
  static BusStopPoint getClosestStop(double lat, double lng, {bool isForward = true}) {
    final stops = isForward ? forwardStops : backwardStops;
    BusStopPoint closest = stops.first;
    double minD = double.infinity;

    for (final s in stops) {
      final d = haversineDistanceKm(lat, lng, s.latitude, s.longitude);
      if (d < minD) {
        minD = d;
        closest = s;
      }
    }
    return closest;
  }
}

/// Barcha yo'nalishlarni birlashtiruvchi markaziy boshqaruvchi
class GulistonRoutes {
  static List<BusStopPoint> getStops(String routeNum, {bool isForward = true}) {
    if (routeNum == '2') {
      return isForward ? GulistonRoute2.forwardStops : GulistonRoute2.backwardStops;
    }
    return isForward ? GulistonRoute1.forwardStops : GulistonRoute1.backwardStops;
  }

  static String getRouteName(String routeNum, {bool isForward = true}) {
    if (routeNum == '2') {
      return isForward ? 'TYB ➔ Nurafshon (2-mavze)' : 'Nurafshon ➔ TYB (2-mavze)';
    }
    return isForward ? 'Yangi bozor ➔ GulDU' : 'GulDU ➔ Yangi bozor';
  }

  static String getBusCode(String routeNum) {
    if (routeNum == '2') return GulistonRoute2.defaultBusCode;
    return GulistonRoute1.defaultBusCode;
  }

  static String getDriverName(String routeNum) {
    if (routeNum == '2') return GulistonRoute2.defaultDriver;
    return GulistonRoute1.defaultDriver;
  }

  static int calculateEta(String routeNum, {
    required double busLat,
    required double busLng,
    required int targetStopIndex,
    double speedKmH = 11.0,
    bool isForward = true,
  }) {
    if (routeNum == '2') {
      return GulistonRoute2.calculateEtaToStop(
        busLat: busLat,
        busLng: busLng,
        targetStopIndex: targetStopIndex,
        busSpeedKmH: speedKmH,
        isForward: isForward,
      );
    }
    return GulistonRoute1.calculateEtaToStop(
      busLat: busLat,
      busLng: busLng,
      targetStopIndex: targetStopIndex,
      busSpeedKmH: speedKmH,
      isForward: isForward,
    );
  }
}
