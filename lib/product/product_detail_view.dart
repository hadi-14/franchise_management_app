import 'package:flutter/material.dart';
import 'package:franchise_management_app/AppState.dart';
import 'package:franchise_management_app/Common/flutter_flow_theme.dart';
import 'package:provider/provider.dart';

class ProductDetailsPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  _ProductDetailsPageState createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Details",
          style: theme.displayMedium.copyWith(
            color: const Color(0xFF353934),
            fontSize: 22,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(color: Color(0xFFFAFAFA)),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 33,
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: 171,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(widget.product['image']),
                    fit: BoxFit.fitWidth,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 10,
              top: MediaQuery.of(context).size.height - 200,
              child: SizedBox(
                width: MediaQuery.of(context).size.width - 20,
                height: 76,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: 0,
                      child: Container(
                        width: MediaQuery.of(context).size.width - 20,
                        height: 76,
                        padding: const EdgeInsets.all(10),
                        decoration: ShapeDecoration(
                          color: const Color(0xFFD09A6C),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: TextButton(
                          onPressed: () {
                            final product = {
                              'productID': widget.product['ID'],
                              'categoryID': widget.product['categoryID'],
                              'productName': widget.product['productName'],
                              'image': widget.product['image'],
                              'price': widget.product['price'],
                              'quantity': _quantity,
                              'upcCode': widget.product['upcCode'],
                            };
                            appState.addToCart(product);
                            print(product);

                            Navigator.of(context).pop();
                          },
                          child: Center(
                            child: Text(
                              'Add To Cart',
                              style: theme.displaySmall.copyWith(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 20,
              top: 227,
              child: Text(
                widget.product['productName'],
                style: theme.displayMedium.copyWith(
                  color: const Color(0xFF353934),
                  fontSize: 16,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Positioned(
              left: 20,
              top: MediaQuery.of(context).size.height - 300,
              child: Container(
                width: MediaQuery.of(context).size.width - 40,
                height: 73,
                decoration: ShapeDecoration(
                  color: const Color(0xFFFAFAFA),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  shadows: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 15,
                      offset: Offset(0, 10),
                      spreadRadius: 0,
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        width: 59,
                        height: 57,
                        decoration: ShapeDecoration(
                          image: DecorationImage(
                            image: NetworkImage(widget.product['image']),
                            fit: BoxFit.fill,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width - 250,
                          child: Text(
                            widget.product['productName'],
                            style: theme.titleMedium?.copyWith(
                              color: const Color(0xFF353934),
                              fontSize: 14,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          '\$${widget.product['price'].toString()}',
                          style: theme.bodySmall?.copyWith(
                            color: const Color(0xFF353934),
                            fontSize: 12,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: _quantity > 1
                              ? () {
                                  setState(() {
                                    _quantity--;
                                  });
                                }
                              : null,
                        ),
                        Text(
                          '$_quantity',
                          style: theme.headlineMedium?.copyWith(
                            color: const Color(0xFF353934),
                            fontSize: 14,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              _quantity++;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 21,
              top: 266,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                child: Text(
                  widget.product['desc'],
                  softWrap: true,
                  maxLines: 10,
                  style: theme.bodySmall.copyWith(
                    color: const Color(0xFF8E918D),
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
