import 'dart:math';

import 'package:feed/util/global/functions.dart';
import 'package:feed/util/render/keep_alive.dart';
import 'package:feed/util/state/concrete_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tuple/tuple.dart';

/// Splits the feed widget into n parts allows for simultanious list of independant feeds.
/// Allows the exsiatnce of multiple feeds with a preset header.
/// All feeds maintain the same type.
/// 
/// [SimpleMultiFeed] functions exactly like a feed, without using [EasyRefresh]. 
/// The independent feeds will load more content however will not be able to call refresh. 
/// 
/// [childBuilders] - a list of builder, populate the specific index to build a custom child on that index
/// 
/// [childBuilder] - a builder that will populate the children in all feeds, is overriden by [childBuilders]
/// 
/// `Supports: Posts, Polls, All Objects if childBuilder is present`
class SimpleMultiFeed extends StatefulWidget {
  final List<FeedLoader> loaders;

  final List<Widget>? headerSliver;

  final List<Widget>? footerSliver;

  final int? lengthFactor;

  final int? innitalLength;

  final Future Function()? onRefresh;

  final List<MultiFeedBuilder>? childBuilders;

  final MultiFeedBuilder? childBuilder;

  final SimpleMultiFeedController? controller;

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

  const SimpleMultiFeed(
      {Key? key,
      required this.loaders,
      this.headerSliver,
      this.lengthFactor,
      this.innitalLength,
      this.onRefresh,
      this.controller,
      this.footerSliver,
      this.childBuilders,
      this.childBuilder,
      this.footerHeight,
      this.placeHolders,
      this.placeHolder,
      this.loading,
      this.condition = false, 
      this.disableScroll, 
      this.headerBuilder})
      : assert(childBuilders == null || childBuilders.length == loaders.length),
        assert(controller == null || controller.length == loaders.length),
        super(key: key);

  @override
  State<SimpleMultiFeed> createState() => _SimpleMultiFeedState();
}

///feed state used for displaying storable lists dynamically
class _SimpleMultiFeedState extends State<SimpleMultiFeed> {

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
  

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Render State ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  ///The list iof loaded items to be displayed on the feed
  late List<ConcreteCubit<List>> itemsCubit;

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
    sizes = List<int>.generate(_feedCount, (i) => (loadSize/2).floor());
    tokens = List<String?>.generate(_feedCount, (i) => null);
    loading = List<bool>.generate(_feedCount, (i) => false);
    loadMore = List<bool>.generate(_feedCount, (index) => true);

    //Creates concrete cubit
    itemsCubit = List.generate(_feedCount, (i) => ConcreteCubit<List>([]));

    //Loads the innitial set of items
    _refresh(feedIndex, false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (widget.controller != null) {
      //Binds the controller to this state
      widget.controller?._bind(this);

      ///Dispose the old page controller
      pageController?.dispose();

      //Reinitialize the page controller
      pageController = widget.controller?.pageController ?? PageController();

      ///Bind the onchnage to the tab controller
      widget.controller?.tabController!.addListener(() {
        // if(widget.tabController.index != feedIndex && !widget.tabController.indexIsChanging){
        //   pageController.animateToPage(widget.tabController.index, duration: Duration(milliseconds: 300), curve: Curves.linear);
        // }
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
  Future<void> _incrementallyAddItems(List newItems, int index) async {

    for (var i = 0; i < newItems.length; i++) {
      
      await Future.delayed(Duration(milliseconds: ITEM_ADD_DELAY)).then((_){
        List addNewItem = [...itemsCubit[index].state, newItems[i]];

        itemsCubit[index].emit( addNewItem );
        
        //Updates the size variable //TODO clean up
        sizes[index] = addNewItem.length;
      });

    }
  }

  ///The function that is run to refresh the page
  ///[full] - defines if the parent widget should be refreshed aswell
  Future<void> _refresh(int feedIndex, [bool full = true]) async {
    //Calls the refresh function from the parent widget
    Future<void>? refresh =
        widget.onRefresh != null && full ? widget.onRefresh!() : null;

    //Set the loading to true
    loading[feedIndex] = true;

    //Retreives items
    Tuple2<List, String?> loaded = await widget.loaders[feedIndex](loadSize);

    //The loaded items
    List loadedItems = loaded.item1;

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
        
      //Notifies all the controller lisneteners
      widget.controller?._update();
    }
  }

  ///The function run to load more items onto the page
  Future<void> _loadMore(int feedIndex) async {
    //Set the loading to true
    loading[feedIndex] = true;
    int newSize = LENGTH_INCREASE_FACTOR;
    Tuple2<List, String?> loaded;

    //use pending
    if(pending[feedIndex].isNotEmpty){
      loaded = Tuple2([...pending[feedIndex]], tokens[feedIndex]!);

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
    //Load more
    else{
      loaded = await widget.loaders[feedIndex](newSize, tokens[feedIndex]!);

      //The loaded items
      List loadedItems = loaded.item1;

      if (mounted) {

        List newItems = _allocateToPending(loaded.item1, feedIndex);

        tokens[feedIndex] = loaded.item2;


        if(loadedItems.length < newSize){
          loadMore[feedIndex] = false;
        }

        await _incrementallyAddItems(newItems, feedIndex);

        //Set the loading to false
        loading[feedIndex] = false;

        //Notifies all the controller lisneteners
        widget.controller?._update();
      }
    }
  }

  ///Builds the tabs used in the custom scroll view
  List<Widget> _loadTabs() {
    List<Widget> tabs = <Widget>[];
    for (int j = 0; j < widget.loaders.length; j++) {

      if (sizes[j] == 0) {
        tabs.add(widget.placeHolders![j]);
      } else {
        tabs.add(
          KeepAliveWidget(
            child: _SimpleMultiFeedListView(
              controller: widget.controller?.scrollControllers![j],
              itemsCubit: itemsCubit[j],
              disableScroll: widget.disableScroll == null ? false : widget.disableScroll,
              footerHeight: widget.footerHeight == null ? 0 : widget.footerHeight,
              onLoad: (){
                // print(loadMore[j]);
                if(loading[j] == false && loadMore[j] == true) {
                  _loadMore(j);
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
                } else if (widget.childBuilders != null) {
                  return widget.childBuilders![j](items[i], items.length - 1 == i);
                }
                else if(widget.childBuilder != null){
                  return widget.childBuilder!(items[i], items.length - 1 == i);
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
    return PageView(
      controller: pageController,
      onPageChanged: (value) {
        widget.controller?.tabController!.animateTo(value, duration: Duration(milliseconds: 300));
        feedIndex = value;
      },
      children: _loadTabs(),
    );
  }
}

///Controller for the simple multi feed. 
///Holds a nested Page, Tab and Scroll controllers
class SimpleMultiFeedController extends ChangeNotifier {
  late _SimpleMultiFeedState? _state;

  ///The amount of pages in the multi feed
  int _pageCount;

  ///Controllers for the individual list
  List<ScrollController>? _scrollControllers;

  ///Controls the tab bar within the header
  TabController? _tabController;

  ///Controls the bottom pageview
  PageController? _pageController;

  ///Private constructor
  SimpleMultiFeedController._(this._pageCount, this._pageController, this._tabController, this._scrollControllers);

  ///Default constuctor
  ///Creates the nested controllers
  factory SimpleMultiFeedController({
    required int pageCount,
    int initialPage = 0,
    bool keepPage = true,
    double viewportFraction = 1.0,
    TickerProvider? vsync,
    List<double>? initialOffsets,
    List<bool>? keepScrollOffsets,
    List<String>? debugLabels
  }){
    assert(initialOffsets == null || initialOffsets.length == pageCount);
    assert(keepScrollOffsets == null || keepScrollOffsets.length == pageCount);
    assert(debugLabels == null || debugLabels.length == pageCount);
    return SimpleMultiFeedController._(
      pageCount,
      PageController(initialPage: initialPage, keepPage: keepPage, viewportFraction: viewportFraction),
      vsync == null ? null : TabController(initialIndex: initialPage, length: pageCount, vsync: vsync),
      List.generate(pageCount, (index) => ScrollController(
        debugLabel: debugLabels?.elementAt(index) ?? 'SimpleMultiFeedScrollController-' + UniqueKey().toString() + '$index',
        initialScrollOffset: initialOffsets?.elementAt(index) ?? 0.0,
        keepScrollOffset: keepScrollOffsets?.elementAt(index) ?? true
      ))
    );
  }

  ///Binds the feed state
  void _bind(_SimpleMultiFeedState bind) => _state = bind;

  //Called to notify all listners
  void _update() => notifyListeners();

  ///Retreives the list of items from the feed
  List list(index) => _state!.itemsCubit[index].state;

  ///Reloads the feed state based on the original size parameter
  void reload(int index) => _state!._refresh(index);

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

///Defines the laoding state
enum FeedLoadingState {
  BLOCK, //Load but do not display
  LOADED, //Loaded but do not display
  DISPLAY, //Display item
  FIRST, //Start the loading process
}

class _SimpleMultiFeedListView extends StatefulWidget {

  //Weither to disable scrolling
  final bool? disableScroll;

  //The onload function when more items need to be loaded
  final Function()? onLoad;

  ///Cubit holding the items
  final ConcreteCubit<List> itemsCubit;

  ///Builder function for each item
  final Widget Function(BuildContext context, int i, List items) builder;

  //The scroll controller
  final ScrollController? controller;

  //The height of the footer
  final double? footerHeight;

  ///Loading widget
  final Widget? loading;
  
  ///The header builder
  final Widget Function(BuildContext context)? headerBuilder;

  const _SimpleMultiFeedListView({ 
    Key? key, 
    this.disableScroll = false, 
    this.onLoad, 
    required this.builder, 
    required this.itemsCubit, 
    this.controller, 
    this.footerHeight, 
    this.headerBuilder, 
    this.loading
  }) : super(key: key);

  @override
  __SimpleMultiFeedListViewState createState() => __SimpleMultiFeedListViewState();
}

class __SimpleMultiFeedListViewState extends State<_SimpleMultiFeedListView> {


  //Cubit for each list item
  List<ConcreteCubit<FeedLoadingState>> itemLoadState = [];


  @override
  void initState() {
    super.initState();

    //Sync the providers
    _syncProviders(widget.itemsCubit.state);
  }

  Widget get loading => widget.loading == null ? Container() : widget.loading!;


  ///Adds new items to the list of loading cubits and sets the first one to display if not set
  void _syncProviders(List items){

    //Difference in the items and providers lengths
    int newCubitLength = items.length - itemLoadState.length;

    //Creates new cubits for non included items
    List<ConcreteCubit<FeedLoadingState>> newCubits = List.generate(newCubitLength, (i){
      return ConcreteCubit(FeedLoadingState.BLOCK);
    });

    //Add all the new cubits to the list
    itemLoadState.addAll(newCubits);

    for (var i = 0; i < itemLoadState.length; i++) {
      bool startProcess = itemLoadState[i].state != FeedLoadingState.DISPLAY;

      //If the first cubit is not set to display set it
      if(startProcess){
        return itemLoadState[i].emit(FeedLoadingState.FIRST);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels + 1 >= scrollInfo.metrics.maxScrollExtent - 50 - (widget.footerHeight ?? 0)) {
          widget.onLoad!();
        }
        return false;
      },
      child: BlocConsumer<Cubit<List>, List>(
        bloc: widget.itemsCubit,
        listener: (context, items) {
          //Adds cubits to the list if they are not defined
          _syncProviders(items);
        },
        builder: (context, items) {

          return SingleChildScrollView(
            physics: (widget.disableScroll ?? false) ? NeverScrollableScrollPhysics() : AlwaysScrollableScrollPhysics(),
            controller: widget.controller,
            child: Column(
              children: [
                if(widget.headerBuilder != null)
                  widget.headerBuilder!(context),

                if(items.isEmpty)
                  Center(child: loading),

                for (var i = 0; i < items.length; i++)
                  _buildChild(items, i),
              ],
            ),
          );
          
          // return ListView.builder(
          //   physics: (widget.disableScroll ?? false) ? NeverScrollableScrollPhysics() : AlwaysScrollableScrollPhysics(),
          //   controller: widget.controller != null ? widget.controller.scrollControllers[j] : null,
          //   itemCount: items.length + 1,
          //   itemBuilder: (context, i) {
          //     if (i == items.length) {
          //       return Column(
          //         children: [
          //           Container(
          //             height: 100,
          //             width: double.infinity,
          //             child: Center(
          //               child: PollarLoading(),
          //             ),
          //           ),
          //           Container(
          //             height: widget.footerHeight,
          //             width: double.infinity,
          //           ),
          //         ],
          //       );
          //     } else if (widget.childBuilders != null && widget.childBuilders[j] != null) {
          //       return widget.childBuilders[j](items[i], items.length - 1 == i);
          //     }
          //     else if(widget.childBuilder != null){
          //       return widget.childBuilder(items[i], items.length - 1 == i);
          //     }
      
          //     return _loadCard(items, i);
          //   },
          // );
        }
      ),
    );
  }

  Widget _buildChild(List items, int i){
    //The feed load state bloc
    ConcreteCubit<FeedLoadingState> bloc = itemLoadState.length > i ? itemLoadState[i] : ConcreteCubit(FeedLoadingState.BLOCK);

    return BlocListener(
      key: ValueKey('key - ${i}'),
      bloc: bloc,
      listener: (context, state) {
        try{
          if(state == FeedLoadingState.DISPLAY){
            itemLoadState[i + 1].emit(FeedLoadingState.FIRST);
          }
        // ignore: empty_catches
        }catch(e){}
      },
      child: BlocProvider<ConcreteCubit<FeedLoadingState>>(
        create: (context) => bloc,
        child: widget.builder(context, i, items)
      ),
    );
  }
}