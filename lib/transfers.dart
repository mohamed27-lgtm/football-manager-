import 'models.dart';

/// عرض وارد من نادٍ آخر لشراء أحد لاعبيك
class Offer {
  final Player player;
  final String club;
  final double amount;
  int weeksLeft;
  Offer(this.player, this.club, this.amount, this.weeksLeft);

  Map<String, dynamic> toJson() =>
      {'pid': player.id, 'club': club, 'amt': amount, 'w': weeksLeft};
}

/// نتيجة جولة تفاوض: accept / counter / reject
class NegoResult {
  final String status;
  final double? counter;
  final String msg;
  const NegoResult(this.status, this.counter, this.msg);
}
