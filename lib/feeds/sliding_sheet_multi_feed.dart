
import 'package:feed/feed.dart';
import 'package:feed/util/global/functions.dart';
import 'package:flutter/material.dart';
import 'package:perceive_slidable/sliding_sheet.dart';
import 'package:tuple/tuple.dart';

/// Creates a singular feed within a sliding sheet
class SlidingSheetMultiFeed extends StatelessWidget {

  // used to define a custom multi feed delegate
  final PerceiveSlidableMultiFeedDelegate delegate;

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
  /// Starting extent and the middle resting extent of the sliding sheet
  final double initialExtent;
  /// The max extent of the sliding sheet
  final double expandedExtent;
  /// The lowest possible extent for the sliding sheet
  final double minExtent;

  /// The persistent footer on the sliding sheet
  final Widget Function(BuildContext context, SheetState, dynamic pageObject)? footerBuilder;

  /// Listeners
  final Function(double extent)? extentListener;

  // Editors
  final bool isBackgroundIntractable;
  final bool closeOnBackdropTap;
  final bool doesPop;

  const SlidingSheetMultiFeed._({ 
    Key? key,
    required this.delegate,
    this.sheetController,
    this.staticSheet = false,
    this.backgroundColor,
    this.minBackdropColor,
    this.initialExtent = 0.4,
    this.expandedExtent = 1.0,
    this.minExtent = 0.0,
    this.footerBuilder,
    this.extentListener,
    this.isBackgroundIntractable = false,
    this.closeOnBackdropTap = true,
    this.doesPop = true,
  }) : super(key: key);

  factory SlidingSheetMultiFeed({
    required List<FeedLoader> loaders,
    required MultiFeedController controller,
    required MultiFeedBuilder childBuilder,
    double? footerHeight,
    int? lengthFactor,
    int? initialLength,
    bool initiallyLoad = true,
    bool? disableScroll,
    Widget Function(double extent, int index)? placeholders,
    Widget? loading,
    RetrievalFunction? getItemID,
    IndexWidgetWrapper? wrapper,
    final Widget? Function(BuildContext context, int pageIndex)? feedHeader,
    final Widget? Function(BuildContext context, int pageIndex)? feedFooter,
    List<Tuple2<dynamic, int>>? pinnedItems,
    Widget Function(BuildContext context, dynamic pageObj, Widget spacer, double borderRadius)? headerBuilder,
    PerceiveSlidableController? sheetController,
    bool staticSheet = false,
    Color? backgroundColor,
    Color? minBackdropColor,
    double initialExtent = 0.4,
    double expandedExtent = 1.0,
    double minExtent = 0.0,
    Widget Function(BuildContext context, SheetState, dynamic pageObject)? footerBuilder,
    Function(double extent)? extentListener,
    bool isBackgroundIntractable = false,
    bool closeOnBackdropTap = true,
    bool doesPop = true,
    double staticScrollModifier = 0.0
  }) => SlidingSheetMultiFeed._(
    delegate: PerceiveSlidableMultiFeedDelegate(
      loaders: loaders,
      controller: controller,
      footerHeight: footerHeight,
      lengthFactor: lengthFactor,
      initialLength: initialLength,
      childBuilder: childBuilder,
      initiallyLoad: initiallyLoad,
      disableScroll: disableScroll,
      placeholders: placeholders,
      loading: loading,
      getItemID: getItemID,
      feedHeader: feedHeader,
      feedFooter: feedFooter,
      pinnedItems: pinnedItems,
      header: headerBuilder,
      staticScrollModifier: staticScrollModifier
    ),
    sheetController: sheetController,
    staticSheet: staticSheet,
    backgroundColor: backgroundColor,
    minBackdropColor: minBackdropColor,
    initialExtent: initialExtent,
    expandedExtent: expandedExtent,
    minExtent: minExtent,
    footerBuilder: footerBuilder,
    extentListener: extentListener,
    isBackgroundIntractable: isBackgroundIntractable,
    closeOnBackdropTap: closeOnBackdropTap,
    doesPop: doesPop,
  );

  factory SlidingSheetMultiFeed.delegate({
    required PerceiveSlidableMultiFeedDelegate delegate,
    PerceiveSlidableController? sheetController,
    bool staticSheet = false,
    Color? backgroundColor,
    Color? minBackdropColor,
    double initialExtent = 0.4,
    double expandedExtent = 1.0,
    double minExtent = 0.0,
    Widget Function(BuildContext context, SheetState, dynamic pageObject)? footerBuilder,
    Function(double extent)? extentListener,
    bool isBackgroundIntractable = false,
    bool closeOnBackdropTap = true,
    bool doesPop = true,
  }) => SlidingSheetMultiFeed._(
    delegate: delegate,
    sheetController: sheetController,
    staticSheet: staticSheet,
    backgroundColor: backgroundColor,
    minBackdropColor: minBackdropColor,
    initialExtent: initialExtent,
    expandedExtent: expandedExtent,
    minExtent: minExtent,
    footerBuilder: footerBuilder,
    extentListener: extentListener,
    isBackgroundIntractable: isBackgroundIntractable,
    closeOnBackdropTap: closeOnBackdropTap,
    doesPop: doesPop,
  );

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
      delegate: delegate,
    );
  }
}

class PerceiveSlidableMultiFeedDelegate extends ScrollablePerceiveSlidableDelegate{

  final double? footerHeight;

  final List<FeedLoader> loaders;

  final MultiFeedController controller;

  final int? lengthFactor;

  final int? initialLength;

  final MultiFeedBuilder? childBuilder;

  ///Determines if the the feed should initially load, defaulted to true
  final bool initiallyLoad;

  ///Disables the scroll controller when set to true
  final bool? disableScroll;

  /// Loading state placeholders
  final Widget Function(double extent, int index)? placeholders;

  /// Loading widget
  final Widget? loading;

  ///Retrieves the item id, used to ensure the prevention of duplicate additions
  final RetrievalFunction? getItemID;

  ///The optional function used to wrap the list view
  final Widget? Function(BuildContext context, int pageIndex)? feedHeader;

  ///The optional function used to wrap the list view
  final Widget? Function(BuildContext context, int pageIndex)? feedFooter;

  /// Items that will be pinned to the top of the list on init
  final List<Tuple2<dynamic, int>>? pinnedItems;

  final Widget Function(BuildContext context, dynamic pageObj, Widget spacer, double borderRadius)? header;

  PerceiveSlidableMultiFeedDelegate({
    required this.loaders,
    required this.controller,
    required this.footerHeight,
    required this.lengthFactor,
    required this.initialLength,
    required this.childBuilder,
    required this.initiallyLoad,
    required this.disableScroll,
    required this.placeholders,
    required this.loading,
    required this.getItemID,
    required this.feedHeader,
    required this.feedFooter,
    required this.pinnedItems,
    required this.header,
    int? initialPage,
    dynamic delegateObject,
    double staticScrollModifier = 0.0
  }) : super(pageCount: loaders.length, initialPage: initialPage ?? ((loaders.length - 1)/2).ceil(), delegateObject: delegateObject, staticScrollModifier: staticScrollModifier);

  Widget? feedHeaderBuilder(BuildContext context, int pageIndex){
    return feedHeader?.call(context, pageIndex);
  }

  Widget? feedFooterBuilder(BuildContext context, int pageIndex){
    return feedFooter?.call(context, pageIndex);
  }

  Widget? placeholderBuilder(BuildContext context, double extent, int pageIndex){
    return placeholders?.call(extent, pageIndex);
  }

  Widget itemBuilder(dynamic item, int pageIndex, bool isLast){
    return childBuilder?.call(item, pageIndex, isLast) ?? Container();
  }

  Widget? loadingBuilder(BuildContext context, int pageIndex){
    return loading;
  }

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
      loader: loaders[pageIndex],
      controller: controller.controllerAt(pageIndex),
      lengthFactor: lengthFactor,
      initialLength: initialLength,
      childBuilder: (item, isLast) => itemBuilder(item, pageIndex, isLast),
      initiallyLoad: initiallyLoad,
      disableScroll: (disableScroll ?? false) || scrollLock,
      placeholder: placeholderBuilder(context, state?.extent ?? initialExtent, pageIndex),
      loading: loadingBuilder.call(context, pageIndex),
      getItemID: getItemID,
      header: feedHeaderBuilder(context, pageIndex),
      footer: feedFooterBuilder(context, pageIndex),
      pinnedItems: pinnedItems?.where((e) => e.item2 == pageIndex).toList(),
    );
  }

}

class MultiFeedController {

  final int pageCount;
  final List<FeedController> _controllers;

  MultiFeedController({required this.pageCount, FeedGridViewDelegate? Function(int index)? gridDelegatesAtIndex}) : this._controllers = List.generate(pageCount, (index) => FeedController(
    gridDelegate: gridDelegatesAtIndex?.call(index) ?? null
  ));

  void removeItem(String item, {RetrievalFunction? retrievalFunction}) {
    for (var i = 0; i < pageCount; i++) {
      try{
        controllerAt(i).removeItem(item, retrievalFunction: retrievalFunction);
      }catch(e){}
    }
  }

  FeedController controllerAt(int index) => _controllers[index];
  
  bool isBinded(int index) => _controllers[index].isBinded();
}