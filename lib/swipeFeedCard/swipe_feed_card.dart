import 'package:feed/swipeCard/swipe_card.dart';
import 'package:feed/swipeFeedCard/state.dart';
import 'package:feed/util/global/functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:fort/fort.dart';
import 'package:tuple/tuple.dart';

class SwipeFeedCard<T> extends StatefulWidget {

  final SwipeFeedCardController controller;
  final Function(double dx, double dy)? onPanUpdate;
  final Future<bool> Function(double dx, double dy, Future<void> Function(), DismissDirection direction)? onSwipe;
  final Future<void> Function()? onContinue;
  final SwipeFeedBuilder<T>? childBuilder;
  final Widget Function(BuildContext context, Widget? child)? background;
  final Tuple2<dynamic, Store<SwipeFeedCardState>> item;
  final EdgeInsets? padding;
  final bool Function(T)? canExpand;

  const SwipeFeedCard({ 
    Key? key,
    required this.controller,
    required this.item,
    this.padding,
    this.canExpand,
    this.childBuilder,
    this.background,
    this.onPanUpdate,
    this.onSwipe,
    this.onContinue,
  }) : super(key: key);

  @override
  _SwipeFeedCardState<T> createState() => _SwipeFeedCardState<T>();
}

class _SwipeFeedCardState<T> extends State<SwipeFeedCard> {

  /// Controller
  late SwipeCardController swipeCardController;

  @override
  void initState(){
    super.initState();

    // Initialize controllers
    swipeCardController = SwipeCardController();
  }

  EdgeInsets get padding => widget.padding ?? EdgeInsets.zero;

  /// Called when the card registers a swipe
  /// Checks to see if the onSwipe method passed in and forwards the animation accordingly
  /// True - Forward animation
  /// False - Do nothing
  dynamic _onSwipe(double dx, double dy, DismissDirection direction) async {
    bool swipeAlert = true;
    if(widget.onSwipe != null){
      swipeAlert = await widget.onSwipe!(dx, dy, reverseAnimation, direction);
    }
    if(swipeAlert){
      forwardAnimation();
    }
  }

  /// Reverses the swipe card back to its initial location
  Future<void> reverseAnimation() async {
    swipeCardController.reverse();
    return;
  }

  /// Forwards the swipe card and signals the swipe feed to continue
  Future<void> forwardAnimation() async {
    if(widget.onContinue != null){
      widget.onContinue!();
    }
  }

  /// Loads the Swipe Card
  /// If the swipe card is at the top of the feed it will unmask the swipe card
  /// If the swipe card is behind another swipe card will mask the swipe card 
  /// with background
  Widget _loadCard(BuildContext context, FeedCardState state){
    bool isExpanded = state == SwipeCardExpandState();
    if(widget.childBuilder != null && widget.item != null){
      return Stack(
        children: [
          Positioned.fill(
            child: widget.childBuilder!(widget.item, isExpanded, (){
              widget.item.item2.dispatch(SetSwipeFeedCardState(SwipeCardShowState()));
            }),
          ),
          AnimatedSwitcher(
            duration: Duration(milliseconds: 300),
            child: state == SwipeCardHideState() && widget.background != null ? Positioned.fill(
              child: widget.background!(context, Container())
            ) : SizedBox.shrink(),
          )
        ]
      );
    }
    else{
      return widget.background != null ? widget.background!(context, Container()) : SizedBox.shrink();
    }
  }

  Widget buildSwipeCard(BuildContext context){
    return StoreProvider(
      store: widget.item.item2,
      child: StoreConnector<SwipeFeedCardState, FeedCardState>(
        converter: (store) => store.state.state,
        builder: (context, state) {
          return KeyboardVisibilityBuilder(
            builder: (context, keyboard) {
              return AnimatedPadding(
                duration: Duration(milliseconds: 200),
                padding: state is SwipeCardExpandState ? EdgeInsets.zero : (keyboard ? padding.copyWith(bottom: 0) : padding),
                child: GestureDetector(
                  onTap: widget.item.item1 != null && widget.canExpand != null && 
                  widget.canExpand!(widget.item.item1) && state is SwipeCardShowState && !keyboard ? (){
                    widget.item.item2.dispatch(SetSwipeFeedCardState(SwipeCardExpandState()));
                  } : null,
                  child: Opacity(
                    opacity: keyboard && state is SwipeCardHideState ? 0.0 : 1.0,
                    child: IgnorePointer(
                      ignoring: state is SwipeCardHideState && state.overlay == null,
                      child: SwipeCard(
                        controller: swipeCardController,  
                        swipable: true,
                        opacityChange: true,
                        onPanUpdate: (dx, dy){
                          if(widget.item.item1 != null && widget.item.item2.state.state is SwipeCardExpandState){
                            widget.item.item2.dispatch(SetSwipeFeedCardState(SwipeCardShowState()));
                          }
                          if(widget.onPanUpdate != null){
                            widget.onPanUpdate!(dx, dy);
                          }
                        },
                        onSwipe: _onSwipe,
                        child: AnimatedSwitcher(
                          duration: Duration(milliseconds: 200),
                          child: _loadCard(context, state)
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }
          );
        }
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 200),
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: animation,
          child: child,
        );
      },
      child: buildSwipeCard(context),
    );
  }
}

///Controller for the swipe card
class SwipeFeedCardController extends ChangeNotifier {

  late _SwipeFeedCardState? _state;

  SwipeFeedCardController();

  void _bind(_SwipeFeedCardState bind) => _state = bind;

  /// Forward Animation
  void forwardAnimation() => _state != null ? _state!.forwardAnimation() : null;

  /// Reverse Animation
  void reverseAnimation() => _state != null ? _state!.reverseAnimation() : null;

  //Disposes of the controller
  @override
  void dispose() {
    _state = null;
    super.dispose();
  }
}

