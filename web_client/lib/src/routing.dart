import 'package:angular_router/angular_router.dart';

import 'screens/game/game.template.dart' as game_template;
import 'screens/home/home.template.dart' as home_template;

class Routes {
  static final home = RouteDefinition(
    path: "home",
    component: home_template.HomeScreenNgFactory,
    useAsDefault: true,
  );

  static const _gameCode = "gameCode";
  static final game = RouteDefinition(
    path: "game/:$_gameCode",
    component: game_template.GameScreenNgFactory,
  );
  static String gameLink(String code) => game.toUrl({_gameCode: code});

  static String getGameCode(Map<String, String> parameters) =>
      parameters[_gameCode];

  static final all = [
    home,
    game,
  ];
}
