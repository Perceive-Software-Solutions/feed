import 'dart:math';
import 'dart:ui';

import 'package:feed/providers/color_provider.dart';
import 'package:feed/util/global/functions.dart';
import 'package:feed/util/global/pollar_icons.dart';
import 'package:feed/util/icon_position.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

///Animates behind the poll card while swiping
class PollPageAnimatedIcon extends StatefulWidget {

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Constructor ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  const PollPageAnimatedIcon({ 
    Key? key, 
    this.controller, 
    required this.position, this.child, this.onContinue, 
  }): assert(position != null),
      super(key: key);

  @override
  _PollPageAnimatedIconState createState() => _PollPageAnimatedIconState();

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Variables ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  ///Controls the animation flow for this widget
  final PollPageAnimatedIconController? controller;

  ///Which corner the alginment is on
  final IconPosition position;

  ///What is displayed when the animation is complete
  final Widget? child;

  ///Function that is automatically run when there is no child
  final Function()? onContinue;
}

class _PollPageAnimatedIconState extends State<PollPageAnimatedIcon> with TickerProviderStateMixin {

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Animation State ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  ///Controls the innitial opacity animation for the icon
  late AnimationController showAnimation;

  ///Animates chnaging the size of the icon.
  ///When completed the icon swites into the defined inner widget
  late AnimationController moveAnimation;

  ///The sequence of animations that happen in accorance to moving the icon
  late Animation<double> scaleSequence;

  
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ State ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  ///Controls moving the icon into the center
  bool move = false;

  ///If the poll has been swiped away
  bool fillLock = false;

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Getters ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  // //Retreive the padding from the alignment
  // EdgeInsets get padding {
  //   if(widget.position == IconPosition.TOP) {
  //     return EdgeInsets.only(top: 24);
  //   } else if(widget.position == IconPosition.BOTTOM) {
  //     return EdgeInsets.only(bottom: 24);
  //   } else if(widget.position == IconPosition.LEFT) {
  //     return EdgeInsets.only(left: 24);
  //   } else if(widget.position == IconPosition.RIGHT) {
  //     return EdgeInsets.only(right: 24);
  //   } else {
  //     throw 'Invalid Alignment';
  //   }
  // }

  //Retreive the padding from the alignment
  Alignment? get position {
    if(widget.position == IconPosition.TOP) {
      return Alignment.topCenter;
    } else if(widget.position == IconPosition.BOTTOM) {
      return Alignment.bottomCenter;
    } else if(widget.position == IconPosition.LEFT) {
      return Alignment.centerLeft;
    } else if(widget.position == IconPosition.RIGHT) {
      return Alignment.centerRight;
    } else {
      return null;
    }
  }

  //Retreive the icon color from the alignment
  Color? get color {
    AppColor colors = ColorProvider.of(context);
    if(widget.position == IconPosition.TOP) {
      return colors.onBackground;
    } else if(widget.position == IconPosition.BOTTOM) {
      return Colors.yellow;
    } else if(widget.position == IconPosition.LEFT) {
      return colors.blue;
    } else if(widget.position == IconPosition.RIGHT) {
      return colors.red;
    } else {
      return null;
    }
  }

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Lifecycle ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  @override
  void initState() {
    super.initState();

    //Initialize the show opacity animation
    showAnimation = AnimationController(
      vsync: this,
      value: 0
    );

    //Initialize the move animation
    moveAnimation = AnimationController(
      vsync: this,
      value: 0.07,
      lowerBound: 0.07,
      duration: Duration(milliseconds: 800)
    );

    //Initialize the scale sequence
    scaleSequence = TweenSequence<double>([

      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 3.0),
        weight: 0.4
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 3.0, end: 3.0),
        weight: 0.4
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 3.0, end: 1.0),
        weight: 0.2
      ),
    ]).animate(moveAnimation);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    //Bind the controller if its defined
    widget.controller?._bind(this);
  }

  @override
  void dispose() {
    showAnimation.dispose();
    moveAnimation.dispose();

    super.dispose();
  }

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Helpers ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  void setFillLock(){
    fillLock = true;
    setState(() {});
  }

  ///Updates the show animation value
  void show(double show){
    showAnimation.animateTo(min(1.0, show), duration: Duration(milliseconds: 0));
  }

  ///Updates the show animation value
  void moveIcon(double move){
    if(!moveAnimation.isAnimating) {
      moveAnimation.animateTo(lerpDouble(0, 0.5, move / 7)!, duration: Duration.zero);
    }
  }

  ///Updates moving the icon
  void maximize(bool move){
    this.move = move;
    if(this.move){
      showAnimation.animateTo(1.0, duration: Duration(milliseconds: 0));
      moveAnimation.forward(from: moveAnimation.value);
      Future.delayed(Duration(milliseconds: (800 * (1.0 - moveAnimation.value) - 160).toInt())).then((value){
        showAnimation.animateTo(0.0, duration: Duration(milliseconds: 160));
      });
    }
    else{
      moveAnimation.animateTo(0, duration: Duration(milliseconds: 0));
      //After a delay make the icon disappear
      Future.delayed(Duration(milliseconds: 250)).then((_){
        show(0.0);
        moveIcon(0.0);
      });
    }
    if(mounted) {
      setState(() {});
    }
  }

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Build Helpers ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  ///Builds the widget that is displayed whent he animation is done moving. 
  ///When `null` the icon is displayed
  Widget? _buildCompleteView(BuildContext context){

    print("~~~~~~~~ Complete View Called ~~~~~~~~");

    if(widget.child == null && widget.onContinue != null){
      fillLock = false;
      widget.onContinue!();
    }


    return widget.child ?? Container();
  }

  ///Builds the inner icon
  Widget? _buildIcon(BuildContext context){
    if(widget.position == IconPosition.TOP) {
      return ScaleTransition(
        scale: scaleSequence,
        child: TrashCan(controller: moveAnimation)
      );
    } else if(widget.position == IconPosition.BOTTOM) {
      return Icon(Icons.star, size: 36 * scaleSequence.value, color: color,);
    } else if(widget.position == IconPosition.LEFT) {
      return Icon(Icons.check, size: 36 * scaleSequence.value, color: color);
    } else if(widget.position == IconPosition.RIGHT) {
      return Icon(Icons.cancel, size: 36 * scaleSequence.value, color: color,);
    } else {
      return null;
    }
  }

  ///Creates the inner widget which is shown within the animated opacity change
  Widget _buildMovingIcon(BuildContext context){
    return AnimatedBuilder(
      animation: scaleSequence,
      builder: (context, _) {
        return AnimatedSwitcher(
          duration: Duration(milliseconds: 800),
          transitionBuilder: (child, animation) {
            if(widget.position == IconPosition.TOP){
              return child;
            }
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: animation,
                child: child
              ),
            );
          },
          child: scaleSequence.status == AnimationStatus.reverse 
            ? SizedBox.shrink() 
            : fillLock ? (_buildCompleteView(context) ?? _buildIcon(context)) : _buildIcon(context)
        );
      }
    );
  }


  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Build ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: moveAnimation,
      builder: (context, child) {
        //move ? Alignment.center : (position ?? Alignment.center),

        double animation = Functions.animateOverFirst(moveAnimation.value, percent: 0.5);

        // AlignmentGeometry algin = _alignByOffset(position, animation) ?? Alignment.center;
        // if(widget.position == IconPosition.BOTTOM) {
        //   print('ibte ${widget.position.toString()} ${moveAnimation.value}');
        // }

        AlignmentGeometry align = (position! * (1.0 - animation)) - Alignment.center;

        if(widget.position == IconPosition.TOP || widget.position == IconPosition.BOTTOM){
          AlignmentGeometry offset =  Alignment(0, 0.06 * (widget.position == IconPosition.TOP ? -1.0 : 1.0));
          align = align.add(offset);
        }

        return Align(
          alignment: align,
          child: child
        );
      },
      child: AnimatedBuilder(
        animation: showAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: showAnimation.value,
            child: child,
          );
        },
        child: _buildMovingIcon(context),
      ),
    );
  }
}

///Controller for the feed
class PollPageAnimatedIconController extends ChangeNotifier {
  late _PollPageAnimatedIconState? _state;

  ///Binds the feed state
  void _bind(_PollPageAnimatedIconState bind) => _state = bind;

  //Called to notify all listners
  void _update() => notifyListeners();

  ///Updates the show opacity animation value
  void show([double show = 1.0]) => _retreiveState((s) => s.show(show));

  ///Updates the show opacity animation value
  void move([double move = 1.0]) => _retreiveState((s) => s.moveIcon(move));

  ///Updates the maximization of the icon
  void maximize([bool move = true]) => _retreiveState((s) => s.maximize(move));

  void setFillLock() => _retreiveState((s) => s.setFillLock());



  ///Getter for the opacity level
  double get opacity => _retreiveState((s) => s.showAnimation.value);

  //Disposes of the controller
  @override
  void dispose() {
    _state = null;
    super.dispose();
  }

  //Asserts if state is not bound
  T _retreiveState<T>(T Function(_PollPageAnimatedIconState s) onRetreive){
    assert(_state != null);
    return onRetreive(_state!);
  }

}

class TrashCan extends StatefulWidget {

  final AnimationController controller;

  const TrashCan({ 
    Key? key,
    required this.controller
  }) : super(key: key);

  @override
  _TrashCanState createState() => _TrashCanState();
}

class _TrashCanState extends State<TrashCan> with TickerProviderStateMixin {

  late AnimationController moveAnimationHorizontal; // wait(400ms) position(0,0)->position(6.79,3.79) rotation(0)->rotation(45) 200ms wait(400ms)
  late AnimationController moveAnimationVertical; // wait(600ms) 0-4 400ms
  late AnimationController rotateAnimation; // wait(200ms) 0->64 400ms 64-0 400ms
  late AnimationController trashOpacityAnimation; // 0->1 200ms wait(600ms) 1->0 200ms

  late Animation<double> opacityAnimation;
  late Animation<double> lidRotationAnimation;
  late Animation<Offset> cubeMoveAnimation;
  late Animation<double> cubeRotateAnimation;
  late Animation<double> cubeOpacityAnimation;

  @override
  void initState() {
    super.initState();

    opacityAnimation = TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0, end: 1),
        weight: 0.2
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1, end: 1),
        weight: 0.6
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1, end: 0),
        weight: 0.2
      ),
    ]).animate(widget.controller);

    cubeOpacityAnimation = TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0, end: 0),
        weight: 0.4
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0, end: 1),
        weight: 0.1
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1, end: 1),
        weight: 0.4
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1, end: 0),
        weight: 0.01
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0, end: 0),
        weight: 0.19
      ),
    ]).animate(widget.controller);

    lidRotationAnimation = TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0, end: 0),
        weight: 0.2
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0, end: 64/360),
        weight: 0.4
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 64/360, end: 0),
        weight: 0.4
      ),
    ]).animate(widget.controller);

    cubeMoveAnimation = TweenSequence<Offset>([
      TweenSequenceItem<Offset>(
        tween: Tween<Offset>(begin: Offset.zero, end: Offset.zero),
        weight: 0.4
      ),
      TweenSequenceItem<Offset>(
        tween: Tween<Offset>(begin: Offset.zero, end: Offset(6.79, 3.79)),
        weight: 0.2
      ),
      TweenSequenceItem<Offset>(
        tween: Tween<Offset>(begin: Offset(6.79, 3.79), end: Offset(6.79, 7.79)),
        weight: 0.4
      ),
    ]).animate(widget.controller);

    cubeRotateAnimation = TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0, end: 0),
        weight: 0.4
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0, end: 45/360),
        weight: 0.2
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 45/360, end: 45/360),
        weight: 0.4
      ),
    ]).animate(widget.controller);

    // moveAnimationHorizontal = AnimationController(vsync: this, value: 0, duration: Duration(milliseconds: 200));
    // moveAnimationVertical = AnimationController(vsync: this, value: 0, duration: Duration(milliseconds: 400));
    // rotateAnimation = AnimationController(vsync: this, value: 0, duration: Duration(milliseconds: 400));
    // trashOpacityAnimation = AnimationController(vsync: this, value: 0, duration: Duration(milliseconds: 200));

    // widget.controller.addStatusListener((status) {
    //   if(widget.controller.value >= 1.0 && widget.controller.isCompleted){
    //     Future.delayed(Duration(seconds: 2)).then((value) {
    //       moveAnimationHorizontal.reset();
    //       rotateAnimation.reset();
    //       trashOpacityAnimation.reset();
    //       moveAnimationVertical.reset();
    //     });
    //   }
    // });

    // widget.controller.addListener(() { 
    //   if(widget.controller.value > 0){
    //     double value = (1000/200) * widget.controller.value;
    //     if(!(value > 1.0)){
    //       trashOpacityAnimation.animateTo(value, duration: Duration(milliseconds: 0));
    //     }
    //   }
    //   if(widget.controller.value >= 0.2){
    //     double value = (1000/400) * widget.controller.value - 0.2;
    //     if(!(value > 1.0)){
    //       rotateAnimation.animateTo(value, duration: Duration(milliseconds: 0));
    //     }
    //     else{
    //       rotateAnimation.animateTo(1, duration: Duration(milliseconds: 400));
    //     }
    //   }
    //   if(widget.controller.value >= 0.4){
    //     double value = (1000/200) * widget.controller.value - 0.4;
    //     if(!(value > 1.0)){
    //       moveAnimationHorizontal.animateTo(value, duration: Duration(milliseconds: 0));
    //     }
    //     else{
    //       moveAnimationHorizontal.animateTo(1, duration: Duration(milliseconds: 200));
    //     }
    //   }
    //   if(widget.controller.value >= 0.6){
    //     double value = (1000/400) * widget.controller.value - 0.6;
    //     if(!(value > 1.0)){
    //       moveAnimationVertical.animateTo(value, duration: Duration(milliseconds: 0));
    //     }
    //     else{
    //       moveAnimationVertical.animateTo(1, duration: Duration(milliseconds: 400));
    //     }
    //   }
    //   if(widget.controller.value >= 0.8){
    //     trashOpacityAnimation.reverse();
    //   }
    // });
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (BuildContext context, Widget? child) {
        return Container(
          height: 32,
          width: 32,
          child: Stack(
            children: [
              Positioned(
                // top: moveAnimationHorizontal.value*3.79 + moveAnimationVertical.value*7,
                // left: 7 + moveAnimationHorizontal.value*6.79,
                top: cubeMoveAnimation.value.dy,
                left: 7 + cubeMoveAnimation.value.dx,
                // duration: Duration(milliseconds: 0),
                child: RotationTransition(
                  turns: cubeRotateAnimation,
                  child: Opacity(
                    opacity: cubeOpacityAnimation.value,
                    child: const Trash()
                  ),
                ),
              ),
              Positioned.fill(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    RotationTransition(
                      alignment: Alignment.centerRight,
                      turns: lidRotationAnimation,
                      child: Opacity(
                        opacity: opacityAnimation.value,
                        child: Lid(),
                      ),
                    ),
                    // RotationTransition(
                    //   alignment: Alignment.centerRight,
                    //   turns: Tween<double>(begin: 0, end: 0.178).animate(
                    //     CurvedAnimation(parent: rotateAnimation, curve: Curves.easeInOut)),
                    //   child: AnimatedOpacity(
                    //     opacity: trashOpacityAnimation.value,
                    //     duration: Duration(milliseconds: 0),
                    //     curve: Curves.easeInOut,
                    //     child: Lid()
                    //   )
                    // ),
                    // AnimatedOpacity(
                    //   opacity: trashOpacityAnimation.value,
                    //   duration: Duration(milliseconds: 0),
                    //   curve: Curves.easeInOut,
                    //   child: Bin()
                    // )
                    Opacity(
                      opacity: opacityAnimation.value,
                      // duration: Duration(milliseconds: 0),
                      // curve: Curves.easeInOut,
                      child: Bin()
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}

class Trash extends StatelessWidget {
  const Trash({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6,
      width: 6,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(1),
        color: Colors.blue,
      ),
  );
  }
}

class Bin extends StatelessWidget {
  const Bin({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget icon = SvgPicture.asset(
      'assets/Bin.svg',
      fit: BoxFit.fill,
      color: Colors.black,
      semanticsLabel: 'trashBin',
    );
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: icon,
    );
  }
}

class Lid extends StatelessWidget {
  const Lid({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget icon = SvgPicture.asset(
      'assets/Lid.svg',
      fit: BoxFit.fill,
      color: Colors.black,
      semanticsLabel: 'trashLid',
    );
    return icon;
  }
}
