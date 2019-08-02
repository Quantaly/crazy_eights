import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_static/shelf_static.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'custom_web_socket_handler.dart';
import 'game_registry.dart';

// For Google Cloud Run, set _hostname to '0.0.0.0'.
const _hostname = '0.0.0.0';

shelf.Response get no => shelf.Response.notFound("no");

final registry = GameRegistry();

main(List<String> args) async {
  var parser = ArgParser()..addOption('port', abbr: 'p');
  var result = parser.parse(args);

  // For Google Cloud Run, we respect the PORT environment variable
  var portStr = result['port'] ?? Platform.environment['PORT'] ?? '8080';
  var port = int.tryParse(portStr);

  if (port == null) {
    stdout.writeln('Could not parse port value "$portStr" into a number.');
    // 64: command line usage error
    exitCode = 64;
    return;
  }

  var handler = const shelf.Pipeline()
      .addMiddleware(shelf.logRequests())
      .addHandler(shelf.Cascade()
          .add(const shelf.Pipeline()
              .addMiddleware(_evaluateGameConnection)
              .addHandler(customWebSocketHandler(_joinGame,
                  pingInterval: const Duration(seconds: 2))))
          .add(_createGame)
          .add(const shelf.Pipeline()
              .addMiddleware(_compressIfPossible)
              .addHandler(createStaticHandler(
                  p.join("..", "web_client", "build"),
                  defaultDocument: "index.html")))
          .add((_) {
        return shelf.Response.notFound("oof");
      }).handler);

  var server = await io.serve(handler, _hostname, port);
  print('Serving at http://${server.address.host}:${server.port}');
}

shelf.Handler _evaluateGameConnection(shelf.Handler innerHandler) => (request) {
      if (request.url.path != "ws/game" ||
          request.url.queryParameters["name"] == null ||
          request.url.queryParameters["code"] == null ||
          !registry.games.containsKey(request.url.queryParameters["code"])) {
        return no;
      }
      return innerHandler(request);
    };

void _joinGame(WebSocketChannel ws, Uri uri) {
  registry.games[uri.queryParameters["code"]]
      .addPlayer(ws, uri.queryParameters["name"]);
}

shelf.Handler _compressIfPossible(shelf.Handler innerHandler) => (request) {
      FutureOr<shelf.Response> handleInnerResponse(
          shelf.Response innerResponse) {
        if ((request.headers["accept-encoding"]
                    ?.split(", ")
                    ?.contains("gzip") ??
                false) &&
            _compressContentType(innerResponse.headers["content-type"])) {
          return innerResponse.change(
              headers: {
                "content-encoding": "gzip",
                "transfer-encoding": "chunked"
              },
              body: chunkedCoding.encoder
                  .bind(gzip.encoder.bind(innerResponse.read())));
        }
        return innerResponse;
      }

      var forInnerResponse = innerHandler(request);
      if (forInnerResponse is Future<shelf.Response>) {
        return forInnerResponse.then(handleInnerResponse);
      } else {
        return handleInnerResponse(forInnerResponse);
      }
    };

// no SVGs so not compressing images is fine
bool _compressContentType(String contentType) =>
    contentType != null &&
    !(contentType.startsWith("image/") || contentType == "application/zip");

shelf.Response _createGame(shelf.Request request) {
  if (request.method == "POST" && request.url.path == "games") {
    return shelf.Response.ok(registry.createGame());
  } else {
    return no;
  }
}
