import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';

import 'src/routing.dart';
import 'src/services/game_connection_service.dart';
import 'src/services/game_creation_service.dart';
import 'src/services/image_loader_service.dart';

@Component(
  selector: 'ce-app',
  templateUrl: 'app_component.html',
  directives: [routerDirectives],
  exports: [Routes],
  providers: [
    ClassProvider(GameConnectionService),
    ClassProvider(GameCreationService),
    ClassProvider(ImageLoaderService),
  ],
)
class AppComponent {}
