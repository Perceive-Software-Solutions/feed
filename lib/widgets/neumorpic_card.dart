import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';

enum EECardMode {
  ///Regular EECard
  NEUMORPHIC,

  ///EECard with no outer shaodws
  THIN,

  ///EECard with no inner or outer shadows
  FLAT
}

@Deprecated('[REFACTOR] Ibtesam - Review Neumorphic Design')
class NeumorpicCard extends StatelessWidget {

  final Widget child;

  final Color? color;
  final double? width;
  final BorderRadius? borderRadius;
  final BoxConstraints? constraints;
  
  final EECardMode mode;

  const NeumorpicCard({
    Key? key,
    required this.child,
    this.color, 
    this.width, 
    this.borderRadius, 
    this.mode = EECardMode.NEUMORPHIC, 
    this.constraints
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return Neumorphic(
      style: NeumorphicStyle(
        shape: NeumorphicShape.flat,
        color: color,
        boxShape: NeumorphicBoxShape.roundRect(borderRadius ?? BorderRadius.circular(0)),
        depth: 1,
        lightSource: LightSource.topLeft,
        shadowDarkColor: Color(0xFF92ACC4),
        shadowLightColor: Colors.transparent
      ),
      child: child,
    );
  }
}