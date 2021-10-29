import 'package:flutter_bloc/flutter_bloc.dart';

///General Typed concrete cubit
class ConcreteCubit<T> extends Cubit<T>{
  ConcreteCubit(T initialState) : super(initialState);
}