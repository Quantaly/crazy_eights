import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import 'card.dart';

part 'player_vision.g.dart';

abstract class PlayerVision
    implements Built<PlayerVision, PlayerVisionBuilder> {
  static Serializer<PlayerVision> get serializer => _$playerVisionSerializer;

  BuiltList<Card> get hand;
  BuiltList<OpponentView> get opponents;
  String get cardColor;
  Card get lastDiscard;
  int get deckSize;
  int get discardSize;
  bool get ownTurn;

  @nullable
  String get winnerName;

  PlayerVision._();
  factory PlayerVision([updates(PlayerVisionBuilder b)]) = _$PlayerVision;
}

abstract class OpponentView
    implements Built<OpponentView, OpponentViewBuilder> {
  static Serializer<OpponentView> get serializer => _$opponentViewSerializer;

  String get name;
  int get handSize;
  bool get hasTurn;

  OpponentView._();
  factory OpponentView([updates(OpponentViewBuilder b)]) = _$OpponentView;
}
