import 'dart:convert';
import 'dart:math' as math;

import 'package:quiver/iterables.dart';

import 'game/game.dart';

class GameRegistry {
  final Map<String, Game> games = {};
  final math.Random rand = math.Random();

  String createGame() {
    var code = randomCode();
    print("creating $code");
    games[code] = Game(onTerminate: () {
      print("removing $code");
      games.remove(code);
    });
    return code;
  }

  String randomCode() {
    String code;
    do {
      code = ascii.decode([for (var _ in range(4)) rand.nextInt(26) + 65]);
    } while (games.containsKey(code));
    return code;
  }
}
