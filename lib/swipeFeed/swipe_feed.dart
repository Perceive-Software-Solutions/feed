import 'dart:async';

import 'package:connectivity/connectivity.dart';
import 'package:feed/feed.dart';
import 'package:feed/swipeFeed/state.dart';
import 'package:feed/swipeFeedCard/state.dart';
import 'package:feed/swipeFeedCard/swipe_feed_card.dart';
import 'package:feed/util/global/functions.dart';
import 'package:feed/util/state/feed_state.dart';
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

  /// Position of the card
  final dynamic Function(double, double)? onPanUpdate;

  ///The on swipe function, run when a card is swiped
  final Future<bool> Function(double dx, double dy, DismissDirection direction, Future<void> Function(), T item)? onSwipe;

  /// Function tells the feed if the card can expand
  final bool Function(dynamic)? canExpand;

  /// Padding applied to the Swipe Feed
  /// Has the option to animate
  final EdgeInsets? padding;

  /// Widget builds on top of the card behind the current card
  final Widget? mask;
  
  const SwipeFeed({ 
    Key? key,
    this.childBuilder,
    this.initialState,
    this.noItemsPlaceHolder,
    this.noConnectivityPlaceHolder,
    this.loadingPlaceHolder,
    this.background,
    this.onSwipe,
    this.onPanUpdate,
    this.canExpand,
    this.padding,
    this.mask,
    required this.loader,
    required this.objectKey,
    required this.controller
  }) : super(key: key);

  @override
  _SwipeFeedState<T> createState() => _SwipeFeedState<T>();
}

class _SwipeFeedState<T> extends State<SwipeFeed> {

  /// Holds the current state of the SwipeFeed
  late Tower<SwipeFeedState<T>> tower;

  ///Controls automating swipes
  List<SwipeFeedCardController> swipeFeedCardControllers = [];

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
      tower.dispatch(populateInitialState<T>(((widget as SwipeFeed<T>) as SwipeFeed<T>).initialState!));
    }

    /// Check initial Connectivity
    checkConnectivity();

    // Initiate SwipeCardControllers
    swipeFeedCardControllers.add(SwipeFeedCardController());
    swipeFeedCardControllers.add(SwipeFeedCardController());
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
    _setCardState(SwipeCardHideState());
    await Future.delayed(Duration(milliseconds: 500));
    final completer = Completer<bool>();
    Function complete = (){
      completer.complete(true);
    };
    tower.dispatch(refresh<T>(onComplete: complete));

    return completer.future;
  }

  /// Remove a card from the feed
  void _removeCard([AdjustList<T>? then]){
    tower.dispatch(removeItem<T>(then));
  }

  /// Removes card when card swipes off the screen
  /// Assigns another swipe controller to the new card
  void _onConinue() async {
    swipeFeedCardControllers.removeAt(0);
    swipeFeedCardControllers.add(SwipeFeedCardController());
    // Duration after the card is swiped off the screen
    // Before the next card unmasks itself
    await Future.delayed(Duration(milliseconds: 200));
    tower.dispatch(removeCard<T>());
  }

  /// Remove Item by Id from the feed
  void _removeItemById(String id){
    tower.dispatch(removeItemById<T>(id, (widget as SwipeFeed<T>).objectKey));
  }

  /// Add a card to the feed
  void _addCard(T item, [Function? onComplete]) {
    tower.dispatch(addItem<T>(item, onComplete));
  }

  void _updateCard(T item, String id){
    tower.dispatch(updateItem<T>(item, id, (widget as SwipeFeed<T>).objectKey));
  }

  /// Swipes the card at the top of the list in a specific direction
  void _swipe(DismissDirection direction){
    swipeFeedCardControllers[0].swipe(direction);
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

    return SwipeFeedCard<T>(
      key:  Key('swipefeed - card - ${item.item1 == null ? UniqueKey().toString() : (widget as SwipeFeed<T>).objectKey(item.item1!)}'),
      objectKey: (widget as SwipeFeed<T>).objectKey,
      controller: swipeFeedCardControllers[index],
      padding: widget.padding,
      item: item,
      childBuilder: (widget as SwipeFeed<T>).childBuilder,
      loadingPlaceHolder: (widget as SwipeFeed<T>).loadingPlaceHolder,
      background: (widget as SwipeFeed<T>).background,
      canExpand: (widget as SwipeFeed<T>).canExpand,
      mask: widget.mask,
      isLast: tower.state.items.length == 1,
      onPanUpdate: (dx, dy){
        if((widget as SwipeFeed<T>).onPanUpdate != null){
          (widget as SwipeFeed<T>).onPanUpdate!(dy, dy);
        }
      },
      onSwipe: (dx, dy, reverseAnimation, dir) async {
        if((widget as SwipeFeed<T>).onSwipe != null && item.item1 != null){
          return await (widget as SwipeFeed<T>).onSwipe!(dx, dy, dir, reverseAnimation, item.item1!);
        }
        return true;
      },
      onContinue: () async {
        _onConinue();
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
        builder: (context, items) {
          return Stack(
            children: [
              _buildCard(1),

              _buildCard(0)
            ],
          );
        }
      ),
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
  void refresh() => _state != null ? _state!.tower.dispatch(refresh) : null;

  ///Reset the swipe feed back to it's initial state
  ///By default this function calls refresh and will refresh the loader with a null pagetoken
  Future<bool> reset() => _state!.reset();

  ///Add an item to the feed, animates in by default
  void addCard(T item, [Function? onComplete]) => _state != null ? _state!._addCard(item, onComplete) : null;

  ///Removes an item from the feed, animates the item out of the feed by default
  void removeCard([AdjustList<T>? then]) => _state != null ? _state!._removeCard(then) : null;

  ///Removes item by Id from the feed, no animation
  void removeItemById(String id) => _state != null ? _state!._removeItemById(id) : null;

  ///Updates the current card at the top of the list
  void updateCard(T item, String id) => _state != null ? _state!._updateCard(item, id) : null;

  ///Swipe the top most card in the specified direction
  void swipe(DismissDirection direction) => _state != null ? _state!._swipe(direction) : null;

  ///Set the card to the new state, if the card is not a null card
  void setCardState(FeedCardState state) => _state != null ? _state!._setCardState(state) : null;

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