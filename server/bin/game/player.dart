import 'dart:convert';

import 'package:built_value/serializer.dart' show DeserializationError;
import 'package:crazy_eights_common/common.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'game.dart';

class Player {
  final Game _game;
  final WebSocketChannel _channel;
  final String name;

  final List<Card> hand = [];

  int get index => _game.players.indexOf(this);

  Player(this._game, this._channel, this.name) {
    _channel.stream.listen(handleIncomingMessage).onDone(disconnect);
    for (var i = 0; i < (name.length > 20 ? name.length : 5); i++) {
      hand.add(_game.deck.removeFirst());
      _game.checkDeckEmpty();
    }
  }

  void handleIncomingMessage(message) {
    if (message is String) {
      try {
        var deser = serializers.deserialize(jsonDecode(message));
        if (deser is PlayerAction) {
          if (_game.turnIndex == index) {
            if (deser.draw) {
              hand.add(_game.deck.removeFirst());
              _game
                ..checkDeckEmpty()
                ..turnIndex += 1
                ..updateAllPlayers();
              return;
            } else {
              if (deser.handIndex != null) {
                var card = hand[deser.handIndex];
                if (!_game.discard.last.matches(card)) return;
                if (card.rank == 8) {
                  if (deser.modifiedSuit == null) return;
                  hand.removeAt(deser.handIndex);
                  _game.discard.add(
                      card.rebuild((b) => b.modifiedSuit = deser.modifiedSuit));
                } else {
                  hand.removeAt(deser.handIndex);
                  _game.discard.add(card);
                }
                if (hand.isEmpty) {
                  _game.end(this);
                } else {
                  _game.turnIndex++;
                }
                _game.updateAllPlayers();
                return;
              }
            }
          } else {
            return;
          }
        }
      } on DeserializationError {
        disconnect();
        return;
      }
    }
    disconnect();
  }

  void update() {
    var vision = PlayerVision((b) => b
      ..hand.addAll(hand)
      ..opponents.addAll(_opponentIndices().map((i) {
        var p = _game.players[i];
        return OpponentView((b) => b
          ..name = p.name
          ..handSize = p.hand.length
          ..hasTurn = _game.turnIndex == i);
      }))
      ..cardColor = _game.cardColor
      ..lastDiscard.replace(_game.discard.last)
      ..deckSize = _game.deck.length
      ..discardSize = _game.discard.length
      ..ownTurn = _game.turnIndex == index
      ..winnerName = _game.winnerName);
    _channel.sink.add(jsonEncode(serializers.serialize(vision)));
  }

  Iterable<int> _opponentIndices() sync* {
    var indexCache = index;
    for (var i = (indexCache + 1) % _game.players.length;
        i != indexCache;
        i = (i + 1) % _game.players.length) {
      yield i;
    }
  }

  bool _hasDisconnected = false;
  void disconnect() {
    if (_hasDisconnected) return;
    _hasDisconnected = true;

    _channel.sink.close();
    if (index > _game.turnIndex) {
      _game.turnIndex--;
    }
    _game.players.remove(this);
    if (_game.players.isEmpty) {
      _game.end();
    } else {
      _game
        ..turnIndex = _game.turnIndex // reset for the modulus
        ..deck.addAll(hand..shuffle(_game.rand))
        ..updateAllPlayers();
    }
  }

  void disconnectAtGameEnd() {
    if (_hasDisconnected) return;
    _hasDisconnected = true;

    _channel.sink.close();
  }
}
