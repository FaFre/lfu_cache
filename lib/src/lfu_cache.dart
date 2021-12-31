import 'dart:collection';

import 'dart:math';

class _CacheNode<K, V> {
  final K key;
  V value;
  int frequency;

  _CacheNode(this.key, this.value, this.frequency);
}

/// LFU cache implementation based on http://dhruvbird.com/lfu.pdf, with some notable differences:
/// <ul>
/// <li>
/// Frequency list is stored as an array with no next/prev pointers between nodes: looping over the array should be faster and more CPU-cache friendly than
/// using an ad-hoc linked-pointers structure.
/// </li>
/// <li>
/// The max frequency is capped at the cache size to avoid creating more and more frequency list entries, and all elements residing in the max frequency entry
/// are re-positioned in the frequency entry linked set in order to put most recently accessed elements ahead of less recently ones,
/// which will be collected sooner.
/// </li>
/// <li>
/// The eviction factor determines how many elements (more specifically, the percentage of) will be evicted.
/// </li>
/// </ul>
/// As a consequence, this cache runs in *amortized* O(1) time (considering the worst case of having the lowest frequency at 0 and having to evict all
/// elements).
///
/// @author Sergio Bossa, Fabian Freund
class LFUCache<K, V> {
  final Map<K, _CacheNode<K, V>> _cache = {};
  final List<LinkedHashSet<_CacheNode<K, V>>> _frequencyList;

  final int maxCacheSize;
  final int evictionCount;

  int _lowestFrequency;
  final int _maxFrequency;

  LFUCache(this.maxCacheSize, this.evictionCount)
      : _frequencyList =
            List.filled(maxCacheSize, LinkedHashSet(), growable: false),
        _lowestFrequency = 0,
        _maxFrequency = maxCacheSize - 1,
        assert(evictionCount > 0);

  V? put(K key, V value) {
    V? oldValue;

    var currentNode = _cache[key];
    if (currentNode == null) {
      if (_cache.length == maxCacheSize) {
        _doEviction();
      }

      final nodes = _frequencyList.first;

      currentNode = _CacheNode(key, value, 0);
      nodes.add(currentNode);

      _cache[key] = currentNode;
      _lowestFrequency = 0;
    } else {
      oldValue = currentNode.value;
      currentNode.value = value;
    }

    return oldValue;
  }

  V? get(K key) {
    var currentNode = _cache[key];
    if (currentNode != null) {
      final currentFrequency = currentNode.frequency;
      if (currentFrequency < _maxFrequency) {
        final nextFrequency = currentFrequency + 1;

        final currentNodes = _frequencyList[currentFrequency];
        final newNodes = _frequencyList[nextFrequency];

        _moveToNextFrequency(
            currentNode, nextFrequency, currentNodes, newNodes);

        _cache[key] = currentNode;

        if (_lowestFrequency == currentFrequency && currentNodes.isEmpty) {
          _lowestFrequency = nextFrequency;
        }
      } else {
        // Hybrid with LRU: put most recently accessed ahead of others:
        final nodes = _frequencyList[currentFrequency];

        nodes.remove(currentNode);
        nodes.add(currentNode);
      }
      return currentNode.value;
    } else {
      return null;
    }
  }

  V? getOrPut(K key, V? Function() valueFunc) {
    final cached = get(key);
    if (cached != null) {
      return cached;
    }

    final value = valueFunc();
    if (value != null) {
      put(key, value);
    }

    return value;
  }

  Future<V?> getOrPutAsync(K key, Future<V?> Function() valueFunc) {
    final cached = get(key);
    if (cached != null) {
      return Future.value(cached);
    }

    return valueFunc().then((value) {
      if (value != null) {
        put(key, value);
      }

      return value;
    });
  }

  V? remove(K key) {
    final currentNode = _cache.remove(key);

    if (currentNode != null) {
      final nodes = _frequencyList[currentNode.frequency];
      nodes.remove(currentNode);

      if (_lowestFrequency == currentNode.frequency) {
        _findNextLowestFrequency();
      }
      return currentNode.value;
    } else {
      return null;
    }
  }

  int frequencyOf(K key) {
    final node = _cache[key];

    if (node != null) {
      return node.frequency + 1;
    } else {
      return 0;
    }
  }

  void _doEviction() {
    var currentlyDeleted = 0;

    while (currentlyDeleted < evictionCount) {
      final nodes = _frequencyList[_lowestFrequency];
      if (nodes.isEmpty) {
        throw Exception("Lowest frequency constraint violated!");
      }

      final removeCount = min(evictionCount - currentlyDeleted, nodes.length);

      final itemsToRemove = nodes.take(removeCount).toList(growable: false);
      nodes.removeAll(itemsToRemove);

      final removeKeyList = itemsToRemove.map((node) => node.key).toSet();
      _cache.removeWhere((key, _) => removeKeyList.contains(key));

      if (nodes.isEmpty) {
        _findNextLowestFrequency();
      }

      currentlyDeleted += removeCount;
    }
  }

  void _moveToNextFrequency(
      _CacheNode<K, V> currentNode,
      int nextFrequency,
      LinkedHashSet<_CacheNode<K, V>> currentNodes,
      LinkedHashSet<_CacheNode<K, V>> newNodes) {
    currentNodes.remove(currentNode);
    newNodes.add(currentNode);
    currentNode.frequency = nextFrequency;
  }

  void _findNextLowestFrequency() {
    while (_lowestFrequency <= _maxFrequency &&
        _frequencyList[_lowestFrequency].isEmpty) {
      _lowestFrequency++;
    }
    if (_lowestFrequency > _maxFrequency) {
      _lowestFrequency = 0;
    }
  }
}
