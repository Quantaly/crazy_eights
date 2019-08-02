import 'dart:html' as h;

import 'package:angular/angular.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:angular_router/angular_router.dart';

import '../../routing.dart';
import '../../services/game_creation_service.dart';
import '../../services/image_loader_service.dart';

@Component(
  selector: "ce-home",
  templateUrl: "home.html",
  styleUrls: ["home.css"],
  directives: [coreDirectives, formDirectives],
  pipes: [commonPipes],
)
class HomeScreen implements OnInit {
  final GameCreationService _gameCreator;
  final ImageLoaderService _imageLoader;
  final Router _router;

  HomeScreen(this._gameCreator, this._imageLoader, this._router);

  Future<String> splashImageSrcF = Future.value("");

  @override
  void ngOnInit() {
    splashImageSrcF = _imageLoader.getImageDataUrl("back_cards-07.png");
  }

  String _joinCode = "";
  String get joinCode => _joinCode;
  set joinCode(String value) => _joinCode = value.toUpperCase();

  void createGame() async {
    var gameCode = await _gameCreator.createGame();
    _joinGame(gameCode);
  }

  void joinGame() {
    _joinGame(joinCode);
  }

  void _joinGame(String gameCode) {
    _router.navigate(Routes.gameLink(gameCode));
  }

  static final RegExp notAZ = RegExp("[^A-Z]");
  bool get validJoinCode => joinCode.length == 4 && !notAZ.hasMatch(joinCode);
}
