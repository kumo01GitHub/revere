/// Holds a limited-length state history for any data type.
class StateTransport<T> {
  final List<T> _state = [];
  final int maxLength;

  StateTransport({this.maxLength = 100});

  void add(T data) {
    _state.add(data);
    if (_state.length > maxLength) {
      _state.removeAt(0);
    }
  }

  List<T> get state => List.unmodifiable(_state);
}
