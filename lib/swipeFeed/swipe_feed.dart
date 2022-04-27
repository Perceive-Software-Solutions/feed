import 'dart:async';

import 'package:connectivity/connectivity.dart';
import 'package:feed/feed.dart';
import 'package:feed/swipeCard/swipe_card.dart';
import 'package:feed/swipeFeed/state.dart';
import 'package:feed/swipeFeedCard/state.dart';
import 'package:feed/swipeFeedCard/swipe_feed_card.dart';
import 'package:feed/util/global/functions.dart';
import 'package:flutter/material.dart';
import 'package:fort/fort.dart';
import 'package:tuple/tuple.dart';

class SwipeFeed<T> extends StatefulWidget {

  /// Object Key
  final String Function(T) objectKey;

  ///A loader for the feed
  final FeedLoader<T> loader;

  ///Controller for the swipe feed
  final SwipeFeedController controller;

  ///A builder for the feed
  final SwipeFeedBuilder<T>? childBuilder;

  ///If defined, then the refresh is not called on init and the feed state is provided
  final InitialFeedState<T>? initialState;

  /// No Polls
  final Widget? noItemsPlaceHolder;

  /// No Connectivity
  final Widget? noConnectivityPlaceHolder;

  /// Loading card displayed when the feed is loading
  final Widget? loadingPlaceHolder;

  /// Background of the card
  final Widget Function(BuildContext context, Widget? child)? background;

  ///The on swipe function, run when a card is swiped
  final Future<bool> Function(double dx, double dy, DismissDirection direction, Duration duration, Future<void> Function(), T item)? onSwipe;
  
  ///When the next card is loading
  final Future<void> Function(T? item)? onConinue;

  /// Function tells the feed if the card can expand
  final bool Function(dynamic)? canExpand;

  /// Padding applied to the Swipe Feed
  /// Has the option to animate
  final EdgeInsets? padding;

  /// Widget builds on top of the card behind the current card
  final Widget? mask;

  /// If it should show the last placeHolder card
  final bool showLastCard;

  /// Updatable view for animations
  final AnimationSystemDelegate? bottomDelegate;

  /// Update view for animations
  final AnimationSystemDelegate? topDelegate;

  /// Background card without a child, delegate
  final AnimationSystemDelegate? backgroundDelegate;

  /// Functions to controlls the top delegate
  final AnimationSystemController? topAnimationSystemController;

  /// Functions to control the bottom delegate
  final AnimationSystemController? bottomAnimationSystemController;

  final Function(T? item)? onLoad;
  
  const SwipeFeed({ 
    Key? key,
    this.childBuilder,
    this.initialState,
    this.noItemsPlaceHolder,
    this.noConnectivityPlaceHolder,
    this.loadingPlaceHolder,
    this.background,
    this.onSwipe,
    this.onConinue,
    this.canExpand,
    this.padding,
    this.mask,
    this.bottomDelegate,
    this.topDelegate,
    this.backgroundDelegate,
    this.topAnimationSystemController,
    this.bottomAnimationSystemController,
    this.showLastCard = true,
    this.onLoad,
    required this.loader,
    required this.objectKey,
    required this.controller
  }) : super(key: key);

  @override
  _SwipeFeedState<T> createState() => _SwipeFeedState<T>();
}

class _SwipeFeedState<T> extends State<SwipeFeed> {

  ///Holds the current state of the SwipeFeed
  late Tower<SwipeFeedState<T>> tower;

  ///Controls automating swipes
  List<SwipeFeedCardController> swipeFeedCardControllers = [];

  List<AnimationSystemController> backgroundSystemControllers = [];

  // If auto swiping is enabled
  bool enabled = false;

  bool initiated = false;

  @override
  void initState(){
    super.initState();

    // Initiate state
    tower = Tower<SwipeFeedState<T>>(
      swipeFeedStateReducer,
      initialState: SwipeFeedState<T>.initial(
        (widget as SwipeFeed<T>).loader, 
        (widget as SwipeFeed<T>).noItemsPlaceHolder ?? Container(), 
        (widget as SwipeFeed<T>).noConnectivityPlaceHolder ?? Container()
      )
    );

    if((widget as SwipeFeed<T>).initialState == null){
      // Initiate the feed from the loader
      tower.dispatch(refresh<T>());
    }
    else{
      // Initiate the feed from an initial state
      tower.dispatch(populateInitialState<T>((widget as SwipeFeed<T>).initialState!));
    }

    /// Check initial Connectivity
    checkConnectivity();
    enableAutoSwiping();

    //Initialize Controllers
    swipeFeedCardControllers.add(SwipeFeedCardController());
    swipeFeedCardControllers.add(SwipeFeedCardController());
    backgroundSystemControllers.add(AnimationSystemController());
    backgroundSystemControllers.add(AnimationSystemController());
  }

  void enableAutoSwiping() async {
    await Future.delayed(Duration(milliseconds: 1000));
    enabled = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    //Bind the controller
    (widget as SwipeFeed<T>).controller._bind(this);
  }

  /// Checks the initial connectivity of the Feed
  void checkConnectivity() async {
    ConnectivityResult connectivityResult = await Connectivity().checkConnectivity();
    tower.dispatch(SetConnectivityEvent(connectivityResult != ConnectivityResult.none));

    // Listen for changes in connectivity
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if(result == ConnectivityResult.none){
        tower.dispatch(SetConnectivityEvent(false));
      }
      else{
        tower.dispatch(SetConnectivityEvent(true));
      }
    });
  }

  /// Reset the Swipe Feed back to its initial state
  Future<bool> reset() async {
    if(tower.state.items.isNotEmpty && !(tower.state.items[0].item2.state.state is SwipeCardHideState)){
      _setCardState(SwipeCardHideState());
      await Future.delayed(Duration(milliseconds: 500)); 
    }
    final completer = Completer<bool>();
    Function complete = (){
      completer.complete(true);
    };
    tower.dispatch(refresh<T>(onComplete: complete));

    return completer.future;
  }

  /// reverse and clear all animations
  Future<void> resetAnimations() async {
    if(widget.topAnimationSystemController != null) widget.topAnimationSystemController!.reverse();
    if(widget.bottomAnimationSystemController != null) widget.bottomAnimationSystemController!.reverse();
    if(backgroundSystemControllers.length >= 2){
      backgroundSystemControllers[1].reverse();
      backgroundSystemControllers[0].reverse();
    }
    if(swipeFeedCardControllers.length > 0) await swipeFeedCardControllers[0].reverseAnimation();
  }

  /// Remove a card from the feed
  void _removeCard<T>([AdjustList<T>? then]){
    tower.dispatch(removeItem<T>(then));
  }

  /// Removes card when card swipes off the screen
  /// Assigns another swipe controller to the new card
  Future<T?> _onConinue() async {
    swipeFeedCardControllers.removeAt(0);
    backgroundSystemControllers.removeAt(0);
    swipeFeedCardControllers.add(SwipeFeedCardController());
    backgroundSystemControllers.add(AnimationSystemController());
    T? nextItem = tower.state.items[1].item1;
    // Duration after the card is swiped off the screen
    // Before the next card unmasks itself
    tower.dispatch(removeCard<T>());
    if((widget as SwipeFeed<T>).onLoad != null){
      (widget as SwipeFeed<T>).onLoad!(tower.state.items[1].item1);
    }
    return nextItem;
  }

  /// Remove Item by Id from the feed
  void _removeItemById(String id){
    tower.dispatch(removeItemById<T>(id, (widget as SwipeFeed<T>).objectKey));
  }

  /// Add a card to the feed
  void _addCard(T item, [Function? onComplete]) {
    backgroundSystemControllers.removeAt(1);
    swipeFeedCardControllers.removeAt(1);
    swipeFeedCardControllers.insert(0, SwipeFeedCardController());
    backgroundSystemControllers.insert(0, AnimationSystemController());
    tower.dispatch(addItem<T>(item, onComplete: onComplete));
  }

  void _updateCard(T item, String id){
    tower.dispatch(updateItem<T>(item, id, (widget as SwipeFeed<T>).objectKey));
  }

  /// Swipes the card at the top of the list in a specific direction
  void _swipe(DismissDirection direction){
    if(enabled) swipeFeedCardControllers[0].swipe(direction);
  }

  /// Sets the card to the passed in state
  void _setCardState(FeedCardState state){
    if(tower.state.items.isNotEmpty && tower.state.items[0].item1 != null){
      tower.state.items[0].item2.dispatch(SetSwipeFeedCardState(state));
    }
  }

  /// Build Swipe Card
  Widget _buildCard(int index){
    if(index >= tower.state.items.length){
      return SizedBox.shrink();
    }

    Tuple2<T?, Store<SwipeFeedCardState>> item = tower.state.items[index];

    if(!initiated){
      if(item.item1 != null && (widget as SwipeFeed<T>).onLoad != null && index == 0){
        (widget as SwipeFeed<T>).onLoad!(item.item1);
        initiated = true;
      }
    }
    
    return SwipeFeedCard<T>(
      key: Key('swipefeed - card - ${item.item1 == null ? 'last - card - key' : (widget as SwipeFeed<T>).objectKey(item.item1!)}'),
      objectKey: (widget as SwipeFeed<T>).objectKey,
      backgroundDelegate: widget.backgroundDelegate,
      backgroundController: backgroundSystemControllers[index],
      topAnimationSystemController: widget.topAnimationSystemController,
      bottomAnimationSystemController: widget.bottomAnimationSystemController,
      controller: swipeFeedCardControllers[index],
      padding: widget.padding,
      item: item,
      index: index,
      childBuilder: (widget as SwipeFeed<T>).childBuilder,
      loadingPlaceHolder: (widget as SwipeFeed<T>).loadingPlaceHolder,
      background: (widget as SwipeFeed<T>).background,
      canExpand: (widget as SwipeFeed<T>).canExpand,
      mask: widget.mask,
      isLast: tower.state.items.length == 1,
      onLoad: (widget as SwipeFeed<T>).onLoad,
      onPanUpdate: (dx, dy){
        if(swipeFeedCardControllers[index].isBinded()){
          if(widget.bottomAnimationSystemController != null && widget.bottomAnimationSystemController!.isBinded()){
            widget.bottomAnimationSystemController!.onUpdate(dx, dy, swipeFeedCardControllers[index].value);
          }
          if(widget.topAnimationSystemController != null && widget.topAnimationSystemController!.isBinded()){
            widget.topAnimationSystemController!.onUpdate(dx, dy, swipeFeedCardControllers[index].value);
          }
          if(backgroundSystemControllers.length >= 2 && widget.backgroundDelegate != null && backgroundSystemControllers[1].isBinded()){
            backgroundSystemControllers[1].onUpdate(dx, dy, swipeFeedCardControllers[index].value);
          }
        }
      },
      onSwipe: (dx, dy, reverseAnimation, dir, duration) async {
        if((widget as SwipeFeed<T>).onSwipe != null && item.item1 != null){
          enabled = false;
          bool value = await (widget as SwipeFeed<T>).onSwipe!(dx, dy, dir, duration, reverseAnimation, item.item1!);
          enableAutoSwiping();
          return value;
        }
        return true;
      },
      onContinue: () async {
        T? item = await _onConinue();
        // Duration for the switching of a card to go from hide state to show state
        await Future.delayed(Duration(milliseconds: 200));
        if((widget as SwipeFeed<T>).onConinue != null){
          (widget as SwipeFeed<T>).onConinue!(item);
        }
        if(widget.bottomAnimationSystemController != null){
          widget.bottomAnimationSystemController!.reset();
        }
        if(widget.topAnimationSystemController != null){
          widget.topAnimationSystemController!.reset();
        }
      },
    );
  }

  /// Build Method!!
  @override
  Widget build(BuildContext context) {
    return StoreProvider(
      store: tower,
      child: StoreConnector<SwipeFeedState<T>, List<Tuple2<T?, Store<SwipeFeedCardState>>>>(
        converter: (store) => store.state.items,
        builder: (context, state) {
          return Stack(
            children: [

              // Animation system
              widget.bottomDelegate != null && widget.bottomAnimationSystemController != null ? 
              AnimationSystemDelegateBuilder(
                key: Key("Percent - Bar - Animation - System"),
                controlHeptic: true,
                controller: widget.bottomAnimationSystemController!, 
                delegate: widget.bottomDelegate!,
                animateAccordingToPosition: widget.bottomDelegate!.animateAccordingToPosition,
              ) : SizedBox.shrink(),

              _buildCard(1),

              // Animation system
              widget.topDelegate != null && widget.topAnimationSystemController != null ? 
              AnimationSystemDelegateBuilder(
                key: Key("Icon - Animation - System"),
                controller: widget.topAnimationSystemController!, 
                delegate: widget.topDelegate!,
                animateAccordingToPosition: widget.topDelegate!.animateAccordingToPosition
              ) : SizedBox.shrink(),

              _buildCard(0)
            ],
          );
        }
      )
    );
  }
}

class SwipeFeedController<T> extends ChangeNotifier{
  late _SwipeFeedState<T>? _state;

  ///Binds the feed state
  void _bind(_SwipeFeedState<T> bind) => _state = bind;
  
  //Called to notify all listners
  void _update() => notifyListeners();

  ///Retreives the list of items from the feed
  List get list => _state != null ? _state!.tower.state.items.where((e) => e.item1 != null).map((e) => e.item1!).toList() : [];

  ///Reloads the feed state based on the original size parameter
  void loadMore() => _state != null ? _state!.tower.dispatch(loadMore) : null;

  ///Refreshes the feed replacing the page token
  void refreshFeed() => _state != null ? _state!.tower.dispatch(refresh<T>()) : null;

  ///Reset the swipe feed back to it's initial state
  ///By default this function calls refresh and will refresh the loader with a null pagetoken
  Future<bool> reset() => _state!.reset();

  ///Add an item to the feed, animates in by default
  void addCard(T item, [Function? onComplete]) => _state != null ? _state!._addCard(item, onComplete) : null;

  ///Removes an item from the feed, animates the item out of the feed by default
  void removeCard<T>([AdjustList<T>? then]) => _state != null ? _state!._removeCard<T>(then) : null;

  ///Removes item by Id from the feed, no animation
  void removeItemById(String id) => _state != null ? _state!._removeItemById(id) : null;

  ///Updates the current card at the top of the list
  void updateCard(T item, String id) => _state != null ? _state!._updateCard(item, id) : null;

  ///Swipe the top most card in the specified direction
  void swipe(DismissDirection direction) => _state != null ? _state!._swipe(direction) : null;

  ///Set the card to the new state, if the card is not a null card
  void setCardState(FeedCardState state) => _state != null ? _state!._setCardState(state) : null;

  ///Reverse all animations back to starting positions
  Future<void> reverseAnimations() async => _state != null ? _state!.resetAnimations() : null;

  // Retrieves background controller from the feed
  AnimationSystemController? backgroundController() => _state != null && _state!.backgroundSystemControllers.length >= 2 ? _state!.backgroundSystemControllers[1] : null;

  /// Get the collective state of items from the feed
  InitialFeedState<T> get collectiveState => InitialFeedState(
    items: _state!.tower.state.items.where((element) => element.item1 != null).map((e) => e.item1).toList(),
    pageToken: _state!.tower.state.pageToken,
    hasMore: _state!.tower.state.hasMore
  );

  //Disposes of the controller
  @override
  void dispose() {
    _state = null;
    super.dispose();
  }
}