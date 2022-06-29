import 'package:feed/swipeFeedCard/state.dart';
import 'package:flutter_neumorphic_null_safety/flutter_neumorphic.dart';
import 'package:fort/fort.dart';
part './simulation_system_delegate.dart';

class SimulationDelegateBuilder extends StatefulWidget {
  final SimulationDelegate delegate;
  final AnimationController controller;
  const SimulationDelegateBuilder({
    Key? key,
    required this.delegate,
    required this.controller
  }) : super(key: key);

  @override
  State<SimulationDelegateBuilder> createState() => _SimulationDelegateBuilderState();
}

class _SimulationDelegateBuilderState extends State<SimulationDelegateBuilder> {
  @override
  Widget build(BuildContext context) {
    return StoreConnector<SwipeFeedCardState, bool>(
      converter: (store) => store.state.state is SwipeCardExpandState,
      builder: (context, isExpanded) {
        return AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _){
            return widget.delegate.build(context, widget.controller.value, isExpanded);
          },
        );
      }
    );
  }
}