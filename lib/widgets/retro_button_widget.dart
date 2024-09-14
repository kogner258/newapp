import 'package:flutter/material.dart';

class RetroButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;
  final bool fixedHeight;
  final Color shadowColor;  // Custom shadow color

  const RetroButton({
    required this.text,
    required this.onPressed,
    this.color = const Color(0xFFD24407),  // Default color
    this.fixedHeight = false,  // Allow control over height adjustment
    this.shadowColor = Colors.black,  // Default shadow color
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.white,  // Thin white outline
            offset: Offset(4.5, 4.5),  // Slightly smaller offset than the shadow
            blurRadius: 0,
          ),
          BoxShadow(
            color: shadowColor.withOpacity(0.9),  // Darker shadow color
            offset: Offset(4, 4),  // Slightly larger offset for more pronounced effect
            blurRadius: 0,
          ),
        ],
        borderRadius: BorderRadius.circular(4),
      ),
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          height: fixedHeight ? 45 : 50,  // Adjust height to prevent overflow
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.black, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}