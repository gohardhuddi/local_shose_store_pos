import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _AddStockScreenState extends State<AddStockScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            spacing: 15,
            children: [
              Text(
                CustomStrings.shopName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text("Add Stock", style: Theme.of(context).textTheme.titleLarge),
              CustomTextField(
                textEditingController: TextEditingController(),
                labelText: "Brand *",
                hintText: "e.g Bata Shoes",
              ),
              CustomTextField(
                textEditingController: TextEditingController(),
                labelText: "Article Code *",
                hintText: "e.g ADSH001",
              ),
              CustomTextField(
                textEditingController: TextEditingController(),
                labelText: "Article Name",
                hintText: "e.g Adidas Runner",
              ),
              CustomTextField(
                textEditingController: TextEditingController(),
                labelText: "Size *",
                hintText: "e.g 48",
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),

              DropdownButtonFormField<String>(
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
                  setState(() {});
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
                textEditingController: TextEditingController(),
                labelText: "Product Code SKU *",
                hintText: "e.g ADSH001-BLK-42",
              ),
              CustomTextField(
                textEditingController: TextEditingController(),
                labelText: "Quantity *",
                hintText: "e.g 10",
                keyboardType: TextInputType.number,
              ),
              CustomTextField(
                textEditingController: TextEditingController(),
                labelText: "Purchase Price *",
                hintText: "e.g 700",
                keyboardType: TextInputType.number,
              ),
              CustomTextField(
                textEditingController: TextEditingController(),
                labelText: "Suggested Sale Price *",
                hintText: "e.g 1000",
                keyboardType: TextInputType.number,
              ),
              CustomButton(onPressed: () {}, buttonTitle: "Add Stock"),
            ],
          ),
        ),
      ),
    );
  }
}
