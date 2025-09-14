import 'package:flutter/material.dart';

import '../../helper/constants.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(CustomStrings.cartScreenHeading),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: 2,
                itemBuilder: (BuildContext context, int index) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                spacing: 10,
                                children: [
                                  Text("SKU : ", style: headingStyle()),
                                  Text("BA101-White-43", style: headingStyle()),
                                ],
                              ),
                              Row(
                                children: [
                                  Text("Quantity : ", style: headingStyle()),
                                  IconButton(
                                    onPressed: _increaseQuantity,
                                    icon: Icon(Icons.add),
                                  ),
                                  Text("$quantity", style: bodyStyle()),
                                  IconButton(
                                    onPressed: _decreaseQuantity,
                                    icon: Transform.translate(
                                      offset: Offset(0, -8),
                                      child: Icon(Icons.minimize_sharp),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(width: 30),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text("Stock", style: headingStyle()),
                                  SizedBox(width: 70),
                                  Text("13", style: bodyStyle()),
                                ],
                              ),
                              Row(
                                children: [
                                  Text("Price", style: headingStyle()),
                                  SizedBox(width: 30),
                                  SizedBox(
                                    width: 75,
                                    child: TextField(
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(),
                                        hintText: 'Enter a search term',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(width: 5),
                          IconButton(
                            onPressed: () {},
                            icon: Icon(Icons.delete),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle headingStyle() {
    return TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
  }

  TextStyle bodyStyle() {
    return TextStyle(fontSize: 16, fontWeight: FontWeight.normal);
  }

  int _increaseQuantity() {
    setState(() {
      quantity++;
    });
    return quantity;
  }

  int _decreaseQuantity() {
    setState(() {
      quantity--;
    });
    return quantity;
  }
}
