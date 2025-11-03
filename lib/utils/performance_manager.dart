import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// 性能管理器 - 统一管理应用性能优化
class PerformanceManager {
  static final Logger _logger = Logger();
  static final PerformanceManager _instance = PerformanceManager._internal();
  
  factory PerformanceManager() => _instance;
  PerformanceManager._internal();

  /// 事件节流管理器
  final Map<String, Timer> _throttleTimers = {};
  
  /// 事件防抖管理器
  final Map<String, Timer> _debounceTimers = {};
  
  /// 缓存管理器
  final LRUCache<String, dynamic> _cache = LRUCache(maxSize: 100);
  
  /// 连接池管理
  final Set<String> _activeConnections = <String>{};
  
  /// 性能监控数据
  final Map<String, PerformanceMetrics> _metrics = {};

  /// 节流函数 - 限制函数执行频率
  void throttle(String key, VoidCallback callback, Duration duration) {
    if (_throttleTimers[key]?.isActive ?? false) {
      return; // 节流中，忽略调用
    }
    
    callback();
    _throttleTimers[key] = Timer(duration, () {
      _throttleTimers.remove(key);
    });
  }

  /// 防抖函数 - 延迟执行，重复调用会重置计时器
  void debounce(String key, VoidCallback callback, Duration duration) {
    _debounceTimers[key]?.cancel();
    _debounceTimers[key] = Timer(duration, callback);
  }

  /// 缓存数据
  void cache(String key, dynamic value, {Duration? expiry}) {
    _cache.put(key, CacheItem(value, expiry));
  }

  /// 获取缓存数据
  T? getCached<T>(String key) {
    final item = _cache.get(key);
    if (item is CacheItem) {
      if (item.isExpired) {
        _cache.remove(key);
        return null;
      }
      return item.value as T?;
    }
    return null;
  }

  /// 清除缓存
  void clearCache([String? pattern]) {
    if (pattern != null) {
      final keysToRemove = _cache.keys.where((key) => key.contains(pattern)).toList();
      for (final key in keysToRemove) {
        _cache.remove(key);
      }
    } else {
      _cache.clear();
    }
  }

  /// 注册活跃连接
  void addConnection(String connectionId) {
    _activeConnections.add(connectionId);
    _logger.d('连接已注册: $connectionId, 当前连接数: ${_activeConnections.length}');
  }

  /// 移除连接
  void removeConnection(String connectionId) {
    _activeConnections.remove(connectionId);
    _logger.d('连接已移除: $connectionId, 当前连接数: ${_activeConnections.length}');
  }

  /// 获取活跃连接数
  int get activeConnectionCount => _activeConnections.length;

  /// 限制最大连接数
  bool canCreateConnection({int maxConnections = 10}) {
    return _activeConnections.length < maxConnections;
  }

  /// 开始性能监控
  PerformanceTracker startTracking(String operation) {
    return PerformanceTracker(operation, this);
  }

  /// 记录性能指标
  void _recordMetrics(String operation, Duration duration, Map<String, dynamic>? metadata) {
    final metrics = _metrics[operation] ??= PerformanceMetrics(operation);
    metrics.addMeasurement(duration, metadata);
    
    if (kDebugMode) {
      _logger.d('性能指标 [$operation]: ${duration.inMilliseconds}ms');
    }
  }

  /// 获取性能报告
  PerformanceReport getPerformanceReport() {
    return PerformanceReport(_metrics.values.toList());
  }

  /// 优化内存使用
  void optimizeMemory() {
    // 清理过期缓存
    final expiredKeys = <String>[];
    for (final entry in _cache.entries) {
      if (entry.value is CacheItem && (entry.value as CacheItem).isExpired) {
        expiredKeys.add(entry.key);
      }
    }
    for (final key in expiredKeys) {
      _cache.remove(key);
    }

    // 清理过期的计时器
    _throttleTimers.removeWhere((key, timer) => !timer.isActive);
    _debounceTimers.removeWhere((key, timer) => !timer.isActive);

    _logger.i('内存优化完成: 清理了 ${expiredKeys.length} 个过期缓存项');
  }

  /// 批处理操作 - 收集多个操作一次性执行
  BatchProcessor<T> createBatchProcessor<T>({
    required Duration interval,
    required void Function(List<T>) processor,
    int maxBatchSize = 50,
  }) {
    return BatchProcessor<T>(
      interval: interval,
      processor: processor,
      maxBatchSize: maxBatchSize,
    );
  }

  /// 释放资源
  void dispose() {
    for (final timer in _throttleTimers.values) {
      timer.cancel();
    }
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _throttleTimers.clear();
    _debounceTimers.clear();
    _cache.clear();
    _activeConnections.clear();
    _metrics.clear();
  }
}

/// LRU缓存实现
class LRUCache<K, V> {
  final int maxSize;
  final LinkedHashMap<K, V> _cache = LinkedHashMap<K, V>();

  LRUCache({required this.maxSize});

  V? get(K key) {
    if (_cache.containsKey(key)) {
      // 移动到最前面（最近使用）
      final value = _cache.remove(key)!;
      _cache[key] = value;
      return value;
    }
    return null;
  }

  void put(K key, V value) {
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    } else if (_cache.length >= maxSize) {
      // 移除最久未使用的项
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = value;
  }

  void remove(K key) {
    _cache.remove(key);
  }

  void clear() {
    _cache.clear();
  }

  Iterable<K> get keys => _cache.keys;
  Iterable<V> get values => _cache.values;
  Iterable<MapEntry<K, V>> get entries => _cache.entries;
  int get length => _cache.length;
}

/// 缓存项
class CacheItem {
  final dynamic value;
  final DateTime? expiry;

  CacheItem(this.value, Duration? ttl) 
      : expiry = ttl != null ? DateTime.now().add(ttl) : null;

  bool get isExpired {
    return expiry != null && DateTime.now().isAfter(expiry!);
  }
}

/// 性能追踪器
class PerformanceTracker {
  final String operation;
  final PerformanceManager _manager;
  final Stopwatch _stopwatch = Stopwatch();
  final Map<String, dynamic> _metadata = {};

  PerformanceTracker(this.operation, this._manager) {
    _stopwatch.start();
  }

  /// 添加元数据
  void addMetadata(String key, dynamic value) {
    _metadata[key] = value;
  }

  /// 结束追踪
  void stop() {
    _stopwatch.stop();
    _manager._recordMetrics(operation, _stopwatch.elapsed, _metadata);
  }
}

/// 性能指标
class PerformanceMetrics {
  final String operation;
  final List<Duration> _measurements = [];
  final List<Map<String, dynamic>> _metadata = [];

  PerformanceMetrics(this.operation);

  void addMeasurement(Duration duration, Map<String, dynamic>? metadata) {
    _measurements.add(duration);
    _metadata.add(metadata ?? {});
    
    // 保持最近100次测量
    if (_measurements.length > 100) {
      _measurements.removeAt(0);
      _metadata.removeAt(0);
    }
  }

  Duration get averageDuration {
    if (_measurements.isEmpty) return Duration.zero;
    final totalMs = _measurements.fold<int>(0, (sum, duration) => sum + duration.inMilliseconds);
    return Duration(milliseconds: totalMs ~/ _measurements.length);
  }

  Duration get minDuration => _measurements.isEmpty ? Duration.zero : _measurements.reduce((a, b) => a < b ? a : b);
  Duration get maxDuration => _measurements.isEmpty ? Duration.zero : _measurements.reduce((a, b) => a > b ? a : b);
  int get measurementCount => _measurements.length;
}

/// 性能报告
class PerformanceReport {
  final List<PerformanceMetrics> metrics;

  PerformanceReport(this.metrics);

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('=== 性能报告 ===');
    
    for (final metric in metrics) {
      buffer.writeln('操作: ${metric.operation}');
      buffer.writeln('  测量次数: ${metric.measurementCount}');
      buffer.writeln('  平均耗时: ${metric.averageDuration.inMilliseconds}ms');
      buffer.writeln('  最小耗时: ${metric.minDuration.inMilliseconds}ms');
      buffer.writeln('  最大耗时: ${metric.maxDuration.inMilliseconds}ms');
      buffer.writeln();
    }
    
    return buffer.toString();
  }
}

/// 批处理器
class BatchProcessor<T> {
  final Duration interval;
  final void Function(List<T>) processor;
  final int maxBatchSize;
  
  final List<T> _batch = [];
  Timer? _timer;

  BatchProcessor({
    required this.interval,
    required this.processor,
    required this.maxBatchSize,
  });

  /// 添加项目到批处理
  void add(T item) {
    _batch.add(item);
    
    if (_batch.length >= maxBatchSize) {
      _processBatch();
    } else {
      _resetTimer();
    }
  }

  /// 重置计时器
  void _resetTimer() {
    _timer?.cancel();
    _timer = Timer(interval, _processBatch);
  }

  /// 处理批次
  void _processBatch() {
    if (_batch.isNotEmpty) {
      final items = List<T>.from(_batch);
      _batch.clear();
      _timer?.cancel();
      _timer = null;
      
      processor(items);
    }
  }

  /// 强制处理当前批次
  void flush() {
    _processBatch();
  }

  /// 释放资源
  void dispose() {
    _timer?.cancel();
    _batch.clear();
  }
}

/// 性能优化的Widget工厂
class OptimizedWidgetFactory {
  static final Map<String, Widget> _widgetCache = {};

  /// 缓存的Widget构建器
  static Widget cached(String key, Widget Function() builder) {
    return _widgetCache.putIfAbsent(key, builder);
  }

  /// 清除Widget缓存
  static void clearCache() {
    _widgetCache.clear();
  }
}

/// 资源池管理器
class ResourcePool<T> {
  final Queue<T> _available = Queue<T>();
  final Set<T> _inUse = <T>{};
  final T Function() _factory;
  final void Function(T)? _resetFunction;
  final int maxSize;

  ResourcePool({
    required T Function() factory,
    void Function(T)? resetFunction,
    this.maxSize = 10,
  }) : _factory = factory, _resetFunction = resetFunction;

  /// 获取资源
  T acquire() {
    T resource;
    
    if (_available.isNotEmpty) {
      resource = _available.removeFirst();
    } else {
      resource = _factory();
    }
    
    _inUse.add(resource);
    return resource;
  }

  /// 释放资源
  void release(T resource) {
    if (_inUse.remove(resource)) {
      _resetFunction?.call(resource);
      
      if (_available.length < maxSize) {
        _available.add(resource);
      }
    }
  }

  /// 获取池状态
  PoolStatus get status => PoolStatus(
    available: _available.length,
    inUse: _inUse.length,
    maxSize: maxSize,
  );
}

/// 资源池状态
class PoolStatus {
  final int available;
  final int inUse;
  final int maxSize;

  PoolStatus({
    required this.available,
    required this.inUse,
    required this.maxSize,
  });

  @override
  String toString() {
    return 'PoolStatus(available: $available, inUse: $inUse, maxSize: $maxSize)';
  }
}
