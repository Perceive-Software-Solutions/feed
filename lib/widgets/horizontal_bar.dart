import 'package:flutter/material.dart';

///Horizontal bar that runs accross the defined context
class HorizontalBar extends StatelessWidget {

  final double width;
  final Color color;
  final double mainAxisPadding;

  const HorizontalBar({
    Key? key, 
    this.width = 1, 
    this.color = Colors.grey, 
    this.mainAxisPadding = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: mainAxisPadding),
      child: Container(
        height: width,
        width: double.infinity,
        color: color,
      ),
    );
  }
}

class VerticalBar extends StatelessWidget {

  final double width;
  final Color color;
  final double mainAxisPadding;

  const VerticalBar({
    Key? key, 
    this.width = 1, 
    this.color = Colors.grey, 
    this.mainAxisPadding = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: mainAxisPadding),
      child: Container(
        height: double.infinity,
        width: width,
        color: color,
      ),
    );
  }
}