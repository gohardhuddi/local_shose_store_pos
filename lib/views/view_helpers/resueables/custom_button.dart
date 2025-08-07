import 'package:flutter/material.dart';

import '../../../helper/constants.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.onPressed,
    required this.buttonTitle,
    this.trailingIcon,
    this.leadingIcon,
    this.backgroundColor,
    this.titleColor,
    this.maxSize,
    this.minSize,
    this.titleFontSize,
    this.padding,
  });

  final VoidCallback? onPressed;
  final String buttonTitle;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final Color? backgroundColor;
  final Color? titleColor;
  final Size? minSize;
  final Size? maxSize;
  final double? titleFontSize;
  final double? padding;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? CustomColors.redButtonColor,
        minimumSize: minSize ?? const Size(380, 70),
        maximumSize: maxSize ?? const Size(380, 70),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        shadowColor: Color(0x0D000000),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          leadingIcon ?? SizedBox.shrink(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: padding ?? 10.0),
            child: Text(
              buttonTitle,
              style: TextStyle(
                color: titleColor ?? Colors.white,
                fontSize: titleFontSize ?? 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          trailingIcon ?? SizedBox.shrink(),
        ],
      ),
    );
  }
}
