import 'package:lfu_cache/lfu_cache.dart';

void main() {
  const maxCacheSize = 2;
  const evictionCount = 1;

  final cache = LFUCache(maxCacheSize, evictionCount);

  cache.put(1, true);
  cache.put(2, true);
  cache.put(3, true);

  print(cache.get(1));
}
