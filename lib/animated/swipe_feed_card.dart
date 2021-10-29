import 'dart:ui';

import 'package:feed/animated/poll_swipe_animated_icon.dart';
import 'package:feed/util/global/functions.dart';
import 'package:feed/util/render/keep_alive.dart';
import 'package:feed/widgets/swipe_card.dart';
import 'package:flutter/material.dart';

///The poll page card is a feed swipe card within a swippable card. 
///These are displayed on the poll page feed as swipable cards. 
///
///When the [show] variable is set to false the card is minimized and blurred.
///
///The swipe card displays icons behind it when swiped, indicating the swipe direction
class SwipeFeedCard extends StatefulWidget {

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Constructor ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  const SwipeFeedCard({ 
    Key? key, 
    this.show = true,
    this.swipeAlert,
    this.onFill, 
    this.onSwipe, 
    this.onDismiss, 
    this.child,
    this.onContinue, 
    this.onPanEnd,
    this.overlay,
    this.blur,
    required this.keyboardOpen
  }) : super(key: key);

  @override
  _SwipeFeedCardState createState() => _SwipeFeedCardState();

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Variables ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  /// Overlay that comes up when [swipeAlert] is true
  final Widget? overlay;

  /// Blur that is produced on the background card
  final Widget? blur;

  /// If the overlay should be shown
  final bool Function(int)? swipeAlert;

  /// Is the keyboard open
  final bool keyboardOpen;
  
  ///Shows and expands the card
  final bool show;

  ///Current Poll
  // final Poll poll;

  /// The fill call back function.
  /// Returns the fill direction along with the value of fill
  final void Function(double fill, IconPosition position)? onFill;

  ///The on swipe function, run when the swiper is completed
  final void Function(DismissDirection direction)? onSwipe;

  ///The on dismiss function is run when the poll card requests to be dismissed
  final void Function()? onDismiss;

  ///Runs when the card is dropped
  final void Function()? onPanEnd;

  ///The on continue function is run when the poll card requests to be continued
  final Future<void> Function(DismissDirection? direction)? onContinue;

  ///The child widget
  final Widget? child;

}

class _SwipeFeedCardState extends State<SwipeFeedCard> {

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Constants ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  ///The offset at which the swipe output becomes axially locked
  final double SWIPE_LOCK_THRESHOLD = 100;

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Controllers ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  ///List of controllers for the aniomated icons.
  ///4 controlls are defined
  late List<PollPageAnimatedIconController> iconControllers;

  //The controller for the swipe card
  late SwipeCardController swipeController;

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ State ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  ///Locks the output from sending to any other axis when locked
  Axis? axisLock;

  ///The direction of the last swipe
  DismissDirection? _lastSwipe;

  Widget get blur => widget.blur == null ? Container() : widget.blur!;

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Lifecycle ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  @override
  void initState() {
    super.initState();

    //Initialize a controller for each of the Icons
    iconControllers = List.generate(4, (i) => PollPageAnimatedIconController());

    //Iniitalize the swipe controller
    swipeController = SwipeCardController();
  }

  bool swipeAlert(index){
    return widget.swipeAlert == null ? false : 
    widget.swipeAlert!(index);
  }

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Helpers ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  ///Calls the onFillFunction if it is defined
  void _onFill(double fill, IconPosition position) => widget.onFill!(fill, position);

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Swipe Gestures ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  // ///Called when the swipe card is swiped in any one of the 4 [DismissDirection]
  // void _onSwipe(DismissDirection direction) {

  //   //Call the defied call back function
  //   if(widget.onSwipe != null){
  //     widget.onSwipe(direction);
  //     _lastSwipe = direction;
  //   }
  // }

  ///Called when the swipe card is starting to be swiped in any one of the 4 [DismissDirection]
  void _onSwipeStart(DismissDirection direction) {
    int i = -1;
    _lastSwipe = direction;
    if(direction == DismissDirection.startToEnd){
      i = 0;
    }
    else if(direction == DismissDirection.endToStart){
      i = 1;
    }
    else if(direction == DismissDirection.up){
      i = 3;
    }
    else if(direction == DismissDirection.down){
      i = 2;
    }

    bool hasAlert = widget.swipeAlert != null;

    // print('ibte ${direction.toString()} ${IconPosition.values[i].toString()}');

    if(i >= 0){
      for (var j = 0; j < 4; j++) {
        if(i == j) {
          iconControllers[j].maximize(true);
        }
        else{
          iconControllers[j].maximize(false);
        }
      }
      swipeController.setSwipe(false);
      if(widget.onContinue != null && !hasAlert){
        widget.onContinue!(direction);
      }
      else if(widget.onSwipe != null && hasAlert){
        widget.onSwipe!(direction);
      }
    }
  }

  ///Called while the swipe card is being panned
  void _onPanUpdate(double dx, double dy, [double? maxX, double? maxYTop, double? maxYBot]) {

    //Height of the screen
    final height = MediaQuery.of(context).size.height;

    //Width of the screen
    final width = MediaQuery.of(context).size.width;

    // Diagonal slope of the screen
    final slope = height/width;

    double verticalLength = slope*dx.abs();

    ///Overrides to the y direction
    bool horizontalAxisOverride = dy > (verticalLength*-1) && dy < verticalLength;

    int i = -1;
    double showValue = 0;
    double? maxSwipeDis;

    if(dx.abs() >= maxX! && axisLock == null){
      axisLock = Axis.horizontal;
    }
    else if(dy.abs() > maxYTop! && axisLock == null){
      axisLock = Axis.vertical;
    }
    else if(dx.abs() < maxYBot! * 0.05 && dy.abs() < maxYTop * 0.05){
      axisLock = null;
    }

    if(axisLock != Axis.horizontal && !horizontalAxisOverride){
      // if(!horizontalAxisOverride){
        if(dy > 0){
          //Show bottom
          i = 2;
          showValue = dy.abs() / maxYBot!;
          maxSwipeDis = maxYBot;
          // print('down');
          _onFill(swipeController.down, IconPosition.BOTTOM);
        }
        else{
          //Show top
          i = 3;
          showValue = dy.abs() / maxYTop!;
          maxSwipeDis = maxYTop;
          // print('up');
          _onFill(swipeController.up, IconPosition.TOP);
        }
      // }
      // else{
      //   axisLock = Axis.horizontal;
      // }
    }
    else if(axisLock != Axis.vertical){
      // if(horizontalAxisOverride){
        if(dx > 0){
          //Show right
          i = 0;
          _onFill(swipeController.right, IconPosition.RIGHT);
        }
        else{
          //Show left
          i = 1;
          _onFill(swipeController.left, IconPosition.LEFT);
        }
        maxSwipeDis = maxX;
        showValue = dx.abs() / maxX;
        // print('sides');
      // }
      // else{
      //   axisLock = Axis.vertical;
      // }
    }

    /*

    if(axisLock != Axis.vertical){

      if(dy >= (verticalLength*-1) && dy <= verticalLength){
        i = dx > 0 ? 0 : 1;
        maxSwipeDis = maxX;
        showValue = dx.abs() / maxX;
        // print('sides');
        _onFill(swipeController.largetSwiperValue, i == 0 ? IconPosition.RIGHT : IconPosition.LEFT);

        //Lock the axis after a threhold
        if(dx.abs() > SWIPE_LOCK_THRESHOLD && axisLock != Axis.horizontal){
          // print('lock --');
          axisLock = Axis.horizontal;
        }
      }
      else if(dy.abs() > SWIPE_LOCK_THRESHOLD){
        // print('lock |');
        axisLock = Axis.vertical;
      }
      
    }
    else if(dy.abs() > 0){
      if(dy > 0){
        //Show bottom
        i = 2;
        showValue = dy.abs() / maxYBot;
        maxSwipeDis = maxYBot;
        print('down');
        _onFill(swipeController.largetSwiperValue, IconPosition.BOTTOM);
      }
      else{
        //Show top
        i = 3;
        showValue = dy.abs() / maxYTop;
        maxSwipeDis = maxYTop;
        // print('up');
        _onFill(swipeController.largetSwiperValue, IconPosition.TOP);
      }

      if(dy.abs() > SWIPE_LOCK_THRESHOLD && axisLock != Axis.horizontal){
        // print('lock |');
        axisLock = Axis.vertical;
      }
    }
    */

    if(i >= 0 && !swipeController.reversing){
      for (var j = 0; j < 4; j++) {
        if(i == j){
          double percent = (SwipeCard.THRESHOLD_OFFSET)/maxSwipeDis!;
          iconControllers[j].show(Functions.animateOver(showValue, percent: 0.5));
        }
        else if(iconControllers[j].opacity > 0){
          iconControllers[j].maximize(false);
        }
      }
    }

  }

  ///Called when the pan for the swipe card is completed
  void _onPanEnd(){
    //Reset the axis lock
    // print('lock O');
    widget.onPanEnd!();
    axisLock = null;
  }

  /// Forward animation
  void forwardAnimation(int index) async{
    if(mounted){
      await widget.onContinue!(_lastSwipe);
      await Future.delayed(Duration(milliseconds: 200));
      _lastSwipe = null;
      iconControllers[index].maximize(false);
      widget.onDismiss!();
    }
  }

  /// Reverse animation
  void reverseAnimation(int index){
    if(mounted){
      widget.onDismiss!();
      swipeController.setSwipe(true);
      _lastSwipe = null;
      swipeController.reverse();
      iconControllers[index].maximize(false);
    }
  }


  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Build Helpers ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // 0: AGREE
  // 1: DISAGREE
  // 2: SKIP
  // 3: TRUST
  // Widget? _buildSwipeAlert(int index){
  //   if(index == 2 || ((index == 0 || index == 1) && 
  //   (PollarStoreBloc().trustingList![widget.poll.topicId] == null || widget.poll.trustedVote == null))){
  //     return null;
  //   }

  //   // return TrustOverlay(
  //   //   forwardAnimation: forwardAnimation,
  //   //   reverseAnimation: reverseAnimation,
  //   //   index: index,
  //   //   poll: widget.poll
  //   // );
  // }

  ///Builds the icon at the specified index
  Widget _buildIconAtIndex(BuildContext context, int index){
    Widget? child;
    if(swipeAlert(index)){
      child = Container();
    }
    // Widget? child = _buildSwipeAlert(index);

    return PollPageAnimatedIcon(
      controller: iconControllers[index],
      position: IconPosition.values[index],
      onContinue: () async {
        //On cancel reverse the animation and minimize the icon
        await widget.onContinue!(_lastSwipe);
        await Future.delayed(Duration(milliseconds: 200));
        _lastSwipe = null;
        iconControllers[index].maximize(false);
        widget.onDismiss!();
      },
      child: child,
    );
  }

  /// Builds the icon container in the packground of the poll card. 
  /// Icons are positoned relative to this container.
  /// 
  /// The container is the same size are the minimized poll card
  Widget _buildIconContainer(BuildContext context){

    //The icons within the container
    List<Widget> icons = [];
    for (var i = 0; i < 4; i++) {
      icons.add(_buildIconAtIndex(context, i));
    }

    //Minimized container
    return _minimize(SizedBox.expand(
      child: Stack(
        children: icons,
      ),
    ));
  }

  //Creates an hideen widget
  Widget _minimize(Widget hide){
    return Transform.scale(
      scale: SwipeCard.CARD_MINIMIZE_SCALE,
      child: Padding(
        padding: const EdgeInsets.only(top: 47, bottom: 5),
        child: hide,
      ),
    );
  }

  /// Builds the primary view for the poll page card. 
  ///
  /// Contains a swipe card which is swipable and communicats with the icon controlls while swiping. 
  /// Within the swipe card is a poll card.
  /// 
  /// The card is minimized and blurred when [show] is set to `false`.
  Widget _buildeSwipeCard(BuildContext context){

    //The inner child within the swipe card
    Widget child = widget.child ?? Container(
      color: widget.show == true ? Colors.blue.withOpacity(0.3) : Colors.blue[100],
      child: SizedBox.expand(
        // child: Center(child: Text("hi")),
      ),
    );

    //Creates the swipe card swidget
    Widget swipeCard = IgnorePointer(
      ignoring: widget.show != true,
      child: SwipeCard(
        controller: swipeController,
        swipable: widget.show == true && widget.keyboardOpen == false,
        opacityChange: true,
        // onSwipe: _onSwipe,
        onStartSwipe: _onSwipeStart,
        onPanEnd: _onPanEnd,
        onPanUpdate: _onPanUpdate,
        child: KeepAliveWidget(
          child: Stack(
            children: [
              Positioned.fill(child: child),
              blur
            ],
          )
        ),
        onSwipe: (direction){},
      ),
    );

    //Minimization sizing for the swipe card
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: widget.show == false ? SwipeCard.CARD_MINIMIZE_SCALE : 1, end: widget.show == false ? SwipeCard.CARD_MINIMIZE_SCALE : 1),
      duration: Duration(milliseconds: 200),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: Padding(
        padding: widget.show == false ? const EdgeInsets.only(top: 47, bottom: 5) : EdgeInsets.symmetric(horizontal: 5),
        child: swipeCard,
      ),
    );
  }

  ///Builds the blur over the card
  // Widget _buildBlur(BuildContext context){
  //   //Full card blur
  //   return Positioned.fill(
  //     child: IgnorePointer(
  //       ignoring: true,
  //       child: FrostedEffect(
  //         blur: 20,
  //         frost: widget.show != true,
  //         shape: ClipShape.rRect(32),
  //         animatedBuilder: (context, frost) {
  //           return Opacity(
  //             opacity: lerpDouble(0, 1, frost/20)!,
  //             child: Container(
  //               decoration: BoxDecoration(
  //                 borderRadius: BorderRadius.all(Radius.circular(32)),
  //                 color: widget.show != true ? Colors.black12 : Colors.transparent),
  //             ),
  //           );
  //         }),
  //     ));
  // }

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Build ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  @override
  Widget build(BuildContext context) {

    return AnimatedSwitcher(
      duration: Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: animation,
          child: child,
        );
      },
      child: widget.show == null ? SizedBox.shrink() : Stack(
        children: [
          //Used to background widgets
          Padding(
            padding: const EdgeInsets.all(0.0),
            child: _buildIconContainer(context),
          ),

          //Used to draw the primary swipe card
          _buildeSwipeCard(context),
        ],
      ),
    );
  }
}