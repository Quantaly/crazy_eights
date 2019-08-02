import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import 'card.dart';

part 'player_action.g.dart';

abstract class PlayerAction
    implements Built<PlayerAction, PlayerActionBuilder> {
  static Serializer<PlayerAction> get serializer => _$playerActionSerializer;

  /// True if the player has chosen to draw rather than play a card.
  bool get draw;

  /// If the player is playing a card, the index into their hand from which
  /// they are playing.
  @nullable
  int get handIndex;

  /// If the player is playing an 8, the suit which they have chosen to play it
  /// as.
  @nullable
  Suit get modifiedSuit;

  PlayerAction._();
  factory PlayerAction([updates(PlayerActionBuilder b)]) = _$PlayerAction;
}
