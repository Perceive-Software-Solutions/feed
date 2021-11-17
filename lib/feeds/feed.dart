import 'dart:math';

import 'package:feed/feeds/simple_multi_feed_list_view.dart';
import 'package:feed/util/global/functions.dart';
import 'package:feed/util/render/keep_alive.dart';
import 'package:feed/util/state/concrete_cubit.dart';
import 'package:flutter/material.dart';
import 'package:sliding_sheet/sliding_sheet.dart';
import 'package:tuple/tuple.dart';

class SingleFeed extends StatefulWidget {

  final FeedLoader loader;

  final SheetController? sheetController;

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

  /// Loading widget
  final Widget? loading;

  /// Corresponds to the [condition] and replaces feed with [Widget]
  final Widget? placeHolder;

  /// Controls the scroll position
  final ScrollController? controller;

  ///The header builder that prints over each multi feed
  final Widget Function(BuildContext context)? headerBuilder;

  //  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Extra ~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  /// Page that can be pushed on top of the single feed
  final Widget? page;

  const SingleFeed({ 
    Key? key,
      required this.loader,
      this.controller,
      this.sheetController,
      this.lengthFactor,
      this.innitalLength,
      this.onRefresh,
      this.childBuilder,
      this.footerHeight,
      this.placeHolder,
      this.loading,
      this.condition = false, 
      this.headerBuilder,
      this.disableScroll,
      this.page})
      : super(key: key);

  @override
  _SingleFeedState createState() => _SingleFeedState();
}

class _SingleFeedState extends State<SingleFeed> {

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Constants ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  ///The default length increase and innitial length factor
  static const int LENGTH_INCREASE_FACTOR = 30;

  ///The fraction of items that are rendered from the list displayed.
  static const int RENDER_COUNT = 10;

  ///The delay between adding an item
  static const int ITEM_ADD_DELAY = 0;

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ State ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  ///Determines when each index in the list is loading
  late bool loading;

  ///Determines the length of each of the lists
  late int size;

  //Items loaded in but not rendered
  late List pending;

  ///List of tokens for each index of the feed
  late String? token;


  late bool loadMore;

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Render State ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  ///The list iof loaded items to be displayed on the feed
  late ConcreteCubit<List> itemsCubit;

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Getter ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  ///Retreives the load size
  int get loadSize => widget.innitalLength ?? widget.lengthFactor ?? LENGTH_INCREASE_FACTOR;

  ///Retreives loading widget
  Widget get load => widget.loading == null ? Container() : widget.loading!;

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Lifecycle ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  @override
  void initState(){
    
    //Initialize
    pending = [];
    size = (loadSize/2).floor();
    token = null;
    loading = false;
    loadMore = true;

    //Creates concrete cubit
    itemsCubit = ConcreteCubit<List>([]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    //Refresh all feeds
    _refresh(false);
  }

  ///Builds the type of item card
  Widget _loadCard(List<dynamic> itemList, int index) {
    dynamic item = itemList[index];
    return Container();
  }

  List _allocateToPending(List items){

    //Determine split index as a fraction fo the items loaded
    int splitIndex = min(RENDER_COUNT, items.length);

    //Alocated the remaining items to pending
    pending = items.sublist(splitIndex);

    //Return the portion of the items
    return items.sublist(0, splitIndex);

  }

  Future<void> _incrementallyAddItems(List newItems) async {

    for (var i = 0; i < newItems.length; i++) {
      
      await Future.delayed(Duration(milliseconds: ITEM_ADD_DELAY)).then((_){
        List addNewItem = [...itemsCubit.state, newItems[i]];

        itemsCubit.emit( addNewItem );
        
        //Updates the size variable //TODO clean up
        size = addNewItem.length;
      });
    }
  }

  ///The function that is run to refresh the page
  ///[full] - defines if the parent widget should be refreshed aswell
  Future<void> _refresh([bool full = true]) async {
    //Calls the refresh function from the parent widget
    Future<void>? refresh =
        widget.onRefresh != null && full ? widget.onRefresh!() : null;

    //Set the loading to true
    loading = true;

    //Retreives items
    Tuple2<List, String?> loaded = await widget.loader(loadSize);

    //The loaded items
    List loadedItems = loaded.item1;

    //Awaits the parent refresh function
    if (refresh != null) await refresh;

    if (mounted) {
      
      List newItems = _allocateToPending(loadedItems);
      token = loaded.item2;


      if(loadedItems.length < loadSize){
        loadMore = false;
      }

      await _incrementallyAddItems(newItems);

      //Set the loading to false
      loading = false;
    }
  }

  ///The function run to load more items onto the page
  Future<void> _loadMore() async {
    //Set the loading to true
    loading = true;
    int newSize = LENGTH_INCREASE_FACTOR;
    Tuple2<List, String?> loaded;

    //use pending
    if(pending.isNotEmpty){
      loaded = Tuple2([...pending], token!);

      if(mounted){

        List newItems = _allocateToPending(loaded.item1);
        token = loaded.item2;

        await _incrementallyAddItems(newItems);

        //Set the loading to false
        loading = false;
      }
    }
    //Load more
    else{
      loaded = await widget.loader(newSize, token!);

      //The loaded items
      List loadedItems = loaded.item1;

      if (mounted) {

        List newItems = _allocateToPending(loaded.item1);

        token = loaded.item2;


        if(loadedItems.length < newSize){
          loadMore = false;
        }

        await _incrementallyAddItems(newItems);

        //Set the loading to false
        loading = false;
      }
    }
  }

  Widget buildFeed(){
    return KeepAliveWidget(
      child: SingleChildScrollView(
        physics: (widget.disableScroll ?? false) ? NeverScrollableScrollPhysics() : AlwaysScrollableScrollPhysics(),
        controller: widget.controller,
        child: SimpleMultiFeedListView(
          sheetController: widget.sheetController,
          controller: widget.controller,
          itemsCubit: itemsCubit,
          disableScroll: widget.disableScroll == null ? false : widget.disableScroll,
          footerHeight: widget.footerHeight == null ? 0 : widget.footerHeight,
          page: widget.page,
          onLoad: (){
            // print(loadMore[j]);
            if(loading == false && loadMore == true) {
              _loadMore();
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
            else if(widget.childBuilder != null){
              return widget.childBuilder!(items[i], items.length - 1 == i);
            }
  
            return _loadCard(items, i);
          },
          headerBuilder: widget.headerBuilder == null ? null : (context){
            return widget.headerBuilder!(context);
          },              
        ),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return buildFeed();
  }
}