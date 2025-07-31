/// Enum for different queue types
enum QueueType {
  spotlight,
  city,
  nearby,
  vlr,
  local,
}

/// Configuration for a queue type
class QueueConfig {
  final QueueType type;
  final String id;
  final int defaultDuration;
  final String collectionPrefix;
  final bool requiresGeolocation;
  final String displayName;
  final String description;

  const QueueConfig({
    required this.type,
    required this.id,
    required this.defaultDuration,
    required this.collectionPrefix,
    this.requiresGeolocation = false,
    required this.displayName,
    required this.description,
  });

  /// Get timer ID for this queue
  String get timerId => '${collectionPrefix}_timer_$id';
  
  /// Get queue collection name
  String get queueCollectionName => '${collectionPrefix}_queue';
  
  /// Get live user collection name
  String get liveUserCollectionName => '${collectionPrefix}_live_users';
  
  /// Get timer collection name
  String get timerCollectionName => '${collectionPrefix}_timer';

  /// Create a copy with modified properties
  QueueConfig copyWith({
    QueueType? type,
    String? id,
    int? defaultDuration,
    String? collectionPrefix,
    bool? requiresGeolocation,
    String? displayName,
    String? description,
  }) {
    return QueueConfig(
      type: type ?? this.type,
      id: id ?? this.id,
      defaultDuration: defaultDuration ?? this.defaultDuration,
      collectionPrefix: collectionPrefix ?? this.collectionPrefix,
      requiresGeolocation: requiresGeolocation ?? this.requiresGeolocation,
      displayName: displayName ?? this.displayName,
      description: description ?? this.description,
    );
  }

  @override
  String toString() {
    return 'QueueConfig(type: $type, id: $id, duration: $defaultDuration, prefix: $collectionPrefix)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QueueConfig &&
        other.type == type &&
        other.id == id &&
        other.defaultDuration == defaultDuration &&
        other.collectionPrefix == collectionPrefix;
  }

  @override
  int get hashCode {
    return type.hashCode ^
        id.hashCode ^
        defaultDuration.hashCode ^
        collectionPrefix.hashCode;
  }
}

/// Factory for creating queue configurations
class QueueConfigFactory {
  /// Create spotlight queue configuration
  static QueueConfig createSpotlightConfig() {
    return const QueueConfig(
      type: QueueType.spotlight,
      id: 'spotlight',
      defaultDuration: 20,
      collectionPrefix: 'spotlight',
      displayName: 'Spotlight',
      description: 'Main spotlight queue for live streaming',
    );
  }

  /// Create city queue configuration
  static QueueConfig createCityConfig(String cityId, String cityName) {
    return QueueConfig(
      type: QueueType.city,
      id: cityId,
      defaultDuration: 20,
      collectionPrefix: 'city',
      requiresGeolocation: true,
      displayName: cityName,
      description: 'City-specific queue for $cityName',
    );
  }

  /// Create nearby queue configuration
  static QueueConfig createNearbyConfig(String locationId) {
    return QueueConfig(
      type: QueueType.nearby,
      id: locationId,
      defaultDuration: 20,
      collectionPrefix: 'nearby',
      requiresGeolocation: true,
      displayName: 'Nearby',
      description: 'Location-based nearby queue',
    );
  }

  /// Create VLR queue configuration
  static QueueConfig createVLRConfig(String roomId, String roomName) {
    return QueueConfig(
      type: QueueType.vlr,
      id: roomId,
      defaultDuration: 20,
      collectionPrefix: 'vlr',
      displayName: roomName,
      description: 'VLR room queue: $roomName',
    );
  }

  /// Create local queue configuration
  static QueueConfig createLocalConfig(String locationId, String locationName) {
    return QueueConfig(
      type: QueueType.local,
      id: locationId,
      defaultDuration: 20,
      collectionPrefix: 'local',
      requiresGeolocation: true,
      displayName: locationName,
      description: 'Local queue for $locationName',
    );
  }

  /// Get configuration by type and ID
  static QueueConfig? getConfig(QueueType type, String id) {
    switch (type) {
      case QueueType.spotlight:
        return createSpotlightConfig();
      case QueueType.city:
        return createCityConfig(id, id); // Fallback to ID as name
      case QueueType.nearby:
        return createNearbyConfig(id);
      case QueueType.vlr:
        return createVLRConfig(id, id); // Fallback to ID as name
      case QueueType.local:
        return createLocalConfig(id, id); // Fallback to ID as name
    }
  }

  /// Get all available queue types
  static List<QueueType> get availableQueueTypes => QueueType.values;

  /// Get display name for queue type
  static String getDisplayName(QueueType type) {
    switch (type) {
      case QueueType.spotlight:
        return 'Spotlight';
      case QueueType.city:
        return 'City';
      case QueueType.nearby:
        return 'Nearby';
      case QueueType.vlr:
        return 'VLR';
      case QueueType.local:
        return 'Local';
    }
  }

  /// Get description for queue type
  static String getDescription(QueueType type) {
    switch (type) {
      case QueueType.spotlight:
        return 'Main spotlight queue for live streaming';
      case QueueType.city:
        return 'City-specific queue based on location';
      case QueueType.nearby:
        return 'Location-based nearby queue';
      case QueueType.vlr:
        return 'VLR room-specific queue';
      case QueueType.local:
        return 'Local area queue';
    }
  }
} 