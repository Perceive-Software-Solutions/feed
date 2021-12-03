import 'dart:ui';

import 'package:feed/providers/color_provider.dart';
import 'package:feed/util/global/functions.dart';
import 'package:feed/util/icon_position.dart';
import 'package:flutter/material.dart';

///NeumorpicPercentBar widget is a percent bar that is not bounded horizontally.
///The percent bar has 2 sides and contains a value for the percentage.
///The animation for the percent bar cna be controlled by a parent widget.
class NeumorpicPercentBar extends StatefulWidget {

  ///Controller for the percent bar
  final PercentBarController controller;

  final TextStyle? style;


  const NeumorpicPercentBar({Key? key, required this.controller, this.style}) : 
  super(key: key);

  @override
  _NeumorpicPercentBarState createState() => _NeumorpicPercentBarState();
}

class _NeumorpicPercentBarState extends State<NeumorpicPercentBar> with TickerProviderStateMixin {

  ///The duration for the animator
  static const Duration FILL_DURATION = Duration(milliseconds: 200);

  ///The duration for the animator when switching sides
  static const Duration FAST_FILL_DURATION = Duration(milliseconds: 0);

  ///An animation for the fill
  late AnimationController fillController;

  ///Current quadrant
  late IconPosition? iconDirection;

  ///Current fill
  CardPosition? cardPosition;

  //Locks the animation
  static bool lockAnimation = false;

  ///The value of the last fill
  double oldFill = 0;

  //Set to true on complete fill
  bool complete = false;

  Duration alignmentDuration = Duration(milliseconds: 0);

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
      return appColors.yellow;
    }
    else if(iconDirection == IconPosition.TOP){
      return appColors.grey;
    }
    else if(iconDirection == IconPosition.LEFT){
      return appColors.red;
    }
    else if(iconDirection == IconPosition.RIGHT){
      return appColors.blue;
    }
    else{
      return appColors.grey;
    }
  }

  ///Retreives the title based on the direction
  String get title {
    if(iconDirection == IconPosition.BOTTOM){
      return 'Trust';
    }
    else if(iconDirection == IconPosition.TOP){
      return 'Skip';
    }
    else if(iconDirection == IconPosition.LEFT){
      return 'Disagree';
    }
    else if(iconDirection == IconPosition.RIGHT){
      return 'Agree';
    }
    else{
      return '';
    }
  }

  AlignmentGeometry get alignment{
    if(cardPosition == CardPosition.Left){
      return Alignment.centerRight;
    }
    else{
      return Alignment.centerLeft;
    }
  }

  @override
  void initState(){
    super.initState();

    //Get position
    cardPosition = CardPosition.Right;
    
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

  Future<void> fillBar(double newFill, IconPosition? newDirection, CardPosition newCardPosition, [bool overrideLock = false]) async {
    if(lockAnimation) return;

    complete = false;

    if(cardPosition != newCardPosition){

      lockAnimation = true;

      setState(() {
        cardPosition = newCardPosition;
      });

      lockAnimation = false;

      //Animate up
      await fillController.animateTo(newFill);
    }

    if(iconDirection != newDirection){

      lockAnimation = true;

      
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

  Future<void> completeFillBar(double newFill, Duration duration, [IconPosition? newDirection, CardPosition? newCardPosition]) async {

    if(newCardPosition != null && cardPosition != newCardPosition){
      setState(() {
        cardPosition = newCardPosition;
      });
    }
    WidgetsBinding.instance!.addPostFrameCallback((_) {

      lockAnimation = true;

      fillController.stop();

      complete = true;

      if(newDirection != null && newDirection != iconDirection){
        iconDirection = newDirection;
      }

      fillController.animateTo(newFill, duration: duration).then((value) {
        lockAnimation = false;
      }).then((value) {
          print(fillController.value);
      });
      setState(() {
        
      });
    });
  }

  void setDirection(IconPosition newIconPosition, CardPosition newCardPosition){
    setState(() {
      lockAnimation = true;
      iconDirection = newIconPosition;
      cardPosition = newCardPosition;
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
                  color: iconDirection == IconPosition.BOTTOM ? fillColor(appColors)!.withOpacity(0.25) : fillColor(appColors)!.withOpacity(0.15),
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
                                color: fillColor(appColors),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 16,
                      left: 16,
                      top: 16.5,
                      bottom: 16.5,
                      child: fillController.value != 0 ? Align(
                        alignment: cardPosition != CardPosition.Left ? 
                        Alignment.centerRight : 
                        Alignment.centerLeft,
                        child: Text(
                          iconDirection == IconPosition.TOP ? '' :
                          '${(fill.abs() * 100).toStringAsFixed(0)}%',
                          style: textStyles.headline5!.copyWith(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.w600
                          ),
                        ),
                      ) : Container(),
                    ),

                    // Other Text
                    Positioned(
                      right: 16,
                      left: 16,
                      top: 16.5,
                      bottom: 16.5,
                      child: AnimatedAlign(
                        duration: iconDirection == IconPosition.TOP && complete ? Duration(milliseconds: 600) : Duration(milliseconds: 0),
                        alignment: (complete && iconDirection == IconPosition.TOP) ? Alignment.center : alignment,
                        child: Container(
                          child: Text(
                            title,
                            textAlign: cardPosition != CardPosition.Left ? TextAlign.left : TextAlign.right,
                            style: widget.style != null ? widget.style! : TextStyle(fontSize: 16, letterSpacing: -0.32, height: 1.188, fontWeight: FontWeight.w600)
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

  Future<void> fillBar(double value, IconPosition? direction, CardPosition cardPosition, [bool overrideLock = false]) async => _state == null ? null : await _state!.fillBar(value, direction, cardPosition);

  Future<void> completeFillBar(double value, Duration duration, [IconPosition? direction, CardPosition? cardPosition]) async => _state == null ? null : await _state!.completeFillBar(value, duration, direction, cardPosition);

  void setDirection(IconPosition iconPosition, CardPosition cardPosition) => _state == null ? null : _state!.setDirection(iconPosition, cardPosition);

  //Disposes of the controller
  @override
  void dispose() {
    _state = null;
    super.dispose();
  }
}