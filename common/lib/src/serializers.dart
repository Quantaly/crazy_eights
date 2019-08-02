import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';

import 'models/card.dart';
import 'models/player_action.dart';
import 'models/player_vision.dart';

part 'serializers.g.dart';

@SerializersFor([
  Card,
  PlayerAction,
  PlayerVision,
])
final Serializers serializers = _$serializers;
