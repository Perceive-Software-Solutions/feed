import 'package:feed/animationSystem/state.dart';
import 'package:feed/swipeCard/swipe_card.dart';
import 'package:feed/util/icon_position.dart';
import 'package:flutter/material.dart';
import 'package:fort/fort.dart';
part 'animation_system_delegate.dart';

class AnimationSystemDelegateBuilder extends StatefulWidget {
  final AnimationSystemDelegate delegate;
  final AnimationSystemController controller;
  const AnimationSystemDelegateBuilder({ 
    Key? key,
    required this.delegate,
    required this.controller,
  }) : super(key: key);

  @override
  State<AnimationSystemDelegateBuilder> createState() => _AnimationSystemDelegateBuilderState();
}

class _AnimationSystemDelegateBuilderState extends State<AnimationSystemDelegateBuilder> {

  /// Holds the current state of the AnimationSystem
  late Tower<AnimationSystemState> tower;

  @override
  void initState(){
    super.initState();
    // Initiate state
    tower = AnimationSystemState.tower();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.controller._bind(this);
  }

  @override
  void dispose(){
    super.dispose();
    widget.controller.dispose();
  }

  /// When the values of the animation system need to be updated from swipefeed (internal)
  void _onUpdate(double dx, double dy, Function(DismissDirection)? value){

    if(value == null) return;

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
    else if(dy.abs() > 0 && dx > horizontalLength*-1 && dx < horizontalLength){
      axisLock = Axis.vertical;
    }

    if(axisLock != Axis.horizontal && !horizontalAxisOverride){
      if(dy > 0){
        if(dx > 0){
          tower.dispatch(SetAllAnimationValues(value(DismissDirection.startToEnd), IconPosition.BOTTOM, CardPosition.Right));
          return;
        } 
        else{
          tower.dispatch(SetAllAnimationValues(value(DismissDirection.endToStart), IconPosition.BOTTOM, CardPosition.Left));
          return;
        }
      }
      else{
        if(dx > 0){
          tower.dispatch(SetAllAnimationValues(value(DismissDirection.startToEnd), IconPosition.TOP, CardPosition.Right));
          return;
        }
        else{
          tower.dispatch(SetAllAnimationValues(value(DismissDirection.endToStart), IconPosition.TOP, CardPosition.Left));
          return;
        }
      }
    }
    else if(axisLock != Axis.vertical){
      if(dx > 0){
        tower.dispatch(SetAllAnimationValues(value(DismissDirection.startToEnd), IconPosition.RIGHT, CardPosition.Right));
        return;
      }
      else{
        tower.dispatch(SetAllAnimationValues(value(DismissDirection.endToStart), IconPosition.LEFT, CardPosition.Left));
        return;
      }
    }
  }

  /// Values of the animation system get updated externally
  void _onFill(double fill, [IconPosition? newIconPosition, CardPosition? newCardPosition]){
    tower.dispatch(
      SetAllAnimationValues(
        fill, 
        newIconPosition != null ? newIconPosition : tower.state.iconPosition,
        newCardPosition != null ? newCardPosition : tower.state.cardPosition
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return StoreProvider(
      store: tower,
      child: StoreConnector<AnimationSystemState, AnimationSystemState>(
        converter: (store) => store.state,
        builder: (context, state) {
          return widget.delegate.build(context, state.iconPosition, state.cardPosition, state.fill);
        }
      )
    );
  }
}

class AnimationSystemController extends ChangeNotifier{
  late _AnimationSystemDelegateBuilderState? _state;

  //Bind to state
  void _bind(_AnimationSystemDelegateBuilderState bind) => _state = bind;

  //Called to notify all listners
  void _update() => notifyListeners();

  //Update on update of dx and dy values inside of the animation state
  void onUpdate(double dx, double dy, Function(DismissDirection) value) => _state != null ? _state!._onUpdate(dx, dy, value) : null;

  //Can be called when onSwipe is called to update the animation state
  void onFill(double fill, [IconPosition? newIconPosition, CardPosition? newCardPosition]) => _state != null ? _state!._onFill(fill, newIconPosition, newCardPosition) : null;

  //Disposes of the controller
  @override
  void dispose() {
    _state = null;
    super.dispose();
  }
}

