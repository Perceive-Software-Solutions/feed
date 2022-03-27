import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tuple/tuple.dart';

///Holds a list of constants used within the application
class Functions {
  ///Only displays a value over its final percentage. 
  ///The final split is outputted in values
  static double animateOver(double value, {double percent = 1.0}){
    assert(percent != null && percent >= 0 && percent <= 1.0);
    assert(value != null && value >= 0);

    double remainder = 1.0 - percent;

    return max(0, (value - percent) / remainder);
  }

  ///Only displays a value over its final percentage. 
  ///The final split is outputted in values
  static double animateOverFirst(double value, {double percent = 1.0}){
    assert(percent != null && percent >= 0 && percent <= 1.0);
    assert(value != null && value >= 0 && value <= 1.0);

    return min(1.0, value / percent);
  }

  //Only displays a value within a range
  static double animateRange(double value, {double start = 0.0, double end = 1.0}){
    assert(start != null && start >= 0 && start <= 1.0);
    assert(end != null && end >= 0 && end <= 1.0);
    assert(value != null && value >= 0 && value <= 1.0);

    //The ratio of the animate over first 
    //that will be the percintile for the animate over
    double ratioOfFirst = start/end;

    return animateOver(
      animateOverFirst(value, percent: end), 
      percent: ratioOfFirst 
    );
  }

  ///Sends out many haptic events to simulate a complex haptic vibration, done when swipe card is swiped
  static void hapticSwipeVibrate() async {
    // HapticFeedback.selectionClick();
    HapticFeedback.mediumImpact();
  }

  ///Dtermines if a value is between a range
  static bool isWithin(double? value, double? start, double? end){
    assert(start != null);
    assert(end != null);
    
    if(value == null){
      return false;
    }
    return value >= start! && value <= end!;
  }

  ///Dtermines if a value is between a marginal range from the value
  static bool inMargin(double? value, double? start, double? margin){
    assert(start != null);
    assert(margin != null);
    
    if(value == null){
      return false;
    }
    return Functions.isWithin(value, start! - margin!, start+ margin);
  }
}

///Loader for the feed returns a tuple of lst items with a token
typedef FeedLoader<T> = Future<Tuple2<List<T>, String?>> Function(int size, [String? token]);

///A Builder for the swipe feed
///The close function shrinks the card
typedef SwipeFeedBuilder<T> = Widget Function(T value, bool isLast, bool expanded, void Function() close);

///Builder for the feed items
typedef FeedBuilder = Widget Function(dynamic item, bool isLast);

///Builder for the multi feed items
typedef MultiFeedBuilder = Widget Function(dynamic item, int index, bool isLast);

///A function that returns an wrapper for a widget
typedef IndexWidgetWrapper = Widget Function(BuildContext context, Widget child, int index);

///Sliding sheet widget wrapper
typedef SlidingSheetWidgetWrapper = Widget Function(BuildContext context, double extent, Widget child, int index);

typedef WidgetWrapper = Widget Function(BuildContext context, Widget child);