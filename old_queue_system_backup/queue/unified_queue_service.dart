import 'base_queue_controller.dart';
import 'queue_config.dart';
import 'queue_registry.dart';
import 'unified_timer_service.dart';

/// Unified queue service that provides a clean interface to the modular queue system
class UnifiedQueueService {
  static final UnifiedQueueService _instance = UnifiedQueueService._internal();
  factory UnifiedQueueService() => _instance;
  UnifiedQueueService._internal();

  final QueueRegistry _registry = QueueRegistry();
  final UnifiedTimerService _timerService = UnifiedTimerService();

  // MARK: - Queue Management

  /// Get a queue controller by ID
  BaseQueueController getQueue(String queueId) {
    return _registry.getQueue(queueId);
  }

  /// Get a queue controller with configuration
  BaseQueueController getQueueWithConfig(QueueConfig config) {
    return _registry.getQueueWithConfig(config);
  }

  /// Get spotlight queue
  BaseQueueController get spotlightQueue => _registry.spotlightQueue;

  /// Get city queue
  BaseQueueController getCityQueue(String cityId) => _registry.getCityQueue(cityId);

  /// Get nearby queue
  BaseQueueController getNearbyQueue(String locationId) => _registry.getNearbyQueue(locationId);

  /// Get VLR queue
  BaseQueueController getVLRQueue(String roomId) => _registry.getVLRQueue(roomId);

  /// Get local queue
  BaseQueueController getLocalQueue(String locationId) => _registry.getLocalQueue(locationId);

  // MARK: - Queue Operations

  /// Join a queue by ID
  Future<void> joinQueue(String queueId) async {
    final queue = getQueue(queueId);
    await queue.joinQueue();
  }

  /// Join a queue with configuration
  Future<void> joinQueueWithConfig(QueueConfig config) async {
    final queue = getQueueWithConfig(config);
    await queue.joinQueue();
  }

  /// Leave a queue by ID
  Future<void> leaveQueue(String queueId) async {
    final queue = getQueue(queueId);
    await queue.leaveQueue();
  }

  /// Leave all queues
  Future<void> leaveAllQueues() async {
    for (final queue in _registry.activeQueues) {
      try {
        await queue.leaveQueue();
      } catch (e) {
        print('⚠️ [UNIFIED_QUEUE] Error leaving queue ${queue.queueId}: $e');
      }
    }
  }

  // MARK: - Queue Information

  /// Get queue users stream
  Stream<List<QueueUser>> getQueueUsers(String queueId) {
    final queue = getQueue(queueId);
    return queue.getQueueUsers();
  }

  /// Get current live user stream
  Stream<QueueUser?> getCurrentLiveUser(String queueId) {
    final queue = getQueue(queueId);
    return queue.getCurrentLiveUser();
  }

  /// Get timer state stream
  Stream<TimerState> getTimerState(String queueId) {
    final queue = getQueue(queueId);
    return queue.getTimerState();
  }

  // MARK: - Live Session Management

  /// Set user as live
  Future<void> setUserAsLive(String queueId, String userId, String userName) async {
    final queue = getQueue(queueId);
    await queue.setUserAsLive(userId, userName);
  }

  /// End live session
  Future<void> endLiveSession(String queueId) async {
    final queue = getQueue(queueId);
    await queue.endLiveSession();
  }

  /// Move to next user
  Future<void> moveToNextUser(String queueId) async {
    final queue = getQueue(queueId);
    await queue.moveToNextUser();
  }

  // MARK: - Timer Management

  /// Start timer for a queue
  Future<void> startTimer(String queueId) async {
    final queue = getQueue(queueId);
    await queue.startTimer();
  }

  /// Stop timer for a queue
  Future<void> stopTimer(String queueId) async {
    final queue = getQueue(queueId);
    await queue.stopTimer();
  }

  /// Reset timer for a queue
  Future<void> resetTimer(String queueId) async {
    final queue = getQueue(queueId);
    await queue.resetTimer();
  }

  // MARK: - Registry Information

  /// Get all active queue IDs
  List<String> get activeQueueIds => _registry.activeQueueIds;

  /// Get all active queue controllers
  List<BaseQueueController> get activeQueues => _registry.activeQueues;

  /// Get queues by type
  List<BaseQueueController> getQueuesByType(QueueType type) {
    return _registry.getQueuesByType(type);
  }

  /// Check if a queue exists
  bool hasQueue(String queueId) => _registry.hasQueue(queueId);

  /// Get configuration for a queue
  QueueConfig? getConfig(String queueId) => _registry.getConfig(queueId);

  /// Get queue statistics
  Map<String, dynamic> getStatistics() => _registry.getStatistics();

  // MARK: - Timer Service Access

  /// Get unified timer service
  UnifiedTimerService get timerService => _timerService;

  /// Get all active timer IDs
  List<String> get activeTimerIds => _timerService.activeTimerIds;

  /// Check if a timer is active
  bool isTimerActive(String timerId) => _timerService.isTimerActive(timerId);

  /// Get current timer state
  TimerState? getCurrentTimerState(String timerId) => _timerService.getCurrentTimerState(timerId);

  // MARK: - Cleanup

  /// Dispose all resources
  void dispose() {
    _registry.dispose();
    _timerService.dispose();
  }

  // MARK: - Convenience Methods

  /// Join spotlight queue
  Future<void> joinSpotlightQueue() async {
    await joinQueue('spotlight');
  }

  /// Join city queue
  Future<void> joinCityQueue(String cityId) async {
    await joinQueue('city_$cityId');
  }

  /// Join nearby queue
  Future<void> joinNearbyQueue(String locationId) async {
    await joinQueue('nearby_$locationId');
  }

  /// Join VLR queue
  Future<void> joinVLRQueue(String roomId) async {
    await joinQueue('vlr_$roomId');
  }

  /// Join local queue
  Future<void> joinLocalQueue(String locationId) async {
    await joinQueue('local_$locationId');
  }

  /// Leave spotlight queue
  Future<void> leaveSpotlightQueue() async {
    await leaveQueue('spotlight');
  }

  /// Leave city queue
  Future<void> leaveCityQueue(String cityId) async {
    await leaveQueue('city_$cityId');
  }

  /// Leave nearby queue
  Future<void> leaveNearbyQueue(String locationId) async {
    await leaveQueue('nearby_$locationId');
  }

  /// Leave VLR queue
  Future<void> leaveVLRQueue(String roomId) async {
    await leaveQueue('vlr_$roomId');
  }

  /// Leave local queue
  Future<void> leaveLocalQueue(String locationId) async {
    await leaveQueue('local_$locationId');
  }

  /// Get spotlight queue users
  Stream<List<QueueUser>> getSpotlightQueueUsers() => getQueueUsers('spotlight');

  /// Get spotlight current live user
  Stream<QueueUser?> getSpotlightCurrentLiveUser() => getCurrentLiveUser('spotlight');

  /// Get spotlight timer state
  Stream<TimerState> getSpotlightTimerState() => getTimerState('spotlight');

  /// Set user as live in spotlight
  Future<void> setSpotlightUserAsLive(String userId, String userName) async {
    await setUserAsLive('spotlight', userId, userName);
  }

  /// End spotlight live session
  Future<void> endSpotlightLiveSession() async {
    await endLiveSession('spotlight');
  }

  /// Move to next user in spotlight
  Future<void> moveToNextSpotlightUser() async {
    await moveToNextUser('spotlight');
  }

  /// Start spotlight timer
  Future<void> startSpotlightTimer() async {
    await startTimer('spotlight');
  }

  /// Stop spotlight timer
  Future<void> stopSpotlightTimer() async {
    await stopTimer('spotlight');
  }

  /// Reset spotlight timer
  Future<void> resetSpotlightTimer() async {
    await resetTimer('spotlight');
  }
} 