import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AddPurchaseOrderPage extends StatefulWidget {
  final String? purchaseOrderId;
  const AddPurchaseOrderPage({Key? key, this.purchaseOrderId}) : super(key: key);

  @override
  _AddPurchaseOrderPageState createState() => _AddPurchaseOrderPageState();
}

class _AddPurchaseOrderPageState extends State<AddPurchaseOrderPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _orderIDController = TextEditingController();
  final TextEditingController _totalAmountController = TextEditingController();
  final TextEditingController _taxController = TextEditingController();
  final TextEditingController _netTotalController = TextEditingController();

  String? _selectedStore;
  List<DropdownMenuItem<String>> _storeDropdownItems = [];
  List<DropdownMenuItem<String>> _categoryDropdownItems = [];
  List<DropdownMenuItem<String>> _productDropdownItems = [];
  final List<Map<String, dynamic>> _items = [];
  String _selectedState = 'Pending';
  DateTime _selectedDate = DateTime.now();

  final List<String> _states = ['Pending', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _fetchStores();
    _fetchCategories();
    _fetchProducts();
    if (widget.purchaseOrderId != null) {
      _loadPurchaseOrder(widget.purchaseOrderId!);
    }
  }

  Future<void> _fetchStores() async {
    final user = _auth.currentUser;
    if (user != null) {
      final storesSnapshot = await _firestore
          .collection('store')
          .doc(user.uid)
          .collection('list')
          .get();

      setState(() {
        _storeDropdownItems = storesSnapshot.docs
            .map((doc) => DropdownMenuItem<String>(
                  value: doc.id,
                  child: Text(doc.data()['Name']),
                ))
            .toList();
      });
    }
  }

  Future<void> _fetchCategories() async {
    final user = _auth.currentUser;
    if (user != null) {
      final categoriesSnapshot = await _firestore
          .collection('product')
          .doc(user.uid)
          .collection('category')
          .get();

      setState(() {
        _categoryDropdownItems = categoriesSnapshot.docs
            .map((doc) => DropdownMenuItem<String>(
                  value: doc.id,
                  child: Text(doc.data()['name']),
                ))
            .toList();
      });
    }
  }

  Future<void> _fetchProducts() async {
    final user = _auth.currentUser;
    if (user != null) {
      final productsSnapshot = await _firestore
          .collection('product')
          .doc(user.uid)
          .collection('list')
          .get();

      setState(() {
        _productDropdownItems = productsSnapshot.docs
            .map((doc) => DropdownMenuItem<String>(
                  value: doc.id,
                  child: Text(doc.data()['productName']),
                ))
            .toList();
      });
    }
  }

  void _addItem() {
    setState(() {
      _items.add({
        'Category': null,
        'Product': null,
        'Quantity': 1,
        'UnitPrice': 0.0,
        'Total': 0.0,
      });
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _calculateTotal() {
    double totalAmount = 0.0;
    for (var item in _items) {
      totalAmount += item['Total'];
    }
    double tax = double.tryParse(_taxController.text) ?? 0.0;
    double netTotal = totalAmount + (totalAmount * tax / 100);
    setState(() {
      _totalAmountController.text = totalAmount.toStringAsFixed(2);
      _netTotalController.text = netTotal.toStringAsFixed(2);
    });
  }

  Future<void> _addPurchaseOrder() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore
          .collection('purchase')
          .doc(user.uid)
          .collection('list')
          .add({
        'OrderID': _orderIDController.text,
        'StoreID': _selectedStore,
        'State': _selectedState,
        'TotalAmount': double.parse(_totalAmountController.text),
        'Tax': double.parse(_taxController.text),
        'NetTotal': double.parse(_netTotalController.text),
        'Date': _selectedDate,
        'items': _items,
      });
      Navigator.pop(context);
    }
  }

  Future<void> _loadPurchaseOrder(String purchaseOrderId) async {
    final user = _auth.currentUser;
    if (user != null) {
      final docSnapshot = await _firestore
          .collection('purchase')
          .doc(user.uid)
          .collection('list')
          .doc(purchaseOrderId)
          .get();
      final data = docSnapshot.data();
      if (data != null) {
        setState(() {
          _orderIDController.text = data['OrderID'];
          _selectedStore = data['StoreID'];
          _selectedState = data['State'];
          _totalAmountController.text = data['TotalAmount'].toString();
          _taxController.text = data['Tax'].toString();
          _netTotalController.text = data['NetTotal'].toString();
          _selectedDate = (data['Date'] as Timestamp).toDate();
          _items.clear();
          _items.addAll(List<Map<String, dynamic>>.from(data['items']));
        });
      }
    }
  }

  void _printInvoice() {
    // Implement the functionality to print the invoice
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Purchase Order'),
        actions: [
          if (widget.purchaseOrderId != null)
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: _printInvoice,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 16.0,
                runSpacing: 16.0,
                children: [
                  _buildTextField('OrderID', _orderIDController),
                  _buildDropdown(
                    'Store',
                    _selectedStore,
                    _storeDropdownItems,
                    (value) {
                      setState(() {
                        _selectedStore = value;
                      });
                    },
                  ),
                  _buildDropdown(
                    'State',
                    _selectedState,
                    _states
                        .map((state) => DropdownMenuItem<String>(
                              value: state,
                              child: Text(state),
                            ))
                        .toList(),
                    (value) {
                      setState(() {
                        _selectedState = value!;
                      });
                    },
                  ),
                  _buildTextField('Total Amount', _totalAmountController,
                      keyboardType: TextInputType.number, enabled: false),
                  _buildTextField('Tax (%)', _taxController,
                      keyboardType: TextInputType.number, onChanged: (value) {
                    _calculateTotal();
                  }),
                  _buildTextField('Net Total', _netTotalController,
                      keyboardType: TextInputType.number, enabled: false),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _addItem,
                child: const Text('+ Add New Item'),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Wrap(
                            spacing: 16.0,
                            runSpacing: 8.0,
                            children: [
                              _buildDropdown(
                                'Category',
                                _items[index]['Category'],
                                _categoryDropdownItems,
                                (value) {
                                  setState(() {
                                    _items[index]['Category'] = value;
                                    _fetchProducts();
                                  });
                                },
                              ),
                              _buildDropdown(
                                'Product',
                                _items[index]['Product'],
                                _productDropdownItems,
                                (value) {
                                  setState(() {
                                    _items[index]['Product'] = value;
                                  });
                                },
                              ),
                              _buildTextField(
                                  'Quantity',
                                  TextEditingController(
                                      text:
                                          _items[index]['Quantity'].toString()),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                setState(() {
                                  _items[index]['Quantity'] = int.parse(value);
                                  _items[index]['Total'] = _items[index]
                                          ['Quantity'] *
                                      _items[index]['UnitPrice'];
                                  _calculateTotal();
                                });
                              }),
                              _buildTextField(
                                  'Unit Price',
                                  TextEditingController(
                                      text: _items[index]['UnitPrice']
                                          .toString()),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                setState(() {
                                  _items[index]['UnitPrice'] =
                                      double.parse(value);
                                  _items[index]['Total'] = _items[index]
                                          ['Quantity'] *
                                      _items[index]['UnitPrice'];
                                  _calculateTotal();
                                });
                              }),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total: \$${_items[index]['Total'].toStringAsFixed(2)}',
                                style: theme.textTheme.bodySmall,
                              ),
                              ElevatedButton(
                                onPressed: () => _removeItem(index),
                                style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.red),
                                child: const Text('Remove Item'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _addPurchaseOrder,
                child: const Text('Add Purchase Order'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text,
      bool enabled = true,
      Function(String)? onChanged}) {
    return SizedBox(
      width: 300,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
        enabled: enabled,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDropdown(String label, String? value,
      List<DropdownMenuItem<String>> items, Function(String?)? onChanged) {
    return SizedBox(
      width: 300,
      child: DropdownButtonFormField<String>(
        value: value,
        onChanged: onChanged,
        items: items,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
