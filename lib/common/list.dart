List<T> stableMoveToFront<T>(List<T> list, bool Function(T) condition) {
  final result = <T>[];
  final deferred = <T>[];
  
  for (final item in list) {
    if (condition(item)) {
      result.add(item);
    } else {
      deferred.add(item);
    }
  }
  
  result.addAll(deferred);
  return result;
}