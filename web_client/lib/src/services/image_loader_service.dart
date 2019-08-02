import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:indexed_db';

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;

class ImageLoaderService {
  final http.Client _client;

  ImageLoaderService(this._client);

  final Future<Database> _dbFuture = openDatabase();

  Future<String> getImageDataUrl(String name, {bool updateCache = true}) async {
    var db = await _dbFuture;
    var ret = await db
        .transaction("image_cache", "readonly")
        .objectStore("image_cache")
        .getObject(name);
    if (ret == null) {
      //print("getImageDataUrl() did not find image data url");
      if (updateCache) {
        await _cacheImages();
        return getImageDataUrl(name, updateCache: false);
      } else {
        return "";
      }
    } else {
      //print("getImageDataUrl() found image data url");
      return ret;
    }
  }

  static Future<Database> openDatabase() =>
      window.indexedDB.open("crazy_eights:crazy_eights", version: 1,
          onUpgradeNeeded: (evt) async {
        Database db = evt.target.result;
        db.createObjectStore("image_cache");
      });

  Future<void> _cacheImages() async {
    var db = await _dbFuture;
    var archive = await _downloadImages();
    var txn = db.transaction("image_cache", "readwrite");
    var imageCache = txn.objectStore("image_cache");

    await Future.wait([
      for (var file in archive.files)
        imageCache.put(
          "data:image/png;base64," + base64Encode(file.content),
          file.name,
        )
    ]);
    await txn.onComplete.first;
  }

  Future<Archive> _downloadImages() async {
    //print("_downloadImages() called");
    var response = await _client.get("/images.zip");
    //print("_downloadImages() completing");
    return ZipDecoder().decodeBytes(response.bodyBytes);
  }
}
