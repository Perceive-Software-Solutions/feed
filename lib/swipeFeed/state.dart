import 'package:connectivity/connectivity.dart';
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
  static const int LENGTH_INCREASE_FACTOR = 10;
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

/// Private
class _SetItemsEvent extends SwipeFeedEvent{
  List<Tuple2<dynamic, Store<SwipeFeedCardState>>> items;
  _SetItemsEvent(this.items);
}

class _SetPageTokenEvent extends SwipeFeedEvent{
  String? pageToken;
  _SetPageTokenEvent(this.pageToken);
}

class _SetPreviousPollsEvent extends SwipeFeedEvent{
  List<dynamic>? items;
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

SwipeFeedState swipeFeedStateReducer(SwipeFeedState state, dynamic event){
  if(event is SwipeFeedEvent){
    return SwipeFeedState(
      items: setItemsReducer(state, event),
      pageToken: setPageTokenReducer(state, event),
      previousPolls: setPreviousPollsReducer(state, event),
      loading: setLoadingReducer(state, event),
      hasMore: setHasMoreReducer(state, event),
      noMoreItems: state.noMoreItems,
      connectivityError: state.connectivityError,
      loader: state.loader
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

List<Tuple2<dynamic, Store<SwipeFeedCardState>>> setItemsReducer(SwipeFeedState state, dynamic event){
  if(event is _SetItemsEvent){
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

List<dynamic>? setPreviousPollsReducer(SwipeFeedState state, dynamic event){
  if(event is _SetPreviousPollsEvent){
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
void refresh(Store<SwipeFeedState> store) async {
  bool loading = store.state.loading;
  if(!loading){

    store.dispatch(_SetLoadingEvent(true));

    // Ensure one element is present inside of the list
    final showItem = SwipeFeedCardState.tower();
    final placeholder = Tuple2(null, showItem);
    store.dispatch(_SetItemsEvent([placeholder]));

    // Show loading state
    showItem.dispatch(SetSwipeFeedCardState(SwipeCardShowState()));

    // Load more items
    Tuple2<List<dynamic>, String?> loaded = await store.state.loader(SwipeFeedState.LENGTH_INCREASE_FACTOR, null);

    // New Items Loaded
    List<dynamic> newItems = loaded.item1;

    // Old items will be empty but just a procaution
    List<Tuple2<dynamic, Store<SwipeFeedCardState>>> oldItems = store.state.items;

    String? pageToken = loaded.item2;

    //If there is no next page, then has more is false
    if(pageToken == null || newItems.length < SwipeFeedState.LENGTH_INCREASE_FACTOR){
      store.dispatch(_SetHasMoreEvent(false));
    }

    /// Generate new items
    List<Tuple2<dynamic, Store<SwipeFeedCardState>>> items = 
      List<Tuple2<dynamic, Store<SwipeFeedCardState>>>.generate(
      newItems.length, (i) => Tuple2(newItems[i], SwipeFeedCardState.tower()));

    if(oldItems[0].item1 == null){
      //No replacement occured, animate loading card into no polls card
      if(store.state.hasMore == false){
        showItem.dispatch(SwipeCardHideState(!store.state.connectivity ? store.state.connectivityError : store.state.noMoreItems));
      }
    }

    // Shift add new items into state
    final newState = shiftAdd(oldItems, items);

    store.dispatch(_SetItemsEvent(newState));
  }
}

ThunkAction<SwipeFeedState> populateInitialState(InitialFeedState state){
  return (Store<SwipeFeedState> store){

    /// Generate new items
    List<Tuple2<dynamic, Store<SwipeFeedCardState>>> items = 
      List<Tuple2<dynamic, Store<SwipeFeedCardState>>>.generate(
      state.items.length, (i) => Tuple2(state.items[i], SwipeFeedCardState.tower()));

    if(items.isEmpty){
      store.dispatch(refresh);
    }
    else{
      store.dispatch(_SetItemsEvent(items));
      store.dispatch(_SetPageTokenEvent(state.pageToken));
      store.dispatch(_SetHasMoreEvent(state.hasMore));
    }
  };
}

/// Removes a card from the list
ThunkAction<SwipeFeedState> removeItem([AdjustList? then]){
  return (Store<SwipeFeedState> store) async {
    var items = [...store.state.items];

    if(!items.isEmpty || items[0].item1 != null){
      items = [
        items[0],
        ...((then?.call(items.sublist(1))) ?? items.sublist(1))
      ];

      assert(items.isNotEmpty);

      if(items.length > 1){
        items[0] = Tuple2(items[1].item1, items[0].item2);
        items.removeAt(1);
      }

      store.dispatch(_SetItemsEvent(items));
    }

    await Future.delayed(Duration(milliseconds: 400)).then((value){
      if(store.state.items[0].item1 == null){
        store.state.items[0].item2.dispatch(
          SetSwipeFeedCardState(
            SwipeCardHideState(!store.state.connectivity ? store.state.connectivityError : store.state.noMoreItems)
          )
        );
      }
      else{
        store.state.items[0].item2.dispatch(SetSwipeFeedCardState(SwipeCardShowState()));
      }
    });
  };
}

void removeFirstItem(Store<SwipeFeedState> store){
  List<Tuple2<dynamic, Store<SwipeFeedCardState>>> items = store.state.items;
  store.dispatch(_SetItemsEvent([...items]..removeAt(0)));
  if(store.state.items.length <= SwipeFeedState.LOAD_MORE_LIMIT){
    store.dispatch(loadMore);
  }
}

// Ensures there is always a placeholder card at the end of the list
// Loads More items
void loadMore(Store<SwipeFeedState> store) async {
  // Ensure not loading
  if(!store.state.loading || store.state.hasMore){

    // Loading
    store.dispatch(_SetLoadingEvent(true));

    // Add PlaceHolder Card at the end of the list
    bool wasEmpty = store.state.items.isEmpty;
    Tower<SwipeFeedCardState>? showItem;
    var placeholder;
    if(wasEmpty || store.state.items.last.item1 != null){
      showItem = SwipeFeedCardState.tower();
      placeholder = Tuple2<dynamic, Store<SwipeFeedCardState>>(null, showItem);
      store.dispatch(_SetItemsEvent([...store.state.items, placeholder]));
    }

    // Load More Items
    Tuple2<List<dynamic>, String?> loaded = await store.state.loader(SwipeFeedState.LENGTH_INCREASE_FACTOR, store.state.pageToken);

    List<dynamic> newItems = loaded.item1;
    List<Tuple2<dynamic, Store<SwipeFeedCardState>>> oldItems = store.state.items;

    store.dispatch(_SetPageTokenEvent(loaded.item2));

    /// Generate new items
    List<Tuple2<dynamic, Store<SwipeFeedCardState>>> items = 
      List<Tuple2<dynamic, Store<SwipeFeedCardState>>>.generate(
      newItems.length, (i) => Tuple2(newItems[i], SwipeFeedCardState.tower()));

    if(store.state.items.isEmpty && wasEmpty && showItem != null){
      /// Dispatch hidden state
      showItem.dispatch(SetSwipeFeedCardState(SwipeCardHideState(!store.state.connectivity ? store.state.connectivityError : store.state.noMoreItems)));
    }

    store.dispatch(_SetItemsEvent(shiftAdd(oldItems, items)));
    store.dispatch(_SetLoadingEvent(false));
  }
}

/// Adds a new item to the top of the list
ThunkAction<SwipeFeedState> addItem(dynamic item) {
  return (Store<SwipeFeedState> store) async {
    if(store.state.items.isNotEmpty){
      store.state.items[0].item2.dispatch(SetSwipeFeedCardState(SwipeCardHideState()));
    }
    List<Tuple2<dynamic, Store<SwipeFeedCardState>>> addNewItem = 
    [Tuple2(item, SwipeFeedCardState.tower()), ...store.state.items];
    store.dispatch(_SetItemsEvent(addNewItem));
  };
}

/// updates an item in the feed
ThunkAction<SwipeFeedState> updateItem(dynamic item, String id){
  return (Store<SwipeFeedState> store) async {
    List<Tuple2<dynamic, Store<SwipeFeedCardState>>> items = store.state.items;
    if(items.isNotEmpty && items[0].item1 != null){
      items.remove(items[0]);
      store.dispatch(_SetItemsEvent(items));
      store.dispatch(addItem(item));
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
List<Tuple2<dynamic, Store<SwipeFeedCardState>>> shiftAdd(List<Tuple2<dynamic, Store<SwipeFeedCardState>>> oldItems, List<Tuple2<dynamic, Store<SwipeFeedCardState>>> newItems){
  int index = oldItems.indexWhere((element) => element.item1 == null);
  if(index == -1){
    return [Tuple2(null, SwipeFeedCardState.tower())];
  }
  else{
    oldItems.insertAll(index, newItems);
  }
  return oldItems;
}


