import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:crazy_eights_common/common.dart';
import 'package:web_socket_channel/html.dart';

import '../utils/window_prompt.dart';

export 'mock_game_connection_service.dart';

class GameConnectionService {
  GameConnection connect(String code) {
    //var name = windowPrompt("Enter a screen name");
    String name;
    do {
      name = windowPrompt("Enter a screen name");
    } while (name.length > 20 ||
        window.confirm("Your name is ${name.length} "
            "characters long, so you will start with ${name.length} "
            "cards in your hand. Is this acceptable?"));
    var channel = HtmlWebSocketChannel.connect((StringBuffer()
          ..write(window.origin.replaceFirst("http", "ws"))
          ..write("/ws/game?code=")
          ..write(Uri.encodeQueryComponent(code))
          ..write("&name=")
          ..write(Uri.encodeQueryComponent(name)))
        .toString());

    return GameConnection(
      channel.stream.transform(StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          if (data is String) {
            sink.add(serializers.deserialize(jsonDecode(data)));
          }
        },
        handleDone: (sink) => sink.close(),
      )),
      _PlayerActionSink(channel.sink),
    );
  }
}

class GameConnection {
  final Stream<PlayerVision> playerVisionStream;
  final Sink<PlayerAction> playerActionSink;
  GameConnection(this.playerVisionStream, this.playerActionSink);
}

class _PlayerActionSink implements Sink<PlayerAction> {
  final Sink _connectionSink;
  _PlayerActionSink(this._connectionSink);

  @override
  void add(PlayerAction data) {
    _connectionSink.add(jsonEncode(serializers.serialize(data)));
  }

  @override
  void close() {
    _connectionSink.close();
  }
}
