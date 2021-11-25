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
  }): super(key: key);

  @override
  _SwipeFeedState<T> createState() => _SwipeFeedState<T>();

  /// The overlay to be shown
  final Widget Function(Future<void> Function(int), Future<void> Function(int), int, T)? overlayBuilder;

  /// If the overlay should be shown
  final bool Function(int)? swipeAlert;

  ///A builder for the feed
  final FeedBuilder<T>? childBuilder;

  ///Loading widget
  final Widget? loading;

  ///A loader for the feed
  final FeedLoader<T> loader;

  ///Set to `true` if you want to prevent the feed from loading onCreate
  final bool loadManually;

  ///Controller for the swipe feed
  final SwipeFeedController? controller;

  ///The on swipe function, run when a card is swiped
  final Future<void> Function(DismissDirection direction, T item)? onSwipe;

  ///The on swipe function, run when a card is completed swiping away
  final Future<void> Function(DismissDirection direction, T item)? onContinue;
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

  ConcreteCubit<List<Tuple2<T, ConcreteCubit<bool>>>> cubit = ConcreteCubit<List<Tuple2<T, ConcreteCubit<bool>>>>([]);

  ///Percent Bar controller
  late PercentBarController _fillController;

  Widget get load => widget.loading == null ? Container() : widget.loading!;

  @override
  void initState(){
    super.initState();

    //Initlaize the fill controller
    _fillController = PercentBarController();

    // topCard = ConcreteCubit<Tuple2<Widget, ConcreteCubit<bool>>>(null);
    // bottomCard = ConcreteCubit<Tuple2<Widget, ConcreteCubit<bool>>>(null);

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

  Future<void> completeFillBar(double value, [IconPosition? direction]) async => await _fillController.completeFillBar(value, direction);
  Future<void> fillBar(double value, IconPosition direction) async => await _fillController.fillBar(min(0.75, value * 0.94), direction);



  // void _addCard(){

  //   //Load more if there are not enough items
  //   if(items.length <= LOAD_MORE_LIMIT){
  //     _loadMore();
  //   }

  //   //Remove first index

  //   // int index = topCard.state == null ? 0 : 1;

  //   // //Checks if card is empty
  //   // if(index == 1 && bottomCard.state != null){
  //   //   return;
  //   // }

  //   // //Create the cubit for the card.
  //   // //The cubit is active if this is the first card
  //   // ConcreteCubit<bool> cubit = ConcreteCubit<bool>(false);

  //   // //Start a delayed animation to open the card
  //   // if(index == 0){
  //   //   Future.delayed(Duration(milliseconds: 300)).then((value){
  //   //     cubit.emit(true);
  //   //   });
  //   // }

  //   // Widget card;
  //   // try{
  //   //   card = _buildCard(cubit, index);
  //   // }catch(e){
  //   //   //Index out of bounds
  //   //   _loadMore();
  //   //   return;
  //   // }

  //   // //Create the card and cubit tuple
  //   // Tuple2<Widget, ConcreteCubit<bool>> cardCubit = Tuple2<Widget, ConcreteCubit<bool>>(
  //   //   card,
  //   //   cubit
  //   // );

  //   // //Add the card cubit to the list
  //   // _setCard(cardCubit, index);

  // }

  void _removeCard(){
    // if(bottomCard.state != null){
      Future.delayed(Duration(milliseconds: 400, seconds: 1)).then((value){
        // bottomCard.state.item2.emit(true);
        if(cubit.state.length >= 2) {
          cubit.state[1].item2.emit(true);
        }
        Future.delayed(Duration(milliseconds: 400)).then((value){
          // _switchCard(start: 1, end: 0);
          fillBar(0.0, IconPosition.BOTTOM);
          cubit.emit([...cubit.state]..removeAt(0));
          // items.removeAt(0); //Remove the item from the loaded list
          if(cubit.state.length <= LOAD_MORE_LIMIT){
            _loadMore();
          }
          // Future.delayed(Duration(milliseconds: 100)).then((value){
          //   _addCard();
          // });
        });
      });
    // }
  }

  //Resets the page and loads more
  Future<void> _reset() async {

    items = [];
    pageToken = null;
    hasMore = true;
    loading = false;
    cubit.emit([]);
    _fillController.fillBar(0, IconPosition.BOTTOM);

    if(mounted){
      setState(() {});
    }

    await _loadMore();

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
    List<Tuple2<T, ConcreteCubit<bool>>> oldItems = cubit.state;

    if(mounted) {
      setState(() {
        //New token
        pageToken = loaded.item2;

        //If there is no next page, then has more is false
        if(pageToken == null || newItems.length < LENGTH_INCREASE_FACTOR){

          hasMore = false;
        }

        //Add all Loaded items
        // items.addAll(newItems);
        //TODO emit
        //Cubit items
        List<Tuple2<T, ConcreteCubit<bool>>> cubitItems = List<Tuple2<T, ConcreteCubit<bool>>>.generate(newItems.length, (i) => Tuple2(newItems[i], ConcreteCubit<bool>(false)));

        if(cubit.state.isEmpty != false && cubitItems.isNotEmpty){
          Future.delayed(Duration(milliseconds: 300)).then((value){
            cubitItems[0].item2.emit(true);
          });
        }
        
        cubit.emit([...oldItems, ...cubitItems]);

        //If there are items addCard
        // _addCard();
        // _addCard();
      });
    }

  }

  ///Builds the type of item card based on the feed type. 
  ///If a custom child builder is present, uses the child builder instead
  Widget _loadCard(T item, int index) {
    if(widget.childBuilder != null){
      //Builds custom child if childBuilder is defined
      return widget.childBuilder!(item, index == 1);
    }
    else {
      throw ('T is not supported by Feed');
    }
  }

  // void _setCard(Tuple2<Widget, ConcreteCubit<bool>> cardCubit, int index){
  //   assert(index == 0 || index == 1);

  //   if(index == 0){
  //     topCard.emit(cardCubit);
  //   }else{
  //     bottomCard.emit(cardCubit);
  //   }

  // }

  // void _switchCard({int start, int end}){
  //   assert(start == 0 || start == 1);
  //   assert(end == 0 || end == 1);

  //   if(start == end){
  //     return;
  //   }
    
  //   if(end == 0){
  //     _setCard(bottomCard.state, 0);
  //     bottomCard.emit(null);
  //   }else{
  //     _setCard(topCard.state, 1);
  //     topCard.emit(null);
  //   }

  // }

  // Widget _buildCard(ConcreteCubit<bool> cubit, int index){
  //   assert(index < items.length);

  //   Key key = UniqueKey();
  //   T item = items[index];
  //   return BlocBuilder<ConcreteCubit<bool>, bool>(
  //     key: key,
  //     bloc: cubit,
  //     builder: (context, show) {
  //       return SwipeFeedCard(
  //         key: key,
  //         show: show,
  //         onFill: (fill, position) {
  //           fillCubit.emit(Tuple2(fill, position));
  //         },
  //         onContinue: (dir) async {
  //           _removeCard();
  //           if(widget.onSwipe != null) {
  //             await widget.onSwipe(dir, item, fillCubit);
  //           }
  //           return;
  //         },
  //         child: _loadCard(item, index),
  //       );
  //     }
  //   );
  // }

  Widget _buildCard(int index){
    if(index >= cubit.state.length){
      return Container();
    }

    Tuple2<T, ConcreteCubit<bool>> itemCubit = cubit.state[index];
    return BlocBuilder<ConcreteCubit<bool>, bool>(
      key: Key('swipefeed - card - ${itemCubit.item1.hashCode}'),
      bloc: itemCubit.item2,
      builder: (context, show) {
        return KeyboardVisibilityBuilder(
          builder: (context, keyoard){
            return SwipeFeedCard(
              overlay: (forwardAnimation, reverseAnimation, index){
                if(widget.overlayBuilder != null)
                  return widget.overlayBuilder!(forwardAnimation, reverseAnimation, index, itemCubit.item1);
                return null;
              },
              swipeAlert: widget.swipeAlert,
              keyboardOpen: keyoard,
              show: show,
              onFill: (fill, position) {
                fillBar(fill, position);
              },
              onContinue: (dir) async {
                if(widget.onContinue != null){
                  await widget.onContinue!(dir!, itemCubit.item1);
                }
                _removeCard();
              },
              onSwipe: (dir) {
                if(widget.onSwipe != null){
                  widget.onSwipe!(dir, itemCubit.item1);
                }
              },
              onPanEnd: () {
                fillBar(0.0, IconPosition.BOTTOM);
              },
              child: _loadCard(itemCubit.item1, index),
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
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: KeepAliveWidget(
            key: Key('PollPage - Bar - KeepAlive'),
            child: NeumorpicPercentBar(
              key: Key('PollPage - Bar'),
              controller: _fillController,
            ),
          ),
        ),


        BlocBuilder<ConcreteCubit<List<Tuple2<T, ConcreteCubit<bool>>>>, List<Tuple2<T, ConcreteCubit<bool>>>>(
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

        // BlocBuilder<ConcreteCubit<Tuple2<Widget, ConcreteCubit<bool>>>, Tuple2<Widget, ConcreteCubit<bool>>>(
        //   bloc: bottomCard,
        //   builder: (context, bottom) {
            
        //     // if(bottom?.item1 != null){
        //     //   print('Bottom - ${bottom.item1.key.toString()}');
        //     // }
            
        //     return bottom?.item1 != null ? bottom.item1 : Center(
        //       child: Container(
        //         height: 200,
        //         width: 200,
        //         color: loading ? Colors.transparent : Colors.purple,
        //       ),
        //     );

        //   },
        // ),
        // BlocBuilder<ConcreteCubit<Tuple2<Widget, ConcreteCubit<bool>>>, Tuple2<Widget, ConcreteCubit<bool>>>(
        //   bloc: topCard,
        //   builder: (context, top) {

        //     // if(top?.item1 != null){
        //     //   print('Top - ${top.item1.key.toString()}');
        //     // }
            
        //     return top?.item1 != null ? top.item1 : Center(
        //       key: Key('poll - page - loader'),
        //       child: PollarLoading(),
        //     );

        //   },
        // ),
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

  Future<void> completeFillBar(double value, [IconPosition? direction]) async => _state == null ? _state!.items : await _state!.completeFillBar(value, direction);

  Future<void> fillBar(double value, IconPosition direction) async => _state == null ? _state!.items : await _state!.fillBar(value, direction);

  //Disposes of the controller
  @override
  void dispose() {
    _state = null;
    super.dispose();
  }
}