# lfu_cache

This is a high performance LFU cache implementation.

The implementation is heavily inspired by the Java implementation of Apache's ActiveMQ cache.

## Features

LFU cache implementation based on http://dhruvbird.com/lfu.pdf, with some notable differences:

- Frequency list is stored as an array with no next/prev pointers between nodes: looping over the array should be faster and more CPU-cache friendly than using an ad-hoc linked-pointers structure.

- The max frequency is capped at the cache size to avoid creating more and more frequency list entries, and all elements residing in the max frequency entry are re-positioned in the frequency entry linked set in order to put most recently accessed elements ahead of less recently ones, which will be collected sooner.

- The eviction factor determines how many elements (more specifically, the percentage of) will be evicted.
As a consequence, this cache runs in *amortized* O(1) time (considering the worst case of having the lowest frequency at 0 and having to evict all elements).

## Usage

```dart
const maxCacheSize = 2;
const evictionCount = 1;

final cache = LFUCache(maxCacheSize, evictionCount);

cache.put(1, true);
cache.put(2, true);
cache.put(3, true);

print(cache.get(1)); //null
``````

