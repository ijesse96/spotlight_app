# Testing Guide for Modular Queue System

## Overview
This guide outlines the testing strategy for the new modular queue system that replaces the monolithic `QueueService`.

## Testing Objectives
1. **Functionality Testing**: Verify all queue operations work correctly
2. **Integration Testing**: Ensure new widgets integrate properly with existing UI
3. **Performance Testing**: Compare performance with the old system
4. **Migration Testing**: Verify backward compatibility through `QueueMigrationService`

## Test Environment Setup

### Prerequisites
- Firebase project configured
- Test user accounts available
- Multiple devices/emulators for testing

### Test Data Setup
```dart
// Test user profiles
final testUsers = [
  {'uid': 'test_user_1', 'displayName': 'Test User 1', 'photoURL': null},
  {'uid': 'test_user_2', 'displayName': 'Test User 2', 'photoURL': null},
  {'uid': 'test_user_3', 'displayName': 'Test User 3', 'photoURL': null},
];

// Test queue configurations
final testConfigs = [
  {'type': 'spotlight', 'maxUsers': 10, 'timerDuration': 20},
  {'type': 'city', 'cityId': 'test_city', 'maxUsers': 5, 'timerDuration': 15},
  {'type': 'nearby', 'locationId': 'test_location', 'maxUsers': 8, 'timerDuration': 18},
  {'type': 'vlr', 'roomId': 'test_room', 'maxUsers': 6, 'timerDuration': 12},
  {'type': 'local', 'locationId': 'test_local', 'maxUsers': 7, 'timerDuration': 16},
];
```

## Test Cases

### 1. Core Queue Operations

#### 1.1 Join Queue
- **Objective**: Verify users can join different queue types
- **Steps**:
  1. Navigate to Live Queue Page
  2. Select different queue tabs (Spotlight, City, Nearby, VLR, Local)
  3. Click "Join Queue" button
  4. Verify user appears in queue list
  5. Verify queue position is correct
- **Expected Results**:
  - User successfully joins queue
  - Queue position updates in real-time
  - User data includes correct queue-specific fields

#### 1.2 Leave Queue
- **Objective**: Verify users can leave queues
- **Steps**:
  1. Join a queue
  2. Click "Leave Queue" button
  3. Verify user is removed from queue
- **Expected Results**:
  - User is removed from queue immediately
  - Other users' positions are updated
  - Timer continues for remaining users

#### 1.3 Queue Timer Management
- **Objective**: Verify timer functionality across all queue types
- **Steps**:
  1. Join multiple users to a queue
  2. Start the queue timer
  3. Monitor countdown progression
  4. Verify user rotation when timer expires
- **Expected Results**:
  - Timer counts down correctly
  - Users rotate in correct order
  - Timer resets for next user
  - Timer state persists across app restarts

### 2. Queue-Specific Features

#### 2.1 Spotlight Queue
- **Features to Test**:
  - Global queue functionality
  - 20-second timer
  - User rotation
  - Live user display
- **Test Scenarios**:
  - Multiple users joining simultaneously
  - Timer interruption and recovery
  - User leaving during active session

#### 2.2 City Queue
- **Features to Test**:
  - City-specific queue isolation
  - City ID tracking
  - 15-second timer
- **Test Scenarios**:
  - Different cities having separate queues
  - City data persistence
  - Cross-city queue isolation

#### 2.3 Nearby Queue
- **Features to Test**:
  - Location-based queue
  - Distance calculation
  - 18-second timer
- **Test Scenarios**:
  - Location updates affecting queue
  - Distance-based filtering
  - Location data accuracy

#### 2.4 VLR Queue
- **Features to Test**:
  - Room-specific queue
  - Room ID tracking
  - 12-second timer
- **Test Scenarios**:
  - Multiple VLR rooms
  - Room-specific data isolation
  - Room switching

#### 2.5 Local Queue
- **Features to Test**:
  - Local area queue
  - Location-based filtering
  - 16-second timer
- **Test Scenarios**:
  - Local area boundaries
  - Location updates
  - Area-specific features

### 3. UI Integration Testing

#### 3.1 New Queue Widgets
- **Objective**: Test the new `*_queue_widget_new.dart` widgets
- **Steps**:
  1. Navigate to Live Queue Page
  2. Test each tab (Spotlight, City, Nearby, VLR, Local)
  3. Verify widget displays correctly
  4. Test all interactive elements
- **Expected Results**:
  - Widgets render correctly
  - All buttons work as expected
  - Real-time updates display properly
  - Navigation to stream pages works

#### 3.2 Widget Features
- **Join/Leave Queue Buttons**
  - Verify button states change correctly
  - Test disabled states
  - Verify loading indicators

- **Queue List Display**
  - Verify user order is correct
  - Test user avatars and names
  - Verify join timestamps

- **Timer Display**
  - Verify countdown accuracy
  - Test timer formatting
  - Verify timer updates in real-time

- **Navigation**
  - Test navigation to stream pages
  - Verify correct parameters passed
  - Test back navigation

### 4. Performance Testing

#### 4.1 Memory Usage
- **Objective**: Compare memory usage between old and new systems
- **Metrics**:
  - Memory consumption during queue operations
  - Memory leaks during extended use
  - Garbage collection frequency

#### 4.2 Response Time
- **Objective**: Measure response times for queue operations
- **Metrics**:
  - Time to join queue
  - Time to leave queue
  - Time to update queue position
  - Time to start timer

#### 4.3 Scalability
- **Objective**: Test system behavior with many users
- **Test Scenarios**:
  - 50+ users in single queue
  - Multiple queues active simultaneously
  - High-frequency queue operations

### 5. Migration Testing

#### 5.1 Backward Compatibility
- **Objective**: Verify `QueueMigrationService` works correctly
- **Steps**:
  1. Use old UI components with new system
  2. Verify all old API calls work
  3. Test data format compatibility
- **Expected Results**:
  - Old UI components work without changes
  - Data formats are compatible
  - No breaking changes

#### 5.2 Gradual Migration
- **Objective**: Test mixed old/new UI usage
- **Steps**:
  1. Use both old and new widgets simultaneously
  2. Verify data consistency
  3. Test cross-widget communication
- **Expected Results**:
  - Consistent data across old/new widgets
  - No conflicts between systems
  - Smooth transition possible

### 6. Error Handling

#### 6.1 Network Errors
- **Test Scenarios**:
  - Firebase connection loss
  - Slow network conditions
  - Network timeouts
- **Expected Results**:
  - Graceful error handling
  - User-friendly error messages
  - Automatic retry mechanisms

#### 6.2 Data Validation
- **Test Scenarios**:
  - Invalid user data
  - Missing required fields
  - Corrupted queue data
- **Expected Results**:
  - Data validation prevents errors
  - Invalid data is handled gracefully
  - System remains stable

### 7. Security Testing

#### 7.1 Authentication
- **Objective**: Verify proper authentication checks
- **Test Scenarios**:
  - Unauthenticated users
  - Expired tokens
  - Invalid user IDs
- **Expected Results**:
  - Proper authentication enforcement
  - Secure data access
  - No unauthorized operations

#### 7.2 Data Access
- **Objective**: Verify proper data access controls
- **Test Scenarios**:
  - Cross-user data access
  - Queue data isolation
  - Admin operations
- **Expected Results**:
  - Users can only access their own data
  - Queue data is properly isolated
  - Admin functions work correctly

## Test Execution

### Manual Testing Checklist
- [ ] Spotlight queue join/leave
- [ ] City queue join/leave
- [ ] Nearby queue join/leave
- [ ] VLR queue join/leave
- [ ] Local queue join/leave
- [ ] Timer functionality for each queue type
- [ ] User rotation in each queue type
- [ ] UI widget functionality
- [ ] Navigation between pages
- [ ] Error handling scenarios
- [ ] Performance under load

### Automated Testing
```dart
// Example test structure
group('Queue System Tests', () {
  test('Spotlight Queue Operations', () async {
    // Test spotlight queue functionality
  });
  
  test('City Queue Operations', () async {
    // Test city queue functionality
  });
  
  test('Timer Management', () async {
    // Test timer functionality
  });
  
  test('UI Integration', () async {
    // Test UI components
  });
});
```

## Success Criteria

### Functional Success
- All queue operations work correctly
- Timer management functions properly
- User rotation occurs as expected
- UI displays real-time updates

### Performance Success
- Response times < 500ms for queue operations
- Memory usage < 100MB during normal operation
- No memory leaks during extended use
- Smooth UI updates (60fps)

### Migration Success
- Old UI components work without changes
- New widgets function correctly
- No data loss during migration
- Consistent behavior across old/new systems

## Reporting

### Test Results Template
```
Test Date: [Date]
Tester: [Name]
App Version: [Version]

Functional Tests:
- [ ] Spotlight Queue: [Pass/Fail]
- [ ] City Queue: [Pass/Fail]
- [ ] Nearby Queue: [Pass/Fail]
- [ ] VLR Queue: [Pass/Fail]
- [ ] Local Queue: [Pass/Fail]

Performance Tests:
- [ ] Memory Usage: [Pass/Fail]
- [ ] Response Time: [Pass/Fail]
- [ ] Scalability: [Pass/Fail]

UI Tests:
- [ ] New Widgets: [Pass/Fail]
- [ ] Navigation: [Pass/Fail]
- [ ] Real-time Updates: [Pass/Fail]

Issues Found:
1. [Issue description]
2. [Issue description]

Recommendations:
1. [Recommendation]
2. [Recommendation]
```

## Next Steps

After successful testing:
1. **Deploy to staging environment**
2. **Conduct user acceptance testing**
3. **Monitor production metrics**
4. **Plan full migration timeline**
5. **Document lessons learned**

## Support

For testing issues or questions:
- Check the `UI_INTEGRATION_GUIDE.md`
- Review `MODULAR_QUEUE_IMPLEMENTATION_SUMMARY.md`
- Consult the queue system documentation
- Contact the development team 