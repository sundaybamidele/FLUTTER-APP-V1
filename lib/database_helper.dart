import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'main.dart';

class DatabaseHelper {
  static const _databaseName = 'blog_database.db';
  static const _databaseVersion = 1;

  static const table = 'blog_items';

  static const columnId = '_id';
  static const columnTitle = 'title';
  static const columnDate = 'date';
  static const columnBody = 'body';
  static const columnImageUrl = 'imageUrl';
  static const columnQuantity = 'quantity';
  static const columnStatus = 'status';
  static const columnDeleted = 'deleted';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $table (
        $columnId INTEGER PRIMARY KEY,
        $columnTitle TEXT NOT NULL,
        $columnDate TEXT NOT NULL,
        $columnBody TEXT NOT NULL,
        $columnImageUrl TEXT,
        $columnQuantity INTEGER NOT NULL,
        $columnStatus TEXT NOT NULL,
        $columnDeleted INTEGER NOT NULL
      )
      ''');
  }

  Future<int> insertBlogItem(BlogItem blogItem) async {
    Database db = await instance.database;
    return await db.insert(table, blogItem.toMap());
  }

  Future<BlogItem> getBlogItem(int id) async {
    Database db = await instance.database;
    List<Map> maps = await db.query(table,
        columns: [
          columnId,
          columnTitle,
          columnDate,
          columnBody,
          columnImageUrl,
          columnQuantity,
          columnStatus,
          columnDeleted
        ],
        where: '$columnId = ?',
        whereArgs: [id]);
    if (maps.isNotEmpty) {
      return BlogItem.fromMap(maps.first);
    } else {
      throw Exception('ID $id not found');
    }
  }

  Future<List<BlogItem>> getBlogItems() async {
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query(table);
    return List.generate(maps.length, (i) {
      return BlogItem(
        id: maps[i][columnId],
        title: maps[i][columnTitle],
        date: DateTime.parse(maps[i][columnDate]),
        body: maps[i][columnBody],
        imageUrl: maps[i][columnImageUrl],
        quantity: maps[i][columnQuantity],
        status: maps[i][columnStatus],
        deleted: maps[i][columnDeleted] == 1,
      );
    });
  }

  Future<int> updateBlogItem(BlogItem blogItem) async {
    Database db = await instance.database;
    return await db.update(table, blogItem.toMap(),
        where: '$columnId = ?', whereArgs: [blogItem.id]);
  }

  Future<int> deleteBlogItem(int id) async {
    Database db = await instance.database;
    return await db.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }
}
