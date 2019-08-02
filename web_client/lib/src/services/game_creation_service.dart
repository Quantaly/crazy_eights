import 'package:http/http.dart' as http;

class GameCreationService {
  final http.Client _client;

  GameCreationService(this._client);

  Future<String> createGame() async {
    var response = await _client.post("/games");
    return response.body;
  }
}
