import 'package:flutter/material.dart';
import 'package:flutter_shopping_list_app_tutorial_udemy/models/grocery_item.dart';

import 'new_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  final List<GroceryItem> _groceryItems = [];

  void _addItem() async {
    final newGroceryItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );

    if (newGroceryItem == null) {
      return;
    }

    setState(() {
      _groceryItems.add(newGroceryItem);
    });
  }

  void _removeItem(GroceryItem groceryItem) {
    setState(() {
      _groceryItems.remove(groceryItem);
    });

    // clear all snack bars
    ScaffoldMessenger.of(context).clearSnackBars();

    // show snack bar for a little bit of time and allow to undo the action
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
      body: mainContent,
    );
  }
}
