import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../Common/user_state.dart';

class AddSalesOrderPage extends StatefulWidget {
  final String? salesOrderId;
  const AddSalesOrderPage({super.key, this.salesOrderId});

  @override
  _AddSalesOrderPageState createState() => _AddSalesOrderPageState();
}

class _AddSalesOrderPageState extends State<AddSalesOrderPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _orderIDController = TextEditingController();
  final TextEditingController _totalAmountController = TextEditingController();
  final TextEditingController _taxController = TextEditingController();
  final TextEditingController _netTotalController = TextEditingController();

  List<DropdownMenuItem<String>> _categoryDropdownItems = [];
  List<DropdownMenuItem<String>> _productDropdownItems = [];
  List<Map<String, dynamic>> _items = [];
  String _selectedState = 'Request';
  DateTime _selectedDate = DateTime.now();

  final List<String> _states = ['Request', 'Pending', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchProducts();
    if (widget.salesOrderId != null) {
      _loadSalesOrder(widget.salesOrderId!);
    }
  }

  Future<void> _fetchCategories() async {
    final userState = Provider.of<UserState>(context, listen: false);
    final franchiseID = userState.franchiseID;

    if (franchiseID.isNotEmpty) {
      final categoriesSnapshot = await _firestore
          .collection('product')
          .doc(franchiseID)
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
    final userState = Provider.of<UserState>(context, listen: false);
    final franchiseID = userState.franchiseID;

    if (franchiseID.isNotEmpty) {
      final productsSnapshot = await _firestore
          .collection('product')
          .doc(franchiseID)
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
        'isBox': false,
        'piecesPerBox': 0,
        'quantityController': TextEditingController(),
        'unitPriceController': TextEditingController(),
        'piecesPerBoxController': TextEditingController(),
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

  Future<void> _saveSalesOrder() async {
    final userState = Provider.of<UserState>(context, listen: false);
    final franchiseID = userState.franchiseID;
    final user = FirebaseAuth.instance.currentUser;

    if (franchiseID.isNotEmpty && user != null) {
      final salesOrderData = {
        'OrderID': _orderIDController.text,
        'State': _selectedState,
        'TotalAmount': double.parse(_totalAmountController.text),
        'Tax': double.parse(_taxController.text),
        'NetTotal': double.parse(_netTotalController.text),
        'Date': _selectedDate,
        'createdBy': user.displayName,
        'items': _items.map((item) {
          final newItem = Map<String, dynamic>.from(item);
          newItem.remove('quantityController');
          newItem.remove('unitPriceController');
          newItem.remove('piecesPerBoxController');
          return newItem;
        }).toList(),
      };

      if (widget.salesOrderId == null) {
        // Add new sales order
        await _firestore
            .collection('sales')
            .doc(franchiseID)
            .collection('list')
            .add(salesOrderData);
      } else {
        // Update existing sales order
        await _firestore
            .collection('sales')
            .doc(franchiseID)
            .collection('list')
            .doc(widget.salesOrderId)
            .update(salesOrderData);
      }

      Navigator.pop(context);
    }
  }

  Future<void> _loadSalesOrder(String salesOrderId) async {
    final userState = Provider.of<UserState>(context, listen: false);
    final franchiseID = userState.franchiseID;

    if (franchiseID.isNotEmpty) {
      final docSnapshot = await _firestore
          .collection('sales')
          .doc(franchiseID)
          .collection('list')
          .doc(salesOrderId)
          .get();
      final data = docSnapshot.data();
      if (data != null) {
        setState(() {
          _orderIDController.text = data['OrderID'];
          _selectedState = data['State'];
          _totalAmountController.text = data['TotalAmount'].toString();
          _taxController.text = data['Tax'].toString();
          _netTotalController.text = data['NetTotal'].toString();
          _selectedDate = (data['Date'] as Timestamp).toDate();
          _items.clear();
          _items.addAll(List<Map<String, dynamic>>.from(data['items']).map((item) {
            item['quantityController'] = TextEditingController(text: item['Quantity'].toString());
            item['unitPriceController'] = TextEditingController(text: item['UnitPrice'].toString());
            item['piecesPerBoxController'] = TextEditingController(text: item['piecesPerBox'].toString());
            return item;
          }).toList());
        });
      }
    }
  }

  void _handleKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent && event.logicalKey.keyId == 4295426088) {
      // Enter key pressed
      _saveSalesOrder();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Sales Order'),
        actions: [
          if (widget.salesOrderId != null)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveSalesOrder,
            ),
        ],
      ),
      body: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: _handleKey,
        child: Padding(
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
                                  _items[index]['quantityController'],
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    setState(() {
                                      _items[index]['Quantity'] = int.parse(value);
                                      _items[index]['Total'] =
                                          _items[index]['Quantity'] *
                                              _items[index]['UnitPrice'];
                                      _calculateTotal();
                                    });
                                  },
                                ),
                                _buildTextField(
                                  'Unit Price',
                                  _items[index]['unitPriceController'],
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    setState(() {
                                      _items[index]['UnitPrice'] =
                                          double.parse(value);
                                      _items[index]['Total'] =
                                          _items[index]['Quantity'] *
                                              _items[index]['UnitPrice'];
                                      _calculateTotal();
                                    });
                                  },
                                ),
                                _buildTextField(
                                  'Pieces per Box',
                                  _items[index]['piecesPerBoxController'],
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    setState(() {
                                      _items[index]['piecesPerBox'] =
                                          int.parse(value);
                                      _items[index]['Total'] = _items[index]
                                                  ['Quantity'] *
                                              _items[index]['UnitPrice'];
                                      _calculateTotal();
                                    });
                                  },
                                  enabled: _items[index]['isBox'],
                                ),
                                Column(
                                  children: [
                                    Checkbox(
                                      value: _items[index]['isBox'],
                                      onChanged: (value) {
                                        setState(() {
                                          _items[index]['isBox'] = value;
                                          _calculateTotal();
                                        });
                                      },
                                    ),
                                    const Text('Box'),
                                  ],
                                ),
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
                                    foregroundColor: Colors.red,
                                  ),
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
                  onPressed: _saveSalesOrder,
                  child: Text(widget.salesOrderId == null ? 'Add Sales Order' : 'Update Sales Order'),
                ),
              ],
            ),
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
