import 'dart:math';

import 'package:feed/feed.dart';
import 'package:feed/feeds/feed_list_view.dart';
import 'package:feed/util/global/functions.dart';
import 'package:feed/util/render/keep_alive.dart';
import 'package:feed/util/state/concrete_cubit.dart';
import 'package:flutter/material.dart';
import 'package:perceive_slidable/sliding_sheet.dart';
import 'package:tuple/tuple.dart';

/// Splits the feed widget into n parts allows for simultanious list of independant feeds.
/// Allows the exsiatnce of multiple feeds with a preset header.
/// All feeds maintain the same type.
/// 
/// [MultiFeed] functions exactly like a feed, without using [EasyRefresh]. 
/// The independent feeds will load more content however will not be able to call refresh. 
/// 
/// [childBuilders] - a list of builder, populate the specific index to build a custom child on that index
/// 
/// [childBuilder] - a builder that will populate the children in all feeds, is overriden by [childBuilders]
/// 
/// `Supports: Posts, Polls, All Objects if childBuilder is present`
class MultiFeed extends StatefulWidget {

  final List<FeedLoader> loaders;

  final MultiFeedController? controller;

  final SheetController? sheetController;

  final List<Widget>? headerSliver;

  final List<Widget>? footerSliver;

  final int? lengthFactor;

  final int? innitalLength;

  final Future Function()? onRefresh;

  final MultiFeedBuilder? childBuilder;

  ///defines the height to offset the body
  final double? footerHeight;

  ///Disables the scroll controller when set to true
  final bool? disableScroll;

  /// Condition to hidefeed
  final bool? condition;

  /// Loading state placeholders
  final List<Widget>? placeHolders;

  /// Loading widget
  final Widget? loading;

  /// Corresponds to the [condition] and replaces feed with [Widget]
  final Widget? placeHolder;

  ///The header builder that prints over each multi feed
  final Widget Function(BuildContext context, int feedIndex)? headerBuilder;

  ///Retreives the item id, used to ensure the prevention of duplcicate additions
  final String Function(dynamic item)? getItemID;

  ///The optional function used to wrap the list view
  final IndexWidgetWrapper? wrapper;

  /// Items that will be pinned to the top of the list on init
  final List<Tuple2<dynamic, int>>? pinnedItems;

  final double extent;

  final double minExtent;

  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Extra ~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  const MultiFeed(
      {Key? key,
      required this.loaders,
      this.controller,
      this.sheetController,
      this.headerSliver,
      this.lengthFactor,
      this.innitalLength,
      this.onRefresh,
      this.footerSliver,
      this.childBuilder,
      this.footerHeight,
      this.placeHolders,
      this.placeHolder,
      this.loading,
      this.condition = false, 
      this.extent = 0.7,
      this.minExtent = 0.0,
      this.disableScroll, 
      this.headerBuilder,
      this.getItemID,
      this.wrapper,
      this.pinnedItems})
      : assert(controller == null || controller.length == loaders.length),
        super(key: key);

  @override
  State<MultiFeed> createState() => _MultiFeedState();
}

///feed state used for displaying storable lists dynamically
class _MultiFeedState extends State<MultiFeed> {

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

  ///THe internal index for the feed
  late int feedIndex;

  ///Controller for the page view
  PageController? pageController;

  ///Determines when each index in the list is loading
  late List <bool> loading;

  ///Determines the length of each of the lists
  late List<int> sizes;

  //Items loaded in but not rendered
  late List<List> pending;

  ///List of tokens for each index of the feed
  late List<String?> tokens;

  ///If there is any more items to be loaded
  List<bool> loadMore = <bool>[]; 
  
  ///The items added the various indicies of the multifeed
  late List<Map<String, bool>> addedItems;

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Render State ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  ///The list iof loaded items to be displayed on the feed
  late List<ConcreteCubit<List>> itemsCubit;

  late List<Widget> _tabs = [];

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Getter ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  ///Retreives the load size
  int get loadSize => widget.innitalLength ?? widget.lengthFactor ?? LENGTH_INCREASE_FACTOR;

  ///Retreives loading widget
  Widget get load => widget.loading == null ? Container() : widget.loading!;

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Lifecycle ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  @override
  void initState() {
    super.initState();

    ///Create the defualt page controller
    if(widget.controller == null) {
      pageController = PageController();
    }

    feedIndex = widget.controller?.tabController!.index ?? 0;

    //Sets the length of the feed
    _feedCount = widget.loaders.length;

    //Sets the state variables for each feed index
    pending = List<List>.generate(_feedCount, (i) => []);
    sizes = List<int>.generate(_feedCount, (i) => 0);
    tokens = List<String?>.generate(_feedCount, (i) => null);
    loading = List<bool>.generate(_feedCount, (i) => false);
    loadMore = List<bool>.generate(_feedCount, (index) => true);
    addedItems = List<Map<String, bool>>.generate(_feedCount, (index) => {});

    //Creates concrete cubit
    itemsCubit = List.generate(_feedCount, (i) => ConcreteCubit<List>([]));

    //Loads the innitial set of items
    _refresh(feedIndex, false);

    if(widget.pinnedItems != null){
      pinItems();
    }

  }

  /// Initially pin items to the top of the list
  void pinItems(){
    for(Tuple2<dynamic, int> pinnedItem in widget.pinnedItems!){
      addItem(pinnedItem.item1, pinnedItem.item2);
    }
  }

  int sizeAtIndex(int index){
    return itemsCubit[index].state.length;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (widget.controller != null) {
      //Binds the controller to this state
      widget.controller?._bind(this);

      ///Dispose the old page controller
      if(pageController != null){
        pageController!.dispose();
      }

      //Reinitialize the page controller
      pageController = widget.controller?.pageController ?? PageController();

      ///Bind the onchnage to the tab controller
      widget.controller?.tabController!.addListener(() {
        if(widget.controller!.tabController!.index != feedIndex && widget.controller!.tabController!.indexIsChanging == false && pageController != null){
          pageController!.animateToPage(widget.controller!.tabController!.index, duration: Duration(milliseconds: 300), curve: Curves.linear);
        }
      });
    }

    //Refresh all feeds
    List.generate(widget.loaders.length, (i) => i).map((e) => _refresh(e, false));
  }

  @override
  void didUpdateWidget(old) {
    super.didUpdateWidget(old);

    //refreshs if the indexed items are empty
    // if (itemsCubit[feedIndex].state.isEmpty) _refresh(feedIndex, false);

    //Refresh feed on key change
    if (widget.key.toString() != old.key.toString()) {
      _refresh(feedIndex, false);
    }
  }

  void removeItem(dynamic item, [dynamic Function(dynamic item)? retreivalFunction]){

    for (var cubit in itemsCubit) {
      List items = [...cubit.state];
      items.removeWhere((element) => (retreivalFunction != null ? retreivalFunction(element) : element) == item);
      cubit.emit(items);
    }
  }
  
  ///Clears the state on a feed index
  void clearFeed(int index){
    setState(() {
      pending[index] = [];
      sizes[index] = 0;
      tokens[index] = null;
      loading[index] = false;
      loadMore[index] = true;
      addedItems[index] = {};
    });
    itemsCubit[index].emit([]);
  }
  
  ///Clears the state on a feed index
  void setFeedState(int index, InitialFeedState state) async {
    // itemsCubit[index].emit([]); //clear previous state

    late final list;
    pending[index] = [];
    sizes[index] = 0;
    tokens[index] = state.pageToken;
    loading[index] = false;
    loadMore[index] = state.hasMore;
    addedItems[index] = {};

    //Retreive list
    list = _allocateToPending(state.items, index);

    // print('ok');
    

    //Add items
    await _incrementallyAddItems(list, index, true);
    setState(() {});
  }

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Helpers ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  ///Builds the type of item card
  Widget _loadCard(List<dynamic> itemList, int index) {
    dynamic item = itemList[index];
    return Container();
    // if (item is Post) {
    //   return PostCard(
    //     key: Key('post - ${item.id}'),
    //     postId: item.id,
    //   );
    // } else if (item is Poll) {
    //   return PollCard(
    //     key: Key('poll - ${item.id}'),
    //     pollId: item.id,
    //     isLast: index == itemList.length - 1,
    //   );
    // } else {
    //   throw ('T is not supported by MultiFeed');
    // }
  }

  List _allocateToPending(List items, int feedIndex){

    //Determine split index as a fraction fo the items loaded
    int splitIndex = min(RENDER_COUNT, items.length);

    //Alocated the remaining items to pending
    pending[feedIndex] = items.sublist(splitIndex);

    //Return the portion of the items
    return items.sublist(0, splitIndex);

  }

  //TODO: chnage
  Future<void> _incrementallyAddItems(List newItems, int index, [bool clear = false]) async {

    for (var i = 0; i < newItems.length; i++) {
      
      await Future.delayed(Duration(milliseconds: ITEM_ADD_DELAY)).then((_){
        List addNewItem = [...(clear && i == 0 ? [] : itemsCubit[index].state), newItems[i]];

        itemsCubit[index].emit( addNewItem );
        
        //Updates the size variable //TODO clean up
        sizes[index] = addNewItem.length;
      });

    }
  }

  ///The function that is run to refresh the page
  ///[full] - defines if the parent widget should be refreshed aswell
  Future<void> _refresh(int feedIndex, [bool full = true]) async {

    
    itemsCubit[feedIndex].emit([]);
    if(loading[feedIndex]){
      return;
    }

    //Calls the refresh function from the parent widget
    Future<void>? refresh =
        widget.onRefresh != null && full ? widget.onRefresh!() : null;

    //Set the loading to true
    loading[feedIndex] = true;

    //Retreives items
    Tuple2<List, String?> loaded = await widget.loaders[feedIndex](loadSize);

    //The loaded items
    List loadedItems = loaded.item1;

    //Remove the items already within addItems
    if(widget.getItemID != null){
      loadedItems = loadedItems.where((item) => addedItems[feedIndex][widget.getItemID!(item)] != true).toList();
    }

    //Awaits the parent refresh function
    if (refresh != null) await refresh;

    if (mounted) {
      
      List newItems = _allocateToPending(loadedItems, feedIndex);
      tokens[feedIndex] = loaded.item2;


      if(loadedItems.length < loadSize){
        loadMore[feedIndex] = false;
      }

      await _incrementallyAddItems(newItems, feedIndex);

      //Set the loading to false
      loading[feedIndex] = false;
      setState(() {});
        
      //Notifies all the controller lisneteners
      widget.controller?._update();
    }
  }

  Future<void> _loadFromPending() async {

    Tuple2<List, String?> loaded;

    //use pending
    if(pending[feedIndex].isNotEmpty){
      loaded = Tuple2([...pending[feedIndex]], tokens[feedIndex]);

      if(mounted){

        List newItems = _allocateToPending(loaded.item1, feedIndex);
        tokens[feedIndex] = loaded.item2;

        await _incrementallyAddItems(newItems, feedIndex);

        //Set the loading to false
        loading[feedIndex] = false;

        //Notifies all the controller lisneteners
        widget.controller?._update();
      }
    }
  }

  ///The function run to load more items onto the page
  Future<void> _loadMore(int feedIndex) async {

    if(loading[feedIndex]){
      return;
    }

    //Set the loading to true
    loading[feedIndex] = true;
    int newSize = LENGTH_INCREASE_FACTOR;
    Tuple2<List, String?> loaded;

    //use pending
    if(pending[feedIndex].isNotEmpty){
      loaded = Tuple2([...pending[feedIndex]], tokens[feedIndex]);

      if(mounted){

        List newItems = _allocateToPending(loaded.item1, feedIndex);
        tokens[feedIndex] = loaded.item2;

        await _incrementallyAddItems(newItems, feedIndex);

        //Set the loading to false
        loading[feedIndex] = false;
        setState(() {});

        //Notifies all the controller lisneteners
        widget.controller?._update();
      }
    }
    //Load more
    else{
      loaded = await widget.loaders[feedIndex](newSize, tokens[feedIndex]);

      //The loaded items
      List loadedItems = loaded.item1;

      //Remove the items already within addItems
      if(widget.getItemID != null){
        loadedItems = loadedItems.where((item) => addedItems[feedIndex][widget.getItemID!(item)] != true).toList();
      }

      if (mounted) {

        List newItems = _allocateToPending(loaded.item1, feedIndex);

        tokens[feedIndex] = loaded.item2;


        if(loadedItems.length < newSize){
          loadMore[feedIndex] = false;
        }

        await _incrementallyAddItems(newItems, feedIndex);

        //Set the loading to false
        loading[feedIndex] = false;
        setState(() {});

        //Notifies all the controller lisneteners
        widget.controller?._update();
      }
    }
  }

  Widget wrapperBuilder({required BuildContext context, required Widget child, required int index}){
    if(widget.wrapper != null){
      return widget.wrapper!(context, child, index);
    }
    return child;
  }

  ///Determines if a feed index is in refresh state or not
  bool isNotRefreshed(int index){
    return itemsCubit[index].state.isEmpty && loadMore[index];
  }

  ///Keps track of the added items are removes them from future loads
  void addItem(dynamic item, int index){
    List addNewItem = [item, ...itemsCubit[index].state];
    itemsCubit[index].emit(addNewItem);

    //track added items only oif the [getItemID] function is defined
    if(widget.getItemID != null){
      addedItems[index][widget.getItemID!(item)] = true;
    }
  }

  ///Builds the tabs used in the custom scroll view
  List<Widget> _loadTabs() {
    List<Widget> tabs = <Widget>[];
    for (int j = 0; j < widget.loaders.length; j++) {

      if (sizes[j] == 0 && !loadMore[j]) {
        if(widget.placeHolders != null && j < widget.placeHolders!.length && widget.placeHolders![j] != null){
          tabs.add(widget.placeHolders![j]);
        }
        else{
          tabs.add(SizedBox());
        }
      }
      else {
        tabs.add(
          KeepAliveWidget(
            child: FeedListView(
              extent: widget.extent,
              minExtent: widget.minExtent,
              sheetController: widget.sheetController,
              controller: widget.controller!.scrollControllers![j],
              itemsCubit: itemsCubit[j],
              gridDelegate: widget.controller?.getDelegateAtIndex(j),
              disableScroll: widget.disableScroll == null ? false : widget.disableScroll,
              footerHeight: widget.footerHeight == null ? 0 : widget.footerHeight,
              wrapper: widget.wrapper == null ? null : (BuildContext context, Widget child){
                return widget.wrapper!(context, child, j);
              },
              onLoad: (){
                // print(loadMore[j]);
                if(loading[j] == false && loadMore[j] == true) {
                  _loadMore(j);
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
                          child: loadMore[i] ? load : SizedBox.shrink(),
                        ),
                      ),
                      Container(
                        height: widget.footerHeight,
                        width: double.infinity,
                      ),
                    ],
                  );
                }
                else if(widget.childBuilder != null){
                  return widget.childBuilder!(items[i], j, items.length - 1 == i);
                }
        
                return _loadCard(items, i);
              },
              headerBuilder: widget.headerBuilder == null ? null : (context){
                return widget.headerBuilder!(context, j);
              },              
            )
          ),
        );
      }
    }
    return tabs;
  }

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Build ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  @override
  Widget build(BuildContext context) {
    _tabs = _loadTabs();
    return PageView(
      controller: pageController,
      onPageChanged: (value) {
        widget.controller?.tabController!.animateTo(value, duration: Duration(milliseconds: 300));
        feedIndex = value;
        if(itemsCubit[feedIndex].state.isEmpty){
          _refresh(feedIndex);
        }
      },
      children: _tabs,
    );
  }
}

///Controller for the simple multi feed. 
///Holds a nested Page, Tab and Scroll controllers
class MultiFeedController extends ChangeNotifier {
  late _MultiFeedState? _state;

  ///The amount of pages in the multi feed
  int _pageCount;

  ///Holds the grid delegates for the index defined by the key
  Map<int, FeedGridViewDelegate?> _gridDelegates;

  ///Controllers for the individual list
  List<ScrollController>? _scrollControllers;

  ///Controls the tab bar within the header
  TabController? _tabController;

  ///Controls the bottom pageview
  PageController? _pageController;

  ///Private constructor
  MultiFeedController._(this._pageCount, this._pageController, this._tabController, this._scrollControllers, this._gridDelegates);

  ///Default constuctor
  ///Creates the nested controllers
  factory MultiFeedController({
    required int pageCount,
    int initialPage = 0,
    bool keepPage = true,
    double viewportFraction = 1.0,
    TickerProvider? vsync,
    List<double>? initialOffsets,
    List<bool>? keepScrollOffsets,
    List<String>? debugLabels,
    Map<int, FeedGridViewDelegate?> indexedGridDelegates = const {}
  }){
    assert(initialOffsets == null || initialOffsets.length == pageCount);
    assert(keepScrollOffsets == null || keepScrollOffsets.length == pageCount);
    assert(debugLabels == null || debugLabels.length == pageCount);
    return MultiFeedController._(
      pageCount,
      PageController(initialPage: initialPage, keepPage: keepPage, viewportFraction: viewportFraction),
      vsync == null ? null : TabController(initialIndex: initialPage, length: pageCount, vsync: vsync),
      List.generate(pageCount, (index) => ScrollController(
        debugLabel: debugLabels?.elementAt(index) ?? 'SimpleMultiFeedScrollController-' + UniqueKey().toString() + '$index',
        initialScrollOffset: initialOffsets?.elementAt(index) ?? 0.0,
        keepScrollOffset: keepScrollOffsets?.elementAt(index) ?? true
      )),
      indexedGridDelegates
    );
  }

  ///Binds the feed state
  void _bind(_MultiFeedState bind) => _state = bind;

  //Called to notify all listners
  void _update() => notifyListeners();

  ///Retreives the list of items from the feed
  List list(index) => _state!.itemsCubit[index].state;

  ///Retreives the list of items from the feed
  bool hasMore(index) => _state!.loadMore[index];

  ///Retreives the list of feed token at the index
  String? pageToken(index) => _state!.tokens[index];

  ///Determines if an index has been refreshed
  bool isNotRefreshed(index) => _state!.isNotRefreshed(index);

  ///Reloads the feed state based on the original size parameter
  Future<void> reload(int index) => _state!._refresh(index);

  ///Removes an item from all the feeds
  void removeItem(dynamic item, {dynamic Function(dynamic item)? retreivalFunction}) => _state!.removeItem(item, retreivalFunction);

  ///Clears the indexed feed
  void clear(int index) => _state!.clearFeed(index);

  ///Adds an item to the beginning of the stated multi feed
  void setState(int index, InitialFeedState state) => _state!.setFeedState(index, state);

  ///Adds an item to the beginning of the stated multi feed
  void addItem(dynamic item, int index) => _state!.addItem(item, index);

  ///Retreives the grid delegate at the index
  FeedGridViewDelegate? getDelegateAtIndex(int index) => _gridDelegates[index];

  ///Determines if the current index is a grid view
  bool isGridIndex(int index) => getDelegateAtIndex(index) != null;

  ///Reloads the feed state based on the original size parameter
  ScrollController? scrollControllerAtIndex(int index) => _scrollControllers![index];

  ///Retreive the tab controller
  TabController? get tabController => _tabController;

  ///Retreive the tab controller
  PageController? get pageController => _pageController;

  ///Retreive the scrollControllers
  List<ScrollController?>? get scrollControllers => _scrollControllers;

  ///Retreive the length of the multi feed
  int get length => _pageCount;

  //Disposes of the controller and all nested controllers
  @override
  void dispose() {

    //Disconnect state
    _state = null;
    
    //Dispose all nested controllers
    _pageController!.dispose();
    _tabController?.dispose();
    for (var scrollController in _scrollControllers!) {
      scrollController.dispose();
    }

    super.dispose();
  }
}