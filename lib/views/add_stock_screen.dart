import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_shoes_store_pos/controller/add_stock_bloc/add_stock_bloc.dart';
import 'package:local_shoes_store_pos/controller/add_stock_bloc/add_stock_events.dart';
import 'package:local_shoes_store_pos/helper/constants.dart';
import 'package:local_shoes_store_pos/views/view_helpers/resueables/custom_button.dart';
import 'package:local_shoes_store_pos/views/view_helpers/resueables/custom_text_field.dart';

class AddStockScreen extends StatefulWidget {
  const AddStockScreen({super.key});

  @override
  State<AddStockScreen> createState() => _AddStockScreenState();
}

String? selectedColor;
TextEditingController customColorController = TextEditingController();

final List<String> colors = ['Black', 'Brown', 'White', 'Red', 'Blue', 'Other'];
TextEditingController brandController = TextEditingController();
TextEditingController articleCodeController = TextEditingController();
TextEditingController suggestedSalePriceController = TextEditingController();
TextEditingController purchasePriceController = TextEditingController();
TextEditingController quantityController = TextEditingController();
TextEditingController productCodeSKUController = TextEditingController();
TextEditingController sizeController = TextEditingController();
TextEditingController articleNameController = TextEditingController();
final _formKey = GlobalKey<FormState>();

class _AddStockScreenState extends State<AddStockScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                spacing: 15,
                children: [
                  Text(
                    CustomStrings.shopName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    "Add Stock",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  CustomTextField(
                    textEditingController: brandController,
                    labelText: "Brand *",
                    hintText: "e.g Bata Shoes",
                    validator: (value) => requiredFieldValidator(
                      value: value,
                      fieldName: "Brand",
                    ),
                  ),
                  CustomTextField(
                    textEditingController: articleCodeController,
                    labelText: "Article Code *",
                    hintText: "e.g ADSH001",
                    validator: (value) => requiredFieldValidator(
                      value: value,
                      fieldName: "Article Code",
                    ),
                  ),
                  CustomTextField(
                    textEditingController: articleNameController,
                    labelText: "Article Name",
                    hintText: "e.g Adidas Runner",
                  ),
                  CustomTextField(
                    textEditingController: sizeController,
                    labelText: "Size *",
                    hintText: "e.g 48",
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) =>
                        requiredFieldValidator(value: value, fieldName: "Size"),
                  ),

                  DropdownButtonFormField<String>(
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    value: selectedColor,
                    decoration: InputDecoration(
                      labelText: 'Color',
                      border: OutlineInputBorder(),
                    ),
                    items: colors.map((color) {
                      return DropdownMenuItem(value: color, child: Text(color));
                    }).toList(),
                    onChanged: (value) {
                      selectedColor = value;
                      setState(() {
                        productCodeSKUController.text =
                            "${articleCodeController.text}-$selectedColor-${sizeController.text}";
                      });
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Color is required';
                      }
                      return null;
                    },
                  ),

                  selectedColor == 'Other'
                      ? CustomTextField(
                          textEditingController: TextEditingController(),
                          labelText: "Color *",
                          hintText: "e.g Black",
                        )
                      : SizedBox.shrink(),
                  CustomTextField(
                    textEditingController: productCodeSKUController,
                    labelText: "Product Code SKU *",
                    hintText: "e.g ADSH001-BLK-42",
                    validator: (value) => requiredFieldValidator(
                      value: value,
                      fieldName: "Product Code SKU",
                    ),
                  ),
                  CustomTextField(
                    textEditingController: quantityController,
                    labelText: "Quantity *",
                    hintText: "e.g 10",
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      var decision = requiredFieldValidator(
                        value: value,
                        fieldName: "Quantity",
                      );
                      if (decision == null) {
                        if (int.tryParse(value ?? "0")! > 0) {
                          return decision = null;
                        } else {
                          return decision = "Quantity should be greater then 0";
                        }
                      }
                      return decision;
                    },
                  ),
                  CustomTextField(
                    textEditingController: purchasePriceController,
                    labelText: "Purchase Price *",
                    hintText: "e.g 700",
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      var decision = requiredFieldValidator(
                        value: value,
                        fieldName: "Purchase Price",
                      );
                      if (decision == null) {
                        if (int.tryParse(value ?? "0")! > 0) {
                          return decision = null;
                        } else {
                          return decision = "Price should be greater then 0";
                        }
                      }
                      return decision;
                    },
                  ),
                  CustomTextField(
                    textEditingController: suggestedSalePriceController,
                    labelText: "Suggested Sale Price *",
                    hintText: "e.g 1000",
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      var decision = requiredFieldValidator(
                        value: value,
                        fieldName: "Sale Price",
                      );
                      if (decision == null) {
                        if (int.tryParse(value ?? "0")! >=
                            int.parse(purchasePriceController.text)) {
                          return decision = null;
                        } else {
                          return decision =
                              "Sale Price should be equal or greater then Purchase Price";
                        }
                      }
                      return decision;
                    },
                  ),
                  CustomButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // Valid input
                        context.read<AddStockBloc>().add(
                          AddStockToDB(
                            articleCode: articleCodeController.text.trim(),
                            articleName: articleNameController.text.trim(),
                            brand: brandController.text.trim(),
                            color: selectedColor!.trim(),
                            productCodeSku: productCodeSKUController.text
                                .trim(),
                            purchasePrice: purchasePriceController.text.trim(),
                            quantity: quantityController.text.trim(),
                            size: sizeController.text.trim(),
                            suggestedSalePrice: suggestedSalePriceController
                                .text
                                .trim(),
                          ),
                        );
                      }
                    },
                    buttonTitle: "Add Stock",
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? requiredFieldValidator({String? value, required String fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
}
