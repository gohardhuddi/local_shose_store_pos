import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../helper/constants.dart';
import '../../theme_bloc/theme_bloc.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    this.hintText,
    this.keyboardType,
    required this.textEditingController,
    this.tarilingWidget,
    this.textCapitalization,
    this.maxLines,
    this.readOnly,
    this.leadingWidget,
    this.onTap,
    this.fillColor,
    this.labelText,
    this.showLabel = true,
    this.inputFormatters,
    this.obscureText = false,
    this.validator,
    this.onFieldSubmitted,
    this.onChanged,
  });

  final String? hintText;
  final String? labelText;
  final TextInputType? keyboardType;
  final TextEditingController textEditingController;
  final Widget? tarilingWidget;
  final Widget? leadingWidget;
  final TextCapitalization? textCapitalization;
  final int? maxLines;
  final bool? readOnly;
  final Color? fillColor;
  final GestureTapCallback? onTap;
  final bool? showLabel;
  final List<TextInputFormatter>? inputFormatters;
  final bool? obscureText;
  final FormFieldValidator<dynamic>? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      obscureText: obscureText ?? false,
      onTap: onTap,
      readOnly: readOnly ?? false,
      maxLines: maxLines ?? 1,
      textCapitalization: textCapitalization ?? TextCapitalization.none,
      controller: textEditingController,
      decoration: InputDecoration(
        suffixIcon: tarilingWidget,
        prefixIcon: leadingWidget,
        hintText: hintText,
        labelText: showLabel == true ? labelText ?? hintText : null,
        hintStyle: TextStyle(
          color: context.watch<ThemeBloc>().state == ThemeMode.dark
              ? Colors.grey
              : Colors.grey,
          fontSize: 16,
        ),
        filled: true,

        fillColor:
            fillColor ??
            (context.watch<ThemeBloc>().state == ThemeMode.dark
                ? Colors.grey.shade900
                : CustomColors.whiteButtonColors),

        floatingLabelBehavior: FloatingLabelBehavior.always, // Always float
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), // Rounded border
          borderSide: BorderSide(
            color: context.watch<ThemeBloc>().state == ThemeMode.dark
                ? CustomColors.whiteButtonColors
                : CustomColors.greyColors, // Black border
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            width: 1,
            color: context.watch<ThemeBloc>().state == ThemeMode.dark
                ? CustomColors.whiteButtonColors
                : CustomColors.greyColors,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            width: 1.5, // Thicker border when focused
            color: context.watch<ThemeBloc>().state == ThemeMode.dark
                ? CustomColors.whiteButtonColors
                : CustomColors.greyColors,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 15,
        ),
      ),
      keyboardType: keyboardType ?? TextInputType.text,
      inputFormatters: inputFormatters,
      validator: validator,
    );
  }
}
