import 'dart:ui';

import 'package:feed/util/global/functions.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:math';

/*

  _____ _   _ _   _ __  __ 
  | ____| \ | | | | |  \/  |
  |  _| |  \| | | | | |\/| |
  | |___| |\  | |_| | |  | |
  |_____|_| \_|\___/|_|  |_|
                            

*/

///Enum for the rotation
enum SwipeCardAngle{
  None,
  Top,
  Bottom
}

// background opac: 75%, inner shadow 1x, 1y, 1blur white 25%opac duration 0.09s

///Swipe card is used to provide a widget with left or right swipe abilities
///The card respondes to left/right/up/down swipes and calls a respective function when swiped
class SwipeCard extends StatefulWidget {


  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Constants ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  ///The relative scale of the smaller card behind this card
  static const double CARD_MINIMIZE_SCALE = 0.9147;

  ///Flat offset to the threshold
  static const double THRESHOLD_OFFSET = 36.0 + 50.0; //Icon offset + icon size

  ///Additional vertial offset on the threshold
  static const EdgeInsets THRESHOLD_VERTICAL_PADDING = EdgeInsets.only(bottom: 5, top: 47);

  /*
 
    ____                _                   _             
   / ___|___  _ __  ___| |_ _ __ _   _  ___| |_ ___  _ __ 
  | |   / _ \| '_ \/ __| __| '__| | | |/ __| __/ _ \| '__|
  | |__| (_) | | | \__ \ |_| |  | |_| | (__| || (_) | |   
   \____\___/|_| |_|___/\__|_|   \__,_|\___|\__\___/|_|   
                                                          

*/

  const SwipeCard({
    Key? key,
    this.swipable = false,
    this.controller,
    required this.onSwipe,
    this.child,
    this.onPanUpdate,
    this.opacityChange = false,
  }) : super(key: key);

  @override
  _SwipeCardState createState() => _SwipeCardState();


  /*
 
  __     __         _       _     _           
  \ \   / /_ _ _ __(_) __ _| |__ | | ___  ___ 
   \ \ / / _` | '__| |/ _` | '_ \| |/ _ \/ __|
    \ V / (_| | |  | | (_| | |_) | |  __/\__ \
     \_/ \__,_|_|  |_|\__,_|_.__/|_|\___||___/
                                              
 
*/

  final SwipeCardController? controller;

  ///Disbales all swiping on the card
  final bool swipable;

  ///Call back function that calls the onSwipe with the DismissDirection
  final Function(double dx, double dy, DismissDirection)? onSwipe;

  ///The internal child widget
  final Widget? child;
  
  ///The function that runs when the pan is updated
  final Function(double dx, double dy)? onPanUpdate;

  ///whether or not the card should fade out opacity
  final bool opacityChange;
}

class _SwipeCardState extends State<SwipeCard> with TickerProviderStateMixin {
  
  /*
 
    ____                _              _       
   / ___|___  _ __  ___| |_ __ _ _ __ | |_ ___ 
  | |   / _ \| '_ \/ __| __/ _` | '_ \| __/ __|
  | |__| (_) | | | \__ \ || (_| | | | | |_\__ \
   \____\___/|_| |_|___/\__\__,_|_| |_|\__|___/
                                               
 
*/

  ///The Duration X for swiping
  static const Duration SWIPE_DURATION_X = Duration(milliseconds: 300); 

  ///The Duration Y for swiping
  static const Duration SWIPE_DURATION_Y = Duration(milliseconds: 300); 

  ///The Duration X for swiping
  static const Duration FLING_DURATION = Duration(milliseconds: 300); 

  ///The Duration Y for swiping
  // static const Duration FLING_DURATION = Duration(milliseconds: 120); 

  ///Pan delay, ratio of the pan delta
  static const double PAN_DELAY_RATIO = 0.8; 

  ///Ratio of the screen that determines the X Swipe Limit
  static const double SWIPE_LIMIT_X = 439.5/375; 

  ///Ratio of the screen that determines the Y Swipe Limit
  static const double SWIPE_LIMIT_Y = 756/812; 

  ///The minimum velocity to be considered a fling
  static const double MIN_FLING_VELOCITY = 3500;

  ///The minimum distance to be considered a fling
  static const double MIN_FLING_DISTANCE = 92;

  ///The minimum distance to be considered a fling
  static const Curve SWIPE_CURVE = Curves.linear;

  ///The minimum distance to be considered a fling
  // static const Curve SPRING_CURVE = ElasticInCurve(0.4);

  /*
 
    ____                _              _     ____  _        _       
   / ___|___  _ __  ___| |_ __ _ _ __ | |_  / ___|| |_ __ _| |_ ___ 
  | |   / _ \| '_ \/ __| __/ _` | '_ \| __| \___ \| __/ _` | __/ _ \
  | |__| (_) | | | \__ \ || (_| | | | | |_   ___) | || (_| | ||  __/
   \____\___/|_| |_|___/\__\__,_|_| |_|\__| |____/ \__\__,_|\__\___|
                                                                    
 
*/

  //Set on first fram build, based on widget size

  ///Determines the horizontal swipe thresh holds
  double horizontalSwipeThresh = 10000;
  ///Determines the top swipe thresh holds
  double topSwipeThresh = 10000;
  ///Determines the bottom swipe thresh holds
  double bottomSwipeThresh = 10000;

  /*
 
      _          _                 _   _               ____  _        _       
     / \   _ __ (_)_ __ ___   __ _| |_(_) ___  _ __   / ___|| |_ __ _| |_ ___ 
    / _ \ | '_ \| | '_ ` _ \ / _` | __| |/ _ \| '_ \  \___ \| __/ _` | __/ _ \
   / ___ \| | | | | | | | | | (_| | |_| | (_) | | | |  ___) | || (_| | ||  __/
  /_/   \_\_| |_|_|_| |_| |_|\__,_|\__|_|\___/|_| |_| |____/ \__\__,_|\__\___|
                                                                              
 
*/

  ///Controls the right swipe animation
  late AnimationController rightSwiper = AnimationController(duration: Duration.zero, vsync: this);
  ///Controls the left swipe animation
  late AnimationController leftSwiper = AnimationController(duration: Duration.zero, vsync: this);
  ///Controls the down swipe animation
  late AnimationController downSwiper = AnimationController(duration: Duration.zero, vsync: this);
  ///Controls the up swipe animation
  late AnimationController upSwiper = AnimationController(duration: Duration.zero, vsync: this);

  ///Holds the value change over the right swiper
  late Animation<double> rightAnimation;
  ///Holds the value change over the left swiper
  late Animation<double> leftAnimation;
  ///Holds the value change over the down swiper
  late Animation<double> downAnimation;
  ///Holds the value change over the up swiper
  late Animation<double> upAnimation;

  /*
 
   ____                _             ____  _        _       
  |  _ \ ___ _ __   __| | ___ _ __  / ___|| |_ __ _| |_ ___ 
  | |_) / _ \ '_ \ / _` |/ _ \ '__| \___ \| __/ _` | __/ _ \
  |  _ <  __/ | | | (_| |  __/ |     ___) | || (_| | ||  __/
  |_| \_\___|_| |_|\__,_|\___|_|    |____/ \__\__,_|\__\___|
                                                            
 
*/

  ///Holds the x drag value that transforms the position of the card
  double xDrag = 0;
  ///Holds the y drag value that transforms the position of the card
  double yDrag = 0;

  ///Determines the angle
  SwipeCardAngle rotation = SwipeCardAngle.None;

  /*
 
   ____  _        _       
  / ___|| |_ __ _| |_ ___ 
  \___ \| __/ _` | __/ _ \
   ___) | || (_| | ||  __/
  |____/ \__\__,_|\__\___|
                          
 
*/

  //Determines if the card is swipable
  bool swipable = false;

  ///Locks the haptic feedback
  Map<DismissDirection, bool> hapticLock = {
    DismissDirection.up: false, //top
    DismissDirection.down: false, //down
    DismissDirection.endToStart: false, //right
    DismissDirection.startToEnd: false, //left
  };

  /*
 
    ____      _   _                
   / ___| ___| |_| |_ ___ _ __ ___ 
  | |  _ / _ \ __| __/ _ \ '__/ __|
  | |_| |  __/ |_| ||  __/ |  \__ \
   \____|\___|\__|\__\___|_|  |___/
                                   
 
*/

  ///The distance the card is dimissed to in the X direction
  double get cardSwipeLimitX => 30 + SWIPE_LIMIT_X * MediaQuery.of(context).size.width;
  ///The distance the card is dimissed to in the Y direction
  double get cardSwipeLimitY => 30 + SWIPE_LIMIT_Y * MediaQuery.of(context).size.height;

  ///Calculates the rotation
  double get angle => lerpDouble(0, 10, xDrag / MediaQuery.of(context).size.width)! / 45;

  ///Returns an animation controller based of given direction
  AnimationController swiper(DismissDirection direction){
    switch (direction) {
      case DismissDirection.startToEnd:
        return rightSwiper;
      case DismissDirection.endToStart:
        return leftSwiper;
      case DismissDirection.up:
        return upSwiper;
      case DismissDirection.down:
        return downSwiper;
      default:
        return rightSwiper;
    }
  }

  /// Returns the animation values based on a DimissDirection
  double value(DismissDirection direction){
    switch (direction) {
      case DismissDirection.startToEnd:
        return rightSwiper.value;
      case DismissDirection.endToStart:
        return leftSwiper.value;
      case DismissDirection.up:
        return upSwiper.value;
      case DismissDirection.down:
        return downSwiper.value;
      default:
        return rightSwiper.value;
    }
  }

  /*
 
   _     _  __                      _      
  | |   (_)/ _| ___  ___ _   _  ___| | ___ 
  | |   | | |_ / _ \/ __| | | |/ __| |/ _ \
  | |___| |  _|  __/ (__| |_| | (__| |  __/
  |_____|_|_|  \___|\___|\__, |\___|_|\___|
                         |___/             
 
*/

  @override
  void initState() {
    super.initState();

    //Set swipable
    setSwipeable(widget.swipable);

    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      //Determines the thresholds
      _determineThresholds();

      //Define the animations
      _defineAnimations();
    });
    
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    //Bind the controller if it is defined
    widget.controller?._bind(this);
  }

  @override
  void didUpdateWidget(covariant SwipeCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    //Update swipable
    if(oldWidget.swipable != widget.swipable){
      setSwipeable(widget.swipable);
    }
  }

  @override
  void dispose(){

    //Dispose the animations
    try{
      rightSwiper.dispose();
      leftSwiper.dispose();
      upSwiper.dispose();
      downSwiper.dispose();
    }catch(e){
      debugPrint('$e');
    }

    super.dispose();
  }

  /*
 
   _   _      _                     
  | | | | ___| |_ __   ___ _ __ ___ 
  | |_| |/ _ \ | '_ \ / _ \ '__/ __|
  |  _  |  __/ | |_) |  __/ |  \__ \
  |_| |_|\___|_| .__/ \___|_|  |___/
               |_|                  
 
*/

  //Controls enabling gestures on the card
  void setSwipeable(bool swipe){
    bool newSwipe = swipe; //defaults to true

    //Prevent set state on no state change
    if(newSwipe != swipable){
      swipable = newSwipe;
      // if(mounted) {
      //   setState(() {});
      // }
    }

  }

  ///Reverses any completed animation
  void reverse(){

    setState(() {
      rotation = SwipeCardAngle.None;

      //Unlock haptic
      for(var direction in hapticLock.keys){
        hapticLock[direction] = false;
      }
    });

    //List of animation controllers for this widget
    List<AnimationController> animations = [leftSwiper, rightSwiper, downSwiper, upSwiper];
    List<Duration> durations = [];

    ///Find out durations
    for(AnimationController animation in animations){
      if(animation.value != 0){
        animation.duration = Duration(milliseconds: (200 ~/ animation.value));
      }
      else{
        durations.add(Duration(milliseconds: 0));
      }
    }

    ///Reverse Animations
    leftSwiper.reverse();
    rightSwiper.reverse();
    downSwiper.reverse();
    upSwiper.reverse();
  }

  void _haptic(DismissDirection direction, double value, double delta){

    double thresh = 0;
    switch (direction) {
      case DismissDirection.up:
        thresh = topSwipeThresh;
        break;
      case DismissDirection.down:
        thresh = bottomSwipeThresh;
        break;
      default:
        thresh = horizontalSwipeThresh;
    }

    //Determines lock
    bool lock = hapticLock[direction]!;

    //Haptic when you are past the
    if(value.abs() > thresh && delta > 0 && !lock && !hapticLock.containsValue(true)){
      hapticLock[direction] = true;
      Functions.hapticSwipeVibrate();
    }
    else if(lock && delta < 0 && value.abs() < thresh){
      hapticLock[direction] = false;
      Functions.hapticSwipeVibrate();
    }

  }

  ///Determines the opacity of the card relative to any animating animation
  @deprecated
  double _cardFadeOutOpacity() {
    //Gets the value of the animation if it is animating
    double value = 0;
    if (leftAnimation == null && rightAnimation == null && downAnimation == null && upAnimation == null) {
      value = 0;
    }
    return (cardSwipeLimitX - value) / cardSwipeLimitX; //Gets the opacity ratio
  }

  /*
 
   ___       _ _   _       _ _                  
  |_ _|_ __ (_) |_(_) __ _| (_)_______ _ __ ___ 
   | || '_ \| | __| |/ _` | | |_  / _ \ '__/ __|
   | || | | | | |_| | (_| | | |/ /  __/ |  \__ \
  |___|_| |_|_|\__|_|\__,_|_|_/___\___|_|  |___/
                                                
 
*/

  ///Determines the max thresh holds for the swipe card based on its size. 
  ///Runs after innitial frame
  void _determineThresholds(){
    //Set the max horizaontal and vertial swipe thresholds
    horizontalSwipeThresh = 92.0;
    bottomSwipeThresh = 157;
    topSwipeThresh = 92.0;

  }
  
  ///Creates the swipe animations
  void _defineAnimations(){
    //Define Right Swipe animation
    rightAnimation = Tween<double>(begin: 0, end: cardSwipeLimitX).animate(CurvedAnimation(parent: rightSwiper, curve: SWIPE_CURVE, reverseCurve: SWIPE_CURVE))
      ..addListener(() {
        setState(() {
          //Update the xdrag
          xDrag = rightAnimation.value;

          //Calls any  binded call backs
          if(widget.onPanUpdate != null)
            widget.onPanUpdate!(xDrag, yDrag);
        });
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && rightSwiper.value == 1.0) {
          //on complete send signal
          // widget.onSwipe!(DismissDirection.startToEnd);

          //Reset duration
          rightSwiper.duration = Duration.zero;
        }
      });

    //Define Left Swipe animation
    leftAnimation = Tween<double>(begin: 0, end: -1 * cardSwipeLimitX).animate(CurvedAnimation(parent: leftSwiper, curve: SWIPE_CURVE, reverseCurve: SWIPE_CURVE))
      ..addListener(() {
        setState(() {
          //Update the xdrag
          xDrag = leftAnimation.value;

          //Calls any  binded call backs
          if(widget.onPanUpdate != null)
            widget.onPanUpdate!(xDrag, yDrag);
        });
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && leftSwiper.value == 1.0) {
          //on complete send signal
          // widget.onSwipe!(DismissDirection.endToStart);

          //Reset duration
          leftSwiper.duration = Duration.zero;
        }
      });

    //Define Down Swipe animation
    downAnimation = Tween<double>(begin: 0, end: cardSwipeLimitY).animate(CurvedAnimation(parent: downSwiper, curve: SWIPE_CURVE, reverseCurve: SWIPE_CURVE))
      ..addListener((){
        setState(() {
          //Update the ydrag
          yDrag = downAnimation.value;

          //Calls any  binded call backs
          if(widget.onPanUpdate != null)
            widget.onPanUpdate!(xDrag, yDrag);
        });
      })
      ..addStatusListener((status) { 
        if(status == AnimationStatus.completed && downSwiper.value == 1.0){
          //on complete send signal
          // widget.onSwipe!(DismissDirection.down);

          //Reset duration
          downSwiper.duration = Duration.zero;
        }
      });

    //Define Up Swipe animation
    upAnimation = Tween<double>(begin: 0, end: cardSwipeLimitY * -1).animate(CurvedAnimation(parent: upSwiper, curve: SWIPE_CURVE, reverseCurve: SWIPE_CURVE))
      ..addListener(() { 
        setState(() {
          //Update the ydrag
          yDrag = upAnimation.value;

          //Calls any  binded call backs
          if(widget.onPanUpdate != null)
            widget.onPanUpdate!(xDrag, yDrag);
        });
      })
      ..addStatusListener((status) { 
        if(status == AnimationStatus.completed && upSwiper.value == 1.0){
          //on complete send signal
          // widget.onSwipe!(DismissDirection.up);

          //Reset duration
          upSwiper.duration = Duration.zero;
        }
      });
  }

  /*
 
    ____           _                       
   / ___| ___  ___| |_ _   _ _ __ ___  ___ 
  | |  _ / _ \/ __| __| | | | '__/ _ \/ __|
  | |_| |  __/\__ \ |_| |_| | | |  __/\__ \
   \____|\___||___/\__|\__,_|_|  \___||___/
                                           
 
*/

  ///Called when the pan gesture starts
  void _onPanStart(DragStartDetails d){

    if (swipable != true) return;

    //The point on the screen that determines the different angles
    double divider = MediaQuery.of(context).size.height / 2;

    if(d.globalPosition.dy > divider){
      //Bottom angle
      setState(() {
        rotation = SwipeCardAngle.Bottom;
      });
    }
    else{
      //Bottom angle
      setState(() {
        rotation = SwipeCardAngle.Top;
      });
    }

  }

  ///Called whenever the user finger is panning accross the screen
  void _onPanUpdate(DragUpdateDetails d) {

    if (swipable != true) return;
    
    //Updtes the card position
    _updateSwipers(d.delta.dx, d.delta.dy);

    //Calls any  binded call backs
    if(widget.onPanUpdate != null)
      widget.onPanUpdate!(xDrag, yDrag);
  }

  ///Called when the user finger is lifted after a pan
  void _onPanEnd(DragEndDetails d) async {

    if (swipable != true) return;
    
    //Determines the swipe direction if there is a signal
    DismissDirection? startSwipeSignal;

    //Determine fling
    bool fling = (d.velocity.pixelsPerSecond.distance) >= MIN_FLING_VELOCITY;
    
    if(fling){ //Fling
      startSwipeSignal = _flingCard(d.velocity.pixelsPerSecond);
    }
    else{  //Swipe
      startSwipeSignal = _swipeCard();
    }
    

    if(startSwipeSignal == null){
      //Otherwise reset the positions
      reverse();
    }
  }

  /// Swiped card in a specified direction
  void swipe(DismissDirection direction){
    AnimationController controller = swiper(direction);
    controller.duration = FLING_DURATION;
    controller.forward(from: xDrag / cardSwipeLimitX); //animate
    widget.onSwipe!(100, 0, DismissDirection.startToEnd);
    swipable = false;
  }

  ///Manages flinding gestures on the card
  DismissDirection? _flingCard(Offset velocity){
    double flingX = velocity.dx;
    double flingY = velocity.dy;
    double vectorX = flingX/sqrt(pow(flingX, 2) + pow(flingY, 2));
    double vectorY = flingY/sqrt(pow(flingX, 2) + pow(flingY, 2));
    if(flingX.abs() > flingY.abs() && xDrag.abs() > MIN_FLING_DISTANCE || xDrag.abs() > yDrag.abs()){
      
      if(flingX > 0){
        rightSwiper.duration = FLING_DURATION;
        // rightSwiper.forward(from: xDrag / cardSwipeLimitX); //animate
        rightSwiper.forward(from: xDrag / cardSwipeLimitX).then((value) {
          rightSwiper.forward();
        });
        if(vectorY.abs() >= 0.45){
          if(flingY > 0){
            downSwiper.animateTo(vectorY.abs(), duration: FLING_DURATION);
          }
          else{
            upSwiper.animateTo(vectorY.abs(), duration: FLING_DURATION);
          }
        }
        // _haptic(startSwipeSignal, 1000, 1);
        widget.onSwipe!(flingX, flingY, DismissDirection.startToEnd);
        swipable = false;
        return DismissDirection.startToEnd; //set signal
      }
      else{
        leftSwiper.duration = FLING_DURATION;
        leftSwiper.forward(from: xDrag.abs() / cardSwipeLimitX).then((value) {
          leftSwiper.forward();
        }); //animate
        if(vectorY.abs() > 0.45){
          if(flingY > 0){
            downSwiper.animateTo(vectorY.abs(), duration: FLING_DURATION);
          }
          else{
            upSwiper.animateTo(vectorY.abs(), duration: FLING_DURATION);
          }
        }
        // _haptic(startSwipeSignal, 1000, 1);
        widget.onSwipe!(flingX, flingY, DismissDirection.endToStart);
        swipable = false;
        return DismissDirection.endToStart; //set signal
      }
    }
    else if(yDrag.abs() > MIN_FLING_DISTANCE){
      // print('AHH ${xDrag.abs() > yDrag.abs()}');
      if(flingY > 0){
        downSwiper.duration = FLING_DURATION;
        downSwiper.forward(from: yDrag / cardSwipeLimitY).then((value) {
          downSwiper.forward();
        }); //animate
        if(vectorX > 0.45){
          if(flingX > 0){
            rightSwiper.animateTo(vectorX.abs(), duration: FLING_DURATION);
            }
            else{
              leftSwiper.animateTo(vectorX.abs(), duration: FLING_DURATION);
            }
        }
        // _haptic(startSwipeSignal, 1000, 1);
        widget.onSwipe!(flingX, flingY, DismissDirection.down);
        swipable = false;
        return DismissDirection.down; //set signal
      }
      else{
        upSwiper.duration = FLING_DURATION;
        upSwiper.forward(from: yDrag.abs() / cardSwipeLimitY).then((value) {
          upSwiper.forward();
        }); //animate
        if(vectorX > 0.45){
          if(flingX > 0){
            rightSwiper.animateTo(vectorX, duration: FLING_DURATION);
          }
          else{
            leftSwiper.animateTo(vectorX, duration: FLING_DURATION);
          }
        }
        // _haptic(startSwipeSignal, 1000, 1);
        widget.onSwipe!(flingX, flingY, DismissDirection.up);
        swipable = false;
        return DismissDirection.up; //set signal
      }
    }

    return null;
  }

  ///Manages swiping gestures on the card
  DismissDirection? _swipeCard(){
    //Height of the screen
    final height = MediaQuery.of(context).size.height;

    //Width of the screen
    final width = MediaQuery.of(context).size.width;

    // Diagonal slope of the screen
    final slope = height/width;

    /// Vertical Length to the slope
    double verticalLength = slope*xDrag.abs();

    /// Horizontal Length to the slope
    double horizontalLength = slope*yDrag.abs();

    //Right swipe after threshhold
    if (xDrag >= horizontalSwipeThresh && yDrag >= verticalLength*-1 && yDrag <= verticalLength) {
      rightSwiper.duration = SWIPE_DURATION_X;

      rightSwiper.forward(from: xDrag / cardSwipeLimitX); //animate
      widget.onSwipe!(xDrag, yDrag, DismissDirection.startToEnd);
      swipable = false;
      return DismissDirection.startToEnd; //set signal
    }
    //Left swipe after threshhold
    else if (xDrag <= -1 * horizontalSwipeThresh && yDrag >= verticalLength*-1 && yDrag <= verticalLength) {
      leftSwiper.duration = SWIPE_DURATION_X;

      leftSwiper.forward(from: xDrag.abs() / cardSwipeLimitX); //animate
      widget.onSwipe!(xDrag, yDrag, DismissDirection.endToStart);
      swipable = false;
      return DismissDirection.endToStart; //set signal
    }
    //Down Swipe after threshold
    else if (yDrag >= bottomSwipeThresh && xDrag > horizontalLength*-1 && xDrag < horizontalLength) {
      downSwiper.duration = SWIPE_DURATION_Y;

      downSwiper.forward(from: yDrag / cardSwipeLimitY); //animate
      widget.onSwipe!(xDrag, yDrag, DismissDirection.down);
      swipable = false;
      return DismissDirection.down; //set signal
    } 
    //Up Swipe after threshold
    else if(yDrag <= -1 * topSwipeThresh && xDrag > horizontalLength*-1 && xDrag < horizontalLength) {
      upSwiper.duration = SWIPE_DURATION_Y;

      upSwiper.forward(from: yDrag.abs() / cardSwipeLimitY); //animate
      widget.onSwipe!(xDrag, yDrag, DismissDirection.up);
      swipable = false;
      return DismissDirection.up; //set signal
    }

    return null;
  }

  ///Updates the swipers delative to a pan update chnage in delta
  void _updateSwipers(double ddx, double ddy){

    //Inner helper used to update the swipers in parrallel directions
    void _updateDirectionalSwiper(
      double delta, 
      double limit, 
      AnimationController positve, 
      AnimationController negative,
      double currentValue,
      DismissDirection positiveDirection,
      DismissDirection negativeDirection
    ){

      //The delta relative to the animation
      double animationDelta = delta * PAN_DELAY_RATIO / limit;

      //Updates the postive swiper
      if((delta > 0 && negative.value <= 0) || positve.value > 0){

        _haptic(positiveDirection, currentValue, delta);

        positve.animateTo(positve.value + animationDelta, duration: Duration.zero);
      }

      //Updates the negative swiper
      else if(delta < 0 || negative.value > 0){

        _haptic(negativeDirection, currentValue, -1*delta);

        negative.animateTo(negative.value + (-1* animationDelta), duration: Duration.zero);
      }

    }

    //Update left and right swipers
    _updateDirectionalSwiper(
      ddx, 
      cardSwipeLimitX, 
      rightSwiper, 
      leftSwiper,
      xDrag,
      DismissDirection.endToStart,
      DismissDirection.startToEnd,
    );
    //Update up and down swipers
    _updateDirectionalSwiper(
      ddy, 
      cardSwipeLimitY, 
      downSwiper, 
      upSwiper,
      yDrag,
      DismissDirection.down,
      DismissDirection.up,
    );
  
  }
  
  /*
 
   ____        _ _     _ 
  | __ ) _   _(_) | __| |
  |  _ \| | | | | |/ _` |
  | |_) | |_| | | | (_| |
  |____/ \__,_|_|_|\__,_|
                         
 
*/

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      behavior: HitTestBehavior.translucent,
      gestures: <Type, GestureRecognizerFactory>{
        PanGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
          () => PanGestureRecognizer(),
          (PanGestureRecognizer instance) {
            instance.minFlingVelocity = 20;
            instance
              ..onUpdate = _onPanUpdate
              ..onEnd = _onPanEnd
              ..onStart = _onPanStart;
              
          },
        ),
      },
      child: Opacity(
        // opacity: widget.opacityChange ? _cardFadoOutOpacity() : 1,
        opacity: 1,
        child: Transform.rotate(
          // alignment: rotation == SwipeCardAngle.Top ? Alignment.topCenter : Alignment.bottomCenter,
          /*
          (!xDrag.isNegative
              ? min(xDrag / 2 / 360, (10 * pi) / 180)
              : max(xDrag / 2 / 360, -(10 * pi) / 180)),
              */
          angle: rotation == SwipeCardAngle.None ? 0
            : (rotation == SwipeCardAngle.Top ? 1 : -1) * angle,
          child: Transform.translate(
              offset: Offset(xDrag, yDrag), child: widget.child ?? Container()),
        ),
      ),
    );
  }
}


///Controller for the swipe card
class SwipeCardController extends ChangeNotifier {

  late _SwipeCardState? _state;

  SwipeCardController();

  void _bind(_SwipeCardState bind) => _state = bind;

  ///Reverses any active animations
  void reverse() => _state!.reverse();

  ///Swipe card in a designated direction
  void swipe(DismissDirection direction) => _state != null ? _state!.swipe(direction) : null;

  ///Get values of the card from a designated direction
  double value(DismissDirection direction) => _state != null ? _state!.value(direction) : 0;

  //Disposes of the controller
  @override
  void dispose() {
    _state = null;
    super.dispose();
  }
}