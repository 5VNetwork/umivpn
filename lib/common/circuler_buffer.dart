
/// Keeps a buffer of the last [maxSize] elements.
class CircularBuffer<T> extends Iterable<T> {
  final int _maxSize;
  final List<T?> _buffer;
  int _start = 0;
  int _count = 0;

  CircularBuffer({int maxSize = 100, List<T>? initialList})
      : _maxSize = maxSize,
        _buffer = List<T?>.filled(maxSize, null) {
    if (initialList != null) {
      _buffer.setAll(0, initialList);
      _count = initialList.length;
    }
  }

  /// Add an element to the buffer.
  /// If the buffer is full, the oldest element will be replaced.
  void add(T element) {
    if (_count < _maxSize) {
      // Buffer not full yet, add at end
      _buffer[_count] = element;
      _count++;
    } else {
      // Buffer full, replace oldest element
      _buffer[_start] = element;
      _start = (_start + 1) % _maxSize;
    }
  }

  @override
  Iterator<T> get iterator => _CircularBufferIterator(this);

  @override
  int get length => _count;

  T? operator [](int index) {
    if (index < 0 || index >= _count) return null;
    return _buffer[(_start + index) % _maxSize];
  }

  void operator []=(int index, T value) {
    if (index < 0 || index >= _count) return;
    _buffer[(_start + index) % _maxSize] = value;
  }

  @override
  T get first {
    if (_count == 0) throw StateError('No elements');
    return _buffer[_start]!;
  }

  void clear() {
    _start = 0;
    _count = 0;
    _buffer.fillRange(0, _maxSize, null);
  }

  /// Returns the index of the last occurrence of [element] in the buffer.
  /// If the element is not found, returns -1.
  int indexOfBackwards(T element) {
    for (int i = _count - 1; i >= 0; i--) {
      if (_buffer[(_start + i) % _maxSize] == element) return i;
    }
    return -1;
  }

   int indexOfBackwardsFunction(bool Function(T) test) {
    for (int i = _count - 1; i >= 0; i--) {
      final e = _buffer[(_start + i) % _maxSize];
      if (e != null && test(e)) return i;
    }
    return -1;
  }
}

class _CircularBufferIterator<T> implements Iterator<T> {
  final CircularBuffer<T> _buffer;
  int _currentIndex = -1;

  _CircularBufferIterator(this._buffer);

  @override
  T get current => _buffer[_currentIndex] as T;

  @override
  bool moveNext() {
    if (_currentIndex + 1 >= _buffer.length) return false;
    _currentIndex++;
    return true;
  }
}
