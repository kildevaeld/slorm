import './model.dart';
import './annotations.dart';
import './descriptions.dart';
import 'package:sqflite/sqflite.dart' as sqlite;
import 'package:path/path.dart' as Path;
import 'package:reflectable/reflectable.dart';
import './errors.dart';

typedef Map<String, dynamic> Serializer<M extends Model>(M model);
typedef M Deserializer<M extends Model>(Map<String, dynamic> map);

class Tuple<K, V> {
  final K item1;
  final V item2;
  Tuple(this.item1, this.item2);
}

Serializer<M> _createSerialize<M extends Model>(ModelDescription desc) {
  return (M model) {
    var out = Map<String, dynamic>();

    var mirror = table.reflect(model);

    for (var v in desc.columns) {
      var name = v.columnName;
      var value = v.getValue(mirror);
      out[name] = value;
    }

    return out;
  };
}

Deserializer<M> _createDeserializer<M extends Model>(ModelDescription desc) {
  return (Map<String, dynamic> map) {
    var instance = desc.mirror.newInstance("", []);
    var mirror = table.reflect(instance);
    for (var v in desc.columns) {
      if (!map.containsKey(v.columnName)) {
        continue;
      }
      v.setValue(mirror, map[v.columnName]);
    }
    return instance;
  };
}

class Collection<M extends Model> {
  Serializer<M> _serializer;
  Deserializer<M> _deserializer;
  ModelDescription _desc;
  sqlite.Database _database;

  ModelDescription get description => _desc;

  Collection(this._database) {
    _desc = ModelDescription.from<M>();

    _serializer = _createSerialize(_desc);
    _deserializer = _createDeserializer(_desc);
  }

  Future<M> create(M model) async {
    var map = _serializer(model), rows = description.createRowStmt();

    if (_desc.primaryKey != null) map.remove(_desc.primaryKey.columnName);

    var values = description.columns.where((m) => !m.primaryKey).map((m) {
      return map[m.columnName];
    }).toList();

    final id = await _database.rawInsert(rows, values);

    if (_desc.primaryKey != null) {
      var instance = table.reflect(model);
      _desc.primaryKey.setValue(instance, id);
    }

    return model;
  }

  Future<List<M>> findAll(
      {String where, List<dynamic> whereArgs, int limit}) async {
    var rows = await _database.rawQuery(_desc.findRowsStmt());
    return rows.map((m) => description.convert(m) as M).toList();
  }

  Future<M> find(dynamic id) async {
    final primaryKey = _desc.primaryKey.columnName;

    final results =
        await findAll(where: "$primaryKey = ?", whereArgs: [id], limit: 1);

    if (results.isEmpty) return null;

    return results[0];
  }

  static Future<Collection<M>> open<M extends Model>(String path) async {
    var databasesPath = await sqlite.getDatabasesPath();
    path = Path.join(databasesPath, path);
    final db = await sqlite.openDatabase(path, version: 1);

    var col = Collection<M>(db);

    await db.execute(col.description.createTableStatement());
    return col;
  }
}
