import 'package:feed/feed.dart';
import 'package:feed/swipeCard/swipe_card.dart';
import 'package:feed/swipeFeedCard/state.dart';
import 'package:feed/util/global/functions.dart';
import 'package:flutter/material.dart';
import 'package:fort/fort.dart';

class SwipeFeedCard<T> extends StatefulWidget {

  final SwipeFeedCardController controller;
  final Store<SwipeFeedCardState> store;
  final bool isLast;
  final Function(double dx, double dy, [double? maxX, double? maxYTop, double? maxYBot])? onPanUpdate;
  final Future<bool> Function(double dx, double dy, Future<void> Function(), DismissDirection direction)? onSwipe;
  final Future<void> Function()? onContinue;
  final SwipeFeedBuilder<T>? childBuilder;
  final Widget? background;
  final T? item;

  const SwipeFeedCard({ 
    Key? key,
    required this.controller,
    required this.store,
    required this.isLast,
    this.item,
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
    bool isExpanded = state == FeedCardState.SwipeCardExpandState;
    if(widget.childBuilder != null && widget.item != null){
      return Stack(
        children: [
          Positioned.fill(
            child: widget.childBuilder!(widget.item, isExpanded, (){
              widget.store.dispatch(SetSwipeFeedCardState(FeedCardState.SwipeCardShowState));
            }),
          ),
          AnimatedSwitcher(
            duration: Duration(milliseconds: 300),
            child: state == FeedCardState.SwipeCardHideState && widget.background != null ? Positioned.fill(
              child: widget.background!
            ) : SizedBox.shrink(),
          )
        ]
      );
    }
    else{
      return widget.background != null ? widget.background! : SizedBox.shrink();
    }
  }


  @override
  Widget build(BuildContext context) {
    return StoreConnector<SwipeFeedCardState, FeedCardState>(
      converter: (store) => store.state.state,
      builder: (context, state) {
        return SwipeCard(
          controller: swipeCardController,  
          swipable: true,
          opacityChange: true,
          onPanUpdate: widget.onPanUpdate != null ? widget.onPanUpdate : null,
          onSwipe: _onSwipe,
          child: _loadCard(context, state),
        );
      }
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

