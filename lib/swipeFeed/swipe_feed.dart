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
  final String Function(T item) objectKey;

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

  /// Background of the card
  final Widget Function(BuildContext context, Widget? child)? background;

  /// Position of the card
  final dynamic Function(double, double)? onPanUpdate;

  ///The on swipe function, run when a card is swiped
  final Future<bool> Function(double dx, double dy, DismissDirection direction, Future<void> Function(), T item)? onSwipe;
  
  const SwipeFeed({ 
    Key? key,
    this.childBuilder,
    this.initialState,
    this.noItemsPlaceHolder,
    this.noConnectivityPlaceHolder,
    this.background,
    this.onSwipe,
    this.onPanUpdate,
    required this.loader,
    required this.objectKey,
    required this.controller
  }) : super(key: key);

  @override
  _SwipeFeedState<T> createState() => _SwipeFeedState<T>();
}

class _SwipeFeedState<T> extends State<SwipeFeed> {

  late Tower<SwipeFeedState> tower;

  ///Controls automating swipes
  List<SwipeFeedCardController> swipeFeedCardControllers = [];

  @override
  void initState(){
    super.initState();

    // Initiate state
    tower = Tower<SwipeFeedState>(
      swipeFeedStateReducer,
      initialState: SwipeFeedState.initial(
        widget.loader, 
        widget.noItemsPlaceHolder ?? Container(), 
        widget.noConnectivityPlaceHolder ?? Container()
      )
    );

    if(widget.initialState == null){
      // Initiate the feed from the loader
      tower.dispatch(refresh);
    }
    else{
      // Initiate the feed from an initial state
      tower.dispatch(populateInitialState(widget.initialState!));
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
    widget.controller._bind(this);
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

  /// Remove a card from the feed
  void _removeCard([AdjustList? then]){
    tower.dispatch(removeItem(then));
  }



  /// Build Swipe Card
  Widget _buildCard(int index){
    if(index >= tower.state.items.length){
      return Container();
    }

    Tuple2<dynamic, Store<SwipeFeedCardState>> item = tower.state.items[index];

    return SwipeFeedCard(
      controller: swipeFeedCardControllers[index],
      item: item,
      childBuilder: widget.childBuilder,
      background: widget.background,
      onPanUpdate: (dx, dy){
        if(widget.onPanUpdate != null){
          widget.onPanUpdate!(dy, dy);
        }
      },
      onSwipe: (dx, dy, reverseAnimation, dir) async {
        if(widget.onSwipe != null && item.item1 != null){
          return await widget.onSwipe!(dx, dy, dir, reverseAnimation, item.item1!);
        }
        return true;
      },
      onContinue: () async {
        _removeCard();
      },
    );
  }

  /// Build Method!!
  @override
  Widget build(BuildContext context) {
    return StoreProvider(
      store: tower,
      child: StoreConnector<SwipeFeedState, SwipeFeedState>(
        converter: (store) => store.state,
        builder: (context, state) {
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

  //Disposes of the controller
  @override
  void dispose() {
    _state = null;
    super.dispose();
  }
}