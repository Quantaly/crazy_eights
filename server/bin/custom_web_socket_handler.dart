/// This is almost entirely copy-pasted from package:shelf_web_socket.
///
/// The only difference is that the web socket handler function in my case
/// needs access to the request URI for figuring out which game to connect to.
///
/// I have no idea why this isn't a thing with package:shelf_web_socket but
/// whatever.
library custom_web_socket_handler;

import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

typedef OnConnection = void Function(WebSocketChannel channel, Uri requestUri);

Handler customWebSocketHandler(OnConnection onConnection,
    {Iterable<String> protocols,
    Iterable<String> allowedOrigins,
    Duration pingInterval}) {
  if (protocols != null) protocols = protocols.toSet();
  if (allowedOrigins != null) {
    allowedOrigins =
        allowedOrigins.map((origin) => origin.toLowerCase()).toSet();
  }

  /*if (onConnection is! _BinaryFunction) {
    if (protocols != null) {
      throw new ArgumentError("If protocols is non-null, onConnection must "
          "take two arguments, the WebSocket and the protocol.");
    }

    var innerOnConnection = onConnection;
    onConnection = (webSocket, _) => innerOnConnection(webSocket);
  }*/

  return CustomWebSocketHandler(
          onConnection, protocols, allowedOrigins, pingInterval)
      .handle;
}

/// A class that exposes a handler for upgrading WebSocket requests.
class CustomWebSocketHandler {
  /// The function to call when a request is upgraded.
  final OnConnection _onConnection;

  /// The set of protocols the user supports, or `null`.
  final Set<String> _protocols;

  /// The set of allowed browser origin connections, or `null`..
  final Set<String> _allowedOrigins;

  /// The ping interval used for verifying connection, or `null`.
  final Duration _pingInterval;

  CustomWebSocketHandler(this._onConnection, this._protocols,
      this._allowedOrigins, this._pingInterval);

  /// The [Handler].
  Response handle(Request request) {
    if (request.method != 'GET') return _notFound();

    var connection = request.headers['Connection'];
    if (connection == null) return _notFound();
    var tokens =
        connection.toLowerCase().split(',').map((token) => token.trim());
    if (!tokens.contains('upgrade')) return _notFound();

    var upgrade = request.headers['Upgrade'];
    if (upgrade == null) return _notFound();
    if (upgrade.toLowerCase() != 'websocket') return _notFound();

    var version = request.headers['Sec-WebSocket-Version'];
    if (version == null) {
      return _badRequest('missing Sec-WebSocket-Version header.');
    } else if (version != '13') {
      return _notFound();
    }

    if (request.protocolVersion != '1.1') {
      return _badRequest('unexpected HTTP version '
          '"${request.protocolVersion}".');
    }

    var key = request.headers['Sec-WebSocket-Key'];
    if (key == null) return _badRequest('missing Sec-WebSocket-Key header.');

    if (!request.canHijack) {
      throw ArgumentError("webSocketHandler may only be used with a server "
          "that supports request hijacking.");
    }

    // The Origin header is always set by browser connections. By filtering out
    // unexpected origins, we ensure that malicious JavaScript is unable to fake
    // a WebSocket handshake.
    var origin = request.headers['Origin'];
    if (origin != null &&
        _allowedOrigins != null &&
        !_allowedOrigins.contains(origin.toLowerCase())) {
      return _forbidden('invalid origin "$origin".');
    }

    var protocol = _chooseProtocol(request);
    request.hijack((channel) {
      var sink = utf8.encoder.startChunkedConversion(channel.sink);
      sink.add("HTTP/1.1 101 Switching Protocols\r\n"
          "Upgrade: websocket\r\n"
          "Connection: Upgrade\r\n"
          "Sec-WebSocket-Accept: ${WebSocketChannel.signKey(key)}\r\n");
      if (protocol != null) sink.add("Sec-WebSocket-Protocol: $protocol\r\n");
      sink.add("\r\n");

      _onConnection(
          WebSocketChannel(channel, pingInterval: _pingInterval), request.url);
    });

    // [request.hijack] is guaranteed to throw a [HijackException], so we'll
    // never get here.
    assert(false);
    return null;
  }

  /// Selects a subprotocol to use for the given connection.
  ///
  /// If no matching protocol can be found, returns `null`.
  String _chooseProtocol(Request request) {
    var protocols = request.headers['Sec-WebSocket-Protocol'];
    if (protocols == null) return null;
    for (var protocol in protocols.split(',')) {
      protocol = protocol.trim();
      if (_protocols.contains(protocol)) return protocol;
    }
    return null;
  }

  /// Returns a 404 Not Found response.
  Response _notFound() => _htmlResponse(
      404, "404 Not Found", "Only WebSocket connections are supported.");

  /// Returns a 400 Bad Request response.
  ///
  /// [message] will be HTML-escaped before being included in the response body.
  Response _badRequest(String message) => _htmlResponse(
      400, "400 Bad Request", "Invalid WebSocket upgrade request: $message");

  /// Returns a 403 Forbidden response.
  ///
  /// [message] will be HTML-escaped before being included in the response body.
  Response _forbidden(String message) => _htmlResponse(
      403, "403 Forbidden", "WebSocket upgrade refused: $message");

  /// Creates an HTTP response with the given [statusCode] and an HTML body with
  /// [title] and [message].
  ///
  /// [title] and [message] will be automatically HTML-escaped.
  Response _htmlResponse(int statusCode, String title, String message) {
    title = htmlEscape.convert(title);
    message = htmlEscape.convert(message);
    return Response(statusCode, body: """
      <!doctype html>
      <html>
        <head><title>$title</title></head>
        <body>
          <h1>$title</h1>
          <p>$message</p>
        </body>
      </html>
    """, headers: {'content-type': 'text/html'});
  }
}
