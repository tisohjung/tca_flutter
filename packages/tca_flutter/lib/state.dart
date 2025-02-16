import 'package:equatable/equatable.dart';

/// Base class for all TCA states
abstract class TCAState extends Equatable {
  /// We want the State to be mutable.
  // ignore: prefer_const_constructors_in_immutables
  TCAState();

  /// Creates a copy of this state with the given fields replaced with new values.
  TCAState copyWith();

  @override
  bool? get stringify => true;
}
