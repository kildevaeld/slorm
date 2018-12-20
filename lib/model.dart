import 'package:reflectable/reflectable.dart';
import './annotations.dart';
import 'package:sqflite/sqflite.dart' as sqlite;
import 'package:path/path.dart' as Path;

abstract class Model {
  static String get tableName => null;
}
