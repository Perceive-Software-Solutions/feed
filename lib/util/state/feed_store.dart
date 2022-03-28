
/*
 
   ____  _        _       
  / ___|| |_ __ _| |_ ___ 
  \___ \| __/ _` | __/ _ \
   ___) | || (_| | ||  __/
  |____/ \__\__,_|\__\___|
                          
 
*/

import 'package:feed/util/global/functions.dart';
import 'package:feed/util/state/feed_state.dart';
import 'package:fort/fort.dart';

class FeedState extends FortState<FeedState>{

  /// If the feed is currently loading items in
  final bool loading;

  /// The amount of items displayed
  final int size;

  /// The items cached to be displayed
  final List<dynamic> pendingItems;

  /// The displayed list of items
  final List<dynamic> items;

  /// Whether the feed has more items to load in
  final bool hasMore;

  /// The token for the next list of items
  final String? token;

  /// The items that were manually added in
  final Map<String, bool> addedItems;

  FeedState({
    required this.loading, 
    required this.size, 
    required this.pendingItems, 
    required this.items, 
    required this.hasMore, 
    required this.token, 
    required this.addedItems
  });

  factory FeedState.initial([InitialFeedState? state]) => FeedState(
    loading: false, 
    size: 0, 
    pendingItems: [], 
    items: state?.items ?? [], 
    hasMore: state?.hasMore ?? true, 
    token: state?.pageToken ?? null, 
    addedItems: {} 
  );

  static Tower<FeedState> get tower => Tower<FeedState>(
    _feedReducer,
    initialState: FeedState.initial()
  );

  @override
  FortState<FeedState> copyWith(FortState<FeedState> other) {
    // TODO: implement copyWith
    throw UnimplementedError();
  }

  @override
  toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }

}

/*
 
   _____                 _       
  | ____|_   _____ _ __ | |_ ___ 
  |  _| \ \ / / _ \ '_ \| __/ __|
  | |___ \ V /  __/ | | | |_\__ \
  |_____| \_/ \___|_| |_|\__|___/
                                 
 
*/

abstract class _FeedEvent{}

/// Resets the state
class ClearFeedStateEvent extends _FeedEvent{
  final InitialFeedState? initialState;

  ClearFeedStateEvent([this.initialState]);
}

/// Sets the loading state for the feed
class SetFeedLoadingState extends _FeedEvent{
  final bool loading;

  SetFeedLoadingState(this.loading);
}

/// Sets the hasMore state for the feed
class SetFeedHasMoreState extends _FeedEvent{
  final bool hasMore;

  SetFeedHasMoreState(this.hasMore);
}

/// Sets the token state for the feed
class SetFeedTokenState extends _FeedEvent{
  final String? token;

  SetFeedTokenState(this.token);
}

/// Adds an item to the feed
class AddFeedItemEvent extends _FeedEvent{

  /// The item to be added
  final dynamic item;

  /// Whether to add the item to the front, defaulted to the end
  final bool inFront;

  /// Whether to clear all the other items, defaulted to false
  final bool clear;

  AddFeedItemEvent(this.item, {this.inFront = false, this.clear = false});
}

/// Sets the items int the feed
class _SetFeedItemsEvent extends _FeedEvent{

  /// The items to set
  final List items;

  _SetFeedItemsEvent(this.items);
}

/// Sets the pending items int the feed
class SetPendingFeedItemsEvent extends _FeedEvent{

  /// The items to set
  final List items;

  SetPendingFeedItemsEvent(this.items);
}

class UpdateAddedItemsEvent extends _FeedEvent {

  /// The item key
  final String itemKey;

  UpdateAddedItemsEvent(this.itemKey);
}

/*
 
      _        _   _                 
     / \   ___| |_(_) ___  _ __  ___ 
    / _ \ / __| __| |/ _ \| '_ \/ __|
   / ___ \ (__| |_| | (_) | | | \__ \
  /_/   \_\___|\__|_|\___/|_| |_|___/
                                     
 
*/

/// Removes an item from the feed
ThunkAction<FeedState> removeFeedItemAction(String item, {RetrievalFunction? retrievalFunction}){
  return (Store<FeedState> store) async {
    List items = [...store.state.items];
    items.removeWhere((element) => (retrievalFunction != null ? retrievalFunction(element) : element) == item);
    store.dispatch(_SetFeedItemsEvent(items));
  };
}

/*
 
   ____          _                     
  |  _ \ ___  __| |_   _  ___ ___ _ __ 
  | |_) / _ \/ _` | | | |/ __/ _ \ '__|
  |  _ <  __/ (_| | |_| | (_|  __/ |   
  |_| \_\___|\__,_|\__,_|\___\___|_|   
                                       
 
*/

FeedState _feedReducer(FeedState state, dynamic event){
  if(event is _FeedEvent){
    
    if(event is ClearFeedStateEvent){
      return FeedState.initial(event.initialState);
    }

    return FeedState(
      loading: _loadingStateReducer(state, event),
      size: _sizeStateReducer(state, event),
      pendingItems: _pendingItemStateReducer(state, event),
      items: _itemStateReducer(state, event),
      hasMore: _hasMoreStateReducer(state, event),
      token: _tokenStateReducer(state, event),
      addedItems: _addedItemStateReducer(state, event),
    );
  }
  return state;
}

/*
 
   ____        _                    _                     
  / ___| _   _| |__    _ __ ___  __| |_   _  ___ ___ _ __ 
  \___ \| | | | '_ \  | '__/ _ \/ _` | | | |/ __/ _ \ '__|
   ___) | |_| | |_) | | | |  __/ (_| | |_| | (_|  __/ |   
  |____/ \__,_|_.__/  |_|  \___|\__,_|\__,_|\___\___|_|   
                                                          
 
*/

bool _loadingStateReducer(FeedState state, _FeedEvent event){
  if(event is SetFeedLoadingState){
    return event.loading;
  }
  return state.loading;
}

int _sizeStateReducer(FeedState state, _FeedEvent event){
  if(event is AddFeedItemEvent){
    if(event.clear){
      return 1;
    }
    return state.size + 1;
  }
  else if(event is _SetFeedItemsEvent){
    return event.items.length;
  }
  return state.size;
}

List<dynamic> _pendingItemStateReducer(FeedState state, _FeedEvent event){
  if(event is SetPendingFeedItemsEvent){
    return [...event.items];
  }
  return state.pendingItems;
}

List<dynamic> _itemStateReducer(FeedState state, _FeedEvent event){
  if(event is AddFeedItemEvent){
    if(event.clear){
      // Clear items
      return [event.item];
    }
    else if(event.inFront){
      // Add item in front
      return [event.item, ...state.items];
    }
    // Add item to the end
    return [...state.items, event.item];
  }
  else if(event is _SetFeedItemsEvent){
    return [...event.items];
  }
  return state.items;
}

bool _hasMoreStateReducer(FeedState state, _FeedEvent event){
  if(event is SetFeedHasMoreState){
    return event.hasMore;
  }
  return state.hasMore;
}

String? _tokenStateReducer(FeedState state, _FeedEvent event){
  if(event is SetFeedTokenState){
    return event.token;
  }
  return state.token;
}

Map<String, bool> _addedItemStateReducer(FeedState state, _FeedEvent event){
  if(event is UpdateAddedItemsEvent){
    final items = {...state.addedItems};
    items[event.itemKey] = true;
    return items;
  }
  return state.addedItems;
}