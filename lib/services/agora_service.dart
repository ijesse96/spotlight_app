import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/agora_config.dart';
import 'token_service.dart';

class AgoraService {
  
  RtcEngine? _engine;
  bool _isInitialized = false;
  bool _isInChannel = false;
  int? _localUid;
  int? _remoteUid;
  
  // Video views
  Widget? _localVideoView;
  Widget? _remoteVideoView;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Create RTC Engine
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(const RtcEngineContext(appId: AgoraConfig.appId));
      
      // Enable video
      await _engine!.enableVideo();
      
      // Set video encoder configuration
      await _engine!.setVideoEncoderConfiguration(
        const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 640, height: 360),
          frameRate: 15,
          bitrate: 0,
        ),
      );
      
      // Set up event handlers
      _engine!.registerEventHandler(RtcEngineEventHandler(
                 onJoinChannelSuccess: (connection, elapsed) {
           print("🎥 SUCCESS: Joined channel: ${connection.channelId}");
           print("🎥 Connection details: localUid=${connection.localUid}, elapsed=$elapsed");
           _isInChannel = true;
           _localUid = connection.localUid;
           print("🎥 Local UID assigned: $_localUid");
           
           // Create local video view after successful join
           _createLocalVideoView();
         },
        onUserJoined: (connection, remoteUid, elapsed) {
          print("🎥 Remote user joined: $remoteUid");
          _remoteUid = remoteUid;
          
          // Create remote video view when remote user joins
          if (_remoteUid != null && _remoteUid != 0) {
            _remoteVideoView = AgoraVideoView(
              controller: VideoViewController.remote(
                rtcEngine: _engine!,
                canvas: VideoCanvas(uid: _remoteUid!),
                connection: RtcConnection(channelId: connection.channelId),
              ),
            );
            print("🎥 Remote video view created for UID: $_remoteUid");
            _notifyVideoViewChanged();
          }
        },
        onUserOffline: (connection, remoteUid, reason) {
          print("🎥 Remote user left: $remoteUid");
          _remoteUid = null;
          _remoteVideoView = null; // Clear remote video view
        },
        onLeaveChannel: (connection, stats) {
          print("🎥 Left channel: ${connection.channelId}");
          _isInChannel = false;
          _localUid = null;
          _remoteUid = null;
          _localVideoView = null; // Clear video views
          _remoteVideoView = null;
        },
        onError: (errorType, errorCode) {
          print("❌ Agora error: $errorType, code: $errorCode");
          if (errorType == ErrorCodeType.errInvalidToken) {
            print("🔑 Token error - this is expected for testing without a token server");
          }
        },
      ));
      
      _isInitialized = true;
      print("🎥 Agora service initialized successfully");
      
    } catch (e) {
      print("❌ Error initializing Agora: $e");
      rethrow;
    }
  }

  Future<void> joinChannel(String channelName) async {
    if (!_isInitialized || _engine == null) {
      await initialize();
    }
    
    try {
      // Request permissions
      final cameraStatus = await Permission.camera.request();
      final microphoneStatus = await Permission.microphone.request();
      
      if (cameraStatus.isDenied || microphoneStatus.isDenied) {
        print("❌ Camera or microphone permission denied");
        throw Exception("Camera or microphone permission denied");
      }
      
      print("🎥 Permissions granted, joining channel: $channelName");
      
      // Create video view immediately for testing
      print("🎥 Creating video view immediately...");
      _localVideoView = AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _engine!,
          canvas: const VideoCanvas(uid: 0),
        ),
      );
      _notifyVideoViewChanged();
      
      // Join channel with empty token
      print("🎥 Joining channel with empty token...");
      await _engine!.joinChannel(
        token: "",
        channelId: channelName,
        uid: 0,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        ),
      );
      
      print("🎥 Channel join request sent");
      
    } catch (e) {
      print("❌ Error joining channel: $e");
      rethrow;
    }
  }

  Future<void> leaveChannel() async {
    if (_engine != null && _isInChannel) {
      try {
        await _engine!.leaveChannel();
        _localUid = null;
        _remoteUid = null;
        print("🎥 Left channel successfully");
      } catch (e) {
        print("❌ Error leaving channel: $e");
      }
    }
  }

  Widget getLocalVideoView() {
    if (_localVideoView != null && _engine != null) {
      print("🎥 Returning local video view");
      return _localVideoView!;
    }
    
    // Try to create video view if engine is available
    if (_engine != null && _localVideoView == null) {
      print("🎥 Creating video view on demand...");
      _localVideoView = AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _engine!,
          canvas: const VideoCanvas(uid: 0),
        ),
      );
      return _localVideoView!;
    }
    
    // Fallback placeholder
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam, size: 64, color: Colors.white54),
            SizedBox(height: 16),
            Text(
              'Local Video Stream',
              style: TextStyle(color: Colors.white54, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'Initializing camera...',
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget getRemoteVideoView() {
    if (_remoteVideoView != null && _remoteUid != null && _isInChannel) {
      print("🎥 Returning remote video view for user: $_remoteUid");
      return _remoteVideoView!;
    }
    
    // Fallback placeholder
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off, size: 64, color: Colors.white54),
            SizedBox(height: 16),
            Text(
              'Remote Video Stream',
              style: TextStyle(color: Colors.white54, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'Waiting for streamer...',
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  void dispose() {
    try {
      if (_engine != null) {
        _engine!.leaveChannel();
        _engine!.release();
      }
      _isInitialized = false;
      _isInChannel = false;
      _localUid = null;
      _remoteUid = null;
      print("🎥 Agora service disposed");
    } catch (e) {
      print("❌ Error disposing Agora service: $e");
    }
  }

  bool get isInitialized => _isInitialized;
  bool get isInChannel => _isInChannel;
  int? get localUid => _localUid;
  int? get remoteUid => _remoteUid;
  
  void printStatus() {
    print("🎥 Agora Status:");
    print("  - Initialized: $_isInitialized");
    print("  - In Channel: $_isInChannel");
    print("  - Local UID: $_localUid");
    print("  - Remote UID: $_remoteUid");
    print("  - Local Video View: ${_localVideoView != null}");
    print("  - Remote Video View: ${_remoteVideoView != null}");
  }
  
  // Callback for UI updates
  Function? _onVideoViewChanged;
  
  void setVideoViewChangedCallback(Function callback) {
    _onVideoViewChanged = callback;
  }
  
  void _notifyVideoViewChanged() {
    if (_onVideoViewChanged != null) {
      _onVideoViewChanged!();
    }
  }
  
  void _createLocalVideoView() {
    if (_engine != null && _isInChannel && _localUid != null && _localUid != 0) {
      print("🎥 Creating local video view for UID: $_localUid");
      _localVideoView = AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _engine!,
          canvas: VideoCanvas(uid: _localUid!),
        ),
      );
      _notifyVideoViewChanged();
    } else {
      print("🎥 Cannot create local video view - engine: ${_engine != null}, inChannel: $_isInChannel, localUid: $_localUid");
    }
  }
} 