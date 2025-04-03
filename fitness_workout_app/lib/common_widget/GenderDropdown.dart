import 'package:flutter/material.dart';

import '../common/colo_extension.dart';
import '../../localization/app_localizations.dart';

class GenderDropdown extends StatefulWidget {
  final String icon;
  final String labelText;
  final List<String> options;
  final TextEditingController controller;

  const GenderDropdown({
    super.key,
    required this.icon,
    required this.labelText,
    required this.options,
    required this.controller,
  });

  @override
  State<GenderDropdown> createState() => _GenderDropdownState();
}

class _GenderDropdownState extends State<GenderDropdown> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: widget.labelText,
          labelStyle: TextStyle(color: TColor.gray),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        ),
        child: Row(
          children: [
            Container(
              alignment: Alignment.center,
              width: 35,
              height: 20,
              child: Image.asset(
                widget.icon,
                width: 20,
                height: 20,
                fit: BoxFit.contain,
                color: TColor.gray,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: AppLocalizations.of(context)?.translate(widget.controller.text),
                  items: widget.options.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      widget.controller.text = value ?? '';
                    });
                  },
                  hint: Text(
                    AppLocalizations.of(context)?.translate("Choose Gender") ?? "Choose Gender",
                    style: TextStyle(color: TColor.gray),
                  ),
                  isExpanded: true,
                  icon: Icon(Icons.arrow_drop_down, color: TColor.gray),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
