// lib/widgets/color_picker_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import 'retro_button_widget.dart';

class ColorPickerWidget extends StatelessWidget {
  final Color currentColor;
  final ValueChanged<Color> onColorChanged;

  const ColorPickerWidget({
    Key? key,
    required this.currentColor,
    required this.onColorChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RetroButton(
      text: 'Pick a Color',
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) {
            Color tempColor = currentColor;
            return AlertDialog(
              title: Text('Select Theme Color', style: TextStyle(fontFamily: 'MS Sans Serif')),
              content: SingleChildScrollView(
                child: BlockPicker(
                  pickerColor: currentColor,
                  onColorChanged: (color) {
                    tempColor = color;
                  },
                ),
              ),
              actions: [
                TextButton(
                  child: Text('Cancel', style: TextStyle(fontFamily: 'MS Sans Serif')),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: Text('Select', style: TextStyle(fontFamily: 'MS Sans Serif')),
                  onPressed: () {
                    onColorChanged(tempColor);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
      color: Color(0xFFD24407),
      fixedHeight: true,
      shadowColor: Colors.black,
    );
  }
}
