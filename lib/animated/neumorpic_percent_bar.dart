import 'dart:math';
import 'dart:ui';

import 'package:feed/animated/poll_swipe_animated_icon.dart';
import 'package:feed/providers/color_provider.dart';
import 'package:feed/util/global/functions.dart';
import 'package:feed/util/icon_position.dart';
import 'package:feed/util/render/inner_shadow.dart';
import 'package:flutter/material.dart';

///NeumorpicPercentBar widget is a percent bar that is not bounded horizontally.
///The percent bar has 2 sides and contains a value for the percentage.
///The animation for the percent bar cna be controlled by a parent widget.
class NeumorpicPercentBar extends StatefulWidget {

  ///Controller for the percent bar
  final PercentBarController controller;

  const NeumorpicPercentBar({Key? key, required this.controller}) :
  super(key: key);

  @override
  _NeumorpicPercentBarState createState() => _NeumorpicPercentBarState();
}

class _NeumorpicPercentBarState extends State<NeumorpicPercentBar> with TickerProviderStateMixin {

  ///The duration for the animator
  static const Duration FILL_DURATION = Duration(milliseconds: 200);

  ///The duration for the animator when switching sides
  static const Duration FAST_FILL_DURATION = Duration(milliseconds: 100);

  ///The duration for the animator when completeing a result
  static const Duration COMPLETE_FILL_DURATION = Duration(milliseconds: 600);

  ///An animation for the fill
  late AnimationController fillController;

  ///The direction of the fill
  late IconPosition direction;

  //Locks the animation
  bool lockAnimation = false;

  ///The value of the last fill
  double oldFill = 0;

  //Set to true on complete fill
  bool complete = false;

  //Retreives the fill percentage relative to the direction
  double get fill {
    if(direction == IconPosition.BOTTOM){
      return 0;
    }
    else if(direction == IconPosition.TOP){
      return fillController.value;
    }
    else if(direction == IconPosition.LEFT){
      return fillController.value;
    }
    else if(direction == IconPosition.RIGHT){
      return fillController.value;
    }
    else{
      throw 'Invalid Type for Icon Positioning';
    }
  }

  //Retreives the fill percentage relative to the direction
  double get rawFill {
    if(direction == IconPosition.BOTTOM){
      return 0;
    }
    else if(direction == IconPosition.TOP){
      return oldFill;
    }
    else if(direction == IconPosition.LEFT){
      return oldFill;
    }
    else if(direction == IconPosition.RIGHT){
      return oldFill;
    }
    else{
      throw 'Invalid Type for Icon Positioning';
    }
  }

  ///Retreives the color based on the direction
  Color? fillColor(AppColor appColors) {
    if(direction == IconPosition.BOTTOM){
      return Colors.transparent;
    }
    else if(direction == IconPosition.TOP){
      return appColors.yellow;
    }
    else if(direction == IconPosition.LEFT){
      return appColors.red;
    }
    else if(direction == IconPosition.RIGHT){
      return appColors.blue;
    }
    else{
      throw 'Invalid Type for Icon Positioning';
    }
  }

  ///Retreives the title based on the direction
  String get title {
    if(direction == IconPosition.BOTTOM){
      return 'Skip';
    }
    else if(direction == IconPosition.TOP){
      return 'Score';
    }
    else if(direction == IconPosition.LEFT){
      return 'Disagree';
    }
    else if(direction == IconPosition.RIGHT){
      return 'Agree';
    }
    else{
      throw 'Invalid Type for Icon Positioning';
    }
  }

  @override
  void initState(){
    super.initState();
    
    //Get direction
    direction = IconPosition.BOTTOM;

    //Bind controller
    widget.controller._bind(this);

    //Initiate the fill controller
    fillController = AnimationController(vsync: this, duration: FILL_DURATION)
      ..addStatusListener((status) {
        if(status == AnimationStatus.completed){
          oldFill = fillController.value;
        }
      });
  }

  Future<void> fillBar(double newFill, IconPosition newDirection) async {
    print(lockAnimation);
    if(lockAnimation == true) return;

    complete = false;

    if(direction != newDirection){

      lockAnimation = true;

      //Animate down
      await fillController.animateTo(0, duration: FAST_FILL_DURATION);

      
      setState(() {
        direction = newDirection;
      });

      lockAnimation = false;

      //Animate up
      await fillController.animateTo(newFill);

    }
    else if(newFill != oldFill && !fillController.isAnimating){

      lockAnimation = true;

      if(!Functions.inMargin(oldFill, newFill, 0.1)){
        await fillController.animateTo(newFill);
      }
      else {
        await fillController.animateTo(newFill, duration: Duration.zero);
      }

      lockAnimation = false;
    }
  }

  Future<void> completeFillBar(double newFill, [IconPosition? newDirection]) async {
    lockAnimation = true;

    complete = true;

    if(newDirection != null && newDirection != direction){
      //Animate down
      await fillController.animateTo(0, duration: FAST_FILL_DURATION);

      
      setState(() {
        direction = newDirection;
      });
    }

    await fillController.animateTo(max(0.01, newFill), duration: COMPLETE_FILL_DURATION);
    lockAnimation = false;
  }

  @override
  Widget build(BuildContext context) {
    ///General app styles
    final appColors = ColorProvider.of(context);

    //Text style provider
    final textStyles = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(colors: [
            Colors.white,
            Colors.white.withOpacity(0.9),
            Colors.white.withOpacity(0.25),
            Color(0xFF3F5E7E).withOpacity(0.10)
          ], begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: Padding(
        padding: const EdgeInsets.all(1),
        child: Container(
          decoration: BoxDecoration(
              color: appColors.background,
              borderRadius: BorderRadius.circular(16)),
          child: AnimatedBuilder(
            animation: fillController,
            builder: (context, _) {
              return Stack(
                children: [
                  //Neumorphic inner shadow
                  Padding(
                    padding: const EdgeInsets.all(2),
                    child: InnerShadow(
                      color: Color(0xFF95AFC6).withOpacity(0.48),
                      offset: Offset(3, 3),
                      blur: 7,
                      child: InnerShadow(
                        color: Colors.white,
                        offset: Offset(-3, -3),
                        blur: 7,
                        child: Container(
                          height: 52,
                          width: double.infinity,
                          decoration: BoxDecoration(
                              color: Color(0xFFEBF2F9),
                              borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ),
          
                  //Percent bar fill
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: FractionallySizedBox(
                            widthFactor: 1,
                            child: AnimatedAlign(
                              duration: Duration(milliseconds: 10),
                              alignment: direction != IconPosition.LEFT ? 
                              Alignment.centerLeft : 
                              Alignment.centerRight,
                              child: FractionallySizedBox(
                                widthFactor: fill,
                                child: AnimatedCrossFade(
                                  crossFadeState: direction == IconPosition.TOP ? 
                                    CrossFadeState.showSecond : 
                                    CrossFadeState.showFirst,
                                  duration: Duration(milliseconds: 350),
                                  firstCurve: Curves.easeOutQuint,
                                  secondCurve: Curves.easeInQuint,
                                  firstChild: InnerShadow(
                                    color: direction != IconPosition.LEFT
                                    ? Color(0xFF8BA7C1).withOpacity(0.48)
                                    : Colors.white.withOpacity(0.5),
                                    blur: 7,
                                    offset: direction != IconPosition.LEFT ? Offset(3, 3) : Offset(-3, -3),
                                    child: AnimatedContainer(
                                      duration: Duration(milliseconds: 10),
                                      decoration: BoxDecoration(
                                        color: fillColor(appColors)!.withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(14)
                                      ),
                                    ),
                                  ),
                                  secondChild: InnerShadow(
                                    color: direction != IconPosition.LEFT
                                    ? Color(0xFF8BA7C1).withOpacity(0.48)
                                    : Colors.white.withOpacity(0.5),
                                    blur: 7,
                                    offset: direction != IconPosition.LEFT ? Offset(3, 3) : Offset(-3, -3),
                                    child: AnimatedContainer(
                                      duration: Duration(milliseconds: 10),
                                      decoration: BoxDecoration(
                                        color: fillColor(appColors),
                                        borderRadius: BorderRadius.circular(14)
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          
                  Positioned(
                    right: 15,
                    left: 15,
                    top: 15,
                    bottom: 15,
                    child: fillController.value != 0
                        ? Align(
                            alignment: direction != IconPosition.LEFT ? 
                            Alignment.centerRight : 
                            Alignment.centerLeft,
                            child: Opacity(
                              opacity: direction != IconPosition.BOTTOM ? 
                                complete ? 1 : Functions.animateOverFirst(fill, percent: 0.13) :
                          0,//, end: 0.04),
                              child: Text(
                                direction == IconPosition.BOTTOM ? '' :
                                '${(fill.abs() * 100).toStringAsFixed(0)}%',
                                style: textStyles.headline5!.copyWith(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          )
                        : Container(),
                  ),
          
                  Positioned(
                    right: 15,
                    left: 15,
                    top: 15,
                    bottom: 15,
                    child: Align(
                      alignment: direction != IconPosition.LEFT
                          ? (direction == IconPosition.BOTTOM ? Alignment.center : Alignment.centerLeft)
                          : Alignment.centerRight,
                      child: Opacity(
                        // duration: Duration(milliseconds: 100),
                        opacity: complete ? 1 : ( direction != IconPosition.BOTTOM ? Functions.animateRange(fill, start: 0, end: 0.13) :
                          Functions.animateRange(fillController.value, start: 0.0, end: 0.25) ),
                        child: Container(
                          child: Text(
                            title,
                            style: textStyles.headline5!.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  )
          
                ],
              );
            }
          ),
        ),
      ),
    );
  }
}

///Controller for the feed
class PercentBarController extends ChangeNotifier {
  _NeumorpicPercentBarState? _state;

  ///Binds the feed state
  void _bind(_NeumorpicPercentBarState bind) => _state = bind;

  //Called to notify all listners
  void _update() => notifyListeners();

  Future<void> fillBar(double value, IconPosition direction) async => _state == null ? null : await _state!.fillBar(value, direction);

  Future<void> completeFillBar(double value, [IconPosition? direction]) async => _state == null ? null : await _state!.completeFillBar(value, direction);

  //Disposes of the controller
  @override
  void dispose() {
    _state = null;
    super.dispose();
  }
}