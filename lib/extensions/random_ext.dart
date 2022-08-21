
import 'dart:math';

extension RandomExtension on Random {
  
  int nextInRange(int min, int max) {
    return nextInt(max-min)+min;
  }

  T from<T>(Iterable<T> list) {
    return list.toList()[nextInt(list.length)];
  }

}