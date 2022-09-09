import 'package:feed/util/global/functions.dart';
import 'package:feed/util/state/feed_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:fort/fort.dart';

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

  final bool usePrimaryScrollController;

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
  final Widget? header;

  ///Loading widget
  final Widget? footer;

  ///If defined builds this feed in grid mode
  final FeedGridViewDelegate? gridDelegate;

  /// If the feed is built in reverse
  final bool reverse;

  /// Physics
  final ScrollPhysics? physics;

  const FeedListView({  
    Key? key, 
    this.usePrimaryScrollController = false,
    this.disableScroll = false, 
    this.compact = false, 
    this.reverse = false, 
    this.onLoad, 
    required this.builder, 
    required this.controller, 
    this.footerHeight, 
    this.header, 
    this.footer, 
    this.gridDelegate,
    this.physics
  }) : super(key: key);

  @override
  _FeedListViewState createState() => _FeedListViewState();
}

class _FeedListViewState extends State<FeedListView> {

  ScrollController get scrollController => widget.controller;

  Widget get header => widget.header ?? SizedBox.shrink();
  Widget get footer => widget.footer ?? SizedBox.shrink();

  Widget listBuilder(BuildContext context, List items){

    final scrollPhysics = widget.physics != null ? widget.physics : widget.disableScroll == true ? NeverScrollableScrollPhysics() : BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
    final controller = widget.usePrimaryScrollController ? null : scrollController;
    final footerHeightAdjustment = Container(
      height: widget.footerHeight ?? 0,
    );

    if(items.isEmpty){
      return SizedBox.shrink();
    }
    else if(widget.gridDelegate != null){
      //Grid list
      Widget list = Column(
        children: [

          header,
          
          StaggeredGridView.countBuilder(
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
          ),

          footer,

          footerHeightAdjustment
        ],
      );

      if(widget.compact){
        return list;
      }
      else{
        return SingleChildScrollView(
          reverse: widget.reverse,
          physics: scrollPhysics,
          controller: controller,
          child: list,
        );
      }
    }
    else{
      return ListView.builder(
        controller: controller,
        reverse: widget.reverse,
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        addRepaintBoundaries: true,
        physics: widget.compact ? NeverScrollableScrollPhysics() : scrollPhysics,
        itemCount: items.length + 3,
        itemBuilder: (context, i){
          if(i == 0){
            return header;
          }
          else if(i == items.length){
            //footer
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                footer,
                footerHeightAdjustment
              ],
            );
          }
          else{
            //items
            return widget.builder(context, i - 1, items);
          }
        },
      );
    }


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
          return Container(
            height: widget.compact ? null : MediaQuery.of(context).size.height,
            child: listBuilder(context, items),
          );
        }
      ),
    );
  }

}