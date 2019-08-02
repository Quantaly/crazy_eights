import 'package:crazy_eights_common/common.dart';

import 'game_connection_service.dart';

class MockGameConnectionService implements GameConnectionService {
  @override
  GameConnection connect(String code) {
    return GameConnection(makeVisionStream(), _UselessSink());
  }

  static Stream<PlayerVision> makeVisionStream() async* {
    var opponents = [
      OpponentView((b) => b
        ..name = "L. R. Jenkins"
        ..handSize = 42
        ..hasTurn = true),
      OpponentView((b) => b
        ..name = "Anita R. E."
        ..handSize = 69
        ..hasTurn = false),
    ];
    yield PlayerVision((b) => b
      ..hand.addAll([
        for (var suit in Suit.values)
          Card((b) => b
            ..rank = 8
            ..suit = suit),
      ])
      ..opponents.addAll(opponents)
      ..cardColor = "blue"
      ..lastDiscard.update((b) => b
        ..rank = 2
        ..suit = Suit.diamonds)
      ..deckSize = 30
      ..discardSize = 20
      ..ownTurn = false);
  }
}

class _UselessSink<T> implements Sink<T> {
  @override
  void add(T data) {}
  @override
  void close() {}
}
