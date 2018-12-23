import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:slorm/slorm.dart' as slorm;
import 'main.reflectable.dart';

void main() => runApp(MyApp());

@slorm.table
class Person extends slorm.Model {
  static String get tableName => "persons";

  @slorm.primaryKey
  int id;
  @slorm.column
  String name;

  @slorm.hasMany
  List<Blog> blogs;
}

@slorm.table
class Blog extends slorm.Model {
  static String get tableName => "blogs";

  @slorm.primaryKey
  int id;
  @slorm.column
  String title;
  @slorm.belongsTo
  Person person;
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // try {
    //   platformVersion = await Slorm.platformVersion;
    // } on PlatformException {
    //   platformVersion = 'Failed to get platform version.';
    // }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.ac_unit),
              onPressed: () async {
                initializeReflectable();

                var persons = await slorm.Collection.open<Person>("demo.db");
                print("persons ${persons.description}");

                persons.findAll();
                // var blogs = await slorm.Collection.open<Blog>("demo.db");
                // var person = Person()..name = "Test Mig";
                // //person = await persons.create(person);
                // // print("${blogs.description.createTableStatement()}");
                // // await blogs.create(Blog()
                // //   ..title = "A Blog title"
                // //   ..person = person);
                // Stopwatch stopwatch = new Stopwatch()..start();
                // var data = await blogs.findAll();
                // print(
                //     'doSomething() executed in ${stopwatch.elapsed.inMilliseconds}');

                // for (var r in data) {
                //   print(
                //       "name ${r.title}, id: ${r.id} ${r.person.id} ${r.person.name}");
                // }

                // var listOfPersons = await persons.findAll();

                // for (var p in listOfPersons) {
                //   print("name ${p.name}: ");
                //   for (var b in p.blogs) {
                //     print("  blog: ${b.title}");
                //   }
                // }
                // var person =
                //     await collection.create(Person()..name = "Test Mig");

                // var p1 = await collection.find(1);

                // print("person ${p1.id} ${p1.name} ${person.id}");
              },
            )
          ],
        ),
        body: Center(
          child: Text('Running on: $_platformVersion\n'),
        ),
      ),
    );
  }
}
