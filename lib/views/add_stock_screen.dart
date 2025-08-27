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

class AddStockScreen extends StatefulWidget {
  StockModel? stock;
  VariantModel? varient;
  AddStockScreen({super.key, this.stock, this.varient});
  @override
  State<AddStockScreen> createState() => _AddStockScreenState();
}

String? selectedColor;
TextEditingController customColorController = TextEditingController();

class _AddStockScreenState extends State<AddStockScreen> {
  final List<String> colors = [
    CustomStrings.black,
    CustomStrings.brown,
    CustomStrings.white,
    CustomStrings.red,
    CustomStrings.blue,
    CustomStrings.other,
  ];
  TextEditingController brandController = TextEditingController();
  TextEditingController articleCodeController = TextEditingController();
  TextEditingController suggestedSalePriceController = TextEditingController();
  TextEditingController purchasePriceController = TextEditingController();
  TextEditingController quantityController = TextEditingController();
  TextEditingController productCodeSKUController = TextEditingController();
  TextEditingController sizeController = TextEditingController();
  TextEditingController articleNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  @override
  void initState() {
    final v = widget.varient;
    if (v != null) {
      brandController.text = widget.stock!.brand;
      articleCodeController.text = widget.stock!.articleCode;
      articleNameController.text = widget.stock!.articleName;
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
                            brandController.clear();
                            articleCodeController.clear();
                            suggestedSalePriceController.clear();
                            purchasePriceController.clear();
                            quantityController.clear();
                            productCodeSKUController.clear();
                            sizeController.clear();
                            articleNameController.clear();
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
                      CustomStrings.addStock,
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
                          CustomStrings.product,
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
                      textEditingController: brandController,
                      labelText: CustomStrings.brand,
                      hintText: CustomStrings.brandHint,
                      validator: (value) => requiredFieldValidator(
                        value: value,
                        fieldName: CustomStrings.brand,
                      ),
                    ),
                    CustomTextField(
                      textEditingController: articleCodeController,
                      labelText: CustomStrings.articleCode,
                      hintText: CustomStrings.articleCodeHint,
                      validator: (value) => requiredFieldValidator(
                        value: value,
                        fieldName: CustomStrings.articleCode,
                      ),
                    ),
                    CustomTextField(
                      textEditingController: articleNameController,
                      labelText: CustomStrings.articleName,
                      hintText: CustomStrings.articleNameHint,
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
                          CustomStrings.variant,
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
                      labelText: CustomStrings.size,
                      hintText: CustomStrings.sizeHint,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) => requiredFieldValidator(
                        value: value,
                        fieldName: CustomStrings.size,
                      ),
                    ),

                    DropdownButtonFormField<String>(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      value: selectedColor,
                      decoration: InputDecoration(
                        labelText: CustomStrings.color,
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
                          return CustomStrings.colorRequired;
                        }
                        return null;
                      },
                    ),

                    selectedColor == CustomStrings.other
                        ? CustomTextField(
                            textEditingController: customColorController,
                            labelText: CustomStrings.color,
                            hintText: CustomStrings.colorHint,
                            onChanged: (v) => updateSku(),
                          )
                        : SizedBox.shrink(),
                    CustomTextField(
                      textEditingController: productCodeSKUController,
                      labelText: CustomStrings.productCodeSku,
                      hintText: CustomStrings.productCodeSkuHint,
                      validator: (value) => requiredFieldValidator(
                        value: value,
                        fieldName: CustomStrings.productCodeSku,
                      ),
                    ),
                    CustomTextField(
                      textEditingController: quantityController,
                      labelText: CustomStrings.quantity,
                      hintText: CustomStrings.quantityHint,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        var decision = requiredFieldValidator(
                          value: value,
                          fieldName: CustomStrings.quantity,
                        );
                        if (decision == null) {
                          if (int.tryParse(value ?? "0")! > 0) {
                            return decision = null;
                          } else {
                            return decision =
                                CustomStrings.quantityGreaterThanZero;
                          }
                        }
                        return decision;
                      },
                    ),
                    CustomTextField(
                      textEditingController: purchasePriceController,
                      labelText: CustomStrings.purchasePrice,
                      hintText: CustomStrings.purchasePriceHint,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        var decision = requiredFieldValidator(
                          value: value,
                          fieldName: CustomStrings.purchasePrice,
                        );
                        if (decision == null) {
                          if (int.tryParse(value ?? "0")! > 0) {
                            return decision = null;
                          } else {
                            return decision = CustomStrings.priceGreaterThanZero;
                          }
                        }
                        return decision;
                      },
                    ),
                    CustomTextField(
                      textEditingController: suggestedSalePriceController,
                      labelText: CustomStrings.suggestedSalePrice,
                      hintText: CustomStrings.suggestedSalePriceHint,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        var decision = requiredFieldValidator(
                          value: value,
                          fieldName: CustomStrings.suggestedSalePrice,
                        );
                        if (decision == null) {
                          if (int.tryParse(value ?? "0")! >=
                              int.parse(purchasePriceController.text)) {
                            return decision = null;
                          } else {
                            return decision =
                                CustomStrings.salePriceGreaterThanPurchase;
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
                              isEdit: widget.varient != null ? true : false,
                            ),
                          );
                        }
                      },
                      buttonTitle: CustomStrings.addStock,
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
      return '$fieldName ${CustomStrings.fieldRequired}';
    }
    return null;
  }

  void updateSku() {
    final code = articleCodeController.text.trim();
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
    final other = CustomStrings.other;
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
