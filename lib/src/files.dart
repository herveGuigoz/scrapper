import 'dart:io';

class FileIO {
  static List<FileSystemEntity> dirContents() {
    final dir = Directory('generated/test');
    final files = dir.listSync();

    return files;
  }
}
