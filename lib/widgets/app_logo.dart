import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double logoHeight;
  final bool showText;
  final double fontSize;
  
  const AppLogo({
    super.key, 
    this.logoHeight = 280,
    this.showText = true,
    this.fontSize = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/logo.png',
          height: logoHeight,
        ),
        if (showText) ...[
          const SizedBox(height: 0),
          Transform.translate(
            offset: const Offset(0, -15), // Pull text closer to logo
            child: Text(
              'إشارة - Ishara',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                fontFamily: 'CustomFont',
                color: Theme.of(context).colorScheme.primary,
                letterSpacing: 2,
                shadows: [
                  Shadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
