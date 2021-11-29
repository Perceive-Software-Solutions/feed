import 'package:feed/animated/neumorpic_percent_bar.dart';
import 'package:feed/animated/poll_swipe_animated_icon.dart';
import 'package:feed/feed.dart';
import 'package:feed/util/global/functions.dart';
import 'package:feed/util/icon_position.dart';
import 'package:feed/util/render/keep_alive.dart';
import 'package:feed/widgets/swipe_card.dart';
import 'package:flutter/material.dart';

enum SwipeFeedCardState{
  HIDE,
  SHOW,
  EXPAND
}

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
    this.swipeOverride,
    this.swipeAlert,
    this.onFill, 
    this.onSwipe, 
    this.onDismiss, 
    this.child,
    this.onContinue, 
    this.onPanEnd,
    this.overlay,
    this.blur,
    required this.icons,
    required this.swipeFeedCardController,
    required this.keyboardOpen,
    required this.fillController,
    required this.swipeFeedController,
  }) : super(key: key);

  @override
  _SwipeFeedCardState createState() => _SwipeFeedCardState();

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Variables ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  final bool? swipeOverride;

  final List<IconData> icons;

  /// Controls automating swipe in the [SwipeController]
  final SwipeFeedCardController swipeFeedCardController;

  final SwipeFeedController swipeFeedController;

  /// Overlay that comes up when [swipeAlert] is true
  final Widget? Function(Future<void> Function(int), Future<void> Function(int), int)? overlay;

  /// Blur that is produced on the background card
  final Widget? blur;

  /// If the overlay should be shown
  final bool Function(int)? swipeAlert;

  /// Is the keyboard open
  final bool keyboardOpen;
  
  ///Shows and expands the card
  final bool show;

  final PercentBarController fillController;

  ///Current Poll
  // final Poll poll;

  /// The fill call back function.
  /// Returns the fill direction along with the value of fill
  final void Function(double fill, IconPosition position, CardPosition cardPosition, bool overrideLock)? onFill;

  ///The on swipe function, run when the swiper is completed
  final void Function(double dx, double dy, DismissDirection direction)? onSwipe;

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

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Controllers ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  ///List of controllers for the aniomated icons.
  ///4 controlls are defined
  late List<PollPageAnimatedIconController> iconControllers;

  //The controller for the swipe card
  late SwipeCardController swipeController;

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ State ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  ///Locks the output from sending to any other axis when locked
  Axis? axisLock = Axis.horizontal;

  /// No more filling
  bool fillLock = false;

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    //Bind the controller if it is defined
    widget.swipeFeedCardController._bind(this);
  }

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Helpers ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  void swipeRight(){
    swipeController.swipeRight();
  }

  void swipeLeft(){
    swipeController.swipeLeft();
  }

  ///Calls the onFillFunction if it is defined
  void _onFill(double fill, IconPosition position, CardPosition cardPosition, [bool overrideLock = false]) => widget.onFill!(fill, position, cardPosition, overrideLock);

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Swipe Gestures ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  ///Called when the swipe card is starting to be swiped in any one of the 4 [DismissDirection]
  void _onSwipeStart(DismissDirection direction) {}

  int currentIndex(DismissDirection direction){
    switch (direction) {
      // Swipe Right
      case DismissDirection.endToStart:
        return 1;
      // Swipe Left
      case DismissDirection.startToEnd:
        return 0;
      // Swipe Bottom
      case DismissDirection.down:
        return 2;
      // Swipe Up
      case DismissDirection.up:
        return 3;
      default:
        return -1;
    }
  }

  void _onFlingUpdate(double dx, double dy, DismissDirection direction) async {
    widget.swipeFeedController.setLock(true);
    fillLock = true;
    widget.onSwipe!(dx, dy, direction);
    for(int i = 0; i < 4; i++){
      if(i != currentIndex(direction)){
        iconControllers[i].show(0.0);
      }
    }

    // Call Finish icon animation
    iconControllers[currentIndex(direction)].maximize(true);

    if(widget.swipeAlert == null || widget.overlay == null || !widget.swipeAlert!(currentIndex(direction))){
      forwardAnimation(currentIndex(direction));
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

    /// Vertical Length to the slope
    double verticalLength = slope*dx.abs();

    /// Horizontal Length to the slope
    double horizontalLength = slope*dy.abs();

    ///Overrides to the y direction
    bool horizontalAxisOverride = dy > (verticalLength*-1) && dy < verticalLength;

    int i = -1;
    double showValue = 0;

    if(dx.abs() >= 0 && dy > verticalLength*-1 && dy < verticalLength){
      axisLock = Axis.horizontal;
    }
    else if(dy.abs() > 0 && dx > horizontalLength*-1 && dx < horizontalLength){
      axisLock = Axis.vertical;
    }

    if(!fillLock){
      if(axisLock != Axis.horizontal && !horizontalAxisOverride){
      // if(!horizontalAxisOverride){
        if(dy > 0){
          //Show bottom
          i = 2;
          showValue = dy.abs() / maxYBot!;

          if(dx > 0){
            _onFill(swipeController.right, IconPosition.BOTTOM, CardPosition.Right);
          } 
          else{
            _onFill(swipeController.left, IconPosition.BOTTOM, CardPosition.Left);
          }
        }
        else{
          //Show top
          i = 3;
          showValue = dy.abs() / maxYTop!;
          if(dx > 0){
            _onFill(swipeController.right, IconPosition.TOP, CardPosition.Right);
          }
          else{
            _onFill(swipeController.left, IconPosition.TOP, CardPosition.Left);
          }
        }
      }
      // else if(axisLock != Axis.vertical && axisLock != null){
      else if(axisLock != Axis.vertical){
        if(dx > 0){
          //Show right
          i = 0;
          _onFill(swipeController.right, IconPosition.RIGHT, CardPosition.Right);
        }
        else{
          //Show left
          i = 1;
          _onFill(swipeController.left, IconPosition.LEFT, CardPosition.Left);
        }
        showValue = dx.abs() / maxX!;
      }
      if(i >= 0 && !swipeController.reversing){

        iconControllers[i].show(Functions.animateOver(showValue, percent: 0.5));

        // Ensure current icon is shown
        for (var j = 0; j < 4; j++) {
          iconControllers[j].move(showValue);
          if(i != j){
            // Hide Other Icon
            iconControllers[j].show(0.0);
          }
        }
      }
    }
  }

  ///Called when the pan for the swipe card is completed
  void _onPanEnd(){
    widget.onPanEnd!();
  }

  /// Forward animation
  Future<void> forwardAnimation(int index) async{
    if(mounted){

      // widget.swipeFeedController.setLock(false);
      // widget.fillController.unlockAnimation();
      fillLock = false;
      await Future.delayed(Duration(milliseconds: 200));
      iconControllers[index].maximize(false);
      iconControllers[index].setMoveAnimationFinished(false);
      widget.onContinue!(_lastSwipe);
      _lastSwipe = null;
      widget.onDismiss!();
    }
  }

  /// Reverse animation
  Future<void> reverseAnimation(int index) async {
    if(mounted){
      widget.swipeFeedController.setLock(false);
      // widget.fillController.unlockAnimation();
      iconControllers[index].maximize(false);
      widget.onDismiss!();
      swipeController.setSwipe(true);
      _lastSwipe = null;
      swipeController.reverse();
      fillLock = false;
    }
  }


  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Build Helpers ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  ///Builds the icon at the specified index
  Widget _buildIconAtIndex(BuildContext context, int index){
    Widget? child;
    if(swipeAlert(index) && widget.overlay != null){
      child = widget.overlay!(forwardAnimation, reverseAnimation, index);
    }
    return PollPageAnimatedIcon(
      icons: widget.icons,
      controller: iconControllers[index],
      position: IconPosition.values[index],
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
    return _minimize(
      SizedBox.expand(
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
      ),
    );

    //Creates the swipe card swidget
    Widget swipeCard = IgnorePointer(
      ignoring: !widget.show,
      child: SwipeCard(
        controller: swipeController,
        swipable: (widget.swipeOverride != null && !widget.swipeOverride!) ? widget.swipeOverride! : (widget.show == true && widget.keyboardOpen == false),
        opacityChange: true,
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
        onSwipe: (dx, dy, direction, fling){
          if(!fillLock){
            _onFlingUpdate(dx, dy, direction);
          }
        },
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
      child: Stack(
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

///Controller for the feed
class SwipeFeedCardController extends ChangeNotifier {
  late _SwipeFeedCardState? _state;

  ///Binds the feed state
  void _bind(_SwipeFeedCardState bind) => _state = bind;

  void swipeRight() => _state != null ? _state!.swipeRight() : null;

  void swipeLeft() => _state != null ? _state!.swipeLeft() : null;

  //Disposes of the controller
  @override
  void dispose() {
    _state = null;
    super.dispose();
  }
}