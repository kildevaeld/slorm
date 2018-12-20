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

class Field {
  final String name;
  final bool primaryKey;

  const Field({this.name, this.primaryKey: false});
}

class BelongsTo extends Field {
  const BelongsTo([String name]) : super(name: name, primaryKey: false);
}

const primaryKey = const Field(primaryKey: true);
const field = const Field();
const table = const Table();
const belongsTo = const BelongsTo();
