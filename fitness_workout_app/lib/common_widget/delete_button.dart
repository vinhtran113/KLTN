import 'package:flutter/material.dart';

import '../common/colo_extension.dart';

enum RoundButtonType { bgGradient, bgSGradient, textGradient, transparentRed }

class DeleteButton extends StatelessWidget {
  final String title;
  final RoundButtonType type;
  final VoidCallback onPressed;
  final double fontSize;
  final double elevation;
  final FontWeight fontWeight;

  const DeleteButton({
    super.key,
    required this.title,
    this.type = RoundButtonType.transparentRed,
    this.fontSize = 16,
    this.elevation = 1,
    this.fontWeight = FontWeight.w700,
    required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: type == RoundButtonType.bgSGradient
            ? LinearGradient(colors: TColor.secondaryG)
            : type == RoundButtonType.bgGradient
            ? LinearGradient(colors: TColor.primaryG)
            : null,
        borderRadius: BorderRadius.circular(25),
        border: type == RoundButtonType.transparentRed
            ? Border.all(color: Colors.red)
            : null,
        boxShadow: (type == RoundButtonType.bgGradient || type == RoundButtonType.bgSGradient)
            ? const [BoxShadow(color: Colors.black26, blurRadius: 0.5, offset: Offset(0, 0.5))]
            : null,
      ),
      child: Material(
        color: Colors.transparent, // Nền thật sự trong suốt
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        child: MaterialButton(
          onPressed: onPressed,
          height: 50,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          textColor: Colors.red,
          splashColor: Colors.red.withOpacity(0.1), // hoặc Colors.transparent nếu không muốn
          highlightColor: Colors.transparent,
          minWidth: double.maxFinite,
          elevation: 0,
          color: Colors.transparent, // giữ trong suốt
          child: Text(
            title,
            style: TextStyle(
              color: Colors.red,
              fontSize: fontSize,
              fontWeight: fontWeight,
            ),
          ),
        ),
      ),
    );
  }
}
