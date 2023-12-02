import 'package:lfu_cache/lfu_cache.dart';

void main() {
  final cache = LFUCache(2, 1);

  cache.put(1, true);
  cache.put(2, true);
  cache.put(3, true);

  print(cache.get(1));
}
