import 'dart:async';

import 'package:feed/animationSystem/state.dart';
import 'package:feed/util/global/functions.dart';
import 'package:feed/util/icon_position.dart';
import 'package:flutter/material.dart';
import 'package:fort/fort.dart';
part './animation_system_delegate.dart';

class AnimationSystemDelegateBuilder extends StatefulWidget {
  final AnimationSystemDelegate delegate;
  final AnimationSystemController controller;
  final bool animateAccordingToPosition;
  final bool controlHeptic;
  const AnimationSystemDelegateBuilder({ 
    Key? key,
    required this.delegate,
    required this.controller,
    this.animateAccordingToPosition = false,
    this.controlHeptic = false
  }) : super(key: key);

  @override
  State<AnimationSystemDelegateBuilder> createState() => _AnimationSystemDelegateBuilderState();
}

class _AnimationSystemDelegateBuilderState extends State<AnimationSystemDelegateBuilder> with TickerProviderStateMixin {

  /// Holds the current state of the AnimationSystem
  late Tower<AnimationSystemState> tower;

  /// Animates the
  late AnimationController animationController;

  int? oldDirection;

  @override
  void initState(){
    super.initState();
    // Initiate state
    tower = AnimationSystemState.tower();
    animationController = AnimationController(vsync: this, duration: widget.delegate.duration, lowerBound: 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.controller._bind(this);
  }

  @override
  void dispose(){
    super.dispose();
  }

/*
 
      ____ _____ _____ _____ _____ ____  ____  
     / ___| ____|_   _|_   _| ____|  _ \/ ___| 
    | |  _|  _|   | |   | | |  _| | |_) \___ \ 
    | |_| | |___  | |   | | | |___|  _ < ___) |
     \____|_____| |_|   |_| |_____|_| \_\____/ 
                                               
 
*/

  IconPosition iconPosition(DismissDirection direction){
    switch (direction) {
      case DismissDirection.startToEnd:
        return IconPosition.RIGHT;
      case DismissDirection.endToStart:
        return IconPosition.LEFT;
      case DismissDirection.down:
        return IconPosition.BOTTOM;
      case DismissDirection.up:
        return IconPosition.TOP;
      default:
        return IconPosition.RIGHT;
    }
  }

  CardPosition cardPosition(DismissDirection direction, double dx){
    if(direction == DismissDirection.startToEnd){
      return CardPosition.Right;
    }
    else if(direction == DismissDirection.endToStart){
      return CardPosition.Left;
    }
    else if(dx >= 0){
      return CardPosition.Right;
    }
    else{
      return CardPosition.Left;
    }
  }

  double get HORIZONTALSWIPETHRESH{
    return 92.0;
  }

  double get BOTTOMSWIPETHRESH{
    return 157;
  }

  double get TOPSWIPETHRESH{
    return 92.0;
  }

/*
 
     _____                 _   _                 
    |  ___|   _ _ __   ___| |_(_) ___  _ __  ___ 
    | |_ | | | | '_ \ / __| __| |/ _ \| '_ \/ __|
    |  _|| |_| | | | | (__| |_| | (_) | | | \__ \
    |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
                                                 
 
*/

  /// Reset the animation state, should be reset after onSwipe has completed
  void reset(){
    tower.dispatch(SetAllAnimationValues(null, null, 0, 0));
    animationController.reset();
    widget.delegate.onUpdate(0, 0, 0);
  }

  // Dispatch values before swipe
  void onSwipe(IconPosition iconPosition, CardPosition cardPosition){
    animationController.animateTo(0.2, duration: Duration.zero);
    tower.dispatch(SetAllAnimationValues(
      iconPosition, 
      cardPosition, 
      iconPosition == IconPosition.LEFT || iconPosition == IconPosition.RIGHT ? 92 : 0, 
      iconPosition == IconPosition.TOP ? 92 : iconPosition == IconPosition.BOTTOM ? -158 : 0));
      widget.delegate.onUpdate(iconPosition == IconPosition.LEFT || iconPosition == IconPosition.RIGHT ? 92 : 0, iconPosition == IconPosition.TOP ? 92 : iconPosition == IconPosition.BOTTOM ? -158 : 0, 0.2);
  }

  Future<void> _reverse() async {
    _onUpdate(0, 0, (direction) => 0, true);
    Future.delayed(Duration(milliseconds: 200));
    return;
  }

  /// When the values of the animation system need to be updated from swipefeed (internal)
  void _onUpdate(double dx, double dy, Function(DismissDirection)? value, [bool reverse = false]) async {

    if(value == null || !mounted) return;

    //Direction to int
    int i = -1;

    //Height of the screen
    final height = MediaQuery.of(context).size.height;

    //Width of the screen
    final width = MediaQuery.of(context).size.width;

    // Diagonal slope of the screen
    final slope = height/width;

    /// Vertical Length to the slope
    double verticalLength = slope*dx.abs();

    /// Horizontal Length to the slope
    double horizontalLength = slope*dy.abs();

    ///Overrides to the y direction
    bool horizontalAxisOverride = dy > (verticalLength*-1) && dy < verticalLength;

    ///Locks the output from sending to any other axis when locked
    Axis axisLock = Axis.horizontal;

    if(dx.abs() >= 0 && dy > verticalLength*-1 && dy < verticalLength){
      axisLock = Axis.horizontal;
    }
    else if((dy > 98 || dy < -32) && dx > horizontalLength*-1 && dx < horizontalLength){
      axisLock = Axis.vertical;
    }

    if(dx == 0 && dy == 0 && reverse){
      tower.dispatch(SetAllAnimationValues(tower.state.iconPosition, tower.state.cardPosition, dx, dy, reversing: true));
      animationController.animateTo(0, duration: Duration(milliseconds: 200));
      await Future.delayed(Duration(milliseconds: 200));
    }
    else if(dx == 0 && dy == 0){
      tower.dispatch(SetAllAnimationValues(null, null, dx, dy));
    }
    else if(axisLock != Axis.horizontal && !horizontalAxisOverride){
      if(dy > 0){
        // show bottom
        i = 2;
        // Card Position Right Vertical Axis, Below Y axis
        if(dx > 0){
          tower.dispatch(SetAllAnimationValues(IconPosition.BOTTOM, CardPosition.Right, dx, dy));
          if(widget.delegate.animateAccordingToPosition){
            widget.delegate.onUpdate(dx, dy, value(DismissDirection.down));
            animationController.animateTo(value(DismissDirection.down), duration: Duration(milliseconds: 0));
          }
          else{
            widget.delegate.onUpdate(dx, dy, value(DismissDirection.startToEnd));
            animationController.animateTo(value(DismissDirection.startToEnd), duration: Duration(milliseconds: 0));
          }
        }
        // Card Position Left Vertical Axis, Below Y axis
        else{
          // show top
          tower.dispatch(SetAllAnimationValues(IconPosition.BOTTOM, CardPosition.Left, dx, dy));
          if(widget.delegate.animateAccordingToPosition){
            widget.delegate.onUpdate(dx, dy, value(DismissDirection.down));
            animationController.animateTo(value(DismissDirection.down), duration: Duration(milliseconds: 0));
          }
          else{
            widget.delegate.onUpdate(dx, dy, value(DismissDirection.endToStart));
            animationController.animateTo(value(DismissDirection.endToStart), duration: Duration(milliseconds: 0));
          }
        }
      }
      else{
        // show top
        i = 3;
        // Card Position Right Vertical Axis, above Y axis
        if(dx > 0){
          tower.dispatch(SetAllAnimationValues(IconPosition.TOP, CardPosition.Right, dx, dy));
          if(widget.delegate.animateAccordingToPosition){
            widget.delegate.onUpdate(dx, dy, value(DismissDirection.up));
            animationController.animateTo(value(DismissDirection.up), duration: Duration(milliseconds: 0));
          }
          else{
            widget.delegate.onUpdate(dx, dy, value(DismissDirection.startToEnd));
            animationController.animateTo(value(DismissDirection.startToEnd), duration: Duration(milliseconds: 0));
          }
        }
        // Card Position Left Vertical Axis, above Y axis
        else{
          tower.dispatch(SetAllAnimationValues(IconPosition.TOP, CardPosition.Left, dx, dy));
          if(widget.delegate.animateAccordingToPosition){
            widget.delegate.onUpdate(dx, dy, value(DismissDirection.up));
            animationController.animateTo(value(DismissDirection.up), duration: Duration(milliseconds: 0));
          }
          else{
            widget.delegate.onUpdate(dx, dy, value(DismissDirection.endToStart));
            animationController.animateTo(value(DismissDirection.endToStart), duration: Duration(milliseconds: 0));
          }
        }
      }
    }
    else if(axisLock != Axis.vertical){
      // Card Position Horizontal Axis Right
      if(dx > 0){
        // show right
        i = 0;
        tower.dispatch(SetAllAnimationValues(IconPosition.RIGHT, CardPosition.Right, dx, dy));
        widget.delegate.onUpdate(dx, dy, value(DismissDirection.startToEnd));
        animationController.animateTo(value(DismissDirection.startToEnd), duration: Duration(milliseconds: 0));
      }
      // Card Position Horizontal Axis Left
      else{
        // show left
        i = 1;
        tower.dispatch(SetAllAnimationValues(IconPosition.LEFT, CardPosition.Left, dx, dy));
        widget.delegate.onUpdate(dx, dy, value(DismissDirection.endToStart));
        animationController.animateTo(value(DismissDirection.endToStart), duration: Duration(milliseconds: 0));
      }
    }
    /// Diagonal Heptic
    if(!reverse && widget.controlHeptic){
      if(oldDirection != i && ((dx.abs() >= HORIZONTALSWIPETHRESH && 
      (i == 0 || i == 1)) || (dy.abs() > TOPSWIPETHRESH 
      && i == 3) || (dy.abs() > BOTTOMSWIPETHRESH && i == 2))){
        Functions.hapticSwipeVibrate();
      }
    }

    oldDirection = i;

    return;
  }

  /// Values of the animation system get updated externally
  Future<void> _onFill(DismissDirection direction, double dx, double? fill, {Duration? duration}) async {
    tower.dispatch(
      SetAllAnimationValues(
        iconPosition(direction),
        cardPosition(direction, dx), 
        tower.state.dx, 
        tower.state.dy,
        nullFill: fill == null,
      )
    );
    await Future.delayed(Duration(milliseconds: 20));
    animationController.animateTo(fill ?? 0.5, duration: duration, curve: Curves.easeInOutCubic);
    await widget.delegate.onFill(fill, tower.state);
    return;
  }

  Future<bool> _onComplete(DismissDirection direction, double dx, {Duration? duration, OverlayDelegate? overlay, Future<void> Function()? reverse, List<dynamic>? args}) async {
    Completer<bool> completer = Completer();

    tower.dispatch(
      SetAllAnimationValues(
        iconPosition(direction),
        cardPosition(direction, dx), 
        tower.state.dx, 
        tower.state.dy,
        nullFill: false
      )
    );
    await Future.delayed(Duration(milliseconds: 20));

    animationController.forward(from: animationController.value).whenComplete(() async {
      bool result = await widget.delegate.onComplete(tower.state, overlay: overlay, reverse: reverse, args: args ?? []);
      completer.complete(result);
    });
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return StoreProvider(
      store: tower,
      child: AnimatedBuilder(
        animation: animationController,
        builder: (context, _) {
          return widget.delegate.build(context, tower.state, animationController.value);
        }
      ),
    );
  }
}


class AnimationSystemController extends ChangeNotifier{
  _AnimationSystemDelegateBuilderState? _state;

  //Bind to state
  void _bind(_AnimationSystemDelegateBuilderState bind) => _state = bind;

  //Called to notify all listners
  void _update() => notifyListeners();

  bool isBinded() => _state != null;

  //Update on update of dx and dy values inside of the animation state
  void onUpdate(double dx, double dy, Function(DismissDirection) value, [bool reverse = false]) => _state != null ? _state!._onUpdate(dx, dy, value, reverse) : null;

  Future<void> reverse() async => _state != null ? await _state!._reverse() : null;

  //Can be called when onSwipe is called to update the animation state
  Future<void>? onFill(DismissDirection direction, double dx, double? fill, {Duration? duration}) async => _state != null ? await _state!._onFill(direction, dx, fill, duration: duration) : null;

  // Completes the current animation
  Future<bool>? onComplete(DismissDirection direction, double dx, {OverlayDelegate? overlay, Future<void> Function()? reverse, List<dynamic>? args}) => _state != null ? _state!._onComplete(direction, dx, overlay: overlay, reverse: reverse, args: args) : null;

  void swipe(IconPosition iconPosition, CardPosition cardPosition) => _state != null ? _state!.onSwipe(iconPosition, cardPosition) : null; 

  void reset() => _state != null ? _state!.reset() : null;

  //Disposes of the controller
  @override
  void dispose() {
    _state = null;
    super.dispose();
  }
}

