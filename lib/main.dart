import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'database_helper.dart';

void main() {
  runApp(const MyApp());
}

class BlogItem {
  int? id;
  String title;
  DateTime date;
  String body;
  String? imageUrl;
  int quantity;
  String status;
  bool deleted;

  BlogItem({
    this.id,
    required this.title,
    required this.date,
    required this.body,
    this.imageUrl,
    required this.quantity,
    required this.status,
    this.deleted = false,
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blog App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const BlogListScreen(),
    );
  }
}

class BlogListScreen extends StatefulWidget {
  const BlogListScreen({super.key});

  @override
  _BlogListScreenState createState() => _BlogListScreenState();
}

class _BlogListScreenState extends State<BlogListScreen> {
  late List<BlogItem> _blogItems;
  late List<BlogItem> _filteredItems;
  final TextEditingController _searchController = TextEditingController();
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadBlogItems();
  }

  Future<void> _loadBlogItems() async {
    _blogItems = await _databaseHelper.getBlogItems();
    _filteredItems = List.from(_blogItems);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Blog List'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Total'),
              Tab(text: 'In Stock'),
              Tab(text: 'Finished'),
              Tab(text: 'Deleted'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: BlogSearchDelegate(_blogItems),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterItems('');
                  },
                ),
              ),
              onChanged: _filterItems,
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildTab(0),
                  _buildTab(1),
                  _buildTab(2),
                  _buildTab(3),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final newBlogItem = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddEditBlogItemScreen(),
              ),
            );
            if (newBlogItem != null) {
              await _databaseHelper.insertBlogItem(newBlogItem);
              _loadBlogItems();
            }
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildTab(int tabIndex) {
    List<BlogItem> filteredItems = [];
    if (tabIndex == 0) {
      filteredItems = _blogItems;
    } else if (tabIndex == 1) {
      filteredItems = _blogItems
          .where((item) => item.quantity > 0 && !item.deleted)
          .toList();
    } else if (tabIndex == 2) {
      filteredItems = _blogItems
          .where((item) => item.quantity == 0 && !item.deleted)
          .toList();
    } else if (tabIndex == 3) {
      filteredItems = _blogItems.where((item) => item.deleted).toList();
    }

    return ListView.builder(
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final blogItem = filteredItems[index];
        return ListTile(
          title: Text(blogItem.title),
          subtitle: Text(DateFormat('yyyy-MM-dd').format(blogItem.date)),
          onTap: () async {
            if (!blogItem.deleted) {
              final updatedBlogItem = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlogItemScreen(blogItem: blogItem),
                ),
              );
              if (updatedBlogItem != null) {
                await _databaseHelper.updateBlogItem(updatedBlogItem);
                _loadBlogItems();
              }
            }
          },
          leading: Checkbox(
            value: _filteredItems.contains(blogItem),
            onChanged: (value) {
              setState(() {
                if (value!) {
                  _filteredItems.add(blogItem);
                } else {
                  _filteredItems.remove(blogItem);
                }
              });
            },
          ),
          trailing: !blogItem.deleted
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        final updatedBlogItem = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AddEditBlogItemScreen(blogItem: blogItem),
                          ),
                        );
                        if (updatedBlogItem != null) {
                          await _databaseHelper.updateBlogItem(updatedBlogItem);
                          _loadBlogItems();
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () {
                        _shareItem(blogItem);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        await _databaseHelper.deleteBlogItem(blogItem.id!);
                        _loadBlogItems();
                      },
                    ),
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.restore),
                      onPressed: () async {
                        blogItem.deleted = false;
                        await _databaseHelper.updateBlogItem(blogItem);
                        _loadBlogItems();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        await _databaseHelper.deleteBlogItem(blogItem.id!);
                        _loadBlogItems();
                      },
                    ),
                  ],
                ),
        );
      },
    );
  }

  void _filterItems(String query) {
    setState(() {
      _filteredItems = _blogItems
          .where((item) =>
              item.title.toLowerCase().contains(query.toLowerCase()) ||
              item.body.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _shareItem(BlogItem item) {
    final text = '${item.title}\n${item.body}';
    Share.share(text);
  }
}

class BlogSearchDelegate extends SearchDelegate<BlogItem> {
  final List<BlogItem> items;

  BlogSearchDelegate(this.items);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(
          context,
          BlogItem(
            title: '',
            date: DateTime.now(),
            body: '',
            quantity: 0,
            status: '',
          ),
        );
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildList(query);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildList(query);
  }

  Widget _buildList(String query) {
    final filteredItems = items
        .where((item) =>
            item.title.toLowerCase().contains(query.toLowerCase()) ||
            item.body.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return ListView.builder(
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final blogItem = filteredItems[index];
        return ListTile(
          title: Text(blogItem.title),
          subtitle: Text(DateFormat('yyyy-MM-dd').format(blogItem.date)),
          onTap: () {
            close(context, blogItem);
          },
        );
      },
    );
  }
}

class AddEditBlogItemScreen extends StatefulWidget {
  final BlogItem? blogItem;

  const AddEditBlogItemScreen({super.key, this.blogItem});

  @override
  _AddEditBlogItemScreenState createState() => _AddEditBlogItemScreenState();
}

class _AddEditBlogItemScreenState extends State<AddEditBlogItemScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  File? _imageFile;
  int _quantity = 0;
  String _status = 'Out of Stock';

  @override
  void initState() {
    super.initState();
    if (widget.blogItem != null) {
      _titleController.text = widget.blogItem!.title;
      _bodyController.text = widget.blogItem!.body;
      _quantity = widget.blogItem!.quantity;
      _status = widget.blogItem!.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.blogItem == null ? 'Add Blog Item' : 'Edit Blog Item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Item name'),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _bodyController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 5,
            ),
            const SizedBox(height: 16.0),
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantity'),
              onChanged: (value) {
                setState(() {
                  _quantity = int.tryParse(value) ?? 0;
                  _status = _quantity > 0 ? 'In Stock' : 'Out of Stock';
                });
              },
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                final pickedFile =
                    await ImagePicker().pickImage(source: ImageSource.gallery);
                setState(() {
                  _imageFile =
                      pickedFile != null ? File(pickedFile.path) : null;
                });
              },
              child: const Text('Select Image'),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                if (_titleController.text.isNotEmpty &&
                    _bodyController.text.isNotEmpty) {
                  final blogItem = BlogItem(
                    title: _titleController.text,
                    date: DateTime.now(),
                    body: _bodyController.text,
                    imageUrl: _imageFile?.path,
                    quantity: _quantity,
                    status: _status,
                  );
                  if (widget.blogItem == null) {
                    await _databaseHelper.insertBlogItem(blogItem);
                  } else {
                    blogItem.id = widget.blogItem!.id;
                    await _databaseHelper.updateBlogItem(blogItem);
                  }
                  Navigator.pop(context);
                } else {
                  // Show error message or handle empty fields
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class BlogItemScreen extends StatelessWidget {
  final BlogItem blogItem;

  const BlogItemScreen({Key? key, required this.blogItem}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(blogItem.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat('yyyy-MM-dd').format(blogItem.date)),
            const SizedBox(height: 16.0),
            Text(blogItem.body),
            const SizedBox(height: 16.0),
            if (blogItem.imageUrl != null)
              Image.network(
                blogItem.imageUrl!,
                fit: BoxFit.cover,
                height: 200,
              ),
            const SizedBox(height: 16.0),
            Text('Quantity: ${blogItem.quantity}'),
            Text('Status: ${blogItem.status}'),
          ],
        ),
      ),
    );
  }
}
