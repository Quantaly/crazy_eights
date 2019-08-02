import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'card.g.dart';

abstract class Card implements Built<Card, CardBuilder> {
  static Serializer<Card> get serializer => _$cardSerializer;

  int get rank;
  Suit get suit;

  /// The suit an 8 has been chosen to behave as.
  @nullable
  @BuiltValueField(compare: false)
  Suit get modifiedSuit;

  Card._();
  factory Card([updates(CardBuilder b)]) = _$Card;

  static const ranks = [
    "A",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9",
    "10",
    "J",
    "Q",
    "K"
  ];

  @override
  String toString() => ranks[rank - 1] + suit.letter;

  /// Whether [other] can be played on top of [this].
  bool matches(Card other) =>
      other.rank == 8 ||
      other.rank == rank ||
      other.suit == (modifiedSuit ?? suit);

  static Iterable<Card> makeDeck() sync* {
    for (var rank = 1; rank <= 13; rank++) {
      for (var suit in Suit.values) {
        yield Card((b) => b
          ..rank = rank
          ..suit = suit);
      }
    }
  }
}

class Suit extends EnumClass {
  static Serializer<Suit> get serializer => _$suitSerializer;

  static const Suit clubs = _$clubs;
  static const Suit diamonds = _$diamonds;
  static const Suit hearts = _$hearts;
  static const Suit spades = _$spades;

  static const _letters = {clubs: "C", diamonds: "D", hearts: "H", spades: "S"};

  String get letter => _letters[this];

  const Suit._(String name) : super(name);

  static BuiltSet<Suit> get values => _$suitValues;
  static Suit valueOf(String name) => _$suitValueOf(name);
}
