import 'package:reflectable/reflectable.dart';
import './model.dart';
import './annotations.dart';
import './errors.dart';
import 'dart:typed_data';
// import 'package:inflection/inflection.dart';

abstract class SqlType {
  String get sqlString;

  dynamic fromSql(dynamic value) => value;

  dynamic toSql(dynamic value) => value;
}

class SqlStringType extends SqlType {
  final String sqlString = "TEXT";
}

class SqlIntegerType extends SqlType {
  final String sqlString = "INTEGER";
}

class SqlRealType extends SqlType {
  final String sqlString = "REAL";
}

class SqlBlobType extends SqlType {
  final String sqlString = "BLOB";
}

class SqlBoolType extends SqlType {
  final String sqlString = "INTEGER";
}

class SqlDateType extends SqlType {
  final String sqlString = "TEXT";

  @override
  DateTime fromSql(dynamic value) {
    if (value == null) return null;
    return DateTime.parse(value);
  }

  @override
  dynamic toSql(dynamic value) {
    if (value is DateTime) {
      return value.toIso8601String();
    }
    return value;
  }
}

SqlType _toSqlType(Type type) {
  if (table.canReflectType(String) &&
      type == table.reflectType(String).reflectedType) {
    return SqlStringType();
  } else if (table.canReflectType(int) &&
      type == table.reflectType(int).reflectedType) {
    return SqlIntegerType();
  } else if (table.canReflectType(double) &&
      type == table.reflectType(double).reflectedType) {
    return SqlRealType();
  } else if (table.canReflectType(bool) &&
      type == table.reflectType(bool).reflectedType) {
    return SqlBoolType();
  } else if (table.canReflectType(Uint8List) &&
      type == table.reflectType(Uint8List).reflectedType) {
    return SqlBlobType();
  } else if (table.canReflectType(DateTime) &&
      type == table.reflectType(DateTime).reflectedType) {
    return SqlDateType();
  }
  return null;
}

SqlType _toSqlTypeFromVar(VariableMirror mirror) {
  if (mirror.hasReflectedType) {
    var sql = _toSqlType(mirror.reflectedType);
    if (sql != null) return sql;
  }
  // var modelType = table.reflectType(Model);
  // if (mirror.type.isSubtypeOf(modelType)) {}
  // print("${mirror.type.isSubtypeOf(modelType)}");
  return null;
}

class ModelDescription {
  String tableName;
  List<ColumnDesc> columns;
  ClassMirror mirror;

  ModelDescription(this.tableName, this.mirror, this.columns);

  ColumnDesc get primaryKey =>
      columns.firstWhere((m) => m.primaryKey == true, orElse: () => null);

  String createTableStatement() {
    var cols = columns.map((col) {
      if (col.primaryKey) {
        return '"${col.columnName}" INTEGER PRIMARY KEY AUTOINCREMENT';
      }
      return '"${col.columnName}" ${col.sqlType.sqlString}';
    });

    return 'CREATE TABLE IF NOT EXISTS "$tableName" (${cols.join(', ')});';
  }

  String createRowStmt() {
    var cols = [], vals = [];
    columns.forEach((col) {
      if (col.primaryKey) return;
      cols.add(col.columnName);
      vals.add('?');
    });
    return 'INSERT INTO "$tableName" (${cols.join(', ')}) VALUES (${vals.join(', ')});';
  }

  String findRowsStmt() {
    var cols = [], joins = [];
    columns.forEach((col) {
      if (col is BelongsToDescription) {
        joins.add(
            "JOIN ${col.target.tableName} on ${col.target.tableName}.${col.target.primaryKey.columnName} = $tableName.${primaryKey.columnName}");

        col.target.columns.forEach((subcol) {
          cols.add(
              '${col.target.tableName}.${subcol.columnName} as "${col.target.tableName}.${subcol.columnName}"');
        });

        return;
      }
      cols.add(
          '$tableName.${col.columnName} as "$tableName.${col.columnName}"');
    });

    var out = ['SELECT ${cols.join(', ')} FROM $tableName'];
    if (joins.isNotEmpty) out.add(joins.join(' '));
    return out.join(' ');
  }

  List<String> get columnNames => columns.map((c) => c.columnName).toList();

  static ModelDescription from<M extends Model>() {
    ClassMirror mirror = table.reflectType(M);

    return fromTypeMirror(mirror);
  }

  static ModelDescription fromTypeMirror(ClassMirror mirror) {
    List<ColumnDesc> columns = [];
    mirror.declarations.forEach((name, method) {
      Field field;
      for (var meta in method.metadata) {
        if (meta is Field && method is VariableMirror) {
          field = meta;
          break;
        }
      }
      if (field == null) return;

      var columnName = field.name ?? method.simpleName;
      if (field is BelongsTo) {
        var mirror = fromTypeMirror((method as VariableMirror).type);
        if (field.name != null) {
          columnName = columnName;
        } else {
          columnName = mirror.tableName + "_id";
        }
        columns.add(BelongsToDescription(columnName, method, mirror));
      } else {
        columns.add(ColumnDescription(columnName, method, field.primaryKey));
      }
    });

    var tableName = mirror.invokeGetter("tableName") ?? mirror.simpleName;

    return ModelDescription(tableName, mirror, columns);
  }

  Map<String, dynamic> toMap() {
    return {
      "tableName": tableName,
      "columns": columns.map((c) => c.toMap()).toList(),
    };
  }

  @override
  String toString() {
    return "${toMap()}";
  }
}

abstract class ColumnDesc {
  final String columnName;
  final VariableMirror mirror;
  final bool primaryKey;
  SqlType sqlType;
  ColumnDesc(this.columnName, this.mirror, this.primaryKey) {
    sqlType = _toSqlTypeFromVar(this.mirror);
  }

  void setValue(InstanceMirror instance, dynamic value) {
    instance.invokeSetter(mirror.simpleName, value);
  }

  dynamic getValue(InstanceMirror instance) =>
      instance.invokeGetter(mirror.simpleName);

  Map<String, dynamic> toMap() {
    return {
      "type": this.runtimeType.toString(),
      "columnName": columnName,
      "primaryKey": primaryKey,
      "sqlType": sqlType.sqlString,
      "dartType": mirror.reflectedType.toString(),
    };
  }
}

abstract class ForeignColumnDesc extends ColumnDesc {
  ModelDescription target;
  ForeignColumnDesc(String columnName, VariableMirror mirror, this.target)
      : super(columnName, mirror, false) {
    this.sqlType = SqlIntegerType();
  }
}

class ColumnDescription extends ColumnDesc {
  ColumnDescription(String columnName, VariableMirror mirror, bool primaryKey)
      : super(columnName, mirror, primaryKey);
}

class BelongsToDescription extends ForeignColumnDesc {
  BelongsToDescription(
      String columnName, VariableMirror mirror, ModelDescription target)
      : super(columnName, mirror, target);

  void setValue(InstanceMirror instance, dynamic value) {
    instance.invokeSetter(mirror.simpleName, value);
  }

  dynamic getValue(InstanceMirror instance) {
    var targetInstance = instance.invokeGetter(mirror.simpleName);
    if (targetInstance == null) return null;
    var m = table.reflect(targetInstance);
    var idName = target.primaryKey.mirror.simpleName;
    var id = m.invokeGetter(idName);
    return id;
  }
}
