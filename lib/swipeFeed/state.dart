import 'package:feed/feed.dart';
import 'package:feed/swipeFeedCard/state.dart';
import 'package:feed/util/global/functions.dart';
import 'package:feed/util/state/feed_state.dart';
import 'package:flutter/material.dart';
import 'package:fort/fort.dart';
import 'package:tuple/tuple.dart';

class SwipeFeedState<T> extends FortState<T>{

  /// Functional
  List<Tuple2<T?, Store<SwipeFeedCardState>>> items;
  FeedLoader<T> loader;
  List<T>? previousPolls;
  String? pageToken;

  /// States
  bool hasMore;
  bool loading;
  bool connectivity;

  /// Displays
  Widget noMoreItems;
  Widget connectivityError;

  /// Getters
  //How many items are loaded in at a time
  //Passed back within the loaded function
  //If items retrieved is less then 10 then has more is set to false
  static const int LENGTH_INCREASE_FACTOR = 10;

  //When the feed should load more
  //When the items contained in the state is less then 10
  //If has more is set to false blocks it from loading more
  static const int LOAD_MORE_LIMIT = 3;

  SwipeFeedState({
    required this.loader,
    required this.items,
    required this.noMoreItems,
    required this.connectivityError,
    this.connectivity = false,
    this.hasMore = true,
    this.loading = false,
    this.previousPolls,
    this.pageToken
  });

  factory SwipeFeedState.initial(FeedLoader<T> loader, Widget noMoreItems, Widget connectivityError) => SwipeFeedState(
    loader: loader,
    items: [Tuple2(null, SwipeFeedCardState.tower())],
    noMoreItems: noMoreItems,
    connectivityError: connectivityError
  );

  @override
  FortState<T> copyWith(FortState<T> other) {
    return this;
  }

  @override
  toJson() {}
}

/*
 
   _____                 _        
  | ____|_   _____ _ __ | |_ ___  
  |  _| \ \ / / _ \ '_ \| __/ __| 
  | |___ \ V /  __/ | | | |_\__ \ 
  |_____| \_/ \___|_| |_|\__|___/ 
                                  
 
*/

class SwipeFeedEvent{}

class ResetEvent extends SwipeFeedEvent{
  ResetEvent();
}

/// Private
class SetItemsEvent<T> extends SwipeFeedEvent{
  List<Tuple2<T?, Store<SwipeFeedCardState>>> items;
  SetItemsEvent(this.items);
}

class _SetPageTokenEvent extends SwipeFeedEvent{
  String? pageToken;
  _SetPageTokenEvent(this.pageToken);
}

class _SetPreviousPollsEvent<T> extends SwipeFeedEvent{
  List<T>? items;
  _SetPreviousPollsEvent(this.items);
}

class _SetLoadingEvent extends SwipeFeedEvent{
  bool loading;
  _SetLoadingEvent(this.loading);
}

class _SetHasMoreEvent extends SwipeFeedEvent{
  bool hasMore;
  _SetHasMoreEvent(this.hasMore);
}

/// Public
class SetConnectivityEvent extends SwipeFeedEvent{
  bool connectivity;
  SetConnectivityEvent(this.connectivity);
}

/*
 
   ____          _                      
  |  _ \ ___  __| |_   _  ___ ___ _ __  
  | |_) / _ \/ _` | | | |/ __/ _ \ '__| 
  |  _ <  __/ (_| | |_| | (_|  __/ |    
  |_| \_\___|\__,_|\__,_|\___\___|_|    
                                        
 
*/

SwipeFeedState<T> swipeFeedStateReducer<T>(SwipeFeedState<T> state, dynamic event){
  if(event is SwipeFeedEvent){
    if(event is ResetEvent){
      return SwipeFeedState(
        items: [Tuple2(null, SwipeFeedCardState.tower())],
        previousPolls: [],
        pageToken: null,
        noMoreItems: state.noMoreItems,
        connectivityError: state.connectivityError,
        loader: state.loader,
        hasMore: true,
        loading: false
      );
    }
    return SwipeFeedState(
      items: setItemsReducer(state, event),
      pageToken: setPageTokenReducer(state, event),
      previousPolls: setPreviousPollsReducer(state, event),
      loading: setLoadingReducer(state, event),
      hasMore: setHasMoreReducer(state, event),
      connectivity: setConnectivityReducer(state, event),
      noMoreItems: state.noMoreItems,
      connectivityError: state.connectivityError,
      loader: state.loader,
    );
  }
  return state;
}

bool setConnectivityReducer(SwipeFeedState state, dynamic event){
  if(event is SetConnectivityEvent){
    return event.connectivity;
  }
  return state.connectivity;
}

bool setHasMoreReducer(SwipeFeedState state, dynamic event){
  if(event is _SetHasMoreEvent){
    return event.hasMore;
  }
  return state.hasMore;
}

bool setLoadingReducer(SwipeFeedState state, dynamic event){
  if(event is _SetLoadingEvent){
    return event.loading;
  }
  return state.loading;
}

List<Tuple2<T?, Store<SwipeFeedCardState>>> setItemsReducer<T>(SwipeFeedState<T> state, dynamic event){
  if(event is SetItemsEvent<T>){
    return event.items;
  }
  return state.items;
}

String? setPageTokenReducer(SwipeFeedState state, dynamic event){
  if(event is _SetPageTokenEvent){
    return event.pageToken;
  }
  return state.pageToken;
}

List<T>? setPreviousPollsReducer<T>(SwipeFeedState<T> state, dynamic event){
  if(event is _SetPreviousPollsEvent<T>){
    return event.items;
  }
  return state.previousPolls;
}


/*
 
      _        _   _                 
     / \   ___| |_(_) ___  _ __  ___ 
    / _ \ / __| __| |/ _ \| '_ \/ __|
   / ___ \ (__| |_| | (_) | | | \__ \
  /_/   \_\___|\__|_|\___/|_| |_|___/
                                     
 
*/

/// Refreshes the feed, ensure null value at the end of the list
ThunkAction<SwipeFeedState<T>> refresh<T>({Function? onComplete}) {
  return (Store<SwipeFeedState<T>> store) async {
    bool loading = store.state.loading;
    if(!loading){

      store.dispatch(_SetLoadingEvent(true));

      // Ensure one element is present inside of the list
      final showItem = SwipeFeedCardState.tower();
      final placeholder = Tuple2(null, showItem);
      store.dispatch(SetItemsEvent<T>([placeholder]));
      Store<SwipeFeedCardState> lastItem = store.state.items[0].item2;
      

      // Wait time for loading card to go from hiding state to show state
      // May need to be minipulated depending on the state
      // If the card is initially loading then wait 500 miliseconds
      // If the card is going from no items state to loading state after reset is called should it wait 500 ms
      await Future.delayed(Duration(milliseconds: 500)).then((value){
        lastItem.dispatch(SetSwipeFeedCardState(SwipeCardShowState()));
      });

      // Load more items
      Tuple2<List<T>, String?> loaded = await (store as Store<SwipeFeedState<T>>).state.loader(SwipeFeedState.LENGTH_INCREASE_FACTOR, null);

      

      // New Items Loaded
      List<T> newItems = loaded.item1;

      // Old items will be empty but just a procaution
      // This will just be the null placeholder
      // The set items event seen above ensures this
      List<Tuple2<T?, Store<SwipeFeedCardState>>> oldItems = store.state.items;


      String? pageToken = loaded.item2;

      //If there is no next page, then has more is false
      //Has to be greater then 10 to have has more not get set to false
      if(pageToken == null || newItems.length < SwipeFeedState.LENGTH_INCREASE_FACTOR){
        store.dispatch(_SetHasMoreEvent(false));
      }

      /// Generate new items
      List<Tuple2<T, Store<SwipeFeedCardState>>> items = 
        List<Tuple2<T, Store<SwipeFeedCardState>>>.generate(
        newItems.length, (i) => Tuple2(newItems[i], SwipeFeedCardState.tower()));

      // Shift add new items into state
      final newState = shiftAdd(oldItems, items);

      // Show first card
      if(newState[0].item1 != null && items.isNotEmpty){
        newState.firstWhere((element) => element.item1 == null).item2.dispatch(SetSwipeFeedCardState(SwipeCardHideState()));
        newState[0] = Tuple2(newState[0].item1, SwipeFeedCardState.tower(SwipeCardShowState()));
        store.dispatch(SetItemsEvent(newState));
      }
      else {
        /// Animate from loading card back to hide state
        lastItem.dispatch(SetSwipeFeedCardState(SwipeCardHideState()));

        /// Duration between animating back to hide state and displaying no items or connectivity
        await Future.delayed(Duration(milliseconds: 200));

        /// Set card back to hide state because no items loaded in
        lastItem.dispatch(SetSwipeFeedCardState(SwipeCardHideState(!store.state.connectivity ? store.state.connectivityError : store.state.noMoreItems)));
      }

      store.dispatch(_SetLoadingEvent(false));
    }

    if(onComplete != null){
      onComplete();
    }
  };
}

/// Hydrates the initial state from a pre-exsisting state
ThunkAction<SwipeFeedState<T>> populateInitialState<T>(InitialFeedState<T> state){
  return (Store<SwipeFeedState<T>> store) async {

    bool loading = store.state.loading;

    if(!loading){

      store.dispatch(_SetLoadingEvent(true));

      // Ensure one element is present inside of the list
      final showItem = SwipeFeedCardState.tower();
      final placeholder = Tuple2(null, showItem);
      store.dispatch(SetItemsEvent<T>([placeholder]));
      Store<SwipeFeedCardState> lastItem = store.state.items[0].item2;

      // Old items will be empty but just a procaution
      // This will just be the null placeholder
      // The set items event seen above ensures this
      List<Tuple2<T?, Store<SwipeFeedCardState>>> oldItems = store.state.items;

      /// Generate new items
      List<Tuple2<T, Store<SwipeFeedCardState>>> items = 
        List<Tuple2<T, Store<SwipeFeedCardState>>>.generate(
        state.items.length, (i) => Tuple2(state.items[i], SwipeFeedCardState.tower()));

      // Shift add new items into state
      final newState = shiftAdd(oldItems, items);

      // Show first card
      if(newState[0].item1 != null && items.isNotEmpty){
        store.dispatch(SetItemsEvent(newState));
        store.state.items[0].item2.dispatch(SetSwipeFeedCardState(SwipeCardShowState()));
      }
      else {
        /// Animate from loading card back to hide state
        lastItem.dispatch(SetSwipeFeedCardState(SwipeCardHideState()));

        /// Duration between animating back to hide state and displaying no items or connectivity
        await Future.delayed(Duration(milliseconds: 200));

        /// Set card back to hide state because no items loaded in
        lastItem.dispatch(SetSwipeFeedCardState(SwipeCardHideState(!store.state.connectivity ? store.state.connectivityError : store.state.noMoreItems)));
      }

      store.dispatch(_SetLoadingEvent(false));
    }
  };
}

/// Removes a card only after being swiped
ThunkAction<SwipeFeedState<T>> removeCard<T>(){
  return (Store<SwipeFeedState<T>> store) async {
    List<Tuple2<T?, Store<SwipeFeedCardState>>> items = store.state.items;
    if(items.length >= 2) {
      if(items[1].item1 == null){
        items[1].item2.dispatch(SetSwipeFeedCardState(SwipeCardHideState(!store.state.connectivity ? store.state.connectivityError : store.state.noMoreItems)));
      }
      else{
        items[1].item2.dispatch(SetSwipeFeedCardState(SwipeCardShowState()));
      }
    }

    // Duration it takes for card to make it off the screen
    // This is after the card has been swipped away
    await Future.delayed(Duration(milliseconds: 400)).then((value){
      items.removeAt(0);
      store.dispatch(SetItemsEvent(items));
      if(store.state.items.length <= SwipeFeedState.LOAD_MORE_LIMIT){
        store.dispatch(loadMore<T>());
      }
    });
  };
}

/// Removes a card from the list, do not use when the card is being swiped
ThunkAction<SwipeFeedState<T>> removeItem<T>([AdjustList<T>? then]){
  return (Store<SwipeFeedState<T>> store) async {
    
    // State
    var items = [...store.state.items];
    
    if(items.isNotEmpty && items.length > 1){
      // The item that is about to be removed
      // Set it to hide state
      items[0].item2.dispatch(SetSwipeFeedCardState(SwipeCardHideState()));
      
      // How long it takes for the current card being remove to enter hide state
      // Do we need this when you remove the last item??
      await Future.delayed(Duration(milliseconds: 400));

      if(!items.isEmpty || items[0].item1 != null){
        items = [
          items[0],
          // Sublist that is added into the state after the current item is removed
          ...((then?.call(items.sublist(1))) ?? items.sublist(1)),
          Tuple2(null, SwipeFeedCardState.tower())
        ];

        assert(items.isNotEmpty);

        if(items.length > 1){
          items[0] = Tuple2(items[1].item1, items[0].item2);
          items.removeAt(1);
        }

        // Set new items
        store.dispatch(SetItemsEvent(items));
      }

      //Maximizes the card
      //Duration before the next card is shown
      //This works in correlation with "one animation to rule them all"
      await Future.delayed(Duration(milliseconds: 400)).then((value){
        if(store.state.items[0].item1 == null){
          store.state.items[0].item2.dispatch(
            SetSwipeFeedCardState(SwipeCardHideState(!store.state.connectivity ? store.state.connectivityError : store.state.noMoreItems))
          );
        }
        else{
          store.state.items[0].item2.dispatch(SetSwipeFeedCardState(SwipeCardShowState()));
        }
      });
    }
  };
}

ThunkAction<SwipeFeedState<T>> removeItemById<T>(String id, String Function(T) objectKey){
  return (Store<SwipeFeedState<T>> store) async {
    List<Tuple2<T?, Store<SwipeFeedCardState>>> items = store.state.items;
    if(items.isNotEmpty && id == objectKey(items[0].item1!)){
      items.remove(0);
      if(items.isNotEmpty){
        items[0].item2.dispatch(SetSwipeFeedCardState(SwipeCardShowState()));
      }
      store.dispatch(SetItemsEvent(items));
    }
  };
}

// Ensures there is always a placeholder card at the end of the list
// Loads More items
ThunkAction<SwipeFeedState<T>> loadMore<T>() {
  return (Store<SwipeFeedState<T>> store) async {
    // Ensure not loading
    if(!store.state.loading && store.state.hasMore){

      // Loading
      store.dispatch(_SetLoadingEvent(true));

      // Add PlaceHolder Card at the end of the list
      bool wasEmpty = store.state.items.isEmpty;
      bool wasLast = store.state.items.isNotEmpty && store.state.items[0].item1 == null;
      Tower<SwipeFeedCardState>? showItem;
      var placeholder;
      // Add last card if it does not already exsist
      // This should never be ran but is an ensurance
      if(wasEmpty || store.state.items.last.item1 != null){
        showItem = SwipeFeedCardState.tower();
        placeholder = Tuple2<T?, Store<SwipeFeedCardState>>(null, showItem);
        store.dispatch(SetItemsEvent<T>([...store.state.items, placeholder]));
      }
      else if(wasLast){
        // If load more is called on the last item in the list then dispatch loading state
        store.state.items[0].item2.dispatch(SetSwipeFeedCardState(SwipeCardShowState()));
      }

      // Load More Items
      Tuple2<List<T>, String?> loaded = await store.state.loader(SwipeFeedState.LENGTH_INCREASE_FACTOR, store.state.pageToken);

      // New items
      List<T> newItems = loaded.item1;

      // Old items will not be empty here and could have more then just the null value
      // This differs from the refresh function
      List<Tuple2<T?, Store<SwipeFeedCardState>>> oldItems = store.state.items;
      
      // Page token
      String? pageToken = loaded.item2;

      //If there is no next page, then has more is false
      //Has to be greater then 10 to have has more not get set to false
      if(pageToken == null || newItems.length < SwipeFeedState.LENGTH_INCREASE_FACTOR){
        store.dispatch(_SetHasMoreEvent(false));
      }

      store.dispatch(_SetPageTokenEvent(loaded.item2));

      /// Generate new items
      List<Tuple2<T, Store<SwipeFeedCardState>>> items = 
        List<Tuple2<T, Store<SwipeFeedCardState>>>.generate(
        newItems.length, (i) => Tuple2(newItems[i], SwipeFeedCardState.tower()));
      
      /// Shift add the new items to the list to ensure the null value is still present
      store.dispatch(SetItemsEvent(shiftAdd(oldItems, items)));

      if(wasLast){
        store.state.items[0].item2.dispatch(SetSwipeFeedCardState(SwipeCardShowState()));
      }

      store.dispatch(_SetLoadingEvent(false));
    }
  };
}

/// Adds a new item to the top of the list
ThunkAction<SwipeFeedState<T>> addItem<T>(T item, {Function? onComplete, bool wait = true}) {
  return (Store<SwipeFeedState<T>> store) async {
    if(store.state.items.isNotEmpty){
      store.state.items[0].item2.dispatch(SetSwipeFeedCardState(SwipeCardHideState()));
      /// Duration After Hiding
      /// This is the functional duration not the actual animation
      /// Insert HERE
      
      /// Do we still need to wait this 400 ms when on the no items card and you are adding an item
      if(store.state.items[0].item1 != null && wait){
        await Future.delayed(Duration(milliseconds: 400));
      }
    }
    List<Tuple2<T?, Store<SwipeFeedCardState>>> addNewItem = 
    [Tuple2(item, SwipeFeedCardState.tower()), ...store.state.items];
    store.dispatch(SetItemsEvent(addNewItem));

    /// Duration For showing the Card
    /// This is the functional duration not the actual animation
    /// Insert Here
    await Future.delayed(Duration(milliseconds: 400)).then((value){
      store.state.items[0].item2.dispatch(SetSwipeFeedCardState(SwipeCardShowState()));
    });
    
    if(onComplete != null){
      onComplete();
    }
  };
}

/// updates an item in the feed
ThunkAction<SwipeFeedState<T>> updateItem<T>(T item, String id, String Function(T) objectKey){
  return (Store<SwipeFeedState<T>> store) async {
    List<Tuple2<T?, Store<SwipeFeedCardState>>> items = store.state.items;
    if(items.isNotEmpty && items[0].item1 != null && id == objectKey(items[0].item1!)){
      items.remove(items[0]);
      store.dispatch(SetItemsEvent(items));
      List<Tuple2<T?, Store<SwipeFeedCardState>>> addNewItem = [Tuple2(item, SwipeFeedCardState.tower(SwipeCardShowState())), ...store.state.items];
      store.dispatch(SetItemsEvent(addNewItem));
    }
  };
}

/*
 
   _   _      _                     
  | | | | ___| |_ __   ___ _ __ ___ 
  | |_| |/ _ \ | '_ \ / _ \ '__/ __|
  |  _  |  __/ | |_) |  __/ |  \__ \
  |_| |_|\___|_| .__/ \___|_|  |___/
               |_|                  
 
*/

// Adds new Items after old items but before the null value at the end of the list
List<Tuple2<T?, Store<SwipeFeedCardState>>> shiftAdd<T>(List<Tuple2<T?, Store<SwipeFeedCardState>>> oldItems, List<Tuple2<T, Store<SwipeFeedCardState>>> newItems){
  int index = oldItems.indexWhere((element) => element.item1 == null);
  if(index == -1){
    return [Tuple2(null, SwipeFeedCardState.tower())];
  }
  else{
    oldItems.insertAll(index, newItems);
  }
  return oldItems;
}


