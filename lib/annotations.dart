import 'package:reflectable/reflectable.dart';

class Table extends Reflectable {
  const Table()
      : super(
            invokingCapability,
            metadataCapability,
            declarationsCapability,
            typeRelationsCapability,
            typeCapability,
            typingCapability,
            //admitSubtypeCapability,
            typeAnnotationDeepQuantifyCapability,
            superclassQuantifyCapability,
            subtypeQuantifyCapability,
            reflectedTypeCapability);
}

class Column {
  final String name;
  final bool primaryKey;

  const Column({this.name, this.primaryKey: false});
}

class BelongsTo extends Column {
  const BelongsTo([String name]) : super(name: name, primaryKey: false);
}

class HasMany extends Column {
  const HasMany({String name}) : super(name: name, primaryKey: false);
}

const primaryKey = const Column(primaryKey: true);
const column = const Column();
const table = const Table();
const belongsTo = const BelongsTo();
const hasMany = const HasMany();
