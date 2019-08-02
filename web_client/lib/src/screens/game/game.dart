import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:crazy_eights_common/common.dart';

import '../../components/card_stack/card_stack.dart';
import '../../routing.dart';
import '../../services/game_connection_service.dart';

@Component(
  selector: "ce-game",
  templateUrl: "game.html",
  styleUrls: ["game.css"],
  directives: [coreDirectives, CardStackComponent],
  exports: [Suit, print],
)
class GameScreen implements OnActivate, OnDestroy {
  final GameConnectionService _gameConnector;

  GameScreen(this._gameConnector);

  StreamSubscription<PlayerVision> _subscription;
  Sink<PlayerAction> _actionSink;

  PlayerVision currentState;

  String get cardBack => currentState.cardColor + "_back.png";

  String get tickerText {
    if (currentState.winnerName != null) {
      return "${currentState.winnerName} has won!";
    } else if (currentState.ownTurn) {
      for (var card in currentState.hand) {
        if (currentState.lastDiscard.matches(card)) {
          return "Play or draw a card";
        }
      }
      return "Draw a card";
    } else {
      var opponent = currentState.opponents.singleWhere((o) => o.hasTurn);
      return "Waiting for ${opponent.name} (${opponent.handSize} cards)...";
    }
  }

  static String cardImage(Card card) => "$card.png";

  @override
  void onActivate(_, RouterState current) {
    var connection =
        _gameConnector.connect(Routes.getGameCode(current.parameters));
    _subscription = connection.playerVisionStream.listen((d) {
      currentState = d;
    });
    _actionSink = connection.playerActionSink;
  }

  static final PlayerAction draw = PlayerAction((b) => b..draw = true);
  static PlayerAction play(int handIndex, Suit modifiedSuit) =>
      PlayerAction((b) => b
        ..draw = false
        ..handIndex = handIndex
        ..modifiedSuit = modifiedSuit);

  void dispatch(PlayerAction action) {
    if (!currentState.ownTurn) return;
    _actionSink.add(action);
  }

  @override
  void ngOnDestroy() {
    _subscription?.cancel();
    _actionSink?.close();
  }
}
