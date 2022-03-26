
///A class that contains the state of a single feed
class InitialFeedState<T> {

  final List<dynamic> items;
  final String? pageToken;
  final bool hasMore;

  InitialFeedState({
    this.items = const [], 
    this.pageToken = null, 
    this.hasMore = false
  });

}