import 'dart:io';

import 'package:image/image.dart';

void main() async {
  var imageDir = Directory("images");
  if (!await imageDir.exists()) {
    print("Run from crazy_eights/web_client");
    return;
  }

  await for (var fse in imageDir.list()) {
    if (fse is File && fse.path.endsWith(".png")) {
      await process(fse);
    }
  }
}

Future<void> process(File f) async {
  var image = decodePng(await f.readAsBytes());
  var newWidth = image.width ~/ 2, newHeight = image.height ~/ 2;
  print("Reducing ${f.path} "
      "from ${image.width}x${image.height} "
      "to ${newWidth}x${newHeight}");
  var smolImage = copyResize(image,
      width: newWidth, height: newHeight, interpolation: Interpolation.cubic);
  await f.writeAsBytes(encodePng(smolImage));
  print("Successfully reduced ${f.path}.");
}
