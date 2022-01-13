import 'package:feed/util/global/functions.dart';
import 'package:feed/util/state/concrete_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
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

  //State of the sheet
  final SheetController? sheetController;

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

  ///The optional function used to wrap the list view
  final WidgetWrapper? wrapper;
  
  ///The header builder
  final Widget Function(BuildContext context)? headerBuilder;

  ///If defined builds this feed in grid mode
  final FeedGridViewDelegate? gridDelegate;

  final double extent;

  final double minExtent;

  const FeedListView({ 
    Key? key, 
    required this.sheetController,
    this.disableScroll = false, 
    this.onLoad, 
    required this.builder, 
    required this.itemsCubit,
    this.minExtent = 0.0,
    this.extent = 0.7,
    this.controller, 
    this.footerHeight, 
    this.headerBuilder, 
    this.wrapper, 
    this.loading, 
    this.gridDelegate,
  }) : super(key: key);

  @override
  _FeedListViewState createState() => _FeedListViewState();
}

class _FeedListViewState extends State<FeedListView> {


  //Cubit for each list item
  List<ConcreteCubit<FeedLoadingState>> itemLoadState = [];

  //If currently snapping
  bool snapping = false;

  late ScrollController controller;

  ScrollController get scrollController => widget.controller ?? scrollController;

  bool keyBoardOpen = false;


  @override
  void initState() {
    super.initState();

    //Sync the providers
    _syncProviders(widget.itemsCubit.state);

    widget.sheetController != null ? scrollController.addListener(() {
      if(keyBoardOpen){
        return;
      }
      else{
        if(scrollController.offset <= -80 && !snapping){
          if(widget.sheetController!.state!.extent == 1.0){
            snapping = true;
            Future.delayed(Duration.zero, () {
              widget.sheetController!.snapToExtent(widget.extent, duration: Duration(milliseconds: 300));
              Future.delayed(Duration(milliseconds: 300)).then((value) => {
                snapping = false
              });
            });
          }
          else if(widget.sheetController!.state!.extent == widget.extent){
            snapping = true;
            Future.delayed(Duration.zero, () {
              widget.sheetController!.snapToExtent(widget.minExtent, duration: Duration(milliseconds: 300));
            });
            Future.delayed(Duration(milliseconds: 300)).then((value) => {
              snapping = false
            });
          }

        }
      }
    }) : null;
  }

  @override
  void dispose(){
    super.dispose();
    scrollController.removeListener(() { 
      scrollController.dispose();
    });
  }

  Widget get loading => widget.loading == null ? Container() : widget.loading!;


  ///Adds new items to the list of loading cubits and sets the first one to display if not set
  void _syncProviders(List items){

    //Difference in the items and providers lengths
    int newCubitLength = items.length - itemLoadState.length;

    if(newCubitLength < 0){
      itemLoadState = [];
      return;
    }

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

  Widget wrapperBuilder({required BuildContext context, required Widget child}){
    if(widget.wrapper != null){
      return widget.wrapper!(context, child);
    }
    return child;
  }

  Widget listBuilder(BuildContext context, List items){

    ///Simple List
    Widget list = Column(
      children: [
        for (var i = 0; i < items.length; i++)
          _buildChild(items, i),
      ],
    );

    if(widget.gridDelegate != null){
      //Grid list
      list = StaggeredGridView.countBuilder(
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        crossAxisCount: widget.gridDelegate!.crossAxisCount,
        mainAxisSpacing: widget.gridDelegate!.mainAxisSpacing,
        crossAxisSpacing: widget.gridDelegate!.crossAxisSpacing,
        padding: widget.gridDelegate!.padding,
        itemCount: items.length,
        itemBuilder: (context, index) => _buildChild(items, index),
        staggeredTileBuilder: (index) => StaggeredTile.fit(1),
      );
      // list = MasonryGridView.count(
      //   physics: NeverScrollableScrollPhysics(),
      //   shrinkWrap: true,
      //   crossAxisCount: widget.gridDelegate!.crossAxisCount,
      //   mainAxisSpacing: widget.gridDelegate!.mainAxisSpacing,
      //   crossAxisSpacing: widget.gridDelegate!.crossAxisSpacing,
      //   padding: widget.gridDelegate!.padding,
      //   itemCount: items.length,
      //   itemBuilder: (context, index) => _buildChild(items, index),
      // );
    }

    return wrapperBuilder(
      context: context,
      child: list
    );
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

          return Container(
            height: MediaQuery.of(context).size.height,
            child: Column(
              children: [
                if(widget.headerBuilder != null)
                  widget.headerBuilder!(context),

                Expanded(
                  child: SingleChildScrollView(
                    physics: widget.disableScroll == true ? NeverScrollableScrollPhysics() : BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    controller: scrollController,
                    child: listBuilder(context, items),
                  ),
                ),
              ],
            ),
          );
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