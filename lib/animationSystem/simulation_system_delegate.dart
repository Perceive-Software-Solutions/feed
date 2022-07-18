part of './simulation_system_delegate_builder.dart';

abstract class SimulationDelegate {
  SimulationDelegate();
  Widget build(BuildContext context, double value, bool isExpanded);
}