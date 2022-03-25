import 'dart:math';
import 'package:connectivity/connectivity.dart';
import 'package:feed/animated/neumorpic_percent_bar.dart';
import 'package:feed/reference/swipe_feed_card_reference.dart';
import 'package:feed/swipeFeed/swipe_feed.dart';
import 'package:feed/util/global/functions.dart';
import 'package:feed/util/icon_position.dart';
import 'package:feed/util/render/keep_alive.dart';
import 'package:feed/util/state/concrete_cubit.dart';
import 'package:feed/util/state/feed_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_neumorphic_null_safety/flutter_neumorphic.dart';
import 'package:tuple/tuple.dart';

//______________________________  Exports  __________________________________\\

///Primary poll page for the application. 
///Holds a feed of popular polls and in swipe cards
class SwipeFeed<T> extends StatefulWidget {

  const SwipeFeed({ 
    Key? key, 
    this.childBuilder,
    required this.loader,
    required this.controller, 
    required this.icons,
    required this.objectKey,
    this.percentBarPadding,
    this.background,
    this.initialState, 
    this.onSwipe, 
    this.onContinue,
    this.overlayBuilder,
    this.swipeAlert,
    this.overrideSwipeAlert,
    this.padding,
    this.duration,
    this.placeholder,
    this.noPollsPlaceHolder,
    this.noConnectivityPlaceHolder,
    this.canExpand,
    this.style,
    this.overlayMaxDuration,
    this.lowerBound,
    this.heightOfCard,
    this.iconPadding,
    this.iconScale,
    this.topAlignment,
    this.bottomAlignment,
    this.startTopAlignment,
    this.startBottomAlignment
  }): super(key: key);

  @override
  _SwipeFeedState<T> createState() => _SwipeFeedState<T>();

  final AlignmentGeometry? topAlignment;

  final AlignmentGeometry? bottomAlignment;

  final AlignmentGeometry? startTopAlignment;

  final AlignmentGeometry? startBottomAlignment;

  final double? iconScale;

  final EdgeInsets? iconPadding;

  final EdgeInsets? percentBarPadding;

  final double? heightOfCard;

  final double? lowerBound;

  final Map<DismissDirection, Duration>? overlayMaxDuration;

  final bool Function(T)? canExpand;

  final List<IconData> icons;

  final String Function(T item) objectKey;

  /// No Polls
  final Widget? noPollsPlaceHolder;

  /// No Connectivity
  final Widget? noConnectivityPlaceHolder;

  /// The overlay to be shown
  final Widget Function(Future<void> Function(int, bool overlay), Future<void> Function(int), int, T)? overlayBuilder;

  /// If the overlay should be shown
  final bool Function(int)? swipeAlert;

  final bool Function(int index, dynamic item, DismissDirection direction)? overrideSwipeAlert;

  ///A builder for the feed
  final SwipeFeedBuilder<T>? childBuilder;

  /// Background behind the card
  final Widget Function(BuildContext context, Widget? child)? background;

  ///A loader for the feed
  final FeedLoader<T> loader;

  ///If defined, then the refresh is not called on init and the feed state is provided
  final InitialFeedState<T>? initialState;

  ///Controller for the swipe feed
  final SwipeFeedController controller;

  ///The on swipe function, run when a card is swiped
  final Future<void> Function(double dx, double dy, DismissDirection direction, Future<void> Function(int), T item)? onSwipe;

  ///The on swipe function, run when a card is completed swiping away
  final Future<void> Function(DismissDirection direction, T item)? onContinue;

  ///Padding for the swipe feed
  final EdgeInsets? padding;

  ///Duration for expanding the swipe car
  final Duration? duration;

  final Widget? placeholder;

  final TextStyle? style;
}

class _SwipeFeedState<T> extends State<SwipeFeed<T>> with AutomaticKeepAliveClientMixin, TickerProviderStateMixin{

  static const int LENGTH_INCREASE_FACTOR = 10;

  static const int LOAD_MORE_LIMIT = 3;

  ///List of loaded items
  List<T> items = [];

  ///A token for the page
  String? pageToken;

  //determines whether there are more items to display
  bool hasMore = true;

  ///Prevents duplicate loadCalls
  bool loading = false;

  bool lock = false;

  ConcreteCubit<List<Tuple2<T?, ConcreteCubit<SwipeFeedCardStateReference>>>> cubit = ConcreteCubit<List<Tuple2<T?, ConcreteCubit<SwipeFeedCardStateReference>>>>([]);

  ///Percent Bar controller
  late PercentBarController fillController;

  ///Controls automating swipes
  List<SwipeFeedCardController> swipeFeedCardControllers = [];

  bool connectivity = true;

  ///The collective state since the last refresh
  InitialFeedState<T> collectiveState = InitialFeedState<T>(
    items: [],
    hasMore: true,
    pageToken: null
  );

  EdgeInsets get padding => widget.padding ?? EdgeInsets.zero;

  Duration get duration => widget.duration ?? Duration(milliseconds: 0);

  bool get isExpandable => widget.duration != null;
  
  Widget? get placeholder => widget.placeholder;

  @override
  void initState(){
    super.initState();

    // Initialize Controllers
    fillController = PercentBarController();
    swipeFeedCardControllers.add(SwipeFeedCardController());
    swipeFeedCardControllers.add(SwipeFeedCardController());

    if(widget.initialState == null) {
      // _loadMore();
      _refresh();
    }
    else{
      populateInitialState(widget.initialState!);
    }

    checkConnectivity();

    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if(result == ConnectivityResult.none){
        connectivity = false;
      }
      else{
        connectivity = true;
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    //Bind the controller
    widget.controller._bind(this);
  }

  void populateInitialState(InitialFeedState<T> state){
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {

      List<Tuple2<T?, ConcreteCubit<SwipeFeedCardStateReference>>> cubitItems = 
        List<Tuple2<T?, ConcreteCubit<SwipeFeedCardStateReference>>>.generate(
          state.items.length, (i) => Tuple2(state.items[i], ConcreteCubit<SwipeFeedCardStateReference>(i == 0 ? ShowSwipeFeedCardState() : HideSwipeFeedCardState())));

      if(cubitItems.isEmpty){
        _refresh();
      }
      else{
        cubit.emit(cubitItems);
        collectiveState = state;
        setState(() {
          pageToken = state.pageToken;
          hasMore = state.hasMore;
        });
      }
    });
  }

  bool setCardState(SwipeFeedCardStateReference state,){
    if(cubit.state.isNotEmpty){
      if(state is HideSwipeFeedCardState) clearBar(state.text);
      cubit.state[0].item2.emit(state);
      return true;
    }
    return false;
  }

  ///Adds an item to the start of the swipe feed. 
  Future<void> animateItem(T item) async {
    var showCubit;
    final items = [...cubit.state];

    if(items.isEmpty){
      //Adds a mimnimized card if list is empty
      showCubit = ConcreteCubit<SwipeFeedCardStateReference>(HideSwipeFeedCardState());
      final placeholder = Tuple2<T?, ConcreteCubit<SwipeFeedCardStateReference>>(item, showCubit);
      items.add(placeholder);
    }
    else if(items[0].item1 == null){
      //Determine if the first card is a null card
      //Replaces card
      items[0] = Tuple2<T?, ConcreteCubit<SwipeFeedCardStateReference>>(item, items[0].item2);
    }
    else{
      //Minimizes current card and replaces it

      //Set the current first item state to hidden
      clearBar();
      items[0].item2.emit(HideSwipeFeedCardState());
      await Future.delayed(Duration(seconds: 1));

      //Add a new item to the start with a new state
      showCubit = ConcreteCubit<SwipeFeedCardStateReference>(HideSwipeFeedCardState());
      items.insert(0, Tuple2(item, showCubit));
    }

    //Emit the state
    cubit.emit(items);

    if(showCubit == null){
      return;
    }

    //Maximizes the card
    await Future.delayed(Duration(seconds: 1)).then((value){
      cubit.state[0].item2.emit(ShowSwipeFeedCardState());
    });
  }

  ///Removes the top most item from the multi feed, runs a predefined function before continuing
  Future<void> animatedRemove([List<Tuple2<T?, ConcreteCubit<SwipeFeedCardStateReference>>> Function(List<Tuple2<T?, ConcreteCubit<SwipeFeedCardStateReference>>>)? then]) async {
    var items = [...cubit.state];

    if(items.isEmpty || items[0].item1 == null){
      //Does nothing
      return;
    }
    // //Minimizes current card and replaces it
    // //Set the current first item state to hidden
    // if(!(items[0].item2.state is HideSwipeFeedCardState)){
    // }
    bool longDelay = !(items[0].item2.state is HideSwipeFeedCardState);
    
    items[0].item2.emit(HideSwipeFeedCardState());
    
    if(longDelay)
      clearBar();
    await Future.delayed(Duration(milliseconds: longDelay ? 1000 : 300));

    ///DO NOT REMOVE FIRST ITEM
    items = [
      items[0],
      ...((then?.call(items.sublist(1))) ?? items.sublist(1))
    ];

    assert(items.isNotEmpty);

    //Remove the item
    if(items.length == 1) {
      items[0] = Tuple2(null, items[0].item2);
    }
    else{
      items[0] = Tuple2(items[1].item1, items[0].item2);
      items.removeAt(1);
    }

    cubit.emit(items);

    //Maximizes the card
    await Future.delayed(Duration(milliseconds: 400)).then((value){
      if(cubit.state[0].item1 == null){
        cubit.state[0].item2.emit(HideSwipeFeedCardState(!connectivity ? widget.noConnectivityPlaceHolder : widget.noPollsPlaceHolder));
      }
      else{
        items[0].item2.emit(ShowSwipeFeedCardState());
      }
    });

  }

  void checkConnectivity() async {
    ConnectivityResult connectivityResult = await Connectivity().checkConnectivity();
    connectivity = connectivityResult != ConnectivityResult.none;
  }

  Future<void> completeFillBar(double value, Duration duration, [IconPosition? direction, CardPosition? cardPosition]) async => await fillController.completeFillBar(value, duration, direction, cardPosition);
  Future<void> fillBar(double value, IconPosition? direction, CardPosition cardPosition, [bool overrideLock = false]) async => await fillController.fillBar(min(0.75, value * 0.94), direction, cardPosition, overrideLock);
  void clearBar([String text = '']) => fillController.clearBar(text);

  void swipeRight(){
    if(!lock){
      lock = true;
      fillController.setDirection(IconPosition.LEFT, CardPosition.Left);
      swipeFeedCardControllers[0].swipeRight();
    }
  }

  void swipeLeft(){
    if(!lock){
      lock = true;
      fillController.setDirection(IconPosition.RIGHT, CardPosition.Right);
      swipeFeedCardControllers[0].swipeLeft();
    }
  }

  void setLock(bool newLock){
    lock = newLock;
  }
  
  void _removeCard(bool overlay){
    swipeFeedCardControllers.removeAt(0);
    swipeFeedCardControllers.add(SwipeFeedCardController());

    Future.delayed(Duration(milliseconds: overlay ? 200 : 1000)).then((value){
      if(cubit.state.length >= 2) {
        if(cubit.state[1].item1 == null){
          cubit.state[1].item2.emit(HideSwipeFeedCardState(!connectivity ? widget.noConnectivityPlaceHolder : widget.noPollsPlaceHolder));
        }
        else{
          cubit.state[1].item2.emit(ShowSwipeFeedCardState());
        }
      }
      Future.delayed(Duration(milliseconds: 400)).then((value){
        clearBar();
        cubit.emit([...cubit.state]..removeAt(0));
        if(cubit.state.length <= LOAD_MORE_LIMIT){
          _loadMore();
        }
        lock = false;
      });
    });
  }

  //Resets the page and loads more
  Future<void> _reset() async {

    items = [];
    pageToken = null;
    hasMore = true;
    loading = false;
    cubit.emit([]);

    if(mounted){
      setState(() {});
    }

    await _refresh();

  }

  /// Get current index
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

  Future<void> _refresh() async {
    //Skip loading if there are no more polls or you are currently loading
    if(loading){
      return;
    }

    collectiveState = InitialFeedState<T>(
      items: [],
      hasMore: true,
      pageToken: null
    );

    // Emit Loading State
    final showCubit = ConcreteCubit<SwipeFeedCardStateReference>(HideSwipeFeedCardState());
    final placeholder = Tuple2(null, showCubit);
    cubit.emit([
      placeholder
    ]);
    await Future.delayed(Duration(milliseconds: 500)).then((value){
      showCubit.emit(ShowSwipeFeedCardState());
    });

    loading = true;

    Tuple2<List<T>, String?> loaded = await widget.loader(LENGTH_INCREASE_FACTOR, null);

    loading = false;

    // New Items Loaded
    List<T> newItems = loaded.item1;

    // Old items will be empty but just a procaution
    List<Tuple2<T?, ConcreteCubit<SwipeFeedCardStateReference>>> oldItems = cubit.state;

    if(mounted) {
      setState(() {
        //New token
        pageToken = loaded.item2;

        //If there is no next page, then has more is false
        if(pageToken == null || newItems.length < LENGTH_INCREASE_FACTOR){
          hasMore = false;
        }


        //Cubit items
        List<Tuple2<T?, ConcreteCubit<SwipeFeedCardStateReference>>> cubitItems = 
        List<Tuple2<T?, ConcreteCubit<SwipeFeedCardStateReference>>>.generate(
          newItems.length, (i) => Tuple2(newItems[i], ConcreteCubit<SwipeFeedCardStateReference>(HideSwipeFeedCardState())));
        
        if(cubitItems.isNotEmpty && oldItems[0].item1 == null){
          oldItems[0] = Tuple2(cubitItems[0].item1, oldItems[0].item2);
          cubitItems.removeAt(0);
          if(hasMore == false){
            cubitItems.add(Tuple2(null, ConcreteCubit<SwipeFeedCardStateReference>(HideSwipeFeedCardState())));
          }
        }
        else if(oldItems[0].item1 == null){
          //No replacement occured, animate loading card into no polls card
          if(hasMore == false)
            Future.delayed(Duration(milliseconds: 500)).then((value){
              showCubit.emit(HideSwipeFeedCardState(!connectivity ? widget.noConnectivityPlaceHolder : widget.noPollsPlaceHolder));
            });
        }

        final newState = [...oldItems, ...cubitItems];

        //Update collective feed state
        collectiveState = InitialFeedState<T>(
          items: newState.where((e) => e.item1 != null).map((e) => e.item1!).toList(),
          hasMore: hasMore,
          pageToken: pageToken
        );

        cubit.emit(newState);
        lock = false;
      });
    }
  }

  Future<void> _loadMore() async {
    
    //Skip loading if there are no more polls or you are currently loading
    if(loading || !hasMore){
      return;
    }

    //Add a loading card at the end
    bool wasEmpty = cubit.state.isEmpty;
    var showCubit;
    if(wasEmpty || cubit.state.last.item1 != null){
      showCubit = ConcreteCubit<SwipeFeedCardStateReference>(HideSwipeFeedCardState());
      var placeholder = Tuple2<T?, ConcreteCubit<SwipeFeedCardStateReference>>(null, showCubit);
      cubit.emit([
        ...cubit.state,
        placeholder,
      ]);
    }

    loading = true;

    Tuple2<List<T>, String?> loaded = await widget.loader(LENGTH_INCREASE_FACTOR, pageToken);
    
    loading = false;

    List<T> newItems = loaded.item1;
    List<Tuple2<T?, ConcreteCubit<SwipeFeedCardStateReference>>> oldItems = cubit.state;

    if(mounted) {
      setState(() {
        //New token
        pageToken = loaded.item2;

        //If there is no next page, then has more is false
        if(pageToken == null || newItems.length < LENGTH_INCREASE_FACTOR){
          hasMore = false;
        }

        //TODO emit
        //Cubit items
        List<Tuple2<T?, ConcreteCubit<SwipeFeedCardStateReference>>> cubitItems = 
        List<Tuple2<T?, ConcreteCubit<SwipeFeedCardStateReference>>>.generate(
          newItems.length, (i) => Tuple2(newItems[i], ConcreteCubit<SwipeFeedCardStateReference>(HideSwipeFeedCardState())));

        // if(oldItems.isEmpty && cubitItems.isNotEmpty){
        //   Future.delayed(Duration(milliseconds: 300)).then((value){
        //     cubitItems[0].item2.emit(ShowSwipeFeedCardState());
        //   });
        // }

        if(cubitItems.isEmpty && wasEmpty && showCubit != null){
          Future.delayed(Duration(milliseconds: 500)).then((value){
            showCubit.emit(HideSwipeFeedCardState(!connectivity ? widget.noConnectivityPlaceHolder : widget.noPollsPlaceHolder));
          });
        }
        else if(cubitItems.isNotEmpty && oldItems.isNotEmpty && oldItems.last.item1 == null){
          //Remove null value at end
          oldItems.removeLast();
        }
        
        //Update collective feed state
        collectiveState = InitialFeedState<T>(
          items: [...collectiveState.items, ...newItems],
          hasMore: hasMore,
          pageToken: pageToken
        );

        cubit.emit([...oldItems, ...cubitItems]);
        lock = false;
      });
    }
  }

  /// Add custom on top of the swipe feed state
  void addItem(T item){
    if(cubit.state.isNotEmpty){
      cubit.state[0].item2.emit(HideSwipeFeedCardState());
    }
    List<Tuple2<T?, ConcreteCubit<SwipeFeedCardStateReference>>> addNewItem = 
    [Tuple2(item, ConcreteCubit<SwipeFeedCardStateReference>(ShowSwipeFeedCardState())), ...cubit.state];
    cubit.emit(addNewItem);
  }

  /// Update item inside the swipe feed
  void updateItem(T item, String id){
    List<Tuple2<T?, ConcreteCubit<SwipeFeedCardStateReference>>> state = cubit.state;
    if(state.isNotEmpty){
      if(id == widget.objectKey(state[0].item1!)){
        state.remove(state[0]);
        cubit.emit(state);
        addItem(item);
      }
    }
  }

  /// Remove an item inside the swipe feed specified by the ID
  void removeItem(String id){
    List<Tuple2<T?, ConcreteCubit<SwipeFeedCardStateReference>>> state = cubit.state;
    if(state.isNotEmpty){
      if(id == widget.objectKey(state[0].item1!)){
        state.remove(state[0]);
        if(state.isNotEmpty){
          state[0].item2.emit(ShowSwipeFeedCardState());
        }
        cubit.emit(state);
      }
    }
  }

  ///Builds the type of item card based on the feed type. 
  ///If a custom child builder is present, uses the child builder instead
  Widget _loadCard(BuildContext context, T? item, bool show, int index, bool isExpanded, Widget? child, Function() close) {
    if(!show && widget.background != null){
      return Container(
        key: ValueKey('SwipeFeed Background Card ${child == null ? 'Without Child' : 'With Child'}'),
        child: widget.background!(context, SizedBox.expand(child: child))
      );
    }
    if(item == null){
      lock = true;
      return Container(
        key: item == null ? UniqueKey() : ValueKey('SwipeFeed Placeholder Card ' + widget.objectKey(item)),
        child: placeholder ?? SizedBox.shrink()
      );
    }
    else if(widget.childBuilder != null && item != null){
      //Builds custom child if childBuilder is defined
      return Container(
        key: item == null ? UniqueKey() : ValueKey('SwipeFeed Child Card ' + widget.objectKey(item)),
        child: widget.childBuilder!(item, index == 1, isExpanded, close)
      );
    }
    else {
      throw ('T is not supported by Feed');
    }
  }

  Widget _buildCard(int index){
    if(index >= cubit.state.length){
      return Container();
    }

    var mediaQuery = MediaQuery.of(context);

    Tuple2<T?, ConcreteCubit<SwipeFeedCardStateReference>> itemCubit = cubit.state[index];
    return BlocBuilder<ConcreteCubit<SwipeFeedCardStateReference>, SwipeFeedCardStateReference>(
      key: Key('swipefeed - card - ${itemCubit.item1 == null ? UniqueKey().toString() : widget.objectKey(itemCubit.item1!)}'),
      bloc: itemCubit.item2,
      builder: (context, show) {

        ///Te child to display on the hidden card
        Widget? hiddenChild = show is HideSwipeFeedCardState ? show.overlay : null;

        return KeyboardVisibilityBuilder(
          builder: (context, keyboard){
            return AnimatedPadding(
              duration: duration,
              padding: show is ExpandSwipeFeedCardState ? EdgeInsets.zero : (keyboard ? padding.copyWith(bottom: 0): padding),
              child: GestureDetector(
                onTap: itemCubit.item1 != null && widget.canExpand != null && 
                widget.canExpand!(itemCubit.item1!) && show is ShowSwipeFeedCardState && 
                isExpandable && !keyboard ? (){
                  itemCubit.item2.emit(ExpandSwipeFeedCardState());
                } : null,
                child: Opacity(
                  opacity: keyboard && show is HideSwipeFeedCardState ? 0.0 : 1.0,
                  child: SwipeFeedCard(
                    blur: show is HideSwipeFeedCardState && show.overlay == null,
                    startTopAlignment: widget.startTopAlignment,
                    startBottomAlignment: widget.startBottomAlignment,
                    topAlignment: widget.topAlignment,
                    bottomAlignment: widget.bottomAlignment,
                    iconPadding: widget.iconPadding,
                    iconScale: widget.iconScale,
                    swipeOverride: itemCubit.item1 != null,
                    overlayMaxDuration: widget.overlayMaxDuration,
                    icons: widget.icons,
                    swipeFeedController: widget.controller,
                    fillController: fillController,
                    swipeFeedCardController: swipeFeedCardControllers[index],
                    lowerBound: widget.lowerBound,
                    heightOfCard: widget.heightOfCard,
                    overlay: (forwardAnimation, reverseAnimation, index){
                      if(widget.overlayBuilder != null && itemCubit.item1 != null)
                        return widget.overlayBuilder!(forwardAnimation, reverseAnimation, index, itemCubit.item1!);
                      return null;
                    },
                    onPanUpdate: (double dx, double dy, [double? maxX, double? maxYTop, double? maxYBot]) {
                      if(show is ExpandSwipeFeedCardState){
                        itemCubit.item2.emit(ShowSwipeFeedCardState());
                      }
                    },
                    overrideSwipeAlert: (index, direction){
                        return widget.overrideSwipeAlert!(index, itemCubit.item1, direction);
                    },
                    swipeAlert: widget.swipeAlert,
                    keyboardOpen: keyboard,
                    show: show is ShowSwipeFeedCardState || show is ExpandSwipeFeedCardState,
                    onFill: (fill, iconPosition, cardPosition, overrideLock) {
                      fillBar(fill, iconPosition, cardPosition, overrideLock);
                    },

                    onContinue: itemCubit.item1 != null ? (dir, overlay) async {
                      if(widget.onContinue != null){
                        await widget.onContinue!(dir!, itemCubit.item1!);
                      }
                      _removeCard(overlay);
                    } : null,
                    onDismiss: (){
                      // Nothing
                    },
                    onSwipe: (dx, dy, reverseAnimation, dir) {
                      if(widget.onSwipe != null && itemCubit.item1 != null){
                        widget.onSwipe!(dx, dy, dir, reverseAnimation, itemCubit.item1!);
                      }
                    },
                    onPanEnd: () {
                      // Nothing
                    },
                    child: AnimatedSwitcher(
                      duration: Duration(milliseconds: 200),
                      child: _loadCard(context, itemCubit.item1, !(show is HideSwipeFeedCardState), index, show is ExpandSwipeFeedCardState, hiddenChild, (){
                        itemCubit.item2.emit(ShowSwipeFeedCardState());
                      },
                    ),
                  ),
                ),
              ),
            ),
            );
          },
        );
      }
    );
  }
  

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Stack(
    key: Key('NeumorpicPercentBar'),
    children: [
          
        //Percent bar displaying current vote
        Padding(
          padding: widget.percentBarPadding ?? EdgeInsets.only(left: 8 + padding.left, right: 8 + padding.right, top: padding.top + 6, bottom: padding.top),
          child: KeepAliveWidget( 
            key: Key('PollPage - Bar - KeepAlive'),
            child: NeumorpicPercentBar(
              key: Key('PollPage - Bar'),
              controller: fillController,
              style: widget.style,
            ),
          ),
        ),


        BlocBuilder<ConcreteCubit<List<Tuple2<T?, ConcreteCubit<SwipeFeedCardStateReference>>>>, List<Tuple2<T?, ConcreteCubit<SwipeFeedCardStateReference>>>>(
          bloc: cubit,
          builder: (context, state) {
            
            return Stack(
              children: [
                // state.length <= 1 ? 
                // (widget.noPollsPlaceHolder != null && connectivity == false ? 
                  // AnimatedSwitcher(
                  //   duration: Duration(milliseconds: 300),
                  //   reverseDuration: Duration(milliseconds: 300),
                  //   child: state.length == 1 ? Padding(
                  //     key: Key("Display-Background-No-Polls-Or-Connectivity"),
                  //     padding: EdgeInsets.only(top: 74),
                  //     child: Padding(
                  //       padding: padding,
                  //       child: Center(child: widget.background?.call())),
                  //   ) : Padding(
                  //     key: Key("Display-No-Polls-Or-Connectivity"),
                  //     padding: EdgeInsets.only(top: 74),
                  //     child: Padding(
                  //       padding: padding,
                  //       child: Center(child: widget.noConnectivityPlaceHolder!),
                  //     ),
                  //   )
                  // ) : widget.noPollsPlaceHolder != null ? 
                  // AnimatedSwitcher(
                  //   duration: Duration(milliseconds: 300),
                  //   reverseDuration: Duration(milliseconds: 300),
                  //   child: state.length == 1 ? Padding(
                  //     key: Key("Display-Background-No-Polls"),
                  //     padding: EdgeInsets.only(top: 74),
                  //     child: Padding(
                  //       padding: padding,
                  //       child: Center(child: widget.background?.call())),
                  //   ) : Padding(
                  //     key: Key("Display-No-Polls"),
                  //     padding: EdgeInsets.only(top: 74),
                  //     child: Padding(
                  //       padding: padding,
                  //       child: Center(child: widget.noPollsPlaceHolder!),
                  //     ),
                  //   )) : 
                  // SizedBox.shrink()) : SizedBox.shrink(),

                _buildCard(1),

                _buildCard(0),
              ],
            );
          },
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;

}

// ///Controller for the feed
// class SwipeFeedController<T> extends ChangeNotifier {
//   late _SwipeFeedState<T>? _state;

//   ///Binds the feed state
//   void _bind(_SwipeFeedState<T> bind) => _state = bind;

//   //Called to notify all listners
//   void _update() => notifyListeners();

//   ///Retreives the list of items from the feed
//   List<T> get list => _state!.cubit.state.where((e) => e.item1 != null).map((e) => e.item1!).toList();

//   ///The state of the feed since the last refresh
//   InitialFeedState<T> get collectiveState => _state!.collectiveState;

//   ///Reloads the feed state based on the original size parameter
//   void loadMore() => _state!._loadMore();

//   ///Refreshes the feed replacing the page token
//   void refresh() => _state!._refresh();

//   ///Reloads the feed state based on the original size parameter
//   Future<void> reset() => _state!._reset();

//   Future<void> completeFillBar(double value, Duration duration, [IconPosition? direction, CardPosition? cardPosition]) async => _state == null ? _state!.items : await _state!.completeFillBar(value, duration, direction, cardPosition);

//   Future<void> fillBar(double value, IconPosition iconDirection, CardPosition cardPosition, [bool overrideLock = false]) async => _state == null ? _state!.items : await _state!.fillBar(value, iconDirection, cardPosition, overrideLock);
  
//   void clearBar([String title = '']) => _state == null ? null : _state!.clearBar(title);

//   void addItem(T item) => _state != null ? _state!.addItem(item) : null;

//   Future<void> animateItem(T item) async => _state != null ? await _state!.animateItem(item) : null;

//   void updateItem(T item, String id) => _state != null ? _state!.updateItem(item, id) : null;

//   void removeItem(String id) => _state != null ? _state!.removeItem(id) : null;

//   void animatedRemove([List<Tuple2<T?, ConcreteCubit<SwipeFeedCardStateReference>>> Function(List<Tuple2<T?, ConcreteCubit<SwipeFeedCardStateReference>>>)? then]) => _state != null ? _state!.animatedRemove(then) : null;

//   void swipeRight() => _state != null ? _state!.swipeRight() : null;

//   void swipeLeft() => _state != null ? _state!.swipeLeft() : null;

//   void setLock(bool lock) => _state != null ? _state!.setLock(lock) : null;

//   bool setCardState(SwipeFeedCardStateReference cardState) => _state != null ? _state!.setCardState(cardState) : false;

//   //Disposes of the controller
//   @override
//   void dispose() {
//     _state = null;
//     super.dispose();
//   }
// }