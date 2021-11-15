import 'package:feed/util/state/concrete_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sliding_sheet/sliding_sheet.dart';

///Defines the laoding state
enum FeedLoadingState {
  BLOCK, //Load but do not display
  LOADED, //Loaded but do not display
  DISPLAY, //Display item
  FIRST, //Start the loading process
}

class SimpleMultiFeedListView extends StatefulWidget {

  final SheetController sheetController;

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

  const SimpleMultiFeedListView({ 
    Key? key, 
    required this.sheetController,
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
  _SimpleMultiFeedListViewState createState() => _SimpleMultiFeedListViewState();
}

class _SimpleMultiFeedListViewState extends State<SimpleMultiFeedListView> {


  //Cubit for each list item
  List<ConcreteCubit<FeedLoadingState>> itemLoadState = [];

  late ScrollController scrollController;

  bool snapping = false;


  @override
  void initState() {
    super.initState();

    //Sync the providers
    _syncProviders(widget.itemsCubit.state);

    //init
    scrollController = ScrollController();

    scrollController.addListener(() {
      if(scrollController.offset <= -80 && !snapping){
        print('called');
        if(widget.sheetController.state!.extent == 1.0){
          snapping = true;
          Future.delayed(Duration.zero, () {
            widget.sheetController.snapToExtent(0.7, duration: Duration(milliseconds: 300));
            Future.delayed(Duration(milliseconds: 800)).then((value) => {
              snapping = false
            });
          });
        }
        else if(widget.sheetController.state!.extent == 0.7){
          snapping = true;
          Future.delayed(Duration.zero, () {
            widget.sheetController.snapToExtent(0.0, duration: Duration(milliseconds: 300));
          });
          Future.delayed(Duration(milliseconds: 800)).then((value) => {
            snapping = false
          });
        }

      }
    });
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

                SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: ListView(
                    controller: scrollController,
                    children: [
                      for (var i = 0; i < items.length; i++)
                      _buildChild(items, i),
                    ],
                  ),
                )
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