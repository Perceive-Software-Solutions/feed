import 'package:flutter/material.dart';
import 'package:feed/feeds/simple_multi_feed.dart';
import 'package:tuple/tuple.dart';


class MultiFeed extends StatefulWidget {
  const MultiFeed({ Key? key }) : super(key: key);

  @override
  _MultiFeedState createState() => _MultiFeedState();
}

class _MultiFeedState extends State<MultiFeed> with TickerProviderStateMixin{

  ///Controller for the multifeed
  late SimpleMultiFeedController feedController;

  @override
  void initState() {
    super.initState();

    //Initialize the feed controller
    feedController = SimpleMultiFeedController(
      pageCount: 3,
      initialPage: 1,
      keepPage: true,
      vsync: this
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16),
        child: SimpleMultiFeed(
          controller: feedController,
          headerBuilder: (context, i){
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 32, right: 30),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.grey),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                      const Text('Multi-Feed', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                      const Spacer()
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 32, bottom: 32),
                  child: Text('Asynchronous list that loads depending on position of list', textAlign: TextAlign.center),
                ),
              ],
            );
          },
          //Loaders defined to retreive data for each index in the feed
          loaders: List.filled(3, (int size, [String? token]) async {
            int index = int.parse(token ?? '0');
            return Tuple2(List.generate(size, (i) => i + index), (index + size).toString());
          }),
            //item builder for each element of the feed dependant on the data from ther loaders
          childBuilder: (item, isLast) {

            var list = ['2', '59', '60', '61', '63', '64'];

            return Padding(
              padding: const EdgeInsets.only(left: 16, right: 16),
              child: Column(
                children: [
                  Container(
                    height: 1,
                    color: Colors.grey.withOpacity(0.2),
                  ),
                  Container(
                    height: 75,
                    child: Center(
                      child: Text(list[item % 6], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      )
    );
  }
}