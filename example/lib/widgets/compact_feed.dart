import 'package:feed/feeds/compact_feed.dart';
import 'package:feed/widgets/horizontal_bar.dart';
import 'package:flutter/material.dart';

class CompactFeedExample extends StatefulWidget {
  const CompactFeedExample({ Key? key }) : super(key: key);

  @override
  _CompactFeedExampleState createState() => _CompactFeedExampleState();
}

class _CompactFeedExampleState extends State<CompactFeedExample> {

  PagedCompactListController<List<int>> controller = PagedCompactListController();

  var list = ['Title1', 'Title2', 'Title3', 'Title4', 'Title5', 'Title6'];

  @override
  void initState(){
    super.initState();
  }

  Widget _buildTile(BuildContext context, int num){
    return SizedBox(
      height: 50,
      child: Text(num.toString(), style: const TextStyle(fontSize: 16)),
    );
  }

  Widget buildButton<T>(BuildContext context){

    return Column(
      children: [
        SizedBox(
          child: HorizontalBar(
            width: 0.5,
            color: Colors.grey.withOpacity(0.25),
          ),
        ),

        ///Load More Button if `[loading] == false`. 
        ///Loading indicator `[loading] == true`. 
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Load More', style: TextStyle(fontSize: 12, color: Colors.grey.withOpacity(0.3))),
            ],
          ),
        ),
      ]
    );
  }

  ///Builds a list of [PagedCompactList] inside a [Column]. for displaying the numbers
  Widget _buildTiles(BuildContext context){

    //List of slivers to be outputted when built
    List<Widget> children = [];

    ///Creates a [PagedCompactList] for each num contained in list
    for (String title in list) {

      ///Creates a [PagedCompactList] widget relative to the categories
      Widget pagedSliverList = PagedCompactList<List<int>>(
        key: Key('pagedcompactlist-$title'),
        title: title,
        controller: controller,
        loader: (size) async {
          return List.filled(size, List.generate(10, (i) => i + size));
        },
        builder: (context, index, item) {
          return _buildTile(context, index);
        },
        child: buildButton(context)
      );

      ///adds the [PagedCompactList] to the list
      children.add(pagedSliverList);
    }

    //returns the sliver list
    return Column(children: children);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 32, right: 34),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.grey),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    const Text('Compact Feed', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                    const Spacer()
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 32, bottom: 32),
                child: Text('Asynchronous list that loads depending on position of list', textAlign: TextAlign.center),
              ),
            ),
            SliverToBoxAdapter(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {

                  //Applies a slide transition from below
                  return SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(animation),
                    child: child,
                  );
                },
                child: _buildTiles(context),
              ),
            ),
          ]
        ),
      )
    );
  }
}