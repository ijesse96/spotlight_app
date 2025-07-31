import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_queue_controller.dart';
import 'queue_config.dart';
import 'spotlight_queue_controller.dart';
import 'city_queue_controller.dart';
import 'nearby_queue_controller.dart';
import 'vlr_queue_controller.dart';
import 'local_queue_controller.dart';

/// Registry for managing all queue controller instances
class QueueRegistry {
  static final QueueRegistry _instance = QueueRegistry._internal();
  factory QueueRegistry() => _instance;
  QueueRegistry._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Map of active queue controllers by queue ID
  final Map<String, BaseQueueController> _queues = {};
  
  // Map of queue configurations by queue ID
  final Map<String, QueueConfig> _configs = {};

  /// Get or create a queue controller
  BaseQueueController getQueue(String queueId) {
    if (_queues.containsKey(queueId)) {
      return _queues[queueId]!;
    }
    
    // Try to determine queue type from ID pattern
    final config = _determineConfigFromId(queueId);
    if (config != null) {
      return _createQueueController(config);
    }
    
    throw ArgumentError('Unknown queue ID: $queueId');
  }

  /// Get or create a queue controller with explicit configuration
  BaseQueueController getQueueWithConfig(QueueConfig config) {
    final queueId = _generateQueueId(config);
    
    if (_queues.containsKey(queueId)) {
      return _queues[queueId]!;
    }
    
    return _createQueueController(config);
  }

  /// Create a new queue controller
  BaseQueueController _createQueueController(QueueConfig config) {
    final queueId = _generateQueueId(config);
    
    BaseQueueController controller;
    
    switch (config.type) {
      case QueueType.spotlight:
        controller = SpotlightQueueController(config);
        break;
      case QueueType.city:
        controller = CityQueueController(config);
        break;
      case QueueType.nearby:
        controller = NearbyQueueController(config);
        break;
      case QueueType.vlr:
        controller = VLRQueueController(config);
        break;
      case QueueType.local:
        controller = LocalQueueController(config);
        break;
    }
    
    _queues[queueId] = controller;
    _configs[queueId] = config;
    
    print('✅ [QUEUE_REGISTRY] Created queue controller: $queueId (${config.type})');
    
    return controller;
  }

  /// Generate queue ID from configuration
  String _generateQueueId(QueueConfig config) {
    switch (config.type) {
      case QueueType.spotlight:
        return 'spotlight';
      case QueueType.city:
        return 'city_${config.id}';
      case QueueType.nearby:
        return 'nearby_${config.id}';
      case QueueType.vlr:
        return 'vlr_${config.id}';
      case QueueType.local:
        return 'local_${config.id}';
    }
  }

  /// Determine configuration from queue ID
  QueueConfig? _determineConfigFromId(String queueId) {
    if (queueId == 'spotlight') {
      return QueueConfigFactory.createSpotlightConfig();
    }
    
    if (queueId.startsWith('city_')) {
      final cityId = queueId.substring(5);
      return QueueConfigFactory.createCityConfig(cityId, cityId);
    }
    
    if (queueId.startsWith('nearby_')) {
      final locationId = queueId.substring(7);
      return QueueConfigFactory.createNearbyConfig(locationId);
    }
    
    if (queueId.startsWith('vlr_')) {
      final roomId = queueId.substring(4);
      return QueueConfigFactory.createVLRConfig(roomId, roomId);
    }
    
    if (queueId.startsWith('local_')) {
      final locationId = queueId.substring(6);
      return QueueConfigFactory.createLocalConfig(locationId, locationId);
    }
    
    return null;
  }

  /// Get configuration for a queue
  QueueConfig? getConfig(String queueId) {
    return _configs[queueId];
  }

  /// Get all active queue IDs
  List<String> get activeQueueIds => _queues.keys.toList();

  /// Get all active queue controllers
  List<BaseQueueController> get activeQueues => _queues.values.toList();

  /// Get queues by type
  List<BaseQueueController> getQueuesByType(QueueType type) {
    return _queues.values.where((queue) {
      final config = _configs[queue.queueId];
      return config?.type == type;
    }).toList();
  }

  /// Check if a queue exists
  bool hasQueue(String queueId) => _queues.containsKey(queueId);

  /// Remove a queue from registry
  void removeQueue(String queueId) {
    _queues.remove(queueId);
    _configs.remove(queueId);
    print('🗑️ [QUEUE_REGISTRY] Removed queue: $queueId');
  }

  /// Clear all queues
  void clearAll() {
    _queues.clear();
    _configs.clear();
    print('🧹 [QUEUE_REGISTRY] Cleared all queues');
  }

  /// Get queue statistics
  Map<String, dynamic> getStatistics() {
    final stats = <String, dynamic>{
      'totalQueues': _queues.length,
      'queueTypes': <String, int>{},
      'activeQueues': activeQueueIds,
    };
    
    for (final config in _configs.values) {
      final typeName = config.type.name;
      stats['queueTypes'][typeName] = (stats['queueTypes'][typeName] ?? 0) + 1;
    }
    
    return stats;
  }

  /// Dispose all queues
  void dispose() {
    for (final queue in _queues.values) {
      // Note: BaseQueueController doesn't have dispose method yet
      // This will be implemented when we add cleanup logic
    }
    _queues.clear();
    _configs.clear();
    print('🔄 [QUEUE_REGISTRY] Disposed all queues');
  }

  /// Factory methods for common queue types
  
  /// Get spotlight queue
  BaseQueueController get spotlightQueue => getQueue('spotlight');
  
  /// Get city queue
  BaseQueueController getCityQueue(String cityId) => getQueue('city_$cityId');
  
  /// Get nearby queue
  BaseQueueController getNearbyQueue(String locationId) => getQueue('nearby_$locationId');
  
  /// Get VLR queue
  BaseQueueController getVLRQueue(String roomId) => getQueue('vlr_$roomId');
  
  /// Get local queue
  BaseQueueController getLocalQueue(String locationId) => getQueue('local_$locationId');
} 