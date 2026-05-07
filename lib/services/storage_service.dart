import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// StorageService - saves all app data as a single text file on the device
/// File location: `<app_documents_dir>`/fixmate_data.txt
class StorageService {
  static final StorageService instance = StorageService._internal();
  factory StorageService() => instance;
  StorageService._internal();

  static const String _fileName = 'fixmate_data.txt';

  Map<String, dynamic> _data = {};

  /// Returns the file path on disk
  Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  /// Load all data from the JSON file into memory
  Future<void> load() async {
    try {
      final file = await _file;
      if (await file.exists()) {
        final content = await file.readAsString();
        _data = Map<String, dynamic>.from(json.decode(content));
      }
    } catch (e) {
      _data = {};
    }
  }

  /// Save all in-memory data to the JSON file
  Future<void> save() async {
    try {
      final file = await _file;
      await file.writeAsString(json.encode(_data), flush: true);
    } catch (e) {
      // ignore write errors
    }
  }

  // ==================== Typed Getters & Setters ====================

  String? getString(String key) => _data[key] as String?;

  Future<void> setString(String key, String value) async {
    _data[key] = value;
    await save();
  }

  Future<void> remove(String key) async {
    _data.remove(key);
    await save();
  }

  List<String>? getStringList(String key) {
    final val = _data[key];
    if (val == null) return null;
    return List<String>.from(val as List);
  }

  Future<void> setStringList(String key, List<String> value) async {
    _data[key] = value;
    await save();
  }

  bool? getBool(String key) => _data[key] as bool?;

  Future<void> setBool(String key, bool value) async {
    _data[key] = value;
    await save();
  }

  /// Returns the path of the JSON file (for debugging/display)
  Future<String> getFilePath() async {
    final file = await _file;
    return file.path;
  }
}
