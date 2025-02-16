import 'package:flutter/material.dart';
import 'package:flutter_shopping_list_app_tutorial_udemy/data/categories.dart';
import 'package:flutter_shopping_list_app_tutorial_udemy/dialog/success_dialog.dart';
import 'package:flutter_shopping_list_app_tutorial_udemy/models/category.dart';
import 'package:flutter_shopping_list_app_tutorial_udemy/models/grocery_item.dart';

class NewItem extends StatefulWidget {
  const NewItem({super.key});

  @override
  State<NewItem> createState() => _NewItemState();
}

class _NewItemState extends State<NewItem> {
  // need to use Global key here so when it would be rebuilt etc. it will
  // remember the state of the form, validations etc.
  // NOTE: when working with flutter you will ALMOST always use GlobalKey
  // when working with forms
  final _formKey = GlobalKey<FormState>();

  // initial form values
  int _currentQuantity = 1;
  String _currentName = "";
  Category _selectedCategory = categories[Categories.vegetables]!;

  void _saveItem() {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      return;
    }

    // save the form
    _formKey.currentState!.save();
    print(_currentName);
    print(_currentQuantity);
    print(_selectedCategory.name);

    // pop the screen and pass back a Grocery item
    Navigator.of(context).pop(GroceryItem(
        id: DateTime.now().toString(),
        name: _currentName,
        quantity: _currentQuantity,
        category: _selectedCategory)
    );

    // one option is to use a dialog to show that item was added successfully
    // show dialog message when new item will be added successfully
    // showDialog(
    //     context: context,
    //     builder: (ctx) => SuccessDialog(
    //       dialogText: "Item added successfully!",
    //     )
    // );

    // but for simplicity we will just show a little snack-bar message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Item added successfully!"),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add a new item'),
      ),
      body: Padding(
        padding: EdgeInsets.all(12),

        // that will hold the form that we are adding
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  maxLength: 50,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty ||
                        value.trim().length <= 1 ||
                        value.trim().length > 50) {
                      return "Must be between 1 and 50 characters";
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _currentName = value!;
                  },
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration:
                            const InputDecoration(labelText: "Quantity"),
                        keyboardType: TextInputType.number,
                        initialValue: _currentQuantity.toString(),
                        validator: (value) {
                          if (value == null ||
                                  value.isEmpty ||
                                  int.tryParse(value) == null ||
                                  int.tryParse(value)! <=
                                      0 // we need to explicitly tell Flutter that previous value is not null
                              ) {
                            return "Must be a valid positive number";
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _currentQuantity = int.parse(value!);
                        },
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<Category>(
                        value: _selectedCategory,
                        items: categories.entries.map((category) {
                          return DropdownMenuItem<Category>(
                            value: category.value,
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  color: category.value.color,
                                ),
                                const SizedBox(width: 6),
                                Text(category.value.name),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (Category? value) {
                          setState(() {
                            _selectedCategory = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        onPressed: () {
                          if (_formKey.currentState != null) {
                            _formKey.currentState!.reset();
                          }
                        },
                        child: const Text("Reset")),
                    ElevatedButton(
                        onPressed: _saveItem, child: const Text("Add Item"))
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
