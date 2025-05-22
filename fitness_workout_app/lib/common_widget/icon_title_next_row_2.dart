import 'package:flutter/material.dart';

import '../common/colo_extension.dart';

class IconTitleNextRow2 extends StatelessWidget {
  final String icon;
  final String title;
  final String time;
  final VoidCallback onPressed;
  final Color color;
  const IconTitleNextRow2({super.key, required this.icon, required this.title, required this.time, required this.onPressed, required this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        decoration: BoxDecoration(
          //color: color,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 25,
              height: 25,
              alignment: Alignment.center,
              child: Image.asset(
                icon,
                width: 20,
                height: 20,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title ,
                style: TextStyle(color: TColor.gray, fontSize: 14),
              ),
            ),
            SizedBox(
              width: 120,
              child: Text(
                time,
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 25,
              height: 25,
              child:  Container(
                width: 25,
                height: 25,
                alignment: Alignment.center,
                child: Image.asset(
                  "assets/img/p_next.png",
                  width: 12,
                  height: 12,
                  fit: BoxFit.contain,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}