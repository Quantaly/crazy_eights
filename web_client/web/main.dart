import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:crazy_eights_web_client/app_component.template.dart' as ng;
import 'package:http/http.dart' as http;

import 'main.template.dart' as self;

@GenerateInjector([
  routerProvidersHash,
  ClassProvider(http.Client),
])
final InjectorFactory injector = self.injector$Injector;

void main() {
  runApp(ng.AppComponentNgFactory, createInjector: injector);
}
