import 'package:flutter_riverpod/flutter_riverpod.dart';

class BusTicket {
  final String id;
  final String routeNumber;
  final String routeName;
  final int fare;
  final DateTime purchasedAt;
  final DateTime expiresAt;
  final String qrCodeData;

  BusTicket({
    required this.id,
    required this.routeNumber,
    required this.routeName,
    required this.fare,
    required this.purchasedAt,
    required this.expiresAt,
    required this.qrCodeData,
  });

  bool get isValid => DateTime.now().isBefore(expiresAt);
}

class WalletState {
  final int balance;
  final List<BusTicket> tickets;

  WalletState({
    required this.balance,
    required this.tickets,
  });

  WalletState copyWith({
    int? balance,
    List<BusTicket>? tickets,
  }) {
    return WalletState(
      balance: balance ?? this.balance,
      tickets: tickets ?? this.tickets,
    );
  }
}

final walletProvider = StateNotifierProvider<WalletNotifier, WalletState>((ref) {
  return WalletNotifier();
});

class WalletNotifier extends StateNotifier<WalletState> {
  WalletNotifier()
      : super(WalletState(
          balance: 35000,
          tickets: [
            BusTicket(
              id: 'TCK-9901',
              routeNumber: '17',
              routeName: 'Vokzal — Yangi Bozor — GulDU',
              fare: 2000,
              purchasedAt: DateTime.now().subtract(const Duration(minutes: 5)),
              expiresAt: DateTime.now().add(const Duration(minutes: 25)),
              qrCodeData: 'SMARTBUS-GULISTON-PASS-17-9901',
            )
          ],
        ));

  void topUp(int amount) {
    state = state.copyWith(balance: state.balance + amount);
  }

  bool buyTicket({required String routeNumber, required String routeName, int fare = 2000}) {
    if (state.balance < fare) {
      return false;
    }

    final newBalance = state.balance - fare;
    final now = DateTime.now();
    final newTicket = BusTicket(
      id: 'TCK-${now.millisecondsSinceEpoch.toString().substring(7)}',
      routeNumber: routeNumber,
      routeName: routeName,
      fare: fare,
      purchasedAt: now,
      expiresAt: now.add(const Duration(minutes: 30)),
      qrCodeData: 'SMARTBUS-GULISTON-PASS-$routeNumber-${now.millisecondsSinceEpoch}',
    );

    state = state.copyWith(
      balance: newBalance,
      tickets: [newTicket, ...state.tickets],
    );
    return true;
  }
}
