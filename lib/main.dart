import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(const MyApp());
}

class BlogItem {
  static int _counter = 0;
  int id;
  String title;
  DateTime date;
  String body;
  String? imageUrl;
  int quantity;
  String status;
  bool deleted;

  BlogItem({
    required this.title,
    required this.date,
    required this.body,
    this.imageUrl,
    required this.quantity,
    required this.status,
    this.deleted = false,
  }) : id = _counter++;

  // Other methods and properties...
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
  final List<BlogItem> _blogItems = [];
  late List<BlogItem> _filteredItems;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredItems = List.from(_blogItems);
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
                  _buildTab(_blogItems, 0),
                  _buildTab(_blogItems, 1),
                  _buildTab(_blogItems, 2),
                  _buildTab(_blogItems, 3),
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
              setState(() {
                _blogItems.add(newBlogItem);
                _filteredItems = List.from(_blogItems);
              });
            }
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildTab(List<BlogItem> items, int tabIndex) {
    List<BlogItem> filteredItems = [];
    if (tabIndex == 0) {
      filteredItems = items;
    } else if (tabIndex == 1) {
      filteredItems =
          items.where((item) => item.quantity > 0 && !item.deleted).toList();
    } else if (tabIndex == 2) {
      filteredItems =
          items.where((item) => item.quantity == 0 && !item.deleted).toList();
    } else if (tabIndex == 3) {
      filteredItems = items.where((item) => item.deleted).toList();
    }

    return ListView.builder(
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final blogItem = filteredItems[index];
        return ListTile(
          title: Text('${blogItem.id}. ${blogItem.title}'),
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
                setState(() {
                  items[index] = updatedBlogItem;
                  _filteredItems = List.from(_blogItems);
                });
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
                          setState(() {
                            items[index] = updatedBlogItem;
                            _filteredItems = List.from(_blogItems);
                          });
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
                      onPressed: () {
                        setState(() {
                          blogItem.deleted = true;
                          _filteredItems = List.from(_blogItems);
                        });
                      },
                    ),
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.restore),
                      onPressed: () {
                        setState(() {
                          blogItem.deleted = false;
                          _filteredItems = List.from(_blogItems);
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          items.removeAt(index);
                        });
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
            ));
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
          title: Text('${blogItem.id}. ${blogItem.title}'),
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
              onPressed: () {
                if (_titleController.text.isNotEmpty &&
                    _bodyController.text.isNotEmpty) {
                  Navigator.pop(
                    context,
                    BlogItem(
                      title: _titleController.text,
                      date: DateTime.now(),
                      body: _bodyController.text,
                      imageUrl: _imageFile?.path,
                      quantity: _quantity,
                      status: _status,
                    ),
                  );
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

class BlogItemScreen extends StatefulWidget {
  final BlogItem blogItem;

  const BlogItemScreen({Key? key, required this.blogItem}) : super(key: key);

  @override
  _BlogItemScreenState createState() => _BlogItemScreenState();
}

class _BlogItemScreenState extends State<BlogItemScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.blogItem.id}. ${widget.blogItem.title}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat('yyyy-MM-dd').format(widget.blogItem.date)),
            const SizedBox(height: 16.0),
            Text(widget.blogItem.body),
            const SizedBox(height: 16.0),
            if (widget.blogItem.imageUrl != null)
              Image.network(
                widget.blogItem.imageUrl!,
                fit: BoxFit.cover,
                height: 200,
              ),
            const SizedBox(height: 16.0),
            Text('Quantity: ${widget.blogItem.quantity}'),
            Text('Status: ${widget.blogItem.status}'),
          ],
        ),
      ),
    );
  }
}
