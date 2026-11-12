import 'package:flutter_riverpod/flutter_riverpod.dart';

class EcoRewardItem {
  final String id;
  final String title;
  final String description;
  final int pointsRequired;
  final String category;
  final bool isClaimed;

  EcoRewardItem({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsRequired,
    required this.category,
    this.isClaimed = false,
  });

  EcoRewardItem copyWith({bool? isClaimed}) {
    return EcoRewardItem(
      id: id,
      title: title,
      description: description,
      pointsRequired: pointsRequired,
      category: category,
      isClaimed: isClaimed ?? this.isClaimed,
    );
  }
}

class EcoState {
  final int points;
  final int co2SavedGrams;
  final String rankTitle;
  final List<EcoRewardItem> rewards;

  EcoState({
    required this.points,
    required this.co2SavedGrams,
    required this.rankTitle,
    required this.rewards,
  });

  EcoState copyWith({
    int? points,
    int? co2SavedGrams,
    String? rankTitle,
    List<EcoRewardItem>? rewards,
  }) {
    return EcoState(
      points: points ?? this.points,
      co2SavedGrams: co2SavedGrams ?? this.co2SavedGrams,
      rankTitle: rankTitle ?? this.rankTitle,
      rewards: rewards ?? this.rewards,
    );
  }
}

final ecoRewardsProvider = StateNotifierProvider<EcoRewardsNotifier, EcoState>((ref) {
  return EcoRewardsNotifier();
});

class EcoRewardsNotifier extends StateNotifier<EcoState> {
  EcoRewardsNotifier()
      : super(EcoState(
          points: 380,
          co2SavedGrams: 540,
          rankTitle: 'Eko-Qahramon 🌿 (3-Daraja)',
          rewards: [
            EcoRewardItem(
              id: 'RWD-01',
              title: '1 Kunlik Bepul Avtobus Pass',
              description: 'Kun bo\'yi barcha avtobuslarda bepul yurish chiptasi',
              pointsRequired: 200,
              category: 'Transport',
            ),
            EcoRewardItem(
              id: 'RWD-02',
              title: '15% Qahva Chegirmasi (Coffee-Zone Guliston)',
              description: 'Barcha kofe va ichimliklarga 15% chegirma',
              pointsRequired: 150,
              category: 'Chegirma',
            ),
            EcoRewardItem(
              id: 'RWD-03',
              title: 'Eko-Daraxt Ekish Sertifikati 🌳',
              description: 'Guliston bog\'ida shuning nomingizga yangi nihol ekiladi',
              pointsRequired: 500,
              category: 'Ekologiya',
            ),
          ],
        ));

  bool claimReward(String rewardId) {
    final reward = state.rewards.firstWhere((r) => r.id == rewardId);
    if (state.points < reward.pointsRequired || reward.isClaimed) {
      return false;
    }

    final updatedRewards = state.rewards.map((r) {
      if (r.id == rewardId) return r.copyWith(isClaimed: true);
      return r;
    }).toList();

    state = state.copyWith(
      points: state.points - reward.pointsRequired,
      rewards: updatedRewards,
    );
    return true;
  }

  void addTripEcoPoints({int points = 25, int co2Grams = 40}) {
    state = state.copyWith(
      points: state.points + points,
      co2SavedGrams: state.co2SavedGrams + co2Grams,
    );
  }
}
