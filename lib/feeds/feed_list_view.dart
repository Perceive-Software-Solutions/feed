import 'package:feed/util/global/functions.dart';
import 'package:feed/util/state/concrete_cubit.dart';
import 'package:feed/util/state/feed_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:fort/fort.dart';
import 'package:perceive_slidable/sliding_sheet.dart';

///Defines the laoding state
enum FeedLoadingState {
  BLOCK, //Load but do not display
  LOADED, //Loaded but do not display
  DISPLAY, //Display item
  FIRST, //Start the loading process
}

///The specification for a gridview, if passed into the feed, transforms it into a grid feed
class FeedGridViewDelegate{

  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final EdgeInsets padding;

  FeedGridViewDelegate({
    this.crossAxisCount = 2, 
    this.mainAxisSpacing = 8, 
    this.crossAxisSpacing = 8, 
    this.padding = EdgeInsets.zero
  });

}

class FeedListView extends StatefulWidget {

  final bool compact;

  //Whether to disable scrolling
  final bool? disableScroll;

  //The onload function when more items need to be loaded
  final Function()? onLoad;

  ///Builder function for each item
  final Widget Function(BuildContext context, int i, List items) builder;

  //The scroll controller
  final ScrollController controller;

  //The height of the footer
  final double? footerHeight;

  ///Loading widget
  final Widget? loading;

  ///The optional function used to wrap the list view
  final WidgetWrapper? wrapper;

  ///If defined builds this feed in grid mode
  final FeedGridViewDelegate? gridDelegate;

  /// If the feed is built in reverse
  final bool reverse;

  const FeedListView({ 
    Key? key, 
    this.disableScroll = false, 
    this.compact = false, 
    this.reverse = false, 
    this.onLoad, 
    required this.builder, 
    required this.controller, 
    this.footerHeight, 
    this.wrapper, 
    this.loading, 
    this.gridDelegate,
  }) : super(key: key);

  @override
  _FeedListViewState createState() => _FeedListViewState();
}

class _FeedListViewState extends State<FeedListView> {

  ScrollController get scrollController => widget.controller;

  Widget get loading => widget.loading == null ? Container() : widget.loading!;

  Widget wrapperBuilder({required BuildContext context, required Widget child}){
    if(widget.wrapper != null){
      return widget.wrapper!(context, child);
    }
    return child;
  }

  Widget listBuilder(BuildContext context, List items){

    ///Simple List
    late Widget list;

    if(widget.gridDelegate != null){
      //Grid list
      list = StaggeredGridView.countBuilder(
        reverse: widget.reverse,
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        addRepaintBoundaries: true,
        crossAxisCount: widget.gridDelegate!.crossAxisCount,
        mainAxisSpacing: widget.gridDelegate!.mainAxisSpacing,
        crossAxisSpacing: widget.gridDelegate!.crossAxisSpacing,
        padding: widget.gridDelegate!.padding,
        itemCount: items.length + 1,
        itemBuilder: (context, i) => widget.builder(context, i, items),
        staggeredTileBuilder: (index) => StaggeredTile.fit(1),
      );
    }
    else{
      list = ListView.builder(
        reverse: widget.reverse,
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        addRepaintBoundaries: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: items.length + 1,
        itemBuilder: (context, i) => widget.builder(context, i, items),
      );
    }


    return Column(
      children: [
        wrapperBuilder(
          context: context,
          child: list
        ),

        Container(
          height: widget.footerHeight ?? 0,
        )
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels + 1 >= scrollInfo.metrics.maxScrollExtent - 50 - (widget.footerHeight ?? 0) && !widget.compact) {
          widget.onLoad!();
        }
        return false;
      },
      child: StoreConnector<FeedState, List>(
        distinct: true,
        converter: (store) => store.state.items,
        builder: (context, items) {
          
          late Widget list = listBuilder(context, items);

          if(!widget.compact){
            list = SingleChildScrollView(
              reverse: widget.reverse,
              physics: widget.disableScroll == true ? NeverScrollableScrollPhysics() : BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              controller: scrollController,
              child: list,
            );
          }

          return Container(
            height: widget.compact ? null : MediaQuery.of(context).size.height,
            child: list,
          );
        }
      ),
    );
  }

}