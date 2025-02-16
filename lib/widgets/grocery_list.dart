import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_shopping_list_app_tutorial_udemy/data/categories.dart';
import 'package:flutter_shopping_list_app_tutorial_udemy/models/grocery_item.dart';
import 'package:http/http.dart' as http;

import 'new_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];

  var _isLoading = true;

  // variable to hold any errors that might occur from sending HTTP request
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  // NOTE: initially it was just a void, but after adding FutureBuilder we need
  // to return a list of items that we are interested in
  void _loadItems() async {
    // fetch data from the backend
    final url = Uri.https(
      "flutter-shop-list-app-tutorial-default-rtdb.firebaseio.com",
      "shopping-list.json",
    );

    final response = await http.get(url);

    // a good idea would be to add error handling instead of them being stuck on
    // a loading screen (this is what we have at the moment)
    if (response.statusCode >= 400) {
      // NOTE: this is one way of handling it (manual), but we will do it differently
      setState(() {
        _error = "Failed to fetch data. Please try again later!";
        _isLoading = false;
      });
    }

    // dealing with cases when there are no items
    if (response.body == "null") {
      return;
    }

    final Map<String, dynamic> listData = json.decode(response.body);
    final List<GroceryItem> loadedGroceries = [];
    for (final item in listData.entries) {
      final category = categories.entries
          .firstWhere(
              (catItem) => catItem.value.name == item.value["category"])
          .value;

      loadedGroceries.add(
        GroceryItem(
          id: item.key,
          name: item.value["name"],
          quantity: item.value["quantity"],
          category: category,
        ),
      );

      // interestingly enough we need to still call set state on it even though
      // I though that I am it should be set in the initState
      // reason: it will call only once and will not wait for any async
      // operations to finish
      setState(
        () {
          _groceryItems = loadedGroceries;

          // mark that it set loading to false
          _isLoading = false;
        },
      );
      return;
    }
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );

    if (newItem == null) {
      return;
    }

    setState(() {
      _groceryItems.add(newItem);
    });

    // NOTE: by doing the above we will same an HTTP request to the backend
    // which is really unnecessary here
    // _loadItems();
  }

  void _removeItem(GroceryItem groceryItem) async {
    final itemIndex = _groceryItems.indexOf(groceryItem);

    // we want to delete it immediately from the list, but then we will check
    // if delete was successful and if not we will add it back
    setState(() {
      _groceryItems.remove(groceryItem);
    });

    // delete item from the list
    // NOTE: in firebase it needs to be done by ID
    final url = Uri.https(
      "flutter-shop-list-app-tutorial-default-rtdb.firebaseio.com",
      "shopping-list/${groceryItem.id}.json",
    );

    final response = await http.delete(url);

    if (!context.mounted) {
      return;
    }

    if (response.statusCode >= 400) {
      // add it back to the list
      setState(() {
        _groceryItems.insert(itemIndex, groceryItem);
      });

      // show error message
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Failed to delete item!"),
        ),
      );

      return;

      // if success show the usual dialogue etc.
    } else {
      // clear all snack bars
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).clearSnackBars();

      // show snack bar for a little bit of time and allow to undo the action
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Item removed!"),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: "Undo",
            onPressed: () {
              setState(() {
                _groceryItems.add(groceryItem);
              });
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget mainContent = Center(
      child: Text(
        "No items yet! Add some!",
        style: Theme.of(context).textTheme.headlineSmall!.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
      ),
    );

    // check for loading
    if (_isLoading) {
      mainContent = const Center(
        child: CircularProgressIndicator(),
      );
    }

    // check for errors
    if (_error != null) {
      mainContent = Center(
        child: Text(
          _error!,
          style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_groceryItems.isNotEmpty) {
      mainContent = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (ctx, index) => Dismissible(
          key: ValueKey(_groceryItems[index]),
          child: ListTile(
            title: Text(_groceryItems[index].name),

            // widget that displays before the title
            leading: Container(
              width: 24,
              height: 24,
              color: _groceryItems[index].category.color,
            ),

            // pushed to the right
            trailing: Text(_groceryItems[index].quantity.toString()),
          ),
          onDismissed: (direction) {
            _removeItem(_groceryItems[index]);
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addItem,
          ),
        ],
      ),

      // initial version
      body: mainContent,
    );
  }
}
