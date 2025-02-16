import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_shopping_list_app_tutorial_udemy/data/categories.dart';
import 'package:flutter_shopping_list_app_tutorial_udemy/models/category.dart';
import 'package:flutter_shopping_list_app_tutorial_udemy/models/grocery_item.dart';
import 'package:http/http.dart' as http;

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

  // NOTE: state variable that will indicate that we are sending HTTP request
  // and its still in progress -> we will want to show a spinner while that is
  // in progress as well as disable all buttons so user won't click them
  // if request takes some time to be processed
  // initially set to false as we are not sending anything just yet
  var _isSending = false;

  void _saveItem() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      return;
    }

    // save the form
    _formKey.currentState!.save();

    // indicate that we are sending the request
    setState(() {
      _isSending = true;
    });

    // instead we will be sending it to HTTP backend
    // shopping-list.json is just a path to the database that Firebase will use
    final url = Uri.https(
      "flutter-shop-list-app-tutorial-default-rtdb.firebaseio.com",
      "shopping-list.json",
    );

    // send HTTP Post request and wait for the Response
    // one way is to use .then((response)) and do whatever we need, but that
    // might be inconvenient to write
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: json.encode(
        {
          "name": _currentName,
          "quantity": _currentQuantity,
          "category": _selectedCategory.name,
        },
      ),
    );

    // one option is to use a dialog to show that item was added successfully
    // show dialog message when new item will be added successfully
    // showDialog(
    //     context: context,
    //     builder: (ctx) => SuccessDialog(
    //       dialogText: "Item added successfully!",
    //     )
    // );

    // with async calls Flutter is warning you about whether context was valid
    // as there could be some async gaps
    // rewriting the code to not use the 'BuildContext', or guard the use
    // with a 'mounted' check.
    // False will indicate that context is not mounted anymore
    if (!context.mounted) {
      return;
    }

    // but for simplicity we will just show a little snack-bar message
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Item added successfully!"),
        duration: const Duration(seconds: 3),
      ),
    );

    // IMPORTANT: this will pop the current screen and will return the item
    // including its ID that we will get from the the port request above ->
    // this will be done in order to avoid sending HTTP request to the server
    // to get the the items (list already loaded so we will just append it
    final Map<String, dynamic> responseData = json.decode(response.body);

    // ignore: use_build_context_synchronously
    Navigator.of(context).pop(GroceryItem(
      id: responseData["name"],
      name: _currentName,
      quantity: _currentQuantity,
      category: _selectedCategory,
    ));
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
                      // IMPORTANT: this is an interesting one -> if isSending is
                      // set to true we will return null -> this will disable the
                      // button, otherwise we enable all content
                      // NOTE: same will be applied to the ElevatedButton below
                      onPressed: _isSending
                          ? null
                          : () {
                              if (_formKey.currentState != null) {
                                _formKey.currentState!.reset();
                              }
                            },
                      child: const Text("Reset"),
                    ),
                    ElevatedButton(
                      onPressed: _isSending ? null : _saveItem,

                      // if we are sending the request then we will show a spinner
                      child: _isSending
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(),
                            )
                          : const Text("Add Item"),
                    ),
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
