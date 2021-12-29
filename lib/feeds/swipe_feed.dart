import 'dart:math';
import 'package:connectivity/connectivity.dart';
import 'package:feed/animated/neumorpic_percent_bar.dart';
import 'package:feed/animated/swipe_feed_card.dart';
import 'package:feed/util/global/functions.dart';
import 'package:feed/util/icon_position.dart';
import 'package:feed/util/render/keep_alive.dart';
import 'package:feed/util/state/concrete_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
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
    this.loadManually = false, 
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

  ///Set to `true` if you want to prevent the feed from loading onCreate
  final bool loadManually;

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

  ConcreteCubit<List<Tuple2<T?, ConcreteCubit<SwipeFeedCardState>>>> cubit = ConcreteCubit<List<Tuple2<T?, ConcreteCubit<SwipeFeedCardState>>>>([]);

  ///Percent Bar controller
  late PercentBarController fillController;

  ///Controls automating swipes
  List<SwipeFeedCardController> swipeFeedCardControllers = [];

  late AnimationController controller;

  bool connectivity = true;

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

    if(!widget.loadManually) {
      // _loadMore();
      _refresh();
    }

    controller = new AnimationController(vsync: this);

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

  void checkConnectivity() async {
    ConnectivityResult connectivityResult = await Connectivity().checkConnectivity();
    connectivity = connectivityResult != ConnectivityResult.none;
  }

  Future<void> completeFillBar(double value, Duration duration, [IconPosition? direction, CardPosition? cardPosition]) async => await fillController.completeFillBar(value, duration, direction, cardPosition);
  Future<void> fillBar(double value, IconPosition? direction, CardPosition cardPosition, [bool overrideLock = false]) async => await fillController.fillBar(min(0.75, value * 0.94), direction, cardPosition, overrideLock);

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
        cubit.state[1].item2.emit(ShowSwipeFeedCardState());
      }
      Future.delayed(Duration(milliseconds: 400)).then((value){
        fillBar(0.0, null, CardPosition.Left);
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

    await _loadMore();

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

    // Emit Loading State
    final showCubit = ConcreteCubit<SwipeFeedCardState>(HideSwipeFeedCardState());
    cubit.emit([
      Tuple2(null, showCubit),
    ]);
    final placeHolderAnimation = Future.delayed(Duration(milliseconds: 500)).then((value){
      showCubit.emit(ShowSwipeFeedCardState());
    });

    loading = true;

    Tuple2<List<T>, String?> loaded = await widget.loader(LENGTH_INCREASE_FACTOR, pageToken);
    await placeHolderAnimation;

    loading = false;

    if(loaded.item1.isEmpty){
      items = [];
      pageToken = null;
      hasMore = true;
      loading = false;
      // cubit.emit([]);
      showCubit.emit(HideSwipeFeedCardState(widget.noPollsPlaceHolder));
      return;
    }

    // New Items Loaded
    List<T> newItems = loaded.item1;

    // Old items will be empty but just a procaution
    List<Tuple2<T?, ConcreteCubit<SwipeFeedCardState>>> oldItems = cubit.state;

    if(mounted) {
      setState(() {
        //New token
        pageToken = loaded.item2;

        //If there is no next page, then has more is false
        if(pageToken == null || newItems.length < LENGTH_INCREASE_FACTOR){
          hasMore = false;
        }

        //Cubit items
        List<Tuple2<T?, ConcreteCubit<SwipeFeedCardState>>> cubitItems = 
        List<Tuple2<T?, ConcreteCubit<SwipeFeedCardState>>>.generate(
          newItems.length, (i) => Tuple2(newItems[i], ConcreteCubit<SwipeFeedCardState>(HideSwipeFeedCardState())));

        
        for (var i = 0; i < min(min(2, oldItems.length), cubitItems.length); i++) {
          if(oldItems[i].item1 == null){
            oldItems[i] = Tuple2(cubitItems[0].item1, oldItems[i].item2);
            cubitItems.removeAt(0);
          }
        }

        if(oldItems.isEmpty && cubitItems.isNotEmpty){
          Future.delayed(Duration(milliseconds: 300)).then((value){
            cubitItems[0].item2.emit(ShowSwipeFeedCardState());
          });
        }
        
        cubit.emit([...oldItems, ...cubitItems]);
        lock = false;
      });
    }
  }

  Future<void> _loadMore() async {
    
    //Skip loading if there are no more polls or you are currently loading
    if(loading || !hasMore){
      return;
    }

    loading = true;

    Tuple2<List<T>, String?> loaded = await widget.loader(LENGTH_INCREASE_FACTOR, pageToken);
    
    loading = false;

    List<T> newItems = loaded.item1;
    List<Tuple2<T?, ConcreteCubit<SwipeFeedCardState>>> oldItems = cubit.state;

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
        List<Tuple2<T?, ConcreteCubit<SwipeFeedCardState>>> cubitItems = 
        List<Tuple2<T?, ConcreteCubit<SwipeFeedCardState>>>.generate(
          newItems.length, (i) => Tuple2(newItems[i], ConcreteCubit<SwipeFeedCardState>(HideSwipeFeedCardState())));


        for (var i = 0; i < min(min(2, oldItems.length), cubitItems.length); i++) {
          if(oldItems[i].item1 == null){
            oldItems[i] = Tuple2(cubitItems[0].item1, oldItems[i].item2);
            cubitItems.removeAt(0);
          }
        }

        if(oldItems.isEmpty && cubitItems.isNotEmpty){
          Future.delayed(Duration(milliseconds: 300)).then((value){
            cubitItems[0].item2.emit(ShowSwipeFeedCardState());
          });
        }
        
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
    List<Tuple2<T?, ConcreteCubit<SwipeFeedCardState>>> addNewItem = 
    [Tuple2(item, ConcreteCubit<SwipeFeedCardState>(ShowSwipeFeedCardState())), ...cubit.state];
    cubit.emit(addNewItem);
  }

  /// Update item inside the swipe feed
  void updateItem(T item, String id){
    List<Tuple2<T?, ConcreteCubit<SwipeFeedCardState>>> state = cubit.state;
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
    List<Tuple2<T?, ConcreteCubit<SwipeFeedCardState>>> state = cubit.state;
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
        key: item == null ? UniqueKey() : ValueKey('SwipeFeed Background Card ' + widget.objectKey(item)),
        child: widget.background!(context, child)
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

    Tuple2<T?, ConcreteCubit<SwipeFeedCardState>> itemCubit = cubit.state[index];
    return BlocBuilder<ConcreteCubit<SwipeFeedCardState>, SwipeFeedCardState>(
      key: Key('swipefeed - card - ${itemCubit.item1 == null ? UniqueKey().toString() : widget.objectKey(itemCubit.item1!)}'),
      bloc: itemCubit.item2,
      builder: (context, show) {

        ///Te child to display on the hidden card
        Widget? hiddenChild = show is HideSwipeFeedCardState ? show.overlay : null;

        return KeyboardVisibilityBuilder(
          builder: (context, keyboard){
            if(keyboard){
              controller.animateTo(1.0, duration: Duration(milliseconds: 200), curve: Curves.easeInOutCubic);
            }
            else{
              controller.animateTo(0.0, duration: Duration(milliseconds: 200), curve: Curves.easeInOutCubic);
            }
            return AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, (keyboard && !(show is HideSwipeFeedCardState)) ? (show is ExpandSwipeFeedCardState) ? 0 : -1 * controller.value * (mediaQuery.viewInsets.bottom - padding.bottom) : 0),
                  child: AnimatedPadding(
                    duration: duration,
                    padding: show is ExpandSwipeFeedCardState ? EdgeInsets.zero : padding,
                    child: GestureDetector(
                      onTap: itemCubit.item1 != null && widget.canExpand != null && 
                      widget.canExpand!(itemCubit.item1!) && show is ShowSwipeFeedCardState && 
                      isExpandable && !keyboard ? (){
                        itemCubit.item2.emit(ExpandSwipeFeedCardState());
                      } : null,
                      child: Opacity(
                        opacity: keyboard && show is HideSwipeFeedCardState ? 0.0 : 1.0,
                        child: SwipeFeedCard(
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
                ));
              }
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


        BlocBuilder<ConcreteCubit<List<Tuple2<T?, ConcreteCubit<SwipeFeedCardState>>>>, List<Tuple2<T?, ConcreteCubit<SwipeFeedCardState>>>>(
          bloc: cubit,
          builder: (context, state) {
            
            return Stack(
              children: [
                // state.length <= 1 ? 
                // (widget.noPollsPlaceHolder != null && connectivity == false ? 
                //   AnimatedSwitcher(
                //     duration: Duration(milliseconds: 300),
                //     reverseDuration: Duration(milliseconds: 300),
                //     child: state.length == 1 ? Padding(
                //       key: Key("Display-Background-No-Polls-Or-Connectivity"),
                //       padding: EdgeInsets.only(top: 74),
                //       child: Padding(
                //         padding: padding,
                //         child: Center(child: widget.background)),
                //     ) : Padding(
                //       key: Key("Display-No-Polls-Or-Connectivity"),
                //       padding: EdgeInsets.only(top: 74),
                //       child: Padding(
                //         padding: padding,
                //         child: Center(child: widget.noConnectivityPlaceHolder!),
                //       ),
                //     )
                //   ) : widget.noPollsPlaceHolder != null ? 
                //   AnimatedSwitcher(
                //     duration: Duration(milliseconds: 300),
                //     reverseDuration: Duration(milliseconds: 300),
                //     child: state.length == 1 ? Padding(
                //       key: Key("Display-Background-No-Polls"),
                //       padding: EdgeInsets.only(top: 74),
                //       child: Padding(
                //         padding: padding,
                //         child: Center(child: widget.background)),
                //     ) : Padding(
                //       key: Key("Display-No-Polls"),
                //       padding: EdgeInsets.only(top: 74),
                //       child: Padding(
                //         padding: padding,
                //         child: Center(child: widget.noPollsPlaceHolder!),
                //       ),
                //     )) : 
                //   SizedBox.shrink()) : SizedBox.shrink(),

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

///Controller for the feed
class SwipeFeedController<T> extends ChangeNotifier {
  late _SwipeFeedState<T>? _state;

  ///Binds the feed state
  void _bind(_SwipeFeedState<T> bind) => _state = bind;

  //Called to notify all listners
  void _update() => notifyListeners();

  ///Retreives the list of items from the feed
  List<T> get list => _state!.items;

  ///Reloads the feed state based on the original size parameter
  void loadMore() => _state!._loadMore();

  ///Refreshes the feed replacing the page token
  void refresh() => _state!._refresh();

  ///Reloads the feed state based on the original size parameter
  void reset() => _state!._reset();

  Future<void> completeFillBar(double value, Duration duration, [IconPosition? direction, CardPosition? cardPosition]) async => _state == null ? _state!.items : await _state!.completeFillBar(value, duration, direction, cardPosition);

  Future<void> fillBar(double value, IconPosition iconDirection, CardPosition cardPosition, [bool overrideLock = false]) async => _state == null ? _state!.items : await _state!.fillBar(value, iconDirection, cardPosition, overrideLock);

  void addItem(T item) => _state != null ? _state!.addItem(item) : null;

  void updateItem(T item, String id) => _state != null ? _state!.updateItem(item, id) : null;

  void removeItem(String id) => _state != null ? _state!.removeItem(id) : null;

  void swipeRight() => _state != null ? _state!.swipeRight() : null;

  void swipeLeft() => _state != null ? _state!.swipeLeft() : null;

  void setLock(bool lock) => _state != null ? _state!.setLock(lock) : null;

  //Disposes of the controller
  @override
  void dispose() {
    _state = null;
    super.dispose();
  }
}