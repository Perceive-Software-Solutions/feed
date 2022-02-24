import 'dart:math';

import 'package:feed/feeds/feed_list_view.dart';
import 'package:feed/util/global/functions.dart';
import 'package:feed/util/render/keep_alive.dart';
import 'package:feed/util/state/concrete_cubit.dart';
import 'package:feed/util/state/feed_state.dart';
import 'package:flutter/material.dart';
import 'package:perceive_slidable/sliding_sheet.dart';
import 'package:tuple/tuple.dart';

/// Splits the feed widget into n parts allows for simultanious list of independant feeds.
/// Allows the exsiatnce of multiple feeds with a preset header.
/// All feeds maintain the same type.
/// 
/// [Feed] functions exactly like a feed, without using [EasyRefresh]. 
/// The independent feeds will load more content however will not be able to call refresh. 
/// 
/// [childBuilders] - a list of builder, populate the specific index to build a custom child on that index
/// 
/// [childBuilder] - a builder that will populate the children in all feeds, is overriden by [childBuilders]
/// 
/// `Supports: Posts, Polls, All Objects if childBuilder is present`
class Feed extends StatefulWidget {

  ///Ensures the feed is manualy loaded and does not have its own scroll controller
  final bool compact;

  final FeedLoader loader;

  final FeedController? controller;

  final SheetController? sheetController;

  final List<Widget>? headerSliver;

  final List<Widget>? footerSliver;

  final int? lengthFactor;

  final int? innitalLength;

  final Future Function()? onRefresh;

  final FeedBuilder? childBuilder;

  ///defines the height to offset the body
  final double? footerHeight;

  ///Disables the scroll controller when set to true
  final bool? disableScroll;

  /// Condition to hidefeed
  final bool? condition;

  /// Loading state placeholders
  final Widget? placeholder;

  /// Loading widget
  final Widget? loading;

  ///The header builder that prints over each feed
  final Widget Function(BuildContext context)? headerBuilder;

  ///Retreives the item id, used to ensure the prevention of duplcicate additions
  final String Function(dynamic item)? getItemID;

  ///The optional function used to wrap the list view
  final WidgetWrapper? wrapper;

  /// Items that will be pinned to the top of the list on init
  final List<dynamic>? pinnedItems;

  final double extent;

  final double minExtent;

  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Extra ~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  const Feed(
      {Key? key,
      required this.loader,
      this.controller,
      this.sheetController,
      this.headerSliver,
      this.lengthFactor,
      this.innitalLength,
      this.onRefresh,
      this.footerSliver,
      this.childBuilder,
      this.footerHeight,
      this.placeholder,
      this.loading,
      this.condition = false, 
      this.extent = 0.7,
      this.minExtent = 0.0,
      this.disableScroll, 
      this.headerBuilder,
      this.getItemID,
      this.wrapper,
      this.compact = false,
      this.pinnedItems})
      : super(key: key);

  @override
  State<Feed> createState() => _FeedState();
}

///feed state used for displaying storable lists dynamically
class _FeedState extends State<Feed> {

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Constants ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  ///The default length increase and innitial length factor
  static const int LENGTH_INCREASE_FACTOR = 30;

  ///The fraction of items that are rendered from the list displayed.
  static const int RENDER_COUNT = 10;

  ///The delay between adding an item
  static const int ITEM_ADD_DELAY = 0;

  ///Constant that holds the number of feeds to be generated
  ///The feed count represents the length of the loader list
  late int _feedCount;

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ State ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  ///Determines when each index in the list is loading
  late bool loading;

  ///Determines the length of each of the lists
  late int sizes = 0;

  //Items loaded in but not rendered
  late List<dynamic> pending;

  ///List of tokens for each index of the feed
  late String? tokens;

  ///If there is any more items to be loaded
  late bool loadMore; 
  
  ///The items added the various indicies of the Feed
  late Map<String, bool> addedItems;

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Render State ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  ///The list of loaded items to be displayed on the feed
  late ConcreteCubit<List> itemsCubit;

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Getter ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  ///Retreives the load size
  int get loadSize => widget.innitalLength ?? widget.lengthFactor ?? LENGTH_INCREASE_FACTOR;

  ///Retreives loading widget
  Widget get load => widget.loading == null ? Container() : widget.loading!;

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Lifecycle ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  @override
  void initState() {
    super.initState();

    widget.controller?._bind(this);

    //Sets the state variables for each feed index
    pending = [];
    sizes = 0;
    tokens = null;
    loading = false;
    loadMore = true;
    addedItems = {};

    //Creates concrete cubit
    itemsCubit = ConcreteCubit<List>([]);

    //Loads the innitial set of items
    _refresh(false);

    if(widget.pinnedItems != null){
      pinItems();
    }

  }

  /// Initially pin items to the top of the list
  void pinItems(){
    for(dynamic pinnedItem in widget.pinnedItems!){
      addItem(pinnedItem.item1);
    }
  }

  @override
  void didUpdateWidget(old) {
    super.didUpdateWidget(old);

    widget.controller?._bind(this);

    //Refresh feed on key change
    if (widget.key.toString() != old.key.toString()) {
      _refresh(false);
    }
  }

  void removeItem(dynamic item, [dynamic Function(dynamic item)? retreivalFunction]){

    List items = [...itemsCubit.state];
    items.removeWhere((element) => (retreivalFunction != null ? retreivalFunction(element) : element) == item);
    itemsCubit.emit(items);
  }
  
  ///Clears the state on a feed index
  void clearFeed(){
    setState(() {
      pending = [];
      sizes = 0;
      tokens = null;
      loading = false;
      loadMore = true;
      addedItems = {};
    });
    itemsCubit.emit([]);
  }
  
  ///Clears the state on a feed index
  void setFeedState(InitialFeedState state) async {
    // itemsCubit[index].emit([]); //clear previous state

    late final list;
    pending = [];
    sizes = 0;
    tokens = state.pageToken;
    loading = false;
    loadMore = state.hasMore;
    addedItems = {};

    //Retreive list
    list = _allocateToPending(state.items);

    // print('ok');
    

    //Add items
    await _incrementallyAddItems(list, true);
    setState(() {});
  }

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Helpers ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  List _allocateToPending(List items){

    //Determine split index as a fraction fo the items loaded
    int splitIndex = min(RENDER_COUNT, items.length);

    //Alocated the remaining items to pending
    pending = items.sublist(splitIndex);

    //Return the portion of the items
    return items.sublist(0, splitIndex);

  }

  //TODO: chnage
  Future<void> _incrementallyAddItems(List newItems, [bool clear = false]) async {

    for (var i = 0; i < newItems.length; i++) {
      
      await Future.delayed(Duration(milliseconds: ITEM_ADD_DELAY)).then((_){
        List addNewItem = [...(clear && i == 0 ? [] : itemsCubit.state), newItems[i]];

        itemsCubit.emit( addNewItem );
        
        //Updates the size variable //TODO clean up
        sizes = addNewItem.length;
      });

    }
  }

  ///The function that is run to refresh the page
  ///[full] - defines if the parent widget should be refreshed aswell
  Future<void> _refresh([bool full = true]) async {

    
    itemsCubit.emit([]);
    if(loading){
      return;
    }

    //Calls the refresh function from the parent widget
    Future<void>? refresh =
        widget.onRefresh != null && full ? widget.onRefresh!() : null;

    //Set the loading to true
    loading = true;

    //Retreives items
    Tuple2<List, String?> loaded = await widget.loader(loadSize);

    //The loaded items
    List loadedItems = loaded.item1;

    //Remove the items already within addItems
    if(widget.getItemID != null){
      loadedItems = loadedItems.where((item) => addedItems[widget.getItemID!(item)] != true).toList();
    }

    //Awaits the parent refresh function
    if (refresh != null) await refresh;

    if (mounted) {
      
      List newItems = _allocateToPending(loadedItems);
      tokens = loaded.item2;


      if(loadedItems.length < loadSize){
        loadMore = false;
      }

      await _incrementallyAddItems(newItems);

      //Set the loading to false
      loading = false;
      setState(() {});
        
      //Notifies all the controller lisneteners
      widget.controller?._update();
    }
  }

  Future<void> _loadFromPending() async {

    Tuple2<List, String?> loaded;

    //use pending
    if(pending.isNotEmpty){
      loaded = Tuple2([...pending], tokens);

      if(mounted){

        List newItems = _allocateToPending(loaded.item1);
        tokens = loaded.item2;

        await _incrementallyAddItems(newItems);

        //Set the loading to false
        loading = false;

        //Notifies all the controller lisneteners
        widget.controller?._update();
      }
    }
  }

  ///The function run to load more items onto the page
  Future<void> _loadMore() async {

    if(loading){
      return;
    }

    //Set the loading to true
    loading = true;
    int newSize = LENGTH_INCREASE_FACTOR;
    Tuple2<List, String?> loaded;

    //use pending
    if(pending.isNotEmpty){
      loaded = Tuple2([...pending], tokens);

      if(mounted){

        List newItems = _allocateToPending(loaded.item1);
        tokens = loaded.item2;

        await _incrementallyAddItems(newItems);

        //Set the loading to false
        loading = false;
        setState(() {});

        //Notifies all the controller lisneteners
        widget.controller?._update();
      }
    }
    //Load more
    else{
      loaded = await widget.loader(newSize, tokens);

      //The loaded items
      List loadedItems = loaded.item1;

      //Remove the items already within addItems
      if(widget.getItemID != null){
        loadedItems = loadedItems.where((item) => addedItems[widget.getItemID!(item)] != true).toList();
      }

      if (mounted) {

        List newItems = _allocateToPending(loaded.item1);

        tokens = loaded.item2;


        if(loadedItems.length < newSize){
          loadMore = false;
        }

        await _incrementallyAddItems(newItems);

        //Set the loading to false
        loading = false;
        setState(() {});

        //Notifies all the controller lisneteners
        widget.controller?._update();
      }
    }
  }

  Widget wrapperBuilder({required BuildContext context, required Widget child}){
    if(widget.wrapper != null){
      return widget.wrapper!(context, child);
    }
    return child;
  }

  ///Determines if a feed index is in refresh state or not
  bool isNotRefreshed(){
    return itemsCubit.state.isEmpty && loadMore;
  }

  ///Keps track of the added items are removes them from future loads
  void addItem(dynamic item){
    List addNewItem = [item, ...itemsCubit.state];
    itemsCubit.emit(addNewItem);
    sizes = sizes + 1;

    //track added items only oif the [getItemID] function is defined
    if(widget.getItemID != null){
      addedItems[widget.getItemID!(item)] = true;
    }
  }

  ///Builds the tabs used in the custom scroll view
  Widget _buildFeed() {
    Widget view = SizedBox();

    if (sizes == 0 && !loadMore) {
      if(widget.placeholder != null){
        //No items placeholder
        view = widget.placeholder!;
      }
    }
    else {
      //Feed view
      view = KeepAliveWidget(
        child: FeedListView(
          extent: widget.extent,
          minExtent: widget.minExtent,
          sheetController: widget.sheetController,
          controller: widget.controller!.scrollController(),
          itemsCubit: itemsCubit,
          compact: widget.compact,
          gridDelegate: widget.controller?.getGridDelegate(),
          disableScroll: widget.disableScroll == null ? false : widget.disableScroll,
          footerHeight: widget.footerHeight == null ? 0 : widget.footerHeight,
          wrapper: widget.wrapper,
          onLoad: (){
            if(loading == false && loadMore == true) {
              _loadMore();
            }
            else{
              _loadFromPending();
            }
          },
          builder: (context, i, items){
            if (i == items.length) {
              return Column(
                children: [

                  Container(
                    height: 100,
                    width: double.infinity,
                    child: Center(
                      child: loadMore ? load : SizedBox.shrink(),
                    ),
                  ),
                  Container(
                    height: widget.footerHeight,
                    width: double.infinity,
                  ),
                ],
              );
            }
            return widget.childBuilder!(items[i], items.length - 1 == i);
          },
          headerBuilder: widget.headerBuilder,              
        )
      );
    }
    return view;
  }

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Build ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  @override
  Widget build(BuildContext context) {
    return _buildFeed();
  }
}

///Controller for the simple multi feed. 
///Holds a nested Page, Tab and Scroll controllers
class FeedController extends ChangeNotifier {

  late _FeedState? _state;

  ///Holds the grid delegates for the defined by the key
  FeedGridViewDelegate? _gridDelegate;

  ///Controllers for the individual list
  ScrollController _scrollController;

  ///Private constructor
  FeedController._(this._scrollController, this._gridDelegate);

  ///Default constuctor
  ///Creates the nested controllers
  factory FeedController({
    double? initialOffset,
    bool? keepScrollOffset,
    String? debugLabel,
    FeedGridViewDelegate? gridDelegate
  }){

    return FeedController._(
      ScrollController(
        debugLabel: debugLabel ?? 'SimpleFeedScrollController-' + UniqueKey().toString(),
        initialScrollOffset: initialOffset ?? 0.0,
        keepScrollOffset: keepScrollOffset ?? true
      ),
      gridDelegate
    );
  }

  ///Binds the feed state
  void _bind(_FeedState bind) => _state = bind;

  //Called to notify all listners
  void _update() => notifyListeners();

  ///Determines if the feed is loading
  bool loading() => _state!.loading;

  ///Retreives the length of the list of items from the feed
  int size() => _state!.sizes;

  ///Retreives the list of items from the feed
  List list() => _state!.itemsCubit.state;

  ///Retreives the list of items from the feed
  bool hasMore() => _state!.loadMore;

  ///Retreives the list of feed token
  String? pageToken() => _state!.tokens;

  ///Determines if an index has been refreshed
  bool isNotRefreshed() => _state!.isNotRefreshed();

  ///Reloads the feed state based on the original size parameter
  Future<void> reload() => _state!._refresh();

  ///Loads the next page of the feed
  Future<void> loadMore() => _state!._loadMore();

  ///Removes an item from all the feeds
  void removeItem(dynamic item, {dynamic Function(dynamic item)? retreivalFunction}) => _state!.removeItem(item, retreivalFunction);

  ///Clears the feed
  void clear() => _state!.clearFeed();

  ///Adds an item to the beginning of the stated multi feed
  void setState(InitialFeedState state) => _state!.setFeedState(state);

  ///Adds an item to the beginning of the stated multi feed
  void addItem(dynamic item) => _state!.addItem(item);

  ///Retreives the grid delegate at the index
  FeedGridViewDelegate? getGridDelegate() => _gridDelegate;

  ///Determines if the current index is a grid view
  bool isGridIndex() => getGridDelegate() != null;

  ///Reloads the feed state based on the original size parameter
  ScrollController? scrollController() => _scrollController;

  //Disposes of the controller and all nested controllers
  @override
  void dispose() {

    //Disconnect state
    _state = null;
    
    _scrollController.dispose();

    super.dispose();
  }
}