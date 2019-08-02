import 'dart:async';

import 'package:angular/angular.dart';

import 'package:crazy_eights_common/common.dart';

import '../../services/image_loader_service.dart';

@Component(
  selector: "ce-card-stack",
  templateUrl: "card_stack.html",
  styleUrls: ["card_stack.css"],
  directives: [coreDirectives],
  pipes: [commonPipes],
  exports: [Suit],
)
class CardStackComponent implements AfterChanges {
  @Input()
  String image;

  @Input()
  int stackSize;

  @Input()
  bool displaySuitSelectors = false;

  @Input()
  Suit displaySingleSuit;

  @Input()
  bool disabled = false;

  @Output()
  Stream<Suit> select;
  final StreamController<Suit> selectController = StreamController.broadcast();

  final ImageLoaderService imageLoader;

  CardStackComponent(this.imageLoader) {
    select = selectController.stream;
  }

  Future<String> imageSrcF = Future.value("");

  String _lastImage;
  @override
  void ngAfterChanges() {
    if (image != _lastImage) {
      _lastImage = image;
      if (image != null) {
        imageSrcF = imageLoader.getImageDataUrl(image);
      } else {
        imageSrcF = Future.value("");
      }
    }
  }

  void dispatch(Suit suit) {
    if (disabled) return;
    selectController.add(suit);
  }
}
