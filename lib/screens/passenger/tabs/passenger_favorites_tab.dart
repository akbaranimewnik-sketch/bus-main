import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage_service.dart';
import '../../../core/theme.dart';

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, List<Map<String, String>>>((ref) {
  return FavoritesNotifier(ref.read(storageServiceProvider));
});

class FavoritesNotifier extends StateNotifier<List<Map<String, String>>> {
  final StorageService _storage;
  FavoritesNotifier(this._storage) : super([]) {
    _load();
  }

  void _load() {
    final raw = _storage.favorites;
    state = raw.map((s) {
      final parts = s.split('|');
      return {'type': parts[0], 'name': parts[1], 'detail': parts.length > 2 ? parts[2] : ''};
    }).toList();
  }

  void add(String type, String name, [String detail = '']) {
    if (state.any((f) => f['name'] == name)) return;
    state = [...state, {'type': type, 'name': name, 'detail': detail}];
    _save();
  }

  void remove(String name) {
    state = state.where((f) => f['name'] != name).toList();
    _save();
  }

  bool isFav(String name) => state.any((f) => f['name'] == name);

  void _save() {
    _storage.setFavorites(state.map((f) => '${f['type']}|${f['name']}|${f['detail']}').toList());
  }
}

class PassengerFavoritesTab extends ConsumerWidget {
  const PassengerFavoritesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favs = ref.watch(favoritesProvider);
    final notifier = ref.read(favoritesProvider.notifier);
    final buses = favs.where((f) => f['type'] == 'bus').toList();
    final stops = favs.where((f) => f['type'] == 'stop').toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Sevimlilar')),
      body: favs.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border_rounded, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text("Hali saqlagan narsa yo'q", style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSecondary, fontSize: 16)),
                const SizedBox(height: 8),
                const Text("Avtobus yoki bekat kartasidagi ♥ ni bosing", style: TextStyle(color: AppColors.textSecondary, fontSize: 13), textAlign: TextAlign.center),
              ],
            ),
          )
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (buses.isNotEmpty) ...[
                const _SectionHeader(label: 'Avtobuslar', icon: Icons.directions_bus_rounded),
                const SizedBox(height: 8),
                ...buses.map((fav) => _FavCard(
                  icon: Icons.directions_bus_rounded,
                  iconColor: AppColors.primary,
                  name: fav['name']!,
                  detail: fav['detail'],
                  onDelete: () => notifier.remove(fav['name']!),
                )),
                const SizedBox(height: 16),
              ],
              if (stops.isNotEmpty) ...[
                const _SectionHeader(label: 'Bekatlar', icon: Icons.location_on_rounded),
                const SizedBox(height: 8),
                ...stops.map((fav) => _FavCard(
                  icon: Icons.location_on_rounded,
                  iconColor: AppColors.accent,
                  name: fav['name']!,
                  detail: fav['detail'],
                  onDelete: () => notifier.remove(fav['name']!),
                )),
              ],
            ],
          ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionHeader({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 16, color: AppColors.textSecondary),
      const SizedBox(width: 6),
      Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 1.2)),
    ],
  );
}

class _FavCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String name;
  final String? detail;
  final VoidCallback onDelete;

  const _FavCard({required this.icon, required this.iconColor, required this.name, this.detail, required this.onDelete});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.border),
      boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black12, offset: Offset(0, 2))],
    ),
    child: Row(
      children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              if (detail?.isNotEmpty == true)
                Text(
                  detail!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
            ],
          ),
        ),
        IconButton(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
        ),
      ],
    ),
  );
}
