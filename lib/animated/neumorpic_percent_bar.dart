import 'dart:math';
import 'dart:ui';

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
  static const Duration FAST_FILL_DURATION = Duration(milliseconds: 0);

  ///The duration for the animator when completeing a result
  static const Duration COMPLETE_FILL_DURATION = Duration(milliseconds: 600);

  ///An animation for the fill
  late AnimationController fillController;

  ///Current quadrant
  late IconPosition iconDirection;

  ///Current fill
  late CardPosition cardPosition;


  //Locks the animation
  static bool lockAnimation = false;

  ///The value of the last fill
  double oldFill = 0;

  //Set to true on complete fill
  bool complete = false;

  //Retreives the fill percentage relative to the direction
  double get fill {
    return fillController.value;
  }

  //Retreives the fill percentage relative to the direction
  double get rawFill {
    return oldFill;
  }

  ///Retreives the color based on the direction
  Color? fillColor(AppColor appColors) {
    if(iconDirection == IconPosition.BOTTOM){
      return appColors.grey;
    }
    else if(iconDirection == IconPosition.TOP){
      return appColors.yellow;
    }
    else if(iconDirection == IconPosition.LEFT){
      return appColors.red;
    }
    else if(iconDirection == IconPosition.RIGHT){
      return appColors.blue;
    }
    else{
      throw 'Invalid Type for Icon Positioning';
    }
  }

  ///Retreives the title based on the direction
  String get title {
    if(iconDirection == IconPosition.BOTTOM){
      return 'Skip';
    }
    else if(iconDirection == IconPosition.TOP){
      return 'Score';
    }
    else if(iconDirection == IconPosition.LEFT){
      return 'Disagree';
    }
    else if(iconDirection == IconPosition.RIGHT){
      return 'Agree';
    }
    else{
      throw 'Invalid Type for Icon Positioning';
    }
  }

  @override
  void initState(){
    super.initState();

    //Get position
    cardPosition = CardPosition.Left;
    
    //Get direction
    iconDirection = IconPosition.BOTTOM;

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

  Future<void> fillBar(double newFill, IconPosition newDirection, CardPosition newCardPosition, [bool overrideLock = false]) async {
    if(lockAnimation) return;

    complete = false;

    if(cardPosition != newCardPosition){

      lockAnimation = true;

      //Animate down
      await fillController.animateTo(0, duration: FAST_FILL_DURATION);

      setState(() {
        cardPosition = newCardPosition;
      });

      lockAnimation = false;

      //Animate up
      await fillController.animateTo(newFill);
    }

    if(iconDirection != newDirection){

      lockAnimation = true;

      //Animate down
      await fillController.animateTo(0, duration: FAST_FILL_DURATION);

      
      setState(() {
        iconDirection = newDirection;
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

  Future<void> completeFillBar(double newFill, [IconPosition? newDirection, CardPosition? newCardPosition]) async {
    lockAnimation = true;

    complete = true;

    if(newDirection != null && newDirection != iconDirection){
      iconDirection = newDirection;
    }

    if(newCardPosition != null && cardPosition != newCardPosition){
      cardPosition = newCardPosition;
    }
    Future.delayed(Duration.zero).then((value) {
      fillController.animateTo(newFill, duration: COMPLETE_FILL_DURATION).then((value) {
        lockAnimation = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    ///General app styles
    final appColors = ColorProvider.of(context);

    //Text style provider
    final textStyles = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(1),
      child: Container(
        decoration: BoxDecoration(
          color: appColors.background,
          borderRadius: BorderRadius.circular(16)),
        child: AnimatedBuilder(
          animation: fillController,
          builder: (context, _) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Container(
                height: 52,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: fillColor(appColors)!.withOpacity(0.15),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: FractionallySizedBox(
                        widthFactor: 1,
                        child: AnimatedAlign(
                          duration: Duration(milliseconds: 10),
                          alignment: cardPosition != CardPosition.Left ? Alignment.centerLeft : Alignment.centerRight,
                          child: FractionallySizedBox(
                            widthFactor: fill,
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 10),
                              decoration: BoxDecoration(
                                color: fillColor(appColors)!.withOpacity(0.7),
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
                      child: fillController.value != 0 ? Align(
                        alignment: cardPosition != CardPosition.Left ? 
                        Alignment.centerRight : 
                        Alignment.centerLeft,
                        child: Opacity(
                          opacity:
                            complete ? 1 : Functions.animateOverFirst(fill, percent: 0.13),//, end: 0.04),
                          child: Text(
                            iconDirection == IconPosition.BOTTOM ? '' :
                            '${(fill.abs() * 100).toStringAsFixed(0)}%',
                            style: textStyles.headline5!.copyWith(
                              fontSize: 16,
                              color: Colors.black,
                              fontWeight: FontWeight.w600
                            ),
                          ),
                        ),
                      ) : Container(),
                    ),

                    // Other Text
                    Positioned(
                      right: 15,
                      left: 15,
                      top: 15,
                      bottom: 15,
                      child: Align(
                        alignment: cardPosition != CardPosition.Left ? Alignment.centerLeft : Alignment.centerRight,
                        child: Opacity(
                          opacity: complete ? 1 : ( Functions.animateRange(fill, start: 0, end: 0.13) ),
                          child: Container(
                            child: Text(
                              title,
                              style: textStyles.headline5!.copyWith(
                                fontSize: 16,
                                color: Colors.black,
                                fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ) 
              ),
            );
            // return Stack(
            //   children: [
            //     // Background Color
            //     Container(
            //       height: 52,
            //       width: double.infinity,
            //       decoration: BoxDecoration(
            //         color: fillColor(appColors)!.withOpacity(0.15),
            //         borderRadius: BorderRadius.circular(28)),
            //     ),
            //     //Percent bar fill
            //     Positioned.fill(
            //       child: FractionallySizedBox(
            //         widthFactor: 1,
            //         child: AnimatedAlign(
            //           duration: Duration(milliseconds: 10),
            //           alignment: cardPosition != CardPosition.Left ? 
            //           Alignment.centerLeft : 
            //           Alignment.centerRight,
            //           child: FractionallySizedBox(
            //             widthFactor: fill,
            //             child: AnimatedContainer(
            //               duration: Duration(milliseconds: 10),
            //               decoration: BoxDecoration(
            //                 color: fillColor(appColors)!.withOpacity(0.7),
            //                 borderRadius: cardPosition == CardPosition.Left ? 
            //                 BorderRadius.only(topRight: Radius.circular(28), bottomRight: Radius.circular(28)) : 
            //                 BorderRadius.only(topLeft: Radius.circular(28), bottomLeft: Radius.circular(28))
            //               ),
            //             ),
            //           ),
            //         ),
            //       ),
            //     ),
                
            //     // Skip Text
            //     Positioned(
            //       right: 15,
            //       left: 15,
            //       top: 15,
            //       bottom: 15,
            //       child: fillController.value != 0 ? Align(
            //         alignment: cardPosition != CardPosition.Left ? 
            //         Alignment.centerRight : 
            //         Alignment.centerLeft,
            //         child: Opacity(
            //           opacity:
            //             complete ? 1 : Functions.animateOverFirst(fill, percent: 0.13),//, end: 0.04),
            //           child: Text(
            //             iconDirection == IconPosition.BOTTOM ? '' :
            //             '${(fill.abs() * 100).toStringAsFixed(0)}%',
            //             style: textStyles.headline5!.copyWith(
            //                 color: Colors.black,
            //                 fontWeight: FontWeight.w600),
            //           ),
            //         ),
            //       ) : Container(),
            //     ),

            //     // Other Text
            //     Positioned(
            //       right: 15,
            //       left: 15,
            //       top: 15,
            //       bottom: 15,
            //       child: Align(
            //         alignment: cardPosition != CardPosition.Left ? Alignment.centerLeft : Alignment.centerRight,
            //         child: Opacity(
            //           opacity: complete ? 1 : ( Functions.animateRange(fill, start: 0, end: 0.13) ),
            //           child: Container(
            //             child: Text(
            //               title,
            //               style: textStyles.headline5!.copyWith(
            //                 color: Colors.black,
            //                 fontWeight: FontWeight.w600),
            //             ),
            //           ),
            //         ),
            //       ),
            //     )
        
            //   ],
            // );
          }
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

  Future<void> fillBar(double value, IconPosition direction, CardPosition cardPosition, [bool overrideLock = false]) async => _state == null ? null : await _state!.fillBar(value, direction, cardPosition);

  Future<void> completeFillBar(double value, [IconPosition? direction, CardPosition? cardPosition]) async => _state == null ? null : await _state!.completeFillBar(value, direction, cardPosition);

  //Disposes of the controller
  @override
  void dispose() {
    _state = null;
    super.dispose();
  }
}