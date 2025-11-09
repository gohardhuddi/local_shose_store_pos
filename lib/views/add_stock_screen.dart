import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_shoes_store_pos/controller/add_stock_bloc/add_stock_bloc.dart';
import 'package:local_shoes_store_pos/controller/add_stock_bloc/add_stock_events.dart';
import 'package:local_shoes_store_pos/controller/add_stock_bloc/add_stock_states.dart';
import 'package:local_shoes_store_pos/helper/constants.dart';
import 'package:local_shoes_store_pos/models/stock_model.dart';
import 'package:local_shoes_store_pos/views/view_helpers/resueables/custom_button.dart';
import 'package:local_shoes_store_pos/views/view_helpers/resueables/custom_text_field.dart';

import '../services/storage/mobile/entities/category.dart';
import '../services/storage/mobile/entities/gender.dart';

class AddStockScreen extends StatefulWidget {
  final StockModel? stock;
  final VariantModel? varient;

  const AddStockScreen({super.key, this.stock, this.varient});

  @override
  State<AddStockScreen> createState() => _AddStockScreenState();
}

class _AddStockScreenState extends State<AddStockScreen> {
  // ---------------- Controllers ----------------
  final _formKey = GlobalKey<FormState>();
  final brandController = TextEditingController();
  final articleCodeController = TextEditingController();
  final articleNameController = TextEditingController();
  final sizeController = TextEditingController();
  final productCodeSKUController = TextEditingController();
  final purchasePriceController = TextEditingController();
  final suggestedSalePriceController = TextEditingController();
  final quantityController = TextEditingController();
  final customColorController = TextEditingController();

  // ---------------- Dropdown Lists ----------------
  final List<String> colors = [
    CustomStrings.black,
    CustomStrings.brown,
    CustomStrings.white,
    CustomStrings.red,
    CustomStrings.blue,
    CustomStrings.other,
  ];

  String? selectedColor;
  Category? selectedCategory;
  Gender? selectedGender;

  // ---------------- DB ----------------
  List<Category> categories = [];
  List<Gender> genders = [];

  @override
  void initState() {
    super.initState();

    final v = widget.varient;
    if (v != null && widget.stock != null) {
      brandController.text = widget.stock!.brand;
      articleCodeController.text = widget.stock!.articleCode;
      articleNameController.text = widget.stock!.articleName;
      suggestedSalePriceController.text = v.salePrice.round().toString();
      purchasePriceController.text = v.purchasePrice.round().toString();
      quantityController.text = v.qty.toString();
      productCodeSKUController.text = v.sku;
      sizeController.text = v.size.toString();
      _prefillColorFromVariant(v.colorName);
    }

    // ✅ Safe Bloc event trigger
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AddStockBloc>().add(GetCategoriesEvent());
    });
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
              // ✅ Use BlocConsumer instead of BlocListener
              child: BlocConsumer<AddStockBloc, AddStockStates>(
                listener: (context, state) {
                  if (state is AddStockSuccessState) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.successMessage),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                  if (state is AddStockErrorState) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.error),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is GetCategoriesAndGendersSuccessState) {
                    categories = state.categories;
                    genders = state.genders;
                  }

                  return Column(
                    spacing: 15,
                    children: [
                      _header(context),
                      Text(
                        CustomStrings.addStock,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      _dividerTitle(context, CustomStrings.product),

                      CustomTextField(
                        textEditingController: brandController,
                        labelText: CustomStrings.brand,
                        hintText: CustomStrings.brandHint,
                        validator: (v) =>
                            _requiredFieldValidator(v, CustomStrings.brand),
                      ),
                      CustomTextField(
                        textEditingController: articleCodeController,
                        labelText: CustomStrings.articleCode,
                        hintText: CustomStrings.articleCodeHint,
                        validator: (v) => _requiredFieldValidator(
                          v,
                          CustomStrings.articleCode,
                        ),
                      ),
                      CustomTextField(
                        textEditingController: articleNameController,
                        labelText: CustomStrings.articleName,
                        hintText: CustomStrings.articleNameHint,
                      ),

                      _dividerTitle(context, CustomStrings.variant),

                      CustomTextField(
                        textEditingController: sizeController,
                        labelText: CustomStrings.size,
                        hintText: CustomStrings.sizeHint,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (v) =>
                            _requiredFieldValidator(v, CustomStrings.size),
                      ),

                      DropdownButtonFormField<String>(
                        value: selectedColor,
                        decoration: const InputDecoration(
                          labelText: CustomStrings.color,
                          border: OutlineInputBorder(),
                        ),
                        items: colors
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                        onChanged: (v) {
                          selectedColor = v;
                          updateSku();
                          setState(() {});
                        },
                        validator: (v) =>
                            v == null || v.isEmpty ? "Color required" : null,
                      ),
                      if (selectedColor == CustomStrings.other)
                        CustomTextField(
                          textEditingController: customColorController,
                          labelText: CustomStrings.color,
                          hintText: CustomStrings.colorHint,
                          onChanged: (_) => updateSku(),
                        ),

                      // ---------------- Category Dropdown ----------------
                      DropdownButtonFormField<Category>(
                        value: selectedCategory,
                        decoration: const InputDecoration(
                          labelText: "Category",
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          ...categories.map(
                            (cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat.categoryName),
                            ),
                          ),
                        ],
                        onChanged: (value) async {
                          setState(() => selectedCategory = value);
                        },
                        validator: (v) =>
                            v == null ? "Category is required" : null,
                      ),

                      // ---------------- Gender Dropdown ----------------
                      DropdownButtonFormField<Gender>(
                        value: selectedGender,
                        decoration: const InputDecoration(
                          labelText: "Gender",
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          ...genders.map(
                            (g) => DropdownMenuItem(
                              value: g,
                              child: Text(g.genderName),
                            ),
                          ),
                        ],
                        onChanged: (value) async {
                          setState(() => selectedGender = value);
                        },
                        validator: (v) =>
                            v == null ? "Gender is required" : null,
                      ),

                      // ---------------- Remaining Fields ----------------
                      CustomTextField(
                        textEditingController: productCodeSKUController,
                        labelText: CustomStrings.productCodeSku,
                        hintText: CustomStrings.productCodeSkuHint,
                        validator: (v) => _requiredFieldValidator(v, "SKU"),
                      ),
                      CustomTextField(
                        textEditingController: quantityController,
                        labelText: CustomStrings.quantity,
                        hintText: CustomStrings.quantityHint,
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            _requiredFieldValidator(v, "Quantity"),
                      ),
                      CustomTextField(
                        textEditingController: purchasePriceController,
                        labelText: CustomStrings.purchasePrice,
                        hintText: CustomStrings.purchasePriceHint,
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            _requiredFieldValidator(v, "Purchase Price"),
                      ),
                      CustomTextField(
                        textEditingController: suggestedSalePriceController,
                        labelText: CustomStrings.suggestedSalePrice,
                        hintText: CustomStrings.suggestedSalePriceHint,
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            _requiredFieldValidator(v, "Sale Price"),
                      ),

                      // ---------------- Submit ----------------
                      CustomButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            context.read<AddStockBloc>().add(
                              AddStockToDB(
                                articleCode: articleCodeController.text.trim(),
                                articleName: articleNameController.text.trim(),
                                brand: brandController.text.trim(),
                                color: selectedColor == CustomStrings.other
                                    ? customColorController.text.trim()
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
                                category: selectedCategory!.categoryId,
                                gender: selectedGender!.genderId,
                                isEdit: widget.varient != null,
                              ),
                            );
                          }
                        },
                        buttonTitle: CustomStrings.addStock,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- Helpers ----------------
  Widget _header(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_ios_sharp),
      ),
      Transform.translate(
        offset: const Offset(-20, 0),
        child: Text(
          CustomStrings.shopName,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      const SizedBox(width: 40),
    ],
  );

  String? _requiredFieldValidator(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName ${CustomStrings.fieldRequired}';
    }
    return null;
  }

  Widget _dividerTitle(BuildContext ctx, String title) => Row(
    children: [
      Expanded(child: Divider(thickness: 0.5, indent: 40, endIndent: 40)),
      Text(title, style: Theme.of(ctx).textTheme.bodyLarge),
      Expanded(child: Divider(thickness: 0.5, indent: 40, endIndent: 40)),
    ],
  );

  void updateSku() {
    final code = articleCodeController.text.trim();
    final color = _currentColorValue();
    final size = sizeController.text.trim();
    setState(() => productCodeSKUController.text = "$code-$color-$size");
  }

  String _currentColorValue() {
    if (selectedColor == null) return '';
    if (selectedColor == 'Other') {
      final v = customColorController.text.trim();
      return v.isEmpty ? '' : v.replaceAll(' ', '-');
    }
    return selectedColor!;
  }

  void _prefillColorFromVariant(String? colorName) {
    final other = CustomStrings.other;
    final c = (colorName ?? '').trim();
    final match = colors.firstWhere(
      (x) => x.toLowerCase() == c.toLowerCase(),
      orElse: () => other,
    );
    if (match == other) {
      selectedColor = other;
      customColorController.text = c;
    } else {
      selectedColor = match;
      customColorController.clear();
    }
    updateSku();
  }

  Future<String?> _showAddItemSheet(
    BuildContext context, {
    required String title,
    required String hint,
  }) async {
    final controller = TextEditingController();
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hint,
                  border: const OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.done,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text("Add"),
                onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}
