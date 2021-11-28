import 'dart:math';
import 'package:feed/animated/neumorpic_percent_bar.dart';
import 'package:feed/animated/swipe_feed_card.dart';
import 'package:feed/providers/color_provider.dart';
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
    this.loading,
    required this.loader, 
    this.loadManually = false, 
    this.controller, 
    this.onSwipe, 
    this.onContinue,
    this.overlayBuilder,
    this.swipeAlert,
    this.padding,
    this.duration,
    this.placeholder
  }): super(key: key);

  @override
  _SwipeFeedState<T> createState() => _SwipeFeedState<T>();

  /// The overlay to be shown
  final Widget Function(Future<void> Function(int), Future<void> Function(int), int, T)? overlayBuilder;

  /// If the overlay should be shown
  final bool Function(int)? swipeAlert;

  ///A builder for the feed
  final SwipeFeedBuilder<T>? childBuilder;

  ///Loading widget
  final Widget? loading;

  ///A loader for the feed
  final FeedLoader<T> loader;

  ///Set to `true` if you want to prevent the feed from loading onCreate
  final bool loadManually;

  ///Controller for the swipe feed
  final SwipeFeedController? controller;

  ///The on swipe function, run when a card is swiped
  final Future<void> Function(double dx, double dy, DismissDirection direction, T item)? onSwipe;

  ///The on swipe function, run when a card is completed swiping away
  final Future<void> Function(DismissDirection direction, T item)? onContinue;

  ///Padding for the swipe feed
  final EdgeInsets? padding;

  ///Duration for expanding the swipe car
  final Duration? duration;

  final Widget? placeholder;
}

class _SwipeFeedState<T> extends State<SwipeFeed<T>> with AutomaticKeepAliveClientMixin{

  static const int LENGTH_INCREASE_FACTOR = 10;

  static const int LOAD_MORE_LIMIT = 3;

  // ConcreteCubit<Tuple2<Widget, ConcreteCubit<bool>>> topCard;
  // ConcreteCubit<Tuple2<Widget, ConcreteCubit<bool>>> bottomCard;

  ///List of loaded items
  List<T> items = [];

  ///A token for the page
  String? pageToken;

  //determines whether there are more items to display
  bool hasMore = true;

  ///Prevents duplicate loadCalls
  bool loading = false;

  bool lock = false;

  ConcreteCubit<List<Tuple2<T?, ConcreteCubit<SwipeFeedCardState>>>> cubit = ConcreteCubit<List<Tuple2<T?, ConcreteCubit<SwipeFeedCardState>>>>([
    Tuple2(null, ConcreteCubit<SwipeFeedCardState>(SwipeFeedCardState.SHOW)),
    Tuple2(null, ConcreteCubit<SwipeFeedCardState>(SwipeFeedCardState.HIDE)),
  ]);

  ///Percent Bar controller
  late PercentBarController _fillController;

  ///Controls automating swipes
  List<SwipeFeedCardController> swipeFeedCardControllers = [];

  

  Widget get load => widget.loading == null ? Container() : widget.loading!;

  EdgeInsets get padding => widget.padding ?? EdgeInsets.zero;

  Duration get duration => widget.duration ?? Duration(milliseconds: 0);

  bool get isExpandable => widget.duration != null;
  
  Widget? get placeholder => widget.placeholder;

  @override
  void initState(){
    super.initState();

    // Initialize Controllers
    _fillController = PercentBarController();
    swipeFeedCardControllers.add(SwipeFeedCardController());
    swipeFeedCardControllers.add(SwipeFeedCardController());

    if(!widget.loadManually) {
      _loadMore();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    //Bind the controller
    widget.controller?._bind(this);
  }

  Future<void> completeFillBar(double value, Duration duration, [IconPosition? direction, CardPosition? cardPosition]) async => await _fillController.completeFillBar(value, duration, direction, cardPosition);
  Future<void> fillBar(double value, IconPosition direction, CardPosition cardPosition, [bool overrideLock = false]) async => await _fillController.fillBar(min(0.75, value * 0.94), direction, cardPosition, overrideLock);

  void swipeRight(){
    if(!lock){
      lock = true;
      swipeFeedCardControllers[0].swipeRight();
    }
  }

  void swipeLeft(){
    if(!lock){
      lock = true;
      swipeFeedCardControllers[0].swipeLeft();
    }
  }
  
  void _removeCard(){
    swipeFeedCardControllers.removeAt(0);
    swipeFeedCardControllers.add(SwipeFeedCardController());
    Future.delayed(Duration(milliseconds: 400, seconds: 1)).then((value){
      if(cubit.state.length >= 2) {
        cubit.state[1].item2.emit(SwipeFeedCardState.SHOW);
      }
      Future.delayed(Duration(milliseconds: 400)).then((value){
        fillBar(0.0, IconPosition.BOTTOM, CardPosition.Left);
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
    _fillController.fillBar(0, IconPosition.BOTTOM, CardPosition.Left);

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
        List<Tuple2<T?, ConcreteCubit<SwipeFeedCardState>>> cubitItems = List<Tuple2<T?, ConcreteCubit<SwipeFeedCardState>>>.generate(newItems.length, (i) => Tuple2(newItems[i], ConcreteCubit<SwipeFeedCardState>(SwipeFeedCardState.HIDE)));


        for (var i = 0; i < min(2, oldItems.length); i++) {
          if(oldItems[i].item1 == null){
            oldItems[i] = Tuple2(cubitItems[0].item1, oldItems[i].item2);
            cubitItems.removeAt(0);
          }
        }

        if(oldItems.isEmpty && cubitItems.isNotEmpty){
          Future.delayed(Duration(milliseconds: 300)).then((value){
            cubitItems[0].item2.emit(SwipeFeedCardState.SHOW);
          });
        }
        
        cubit.emit([...oldItems, ...cubitItems]);
        lock = false;
      });
    }

  }

  ///Builds the type of item card based on the feed type. 
  ///If a custom child builder is present, uses the child builder instead
  Widget _loadCard(T? item, int index, bool isExpanded, Function() close) {
    if(widget.childBuilder != null && item != null){
      //Builds custom child if childBuilder is defined
      return widget.childBuilder!(item, index == 1, isExpanded, close);
    }
    else if(item == null){
      lock = true;
      return placeholder ?? SizedBox.shrink();
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
      key: Key('swipefeed - card - ${itemCubit.item1 == null ? UniqueKey().toString() : itemCubit.item1.hashCode}'),
      bloc: itemCubit.item2,
      builder: (context, show) {
        return KeyboardVisibilityBuilder(
          builder: (context, keyboard){
            return Transform.translate(
              offset: Offset(0, keyboard && show != SwipeFeedCardState.HIDE ? -1 * (mediaQuery.viewInsets.bottom - padding.bottom) : 0),
              child: AnimatedPadding(
                duration: duration,
                padding: show == SwipeFeedCardState.EXPAND ? EdgeInsets.zero : padding,
                child: GestureDetector(
                  onTap: show == SwipeFeedCardState.SHOW && isExpandable ? (){
                    itemCubit.item2.emit(SwipeFeedCardState.EXPAND);
                  } : null,
                  child: Opacity(
                    opacity: keyboard && show == SwipeFeedCardState.HIDE ? 0.0 : 1.0,
                    child: SwipeFeedCard(
                      swipeFeedCardController: swipeFeedCardControllers[index],
                      overlay: (forwardAnimation, reverseAnimation, index){
                        if(widget.overlayBuilder != null && itemCubit.item1 != null)
                          return widget.overlayBuilder!(forwardAnimation, reverseAnimation, index, itemCubit.item1!);
                        return null;
                      },
                      
                      swipeAlert: widget.swipeAlert,
                      keyboardOpen: keyboard,
                      show: show != SwipeFeedCardState.HIDE,
                      onFill: (fill, iconPosition, cardPosition, overrideLock) {
                        fillBar(fill, iconPosition, cardPosition, overrideLock);
                      },

                      onContinue: itemCubit.item1 != null ? (dir) async {
                        if(widget.onContinue != null){
                          await widget.onContinue!(dir!, itemCubit.item1!);
                        }
                        _removeCard();
                      } : null,
                      onDismiss: (){
                        // Nothing
                      },
                      onSwipe: (dx, dy, dir) {
                        if(widget.onSwipe != null && itemCubit.item1 != null){
                          widget.onSwipe!(dx, dy, dir, itemCubit.item1!);
                        }
                      },
                      onPanEnd: () {
                        // Nothing
                      },
                      child: _loadCard(itemCubit.item1, index, show == SwipeFeedCardState.EXPAND, (){
                        itemCubit.item2.emit(SwipeFeedCardState.SHOW);
                      }),
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

    //Color provider
    final appColors = ColorProvider.of(context);

    //Text style provider
    final textStyles = Theme.of(context).textTheme;
    
    return Stack(
    key: Key('NeumorpicPercentBar'),
    children: [
        //Loader
        if(cubit.state.isEmpty)
          Positioned.fill(child: Center(child: load)),
          
        //Percent bar displaying current vote
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8 + padding.left, vertical: padding.top),
          child: KeepAliveWidget(
            key: Key('PollPage - Bar - KeepAlive'),
            child: NeumorpicPercentBar(
              key: Key('PollPage - Bar'),
              controller: _fillController,
            ),
          ),
        ),


        BlocBuilder<ConcreteCubit<List<Tuple2<T?, ConcreteCubit<SwipeFeedCardState>>>>, List<Tuple2<T?, ConcreteCubit<SwipeFeedCardState>>>>(
          bloc: cubit,
          builder: (context, state) {
            
            return Stack(
              children: [

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

  ///Reloads the feed state based on the original size parameter
  void reset() => _state!._reset();

  Future<void> completeFillBar(double value, Duration duration, [IconPosition? direction, CardPosition? cardPosition]) async => _state == null ? _state!.items : await _state!.completeFillBar(value, duration, direction, cardPosition);

  Future<void> fillBar(double value, IconPosition iconDirection, CardPosition cardPosition, [bool overrideLock = false]) async => _state == null ? _state!.items : await _state!.fillBar(value, iconDirection, cardPosition, overrideLock);

  void swipeRight() => _state != null ? _state!.swipeRight() : null;

  void swipeLeft() => _state != null ? _state!.swipeLeft() : null;

  //Disposes of the controller
  @override
  void dispose() {
    _state = null;
    super.dispose();
  }
}