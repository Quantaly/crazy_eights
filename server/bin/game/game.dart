import 'dart:collection';
import 'dart:math' as math;

import 'package:crazy_eights_common/common.dart';
import 'package:meta/meta.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'player.dart';

const cardColors = ["blue", "gray", "green", "purple", "red", "yellow"];

class Game {
  final List<Player> players = [];

  final void Function() onTerminate;

  String cardColor;

  Game({@required this.onTerminate}) {
    cardColor = cardColors[rand.nextInt(cardColors.length)];
    deck.addAll(Card.makeDeck().toList()..shuffle(rand));
    discard.add(deck.removeFirst());
    Future.delayed(const Duration(seconds: 10), () {
      if (players.isEmpty) {
        end();
      }
    });
  }

  int _turnIndex = 0;
  int get turnIndex => _turnIndex;
  set turnIndex(int newIndex) {
    _turnIndex = newIndex % players.length;
  }

  final math.Random rand = math.Random();
  final Queue<Card> deck = Queue();
  final Queue<Card> discard = Queue();

  String winnerName;

  void addPlayer(WebSocketChannel channel, String name) {
    players.insert(players.isEmpty ? 0 : (turnIndex - 1) % (players.length + 1),
        Player(this, channel, name));
    updateAllPlayers();
  }

  void checkDeckEmpty() {
    if (deck.isEmpty) {
      var topDiscard = discard.removeLast();
      deck.addAll([
        for (var card in discard) card.rebuild((b) => b..modifiedSuit = null)
      ]..shuffle(rand));
      if (deck.length < 10) {
        deck.addAll(Card.makeDeck().toList()..shuffle(rand));
      }
      discard
        ..clear()
        ..add(topDiscard);
    }
  }

  void updateAllPlayers() {
    for (var player in players) {
      player.update();
    }
  }

  void end([Player winner]) {
    if (winner != null) {
      winnerName = winner.name;
      print("$winnerName has won!");
      updateAllPlayers();
      for (var player in players) {
        player.disconnectAtGameEnd();
      }
    }
    onTerminate();
  }
}
