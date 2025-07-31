# 🏗️ Modular Queue Architecture

## 📋 Overview

The new modular queue architecture provides a clean, scalable, and maintainable solution for managing multiple queue types in the Spotlight app. This replaces the monolithic `QueueService` with a modular system that separates concerns and makes it easy to add new queue types.

## 🎯 Key Benefits

### ✅ **Modularity**
- Each queue type has its own controller
- Easy to add new queue types without modifying existing code
- Clear separation of concerns

### ✅ **Unified Timer Management**
- Centralized timer service for all queues
- Eliminates duplicate timer logic
- Better resource management

### ✅ **Configuration-Driven**
- Queue types defined by configuration
- Easy to customize queue behavior
- Consistent interface across all queue types

### ✅ **Type Safety**
- Strong typing with Dart
- Compile-time error checking
- Better IDE support

### ✅ **Testability**
- Each component can be tested independently
- Mock-friendly architecture
- Clear interfaces

## 🏛️ Architecture Components

### 1. **BaseQueueController** (`lib/services/queue/base_queue_controller.dart`)
Abstract base class that defines the interface for all queue controllers.

**Key Features:**
- Common queue operations (join, leave, get users, etc.)
- Timer management interface
- User authentication helpers
- Firestore integration

### 2. **QueueConfig** (`lib/services/queue/queue_config.dart`)
Configuration system for defining queue types and their properties.

**Key Features:**
- Queue type enumeration
- Configurable properties (duration, collections, etc.)
- Factory methods for creating configurations
- Display names and descriptions

### 3. **UnifiedTimerService** (`lib/services/queue/unified_timer_service.dart`)
Centralized timer management for all queues.

**Key Features:**
- Single timer instance per queue
- Firestore synchronization
- Stream-based state updates
- Automatic cleanup

### 4. **QueueRegistry** (`lib/services/queue/queue_registry.dart`)
Registry for managing all queue controller instances.

**Key Features:**
- Singleton pattern for global access
- Automatic queue creation
- Configuration-based instantiation
- Statistics and monitoring

### 5. **UnifiedQueueService** (`lib/services/queue/unified_queue_service.dart`)
High-level service that provides a clean interface to the queue system.

**Key Features:**
- Simplified API for common operations
- Convenience methods for each queue type
- Error handling and logging
- Resource management

## 🎮 Queue Controllers

### ✅ **SpotlightQueueController** (Implemented)
- Main spotlight queue functionality
- Complete implementation with all features
- Ready for production use

### 🔄 **Other Controllers** (Placeholders)
- `CityQueueController`
- `NearbyQueueController`
- `VLRQueueController`
- `LocalQueueController`

These are placeholder implementations that can be completed by copying the SpotlightQueueController pattern.

## 🚀 Usage Examples

### Basic Usage

```dart
import 'package:spotlight_app/services/queue/index.dart';

// Get the unified queue service
final queueService = UnifiedQueueService();

// Join spotlight queue
await queueService.joinSpotlightQueue();

// Get queue users stream
final usersStream = queueService.getSpotlightQueueUsers();

// Get timer state stream
final timerStream = queueService.getSpotlightTimerState();
```

### Advanced Usage

```dart
// Get a specific queue by ID
final queue = queueService.getQueue('spotlight');

// Join with configuration
final config = QueueConfigFactory.createSpotlightConfig();
final queue = queueService.getQueueWithConfig(config);
await queue.joinQueue();

// Custom queue operations
await queue.setUserAsLive(userId, userName);
await queue.moveToNextUser();
await queue.startTimer();
```

### Timer Management

```dart
// Get timer service directly
final timerService = queueService.timerService;

// Check active timers
final activeTimers = timerService.activeTimerIds;
final isActive = timerService.isTimerActive('spotlight_timer_spotlight');

// Get timer state
final state = timerService.getCurrentTimerState('spotlight_timer_spotlight');
```

## 📊 Queue Types

### 1. **Spotlight** (`QueueType.spotlight`)
- **ID**: `spotlight`
- **Collections**: `spotlight_queue`, `spotlight_live_users`, `spotlight_timer`
- **Duration**: 20 seconds
- **Description**: Main spotlight queue for live streaming

### 2. **City** (`QueueType.city`)
- **ID**: `city_{cityId}`
- **Collections**: `city_queue`, `city_live_users`, `city_timer`
- **Duration**: 20 seconds
- **Requires**: Geolocation
- **Description**: City-specific queue based on location

### 3. **Nearby** (`QueueType.nearby`)
- **ID**: `nearby_{locationId}`
- **Collections**: `nearby_queue`, `nearby_live_users`, `nearby_timer`
- **Duration**: 20 seconds
- **Requires**: Geolocation
- **Description**: Location-based nearby queue

### 4. **VLR** (`QueueType.vlr`)
- **ID**: `vlr_{roomId}`
- **Collections**: `vlr_queue`, `vlr_live_users`, `vlr_timer`
- **Duration**: 20 seconds
- **Description**: VLR room-specific queue

### 5. **Local** (`QueueType.local`)
- **ID**: `local_{locationId}`
- **Collections**: `local_queue`, `local_live_users`, `local_timer`
- **Duration**: 20 seconds
- **Requires**: Geolocation
- **Description**: Local area queue

## 🔧 Migration Guide

### From Old QueueService

**Old Code:**
```dart
final queueService = QueueService();
await queueService.joinSpotlightQueue();
```

**New Code:**
```dart
final queueService = UnifiedQueueService();
await queueService.joinSpotlightQueue();
```

### Stream Changes

**Old Code:**
```dart
Stream<List<Map<String, dynamic>>> getQueueUsers()
```

**New Code:**
```dart
Stream<List<QueueUser>> getQueueUsers()
```

### Timer Access

**Old Code:**
```dart
// Multiple static timers
static Timer? _spotlightTimer;
static Timer? _cityTimer;
```

**New Code:**
```dart
// Unified timer service
final timerService = UnifiedTimerService();
timerService.startTimer('spotlight_timer_spotlight', 20);
```

## 🧪 Testing

### Unit Testing

```dart
// Test queue controller
final config = QueueConfigFactory.createSpotlightConfig();
final controller = SpotlightQueueController(config);

// Test timer service
final timerService = UnifiedTimerService();
await timerService.startTimer('test_timer', 10);
```

### Integration Testing

```dart
// Test unified service
final queueService = UnifiedQueueService();
await queueService.joinSpotlightQueue();
final users = await queueService.getSpotlightQueueUsers().first;
```

## 📈 Performance Benefits

### Memory Usage
- **Before**: Multiple static timers consuming memory
- **After**: Single timer service with efficient cleanup

### Code Maintainability
- **Before**: 1700+ lines in single file
- **After**: Modular components with clear responsibilities

### Scalability
- **Before**: Hard-coded queue types
- **After**: Configuration-driven queue creation

## 🔮 Future Enhancements

### Planned Features
1. **Queue Analytics**: Track queue performance and usage
2. **Dynamic Configuration**: Runtime queue configuration changes
3. **Queue Persistence**: Save queue state across app restarts
4. **Advanced Timer Features**: Custom durations, pause/resume
5. **Queue Notifications**: Push notifications for queue updates

### Implementation Roadmap
1. ✅ **Phase 1**: Base infrastructure and Spotlight queue
2. 🔄 **Phase 2**: Implement other queue controllers
3. 📋 **Phase 3**: UI integration and testing
4. 🚀 **Phase 4**: Performance optimization and monitoring

## 🛠️ Development Guidelines

### Adding New Queue Types

1. **Create Configuration**
```dart
static QueueConfig createCustomConfig(String id) {
  return QueueConfig(
    type: QueueType.custom,
    id: id,
    defaultDuration: 20,
    collectionPrefix: 'custom',
    displayName: 'Custom Queue',
    description: 'Custom queue implementation',
  );
}
```

2. **Implement Controller**
```dart
class CustomQueueController extends BaseQueueController {
  final QueueConfig _config;
  
  CustomQueueController(this._config);
  
  // Implement abstract methods...
}
```

3. **Update Registry**
```dart
case QueueType.custom:
  controller = CustomQueueController(config);
  break;
```

### Best Practices

1. **Use Configuration**: Always use `QueueConfig` for queue creation
2. **Handle Errors**: Implement proper error handling in controllers
3. **Log Operations**: Use consistent logging format
4. **Test Thoroughly**: Write tests for new queue types
5. **Document Changes**: Update this documentation

## 📝 File Structure

```
lib/services/queue/
├── index.dart                          # Export all components
├── base_queue_controller.dart          # Abstract base class
├── queue_config.dart                   # Configuration system
├── unified_timer_service.dart          # Timer management
├── queue_registry.dart                 # Queue registry
├── unified_queue_service.dart          # High-level service
├── spotlight_queue_controller.dart     # Spotlight implementation
├── city_queue_controller.dart          # City queue (placeholder)
├── nearby_queue_controller.dart        # Nearby queue (placeholder)
├── vlr_queue_controller.dart           # VLR queue (placeholder)
└── local_queue_controller.dart         # Local queue (placeholder)
```

## 🎉 Conclusion

The new modular queue architecture provides a solid foundation for the Spotlight app's queue system. It's designed to be:

- **Maintainable**: Clear separation of concerns
- **Scalable**: Easy to add new queue types
- **Reliable**: Strong typing and error handling
- **Performant**: Efficient resource management
- **Testable**: Modular components for easy testing

This architecture will support the app's growth and make it easier to implement new features and queue types in the future. 