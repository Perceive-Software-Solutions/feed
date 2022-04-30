
import 'package:feed/feed.dart';
import 'package:feed/util/global/functions.dart';
import 'package:flutter/material.dart';
import 'package:perceive_slidable/sliding_sheet.dart';

/// Creates a singular feed within a sliding sheet
class SlidingSheetFeed extends StatelessWidget {

  // Proxy Feed variables

  final double? footerHeight;

  final FeedLoader loader;

  final FeedController? controller;

  final int? lengthFactor;

  final int? initialLength;

  final FeedBuilder? childBuilder;

  ///Determines if the the feed should initially load, defaulted to true
  final bool initiallyLoad;

  ///Disables the scroll controller when set to true
  final bool? disableScroll;

  /// Loading state placeholders
  final Widget Function(BuildContext context, double extent)? placeholder;

  /// Loading widget
  final Widget? loading;

  ///Retrieves the item id, used to ensure the prevention of duplicate additions
  final RetrievalFunction? getItemID;

  ///The optional function used to wrap the list view
  final WidgetWrapper? wrapper;

  /// Items that will be pinned to the top of the list on init
  final List<dynamic>? pinnedItems;

  // Proxy sliding sheet variables
  
  ///Controller for the sheet
  final PerceiveSlidableController? sheetController;

  ///If the sheet should be static or not
  final bool staticSheet;

  // Colors
  /// The background color for the sliding sheet
  final Color? backgroundColor;
  /// The color behind the sliding sheet
  final Color? minBackdropColor;

  // Sheet Extents
  /// Starting extent, and the middle resting extent of the sliding sheet
  final double initialExtent;
  /// The max extent of the sliding sheet
  final double expandedExtent;
  /// The lowest possible extent for the sliding sheet
  final double minExtent;

  /// The header for the initial delegate
  final Widget Function(BuildContext context, dynamic pageObj, Widget spacer, double borderRadius)? headerBuilder;
  /// The persistent footer on the sliding sheet
  final Widget Function(BuildContext context, SheetState, dynamic pageObject)? footerBuilder;

  /// Listeners
  final Function(double extent)? extentListener;

  // Editors
  final bool isBackgroundIntractable;
  final bool closeOnBackdropTap;
  final bool doesPop;

  // Sliding sheet delegate
  final double staticScrollModifier;

  const SlidingSheetFeed({ 
    Key? key,
    required this.loader,
    this.controller,
    this.footerHeight,
    this.lengthFactor,
    this.initialLength,
    this.childBuilder,
    this.initiallyLoad = true,
    this.disableScroll,
    this.placeholder,
    this.loading,
    this.getItemID,
    this.wrapper,
    this.pinnedItems,
    this.sheetController,
    this.staticSheet = false,
    this.backgroundColor,
    this.minBackdropColor,
    this.initialExtent = 0.4,
    this.expandedExtent = 1.0,
    this.minExtent = 0.0,
    this.headerBuilder,
    this.footerBuilder,
    this.extentListener,
    this.isBackgroundIntractable = false,
    this.closeOnBackdropTap = true,
    this.doesPop = true,
    this.staticScrollModifier = 0.0
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PerceiveSlidable(
      controller: sheetController,
      staticSheet: staticSheet,
      backgroundColor: backgroundColor,
      minBackdropColor: minBackdropColor,
      initialExtent: initialExtent,
      expandedExtent: expandedExtent,
      mediumExtent: initialExtent,
      minExtent: minExtent,
      footerBuilder: footerBuilder,
      extentListener: extentListener,
      isBackgroundIntractable: isBackgroundIntractable,
      closeOnBackdropTap: closeOnBackdropTap,
      doesPop: doesPop,
      delegate: PerceiveSlidableSingleFeedDelegate(
        loader: loader,
        controller: controller,
        footerHeight: footerHeight,
        lengthFactor: lengthFactor,
        initialLength: initialLength,
        childBuilder: childBuilder,
        initiallyLoad: initiallyLoad,
        disableScroll: disableScroll,
        placeholder: placeholder,
        loading: loading,
        getItemID: getItemID,
        wrapper: wrapper,
        pinnedItems: pinnedItems,
        header: headerBuilder,
        staticScrollModifier: staticScrollModifier
      ),
    );
  }
}

class PerceiveSlidableSingleFeedDelegate extends ScrollablePerceiveSlidableDelegate{

  
  final double? footerHeight;

  final FeedLoader loader;

  final FeedController? controller;

  final int? lengthFactor;

  final int? initialLength;

  final FeedBuilder? childBuilder;

  ///Determines if the the feed should initially load, defaulted to true
  final bool initiallyLoad;

  ///Disables the scroll controller when set to true
  final bool? disableScroll;

  /// Loading state placeholders
  final Widget Function(BuildContext context, double extent)? placeholder;

  /// Loading widget
  final Widget? loading;

  ///Retrieves the item id, used to ensure the prevention of duplicate additions
  final RetrievalFunction? getItemID;

  ///The optional function used to wrap the list view
  final WidgetWrapper? wrapper;

  /// Items that will be pinned to the top of the list on init
  final List<dynamic>? pinnedItems;

  final Widget Function(BuildContext context, dynamic pageObj, Widget spacer, double borderRadius)? header;

  PerceiveSlidableSingleFeedDelegate({
    required this.loader,
    required this.controller,
    required this.footerHeight,
    required this.lengthFactor,
    required this.initialLength,
    required this.childBuilder,
    required this.initiallyLoad,
    required this.disableScroll,
    required this.placeholder,
    required this.loading,
    required this.getItemID,
    required this.wrapper,
    required this.pinnedItems,
    required this.header,
    double staticScrollModifier = 0.0
  }) : super(pageCount: 1, staticScrollModifier: staticScrollModifier);

  @override
  Widget headerBuilder(BuildContext context, pageObj, Widget spacer, double borderRadius) {
    return header?.call(context, pageObj, spacer, borderRadius) ?? Container();
  }

  @override
  Widget scrollingBodyBuilder(BuildContext context, SheetState? state, ScrollController scrollController, int pageIndex, bool scrollLock, double footerHeight) {
    return Feed(
      compact: false,
      footerHeight: (this.footerHeight ?? 0) + footerHeight,
      scrollController: scrollController,
      loader: loader,
      controller: controller,
      lengthFactor: lengthFactor,
      initialLength: initialLength,
      childBuilder: childBuilder,
      initiallyLoad: initiallyLoad,
      disableScroll: (disableScroll ?? false) || scrollLock,
      placeholder: placeholder?.call(context, state?.extent ?? initialExtent),
      loading: loading,
      getItemID: getItemID,
      wrapper: wrapper,
      pinnedItems: pinnedItems,
    );
  }

}