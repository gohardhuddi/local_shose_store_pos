import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_shoes_store_pos/controller/add_stock_bloc/add_stock_bloc.dart';
import 'package:local_shoes_store_pos/controller/add_stock_bloc/add_stock_events.dart';
import 'package:local_shoes_store_pos/helper/constants.dart';
import 'package:local_shoes_store_pos/models/stock_model.dart';
import 'package:local_shoes_store_pos/views/view_helpers/resueables/custom_button.dart';
import 'package:local_shoes_store_pos/views/view_helpers/resueables/custom_text_field.dart';

import '../controller/add_stock_bloc/add_stock_states.dart';

class EditStockScreen extends StatefulWidget {
  StockModel? stock;
  VariantModel? varient;
  EditStockScreen({super.key, this.stock, this.varient});
  @override
  State<EditStockScreen> createState() => _EditStockScreenState();
}

String? selectedColor;
String? selectedAction;
TextEditingController customColorController = TextEditingController();

class _EditStockScreenState extends State<EditStockScreen> {
  final List<String> colors = [
    'Black',
    'Brown',
    'White',
    'Red',
    'Blue',
    'Other',
  ];
  final List<String> actions = ['Add', 'Subtract'];

  TextEditingController suggestedSalePriceController = TextEditingController();
  TextEditingController purchasePriceController = TextEditingController();
  TextEditingController quantityController = TextEditingController();
  TextEditingController productCodeSKUController = TextEditingController();
  TextEditingController sizeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  @override
  void initState() {
    final v = widget.varient;
    if (v != null) {
      suggestedSalePriceController.text = v!.salePrice.round().toString();
      purchasePriceController.text = v!.purchasePrice.round().toString();
      quantityController.text = v!.qty.toString();
      productCodeSKUController.text = v!.sku;
      sizeController.text = v!.size.toString();
      _prefillColorFromVariant(v.colorName); // 👈 this does the logic
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: BlocListener<AddStockBloc, AddStockStates>(
                listener: (BuildContext context, state) {
                  if (state is AddStockSuccessState) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          state.successMessage,
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                child: Column(
                  spacing: 15,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () {
                            suggestedSalePriceController.clear();
                            purchasePriceController.clear();
                            quantityController.clear();
                            productCodeSKUController.clear();
                            sizeController.clear();
                            Navigator.pop(context);
                          },
                          icon: Icon(Icons.arrow_back_ios_sharp),
                        ),
                        Transform.translate(
                          offset: Offset(-20, 0),
                          child: Text(
                            CustomStrings.shopName,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        Container(),
                      ],
                    ),
                    Text(
                      "Update Variant",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            thickness: 0.5,
                            indent: 40,
                            endIndent: 40,
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                        Text(
                          "Variant",
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Expanded(
                          child: Divider(
                            thickness: 0.5,
                            indent: 40,
                            endIndent: 40,
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                      ],
                    ),
                    CustomTextField(
                      textEditingController: sizeController,
                      labelText: "Size *",
                      hintText: "e.g 48",
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) => requiredFieldValidator(
                        value: value,
                        fieldName: "Size",
                      ),
                      onChanged: (v) {
                        updateSku();
                        setState(() {});
                      },
                    ),

                    DropdownButtonFormField<String>(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      value: selectedColor,
                      decoration: InputDecoration(
                        labelText: 'Color',
                        border: OutlineInputBorder(),
                      ),
                      items: colors.map((color) {
                        return DropdownMenuItem(
                          value: color,
                          child: Text(color),
                        );
                      }).toList(),
                      onChanged: (value) {
                        selectedColor = value;
                        updateSku();
                        setState(() {});
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
                            textEditingController: customColorController,
                            labelText: "Color *",
                            hintText: "e.g Black",
                            onChanged: (v) => updateSku(),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.44,
                          child: CustomTextField(
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
                                  return decision =
                                      "Quantity should be greater then 0";
                                }
                              }
                              return decision;
                            },
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.44,
                          child: DropdownButtonFormField<String>(
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            value: selectedAction,
                            decoration: InputDecoration(
                              labelText: 'Action',
                              border: OutlineInputBorder(),
                            ),
                            items: actions.map((action) {
                              return DropdownMenuItem(
                                value: action,
                                child: Text(action),
                              );
                            }).toList(),
                            onChanged: (value) {
                              selectedAction = value;
                            },
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Color is required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
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
                            EditStockVariant(
                              color:
                                  selectedColor!.trim().toLowerCase() == "other"
                                  ? customColorController.text
                                  : selectedColor!.trim(),
                              productCodeSku: productCodeSKUController.text
                                  .trim(),
                              purchasePrice: purchasePriceController.text
                                  .trim(),
                              quantity: quantityController.text.trim(),
                              size: sizeController.text.trim(),
                              suggestedSalePrice: suggestedSalePriceController
                                  .text
                                  .trim(),
                              productID: widget.stock!.productId,
                              variantID: widget.varient!.variantId,
                            ),
                          );
                        }
                      },
                      buttonTitle: "Update Stock",
                    ),
                  ],
                ),
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

  void updateSku() {
    final code = widget.stock!.articleCode.trim();
    final color = _currentColorValue();
    final size = sizeController.text.trim();
    setState(() {
      productCodeSKUController.text = "$code-$color-$size";
    });
  }

  String _currentColorValue() {
    if (selectedColor == null) return '';
    if (selectedColor == 'Other') {
      // Use trimmed, hyphen-safe value for SKU
      final v = customColorController.text.trim();
      return v.isEmpty ? '' : v.replaceAll(' ', '-');
    }
    return selectedColor!;
  }

  void _prefillColorFromVariant(String? colorName) {
    final other = 'Other';
    final c = (colorName ?? '').trim();

    // case-insensitive match against your list
    final match = colors.firstWhere(
      (x) => x.toLowerCase() == c.toLowerCase(),
      orElse: () => other,
    );

    if (match == other) {
      selectedColor = other;
      customColorController.text = c; // show the exact saved color
    } else {
      selectedColor = match; // use the known color
      customColorController.clear(); // hide/free custom field
    }

    // keep SKU in sync
    updateSku();
  }
}
