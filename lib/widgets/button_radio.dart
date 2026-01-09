import 'package:e_logbook/utils/responsive_helper.dart';
import 'package:flutter/material.dart';

enum ButtonRadio { email, phone }

class ButtonRadioController extends ValueNotifier<ButtonRadio> {
  ButtonRadioController([ButtonRadio value = ButtonRadio.email])
    : super(value);
}

class ButtonRadioSelector extends StatelessWidget {
  final ButtonRadioController controller;

  const ButtonRadioSelector({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ButtonRadio>(
      valueListenable: controller,
      builder: (context, value, _) {
        return Row(
          children: [
            Transform.scale(
              scale: 0.8,
              child: Radio<ButtonRadio>(
                value: ButtonRadio.email,
                groupValue: value,
                activeColor: Colors.blueAccent,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: (newValue) {
                  if (newValue != null) controller.value = newValue;
                }, 
              ),
            ),
            Text("Email", style: TextStyle(fontSize: ResponsiveHelper.font(context, mobile: 12, tablet: 14))),
            const SizedBox(width: 16),
            Transform.scale(
              scale: 0.8,
              child: Radio<ButtonRadio>(
                value: ButtonRadio.phone,
                groupValue: value,
                activeColor: Colors.blueAccent,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: (newValue) {
                  if (newValue != null) controller.value = newValue;
                },
              ),
            ),
            Text("No Telp", style: TextStyle(fontSize: ResponsiveHelper.font(context, mobile: 12, tablet: 14))),
          ],
        );
      },
    );
  }
}

