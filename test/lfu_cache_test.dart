import 'package:lfu_cache/lfu_cache.dart';
import 'package:test/test.dart';

void main() {
  test('drop first inserted element', () {
    final cache = LFUCache(2, 1);

    cache.put(1, true);
    cache.put(2, true);
    cache.put(3, true);

    expect(cache.get(1), isNull);
    expect(cache.get(2), isNotNull);
    expect(cache.get(3), isNotNull);
  });

  test('eviction count', () {
    final cache = LFUCache(2, 2);

    cache.put(1, true);
    cache.put(2, true);
    cache.put(3, true);

    expect(cache.get(1), isNull);
    expect(cache.get(2), isNull);
    expect(cache.get(3), isNotNull);
  });

  test('consider access count', () {
    final cache = LFUCache<int, bool>(4, 2);

    cache.put(1, true);
    cache.put(2, true);
    cache.put(3, true);
    cache.put(4, true);

    //Do not optimize gets away
    final nonOptimize = [
      cache.get(1),
      cache.get(1),
      cache.get(3),
    ];

    cache.put(5, true);

    expect(nonOptimize.length, 3);

    expect(cache.get(1), isNotNull);
    expect(cache.get(2), isNull);
    expect(cache.get(3), isNotNull);
    expect(cache.get(4), isNull);
    expect(cache.get(5), isNotNull);
  });

  test('keep access count', () {
    final cache = LFUCache<int, bool>(3, 1);
    cache.put(1, true);
    cache.put(2, true);
    cache.put(3, true);
    final val = cache.get(1);
    cache.put(4, true);
    cache.put(5, true);

    expect(val, isTrue);
    expect(cache.get(1), isNotNull);
  });

  test('getOrPut', () {
    final cache = LFUCache<int, bool>(3, 1);

    var count = 0;
    final first = cache.getOrPut(1, () {
      count++;
      return true;
    });
    final second = cache.getOrPut(1, () {
      count++;
      return true;
    });

    expect(first, equals(second));
    expect(count, 1);
  });

  test('getOrPutAsync', () async {
    final cache = LFUCache<int, bool>(3, 1);

    var count = 0;
    final first = await cache.getOrPutAsync(1, () {
      return Future.delayed(Duration(milliseconds: 50)).then((_) {
        count++;
        return true;
      });
    });

    final second = await cache.getOrPutAsync(1, () {
      return Future.delayed(Duration(milliseconds: 50)).then((_) {
        count++;
        return true;
      });
    });

    expect(first, equals(second));
    expect(count, 1);
  });
}
