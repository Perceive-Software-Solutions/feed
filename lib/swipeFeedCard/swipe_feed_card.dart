import 'dart:math';

import 'package:feed/animationSystem/animation_system_delegate_builder.dart';
import 'package:feed/swipeCard/swipe_card.dart';
import 'package:feed/swipeFeedCard/state.dart';
import 'package:feed/util/global/functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:fort/fort.dart';
import 'package:tuple/tuple.dart';

class SwipeFeedCard<T> extends StatefulWidget {

  /// Object Key
  final String Function(T) objectKey;

  /// Init controller
  final SwipeFeedCardController controller;

  /// Callback for the updating position of the current card
  final Function(double dx, double dy)? onPanUpdate;

  /// Callback for when the card has been dismissed from the screen before forward animation
  final Future<bool> Function(double dx, double dy, Future<void> Function(), DismissDirection direction, Duration duration)? onSwipe;

  /// After forward animation has been called
  final Future<void> Function()? onContinue;

  /// Child of the card
  final SwipeFeedBuilder<T>? childBuilder;

  /// Widget representing the last card in the list "Background Card"
  final Widget Function(BuildContext context, Widget? child)? background;

  /// Loading widget of the card, is called when the feed is in a loading state
  final Widget? loadingPlaceHolder;

  /// Current item dispatched from the loader
  final Tuple2<dynamic, Store<SwipeFeedCardState>> item;

  /// Additional padding
  final EdgeInsets? padding;

  /// If the card can take up the screen and go passed its bounds
  final bool Function(T)? canExpand;

  /// The color of the mask of the next poll in the list
  final Widget? mask;

  /// If it is the last null card in the list
  final bool isLast;

  /// Background card without a child, delegate
  final AnimationSystemDelegate? backgroundDelegate;

  /// Controller for the animation background delegate
  final AnimationSystemController? backgroundController;

  /// Controls the top animation
  final AnimationSystemController? topAnimationSystemController;

  /// Controls the bottom animation
  final AnimationSystemController? bottomAnimationSystemController;

  const SwipeFeedCard({ 
    Key? key,
    required this.objectKey,
    required this.controller,
    required this.item,
    required this.isLast,
    this.mask,
    this.loadingPlaceHolder,
    this.padding,
    this.canExpand,
    this.childBuilder,
    this.background,
    this.onPanUpdate,
    this.onSwipe,
    this.onContinue,
    this.backgroundController,
    this.topAnimationSystemController,
    this.bottomAnimationSystemController,
    this.backgroundDelegate
  }) : super(key: key);

  @override
  _SwipeFeedCardState<T> createState() => _SwipeFeedCardState<T>();
}

class _SwipeFeedCardState<T> extends State<SwipeFeedCard> {

  /// Controller
  late SwipeCardController swipeCardController;

  /// If the animation system should be updated
  bool fillLock = false;

  @override
  void initState(){
    super.initState();

    // Initialize controllers
    swipeCardController = SwipeCardController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    //Bind the controller
    widget.controller._bind(this);
  }

  /// Padding associated with the card
  /// Has to be passed in so the card can control the padding in order to expand
  EdgeInsets get padding => (widget as SwipeFeedCard<T>).padding ?? EdgeInsets.zero;

  /// Called when the card registers a swipe
  /// Checks to see if the onSwipe method passed in and forwards the animation accordingly
  /// True - Forward animation
  /// False - Do nothing
  dynamic _onSwipe(double dx, double dy, DismissDirection direction, Duration duration) async {
    bool swipeAlert = true;
    fillLock = true;
    if((widget as SwipeFeedCard<T>).onSwipe != null){
      swipeAlert = await (widget as SwipeFeedCard<T>).onSwipe!(dx, dy, reverseAnimation, direction, duration);
    }
    if(swipeAlert){
      forwardAnimation();
    }
  }

  /// Reverses the swipe card back to its initial location
  Future<void> reverseAnimation() async {
    if(widget.topAnimationSystemController != null) widget.topAnimationSystemController!.reverse();
    if(widget.bottomAnimationSystemController != null) widget.bottomAnimationSystemController!.reverse();
    await swipeCardController.reverse();
    fillLock = false;
    return;
  }

  /// Forwards the swipe card and signals the swipe feed to continue
  Future<void> forwardAnimation() async {
    if((widget as SwipeFeedCard<T>).onContinue != null){
      (widget as SwipeFeedCard<T>).onContinue!();
    }
    fillLock = false;
    return;
  }

  ///Called while the swipe card is being panned
  void _onPanUpdate(double dx, double dy){
    if((widget as SwipeFeedCard<T>).item.item1 != null && (widget as SwipeFeedCard<T>).item.item2.state.state is SwipeCardExpandState){
      (widget as SwipeFeedCard<T>).item.item2.dispatch(SetSwipeFeedCardState(SwipeCardShowState()));
    }
    if((widget as SwipeFeedCard<T>).onPanUpdate != null && !fillLock){
      (widget as SwipeFeedCard<T>).onPanUpdate!(dx, dy);
    }
  }

  /// Swipe the swipe card in a specific direction
  void swipe(DismissDirection direction){
    swipeCardController.swipe(direction);
  }

  /// Loads the Swipe Card
  /// If the swipe card is at the top of the feed it will unmask the swipe card
  /// If the swipe card is behind another swipe card will mask the swipe card 
  /// with background
  Widget _loadCard(BuildContext context, FeedCardState state, Widget? child){
    bool isExpanded = state is SwipeCardExpandState;
    bool show = state is SwipeCardShowState || state is SwipeCardExpandState;

    if(!show && (widget as SwipeFeedCard<T>).background != null){
      if(child == null){
        return Container(
          key: ValueKey('SwipeFeed Background Card Without Child}'),
          child: (widget as SwipeFeedCard<T>).backgroundDelegate != null && (widget as SwipeFeedCard<T>).backgroundController != null ? AnimationSystemDelegateBuilder(
            controller: (widget as SwipeFeedCard<T>).backgroundController!,
            delegate: (widget as SwipeFeedCard<T>).backgroundDelegate!
          ) : (widget as SwipeFeedCard<T>).background!(context, null)
        );
      }
      else{
        return Container(
          key: ValueKey('SwipeFeed Background Card With Child}'),
          child: (widget as SwipeFeedCard<T>).background!(context, SizedBox.expand(child: child))
        );
      }
    }
    if((widget as SwipeFeedCard<T>).item.item1 == null){
      return Container(
        key: (widget as SwipeFeedCard<T>).item.item1 == null ? UniqueKey() : ValueKey('SwipeFeed Placeholder Card ' + (widget as SwipeFeedCard<T>).objectKey((widget as SwipeFeedCard<T>).item.item1)),
        child: (widget as SwipeFeedCard<T>).loadingPlaceHolder ?? SizedBox.shrink()
      );
    }
    else if((widget as SwipeFeedCard<T>).childBuilder != null && (widget as SwipeFeedCard<T>).item != null){
      //Builds custom child if childBuilder is defined
      return Container(
        key: (widget as SwipeFeedCard<T>).item.item1 == null ? UniqueKey() : ValueKey('SwipeFeed Child Card ' + (widget as SwipeFeedCard<T>).objectKey((widget as SwipeFeedCard<T>).item.item1)),
        child: (widget as SwipeFeedCard<T>).childBuilder!((widget as SwipeFeedCard<T>).item.item1, isExpanded, (){(widget as SwipeFeedCard<T>).item.item2.dispatch(SetSwipeFeedCardState(SwipeCardShowState()));})
      );
    }
    else {
      throw ('T is not supported by Feed');
    }
  }

  Widget buildSwipeCard(BuildContext context){
    return StoreConnector<SwipeFeedCardState, FeedCardState>(
      converter: (store) => store.state.state,
      distinct: true,
      builder: (context, state) {
        Widget? hiddenChild = state is SwipeCardHideState ? state.overlay : null;
        bool show = state is SwipeCardShowState || state is SwipeCardExpandState;
        return KeyboardVisibilityBuilder(
          builder: (context, keyboard) {
            return AnimatedPadding(
              duration: Duration(milliseconds: 200),
              padding: state is SwipeCardExpandState ? EdgeInsets.zero : (keyboard ? padding.copyWith(bottom: 0) : padding),
              child: GestureDetector(
                onTap: (widget as SwipeFeedCard<T>).item.item1 != null && (widget as SwipeFeedCard<T>).canExpand != null && 
                (widget as SwipeFeedCard<T>).canExpand!((widget as SwipeFeedCard<T>).item.item1) && state is SwipeCardShowState && !keyboard ? (){
                  (widget as SwipeFeedCard<T>).item.item2.dispatch(SetSwipeFeedCardState(SwipeCardExpandState()));
                } : null,
                child: Opacity(
                  opacity: keyboard && state is SwipeCardHideState ? 0 : 1.0,
                  child: IgnorePointer(
                      ignoring: state is SwipeCardHideState && state.overlay == null,
                      child: AnimatedPadding(
                        duration: Duration(milliseconds: 200),
                        padding: !show ? const EdgeInsets.only(top: 74, bottom: 12, left: 8, right: 8) : EdgeInsets.zero,
                        child: SwipeCard(
                          controller: swipeCardController,  
                          swipable: state is SwipeCardShowState || state is SwipeCardExpandState && !keyboard,
                          opacityChange: true,
                          onPanUpdate: _onPanUpdate,
                          onSwipe: _onSwipe,
                          child: AnimatedSwitcher(
                            duration: Duration(milliseconds: 200),
                            child: _loadCard(context, state, hiddenChild)
                          ),
                        ),
                      ),
                    ),
                ),
                )
            );
          }
        );
      }
    );
  }


  @override
  Widget build(BuildContext context) {
    return StoreProvider(
      store: (widget as SwipeFeedCard<T>).item.item2,
      child: buildSwipeCard(context),
    );
  }
}

///Controller for the swipe card
class SwipeFeedCardController extends ChangeNotifier {

  late _SwipeFeedCardState? _state;

  void _bind(_SwipeFeedCardState bind) => _state = bind;

  /// Forward Animation
  void forwardAnimation() => _state != null ? _state!.forwardAnimation() : null;

  /// Reverse Animation
  Future<void> reverseAnimation() async => _state != null ? await _state!.reverseAnimation() : Future.error("State is not initiated");

  /// Swipe the card in a specific direction
  void swipe(DismissDirection direction) => _state != null ? _state!.swipe(direction) : null;

  /// Get the current value of one of the swipers
  void value(DismissDirection direction) => _state != null ? _state!.swipeCardController.value(direction) : null;

  //Disposes of the controller
  @override
  void dispose() {
    _state = null;
    super.dispose();
  }
}

class AnimateOver<T extends double> extends Animation<T> with AnimationWithParentMixin<T> {

  ///The minimum value
  final T last;

  ///The parent
  @override
  final Animation<T> parent;

  /// Creates an [AnimationOverLast].
  ///
  /// Both arguments must be non-null. Either can be an [AnimationOverLast] itself
  /// to combine multiple animations.
  AnimateOver(this.parent, this.last) : assert(last != null && last < 1.0), assert(parent != null);

  @override
  T get value{
    Object output = (parent.value - (1.0 - last)) / (last);
    return max((0.0 as T), output as T);
  }
}

class AnimationOverF<T extends double> extends Animation<T> with AnimationWithParentMixin<T> {

  ///The minimum value
  final T first;

  ///The parent
  @override
  final Animation<T> parent;

  /// Creates an [AnimationOverFirst].
  ///
  /// Both arguments must be non-null. Either can be an [AnimationOverFirst] itself
  /// to combine multiple animations.
  AnimationOverF(this.parent, this.first) : assert(first != null && first < 1.0), assert(parent != null);

  @override
  T get value{
    Object output = parent.value / first;
    return min((1.0 as T), output as T);
  }
}

