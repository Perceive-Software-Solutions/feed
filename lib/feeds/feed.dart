import 'dart:math';

import 'package:feed/feeds/feed_list_view.dart';
import 'package:feed/util/global/functions.dart';
import 'package:feed/util/render/keep_alive.dart';
import 'package:feed/util/state/feed_state.dart';
import 'package:feed/util/state/feed_store.dart';
import 'package:flutter/material.dart';
import 'package:fort/fort.dart';
import 'package:tuple/tuple.dart';

/// Splits the feed widget into n parts allows for simultaneous list of independent feeds.
/// 
/// [Feed] functions exactly like a feed, without using [EasyRefresh]. 
/// The independent feeds will load more content however will not be able to call refresh. 
/// 
/// [childBuilder] - a list of builder, populate the specific index to build a custom child on that index
/// 
/// [childBuilder] - a builder that will populate the children in all feeds, is overrides by [childBuilder]
/// 
/// `Supports: Posts, Polls, All Objects if childBuilder is present`
class Feed extends StatefulWidget {
  
  /// Overrides the scroll controller provided in the feed controller
  final ScrollController? scrollController;

  final FeedLoader loader;

  final FeedController? controller;

  final int? lengthFactor;

  final int? initialLength;

  final FeedBuilder? childBuilder;

  ///defines the height to offset the body
  final double? footerHeight;

  ///Determines if the the feed should initially load, defaulted to true
  final bool initiallyLoad;

  ///Ensures the feed is manually loaded and does not have its own scroll controller
  final bool compact;

  ///Disables the scroll controller when set to true
  final bool? disableScroll;

  /// Loading state placeholders
  final Widget? placeholder;

  /// Loading widget
  final Widget? loading;

  ///Retrieves the item id, used to ensure the prevention of duplicate additions
  final RetrievalFunction? getItemID;

  ///The optional function used to wrap the list view
  final WidgetWrapper? wrapper;

  /// Items that will be pinned to the top of the list on init
  final List<dynamic>? pinnedItems;

  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Extra ~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  const Feed(
      {Key? key,
      required this.loader,
      this.controller,
      this.lengthFactor,
      this.initialLength,
      this.childBuilder,
      this.footerHeight,
      this.placeholder,
      this.loading,
      this.disableScroll, 
      this.getItemID,
      this.wrapper,
      this.scrollController,
      this.compact = false,
      this.initiallyLoad = true,
      this.pinnedItems})
      : super(key: key);

  @override
  State<Feed> createState() => _FeedState();
}

///feed state used for displaying storable lists dynamically
class _FeedState extends State<Feed> {

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Constants ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  ///The default length increase and initial length factor
  static const int LENGTH_INCREASE_FACTOR = 30;

  ///The fraction of items that are rendered from the list displayed.
  static const int RENDER_COUNT = 10;

  ///The delay between adding an item
  static const int ITEM_ADD_DELAY = 0;

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ State ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  late final Tower<FeedState> tower = FeedState.tower;

  ///Determines when each index in the list is loading
  bool get loading => tower.state.loading;

  ///Determines the length of each of the lists
  int get size => tower.state.size;

  ///Determines the length of each of the lists
  String? get token => tower.state.token;

  /// Determines if there are no items 
  bool get emptyFeed => tower.state.items.isEmpty;

  /// If there is any more items to be loaded
  bool get hasMore => tower.state.hasMore;

  /// Determines if a feed index is in refresh state or not
  bool get isNotRefreshed => emptyFeed && hasMore;
  
  ///The items added the various indices of the Feed
  Map<String, bool> get addedItems => tower.state.addedItems;

  /// The pending items within the state
  List<dynamic> get pending => tower.state.pendingItems;

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Getter ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  ///Retrieves the load size
  int get loadSize => widget.initialLength ?? widget.lengthFactor ?? LENGTH_INCREASE_FACTOR;

  ///Retrieves loading widget
  Widget get load => widget.loading == null ? Container() : widget.loading!;

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Lifecycle ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  @override
  void initState() {
    super.initState();

    widget.controller?._bind(this);
    
    if(widget.initiallyLoad)
      _refresh();

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
    if (widget.key.toString() != old.key.toString() && !widget.compact) {
      _refresh();
    }
  }

  void removeItem(String item, [RetrievalFunction? retrievalFunction]){
    tower.dispatch(removeFeedItemAction(item, retrievalFunction: retrievalFunction ?? widget.getItemID));
  }
  
  ///Clears the state on a feed index
  void clearFeed(){
    tower.dispatch(ClearFeedStateEvent());
  }
  
  ///Clears the state and updates it
  void setFeedState(InitialFeedState state) async {
    
    tower.dispatch(ClearFeedStateEvent(InitialFeedState(
      hasMore: state.hasMore,
      items: [],
      pageToken: state.pageToken
    )));

    //Add items
    await _offLoadItemsToFeed(state.items, state.pageToken);
  }

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Helpers ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  /// Removes the added items from the feed
  List _purgeAddedItems(List items){
    if(widget.getItemID != null){
      return items.where((item) => addedItems[widget.getItemID!(item)] != true).toList();
    }
    return items;
  }

  List _allocateToPending(List items){

    //Determine split index as a fraction fo the items loaded
    int splitIndex = min(RENDER_COUNT, items.length);

    // Allocate the remaining items to pending
    tower.dispatch(SetPendingFeedItemsEvent(items.sublist(splitIndex)));

    //Return the portion of the items
    return items.sublist(0, splitIndex);

  }

  Future<void> _incrementallyAddItems(List newItems, [bool clear = false]) async {

    for (var i = 0; i < newItems.length; i++) {
      
      await Future.delayed(Duration(milliseconds: ITEM_ADD_DELAY)).then((_){
        tower.dispatch(AddFeedItemEvent(
          newItems[i],
          clear: clear && i == 0
        ));
      });

    }
  }


  /// Uses a list of items and a token to update the feed state
  Future<void> _offLoadItemsToFeed(List items, String? pageToken) async {

    List newItems = _allocateToPending(items);

    await _incrementallyAddItems(newItems);

    if(pageToken == null && newItems.length == items.length){
      tower.dispatch(SetFeedHasMoreState(false));
    }
  }

  /// Uses the items within the pending state to populate the feed
  Future<void> _loadFromPending() {
    return _offLoadItemsToFeed([...pending], token);
  }

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Loaders ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  ///The function that is run to refresh the page
  ///[full] - defines if the parent widget should be refreshed as well
  Future<void> _refresh() async {

    if(loading){
      return;
    }

    //Set the loading to true and clears the feed
    clearFeed();
    tower.dispatch(SetFeedLoadingState(true));

    //Retrieves items
    Tuple2<List, String?> loaded = await widget.loader(loadSize);

    // The loaded items, with the added items purged,
    // Along with the current page token
    List loadedItems = _purgeAddedItems(loaded.item1);
    final pageToken = loaded.item2;

    // Set the token and offload the feed of items
    tower.dispatch(SetFeedTokenState(pageToken));
    await _offLoadItemsToFeed(loadedItems, pageToken);

    //Set the loading to false
    tower.dispatch(SetFeedLoadingState(false));
      
    //Notifies all the controller listeners
    widget.controller?._update();

  }

  ///The function run to load more items onto the page
  Future<void> _loadMore() async {

    // Does not attempt to load more if the end of the state is reached or it is loading
    if(loading || hasMore == false){
      return;
    }

    //Set the loading to true
    tower.dispatch(SetFeedLoadingState(true));

    int newSize = LENGTH_INCREASE_FACTOR;

    // use pending if there are items within it
    if(pending.isNotEmpty){
      await _loadFromPending();
    }
    //Load more
    else{
      final loaded = await widget.loader(newSize, token);

      // The loaded items, with the added items purged,
      // Along with the current page token
      List loadedItems = _purgeAddedItems(loaded.item1);
      final pageToken = loaded.item2;

      // Set the token and offload the feed of items
      tower.dispatch(SetFeedTokenState(pageToken));
      await _offLoadItemsToFeed(loadedItems, pageToken);

    }

    //Set the loading to false
    tower.dispatch(SetFeedLoadingState(false));

    //Notifies all the controller listeners
    widget.controller?._update();
  }

  Widget wrapperBuilder({required BuildContext context, required Widget child}){
    if(widget.wrapper != null){
      return widget.wrapper!(context, child);
    }
    return child;
  }

  ///Keeps track of the added items are removes them from future loads
  void addItem(dynamic item){

    //track added items only oif the [getItemID] function is defined
    if(widget.getItemID != null){
      String itemKey = widget.getItemID!(item);
      removeItem(itemKey, widget.getItemID);
      tower.dispatch(UpdateAddedItemsEvent(itemKey));
    }

    tower.dispatch(AddFeedItemEvent(
      item,
      inFront: true
    ));
  }

  ///Builds the tabs used in the custom scroll view
  Widget _buildFeed(bool loadMore) {
    Widget view = SizedBox();

    if (size == 0 && !loadMore) {
      if(widget.placeholder != null){
        //No items placeholder
        view = widget.placeholder!;
      }
    }
    else {
      //Feed view
      view = KeepAliveWidget(
        child: FeedListView(
          controller: widget.scrollController ?? widget.controller!.scrollController(),
          compact: widget.compact,
          gridDelegate: widget.controller?.getGridDelegate(),
          disableScroll: widget.disableScroll == null ? false : widget.disableScroll,
          footerHeight: widget.footerHeight == null ? 0 : widget.footerHeight,
          wrapper: widget.wrapper,
          onLoad: _loadMore,
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
        )
      );
    }
    return view;
  }

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Build ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  @override
  Widget build(BuildContext context) {
    return StoreProvider(
      store: tower,
      child: StoreConnector<FeedState, bool>(
        distinct: true,
        converter: (store) => store.state.hasMore,
        builder: (context, loadMore) {
          return _buildFeed(loadMore);
        }
      )
    );
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

  ///Default constructor
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

  //Called to notify all listeners
  void _update() => notifyListeners();

  ///Determines if the feed is loading
  bool loading() => _state!.loading;

  ///Retrieves the length of the list of items from the feed
  int size() => _state!.tower.state.size;

  ///Retrieves the list of items from the feed
  List list() => _state!.tower.state.items;

  ///Retrieves the list of items from the feed
  bool hasMore() => _state!.hasMore;

  ///Retrieves the list of feed token
  String? pageToken() => _state!.token;

  ///Determines if an index has been refreshed
  bool isNotRefreshed() => _state!.isNotRefreshed;

  ///Reloads the feed state based on the original size parameter
  Future<void> reload() => _state!._refresh();

  ///Loads the next page of the feed
  Future<void> loadMore() => _state!._loadMore();

  ///Removes an item from all the feeds
  void removeItem(String item, {RetrievalFunction? retrievalFunction}) => _state!.removeItem(item, retrievalFunction);

  ///Clears the feed
  void clear() => _state!.clearFeed();

  ///Adds an item to the beginning of the stated multi feed
  void setState(InitialFeedState state) => _state!.setFeedState(state);

  ///Adds an item to the beginning of the stated multi feed
  void addItem(dynamic item) => _state!.addItem(item);

  ///Retrieves the grid delegate at the index
  FeedGridViewDelegate? getGridDelegate() => _gridDelegate;

  ///Determines if the current index is a grid view
  bool isGridIndex() => getGridDelegate() != null;

  ///Reloads the feed state based on the original size parameter
  ScrollController scrollController() => _scrollController;

  //Disposes of the controller and all nested controllers
  @override
  void dispose() {

    //Disconnect state
    _state = null;
    
    _scrollController.dispose();

    super.dispose();
  }
}