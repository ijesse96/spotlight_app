import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_queue_controller.dart';

/// Unified timer service for managing all queue timers
class UnifiedTimerService {
  static final UnifiedTimerService _instance = UnifiedTimerService._internal();
  factory UnifiedTimerService() => _instance;
  UnifiedTimerService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Map of active timers by timer ID
  static final Map<String, Timer> _activeTimers = {};
  
  // Map of timer states by timer ID
  static final Map<String, TimerState> _timerStates = {};
  
  // Stream controllers for timer state updates
  static final Map<String, StreamController<TimerState>> _streamControllers = {};

  /// Start a timer for a specific queue
  Future<void> startTimer(String timerId, int duration) async {
    print('🕐 [UNIFIED_TIMER] Starting timer: $timerId for $duration seconds');
    
    // Cancel existing timer if any
    _activeTimers[timerId]?.cancel();
    
    // Initialize timer state
    _timerStates[timerId] = TimerState(
      remainingSeconds: duration,
      isActive: true,
    );
    
    // Create stream controller if it doesn't exist
    _streamControllers[timerId] ??= StreamController<TimerState>.broadcast();
    
    // Emit initial state
    _emitTimerState(timerId);
    
    // Update Firestore
    await _updateTimerInFirestore(timerId, _timerStates[timerId]!);
    
    // Start the timer
    _activeTimers[timerId] = Timer.periodic(
      const Duration(seconds: 1),
      (timer) => _handleTimerTick(timerId, timer),
    );
    
    print('✅ [UNIFIED_TIMER] Timer started: $timerId');
  }

  /// Stop a timer
  Future<void> stopTimer(String timerId) async {
    print('⏹️ [UNIFIED_TIMER] Stopping timer: $timerId');
    
    _activeTimers[timerId]?.cancel();
    _activeTimers.remove(timerId);
    
    final currentState = _timerStates[timerId];
    if (currentState != null) {
      _timerStates[timerId] = TimerState(
        remainingSeconds: currentState.remainingSeconds,
        isActive: false,
        currentLiveUserId: currentState.currentLiveUserId,
        currentLiveUserName: currentState.currentLiveUserName,
        startTime: currentState.startTime,
        endTime: currentState.endTime,
      );
      
      _emitTimerState(timerId);
      await _updateTimerInFirestore(timerId, _timerStates[timerId]!);
    }
  }

  /// Reset a timer to its default duration
  Future<void> resetTimer(String timerId, int defaultDuration) async {
    print('🔄 [UNIFIED_TIMER] Resetting timer: $timerId to $defaultDuration seconds');
    
    _activeTimers[timerId]?.cancel();
    _activeTimers.remove(timerId);
    
    _timerStates[timerId] = TimerState(
      remainingSeconds: defaultDuration,
      isActive: false,
    );
    
    _emitTimerState(timerId);
    await _updateTimerInFirestore(timerId, _timerStates[timerId]!);
  }

  /// Get timer state stream
  Stream<TimerState> getTimerStateStream(String timerId) {
    _streamControllers[timerId] ??= StreamController<TimerState>.broadcast();
    
    // Emit current state immediately if available
    final currentState = _timerStates[timerId];
    if (currentState != null) {
      _streamControllers[timerId]!.add(currentState);
    }
    
    return _streamControllers[timerId]!.stream;
  }

  /// Set current live user for a timer
  Future<void> setCurrentLiveUser(String timerId, String userId, String userName) async {
    final currentState = _timerStates[timerId];
    if (currentState != null) {
      _timerStates[timerId] = TimerState(
        remainingSeconds: currentState.remainingSeconds,
        isActive: currentState.isActive,
        currentLiveUserId: userId,
        currentLiveUserName: userName,
        startTime: currentState.startTime,
        endTime: currentState.endTime,
      );
      
      _emitTimerState(timerId);
      await _updateTimerInFirestore(timerId, _timerStates[timerId]!);
    }
  }

  /// Clear current live user for a timer
  Future<void> clearCurrentLiveUser(String timerId) async {
    final currentState = _timerStates[timerId];
    if (currentState != null) {
      _timerStates[timerId] = TimerState(
        remainingSeconds: currentState.remainingSeconds,
        isActive: currentState.isActive,
      );
      
      _emitTimerState(timerId);
      await _updateTimerInFirestore(timerId, _timerStates[timerId]!);
    }
  }

  /// Handle timer tick
  void _handleTimerTick(String timerId, Timer timer) {
    final currentState = _timerStates[timerId];
    if (currentState == null) {
      timer.cancel();
      _activeTimers.remove(timerId);
      return;
    }

    // Simple countdown - no complex server time calculations for now
    final newRemaining = currentState.remainingSeconds - 1;
    
    if (newRemaining <= 0) {
      // Timer finished
      print('⏰ [UNIFIED_TIMER] Timer finished: $timerId');
      timer.cancel();
      _activeTimers.remove(timerId);
      
      _timerStates[timerId] = TimerState(
        remainingSeconds: 0,
        isActive: false,
        currentLiveUserId: currentState.currentLiveUserId,
        currentLiveUserName: currentState.currentLiveUserName,
      );
      
      _emitTimerState(timerId);
      _updateTimerInFirestore(timerId, _timerStates[timerId]!);
      return;
    }

    // Simple decrement
    _timerStates[timerId] = TimerState(
      remainingSeconds: newRemaining,
      isActive: true,
      currentLiveUserId: currentState.currentLiveUserId,
      currentLiveUserName: currentState.currentLiveUserName,
    );
    
    _emitTimerState(timerId);
    
    // Update Firestore every 10 seconds to reduce writes
    if (newRemaining % 10 == 0) {
      _updateTimerInFirestore(timerId, _timerStates[timerId]!);
    }
  }

  /// Emit timer state to stream
  void _emitTimerState(String timerId) {
    final controller = _streamControllers[timerId];
    final state = _timerStates[timerId];
    
    if (controller != null && state != null) {
      controller.add(state);
    }
  }

  /// Update timer state in Firestore
  Future<void> _updateTimerInFirestore(String timerId, TimerState state) async {
    try {
      await _firestore.collection('timers').doc(timerId).set(state.toMap());
    } catch (e) {
      print('❌ [UNIFIED_TIMER] Error updating timer in Firestore: $e');
    }
  }

  /// Get current timer state from Firestore
  Future<TimerState?> getTimerStateFromFirestore(String timerId) async {
    try {
      final doc = await _firestore.collection('timers').doc(timerId).get();
      if (doc.exists) {
        return TimerState.fromMap(doc.data()!);
      }
    } catch (e) {
      print('❌ [UNIFIED_TIMER] Error getting timer state from Firestore: $e');
    }
    return null;
  }

  /// Dispose of all timers and streams
  void dispose() {
    for (final timer in _activeTimers.values) {
      timer.cancel();
    }
    _activeTimers.clear();
    _timerStates.clear();
    
    for (final controller in _streamControllers.values) {
      controller.close();
    }
    _streamControllers.clear();
  }

  /// Get all active timer IDs
  List<String> get activeTimerIds => _activeTimers.keys.toList();
  
  /// Check if a timer is active
  bool isTimerActive(String timerId) => _activeTimers.containsKey(timerId);
  
  /// Get current timer state
  TimerState? getCurrentTimerState(String timerId) => _timerStates[timerId];
} 