import 'package:flutter/material.dart';

///The positionings for the icon
enum IconPosition {
  LEFT, RIGHT, TOP, BOTTOM
}

enum CardPosition{
  Left, Right
}

extension IconPostionExtension on IconPosition{

  DismissDirection? get direction{
    switch (this) {
      case IconPosition.LEFT:
        return DismissDirection.endToStart;
      case IconPosition.RIGHT:
        return DismissDirection.startToEnd;
      case IconPosition.TOP:
        return DismissDirection.down;
      case IconPosition.BOTTOM:
        return DismissDirection.up;
      default:
        return null;
    }
  }

  IconPosition? fromDirection(DismissDirection direction){
    switch (direction) {
      case DismissDirection.endToStart:
        return IconPosition.LEFT;
      case DismissDirection.startToEnd:
        return IconPosition.RIGHT;
      case DismissDirection.down:
        return IconPosition.BOTTOM;
      case DismissDirection.up:
        return IconPosition.TOP;
      default:
        return null;
    }
  }
}