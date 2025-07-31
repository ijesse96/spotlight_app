import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import '../config/agora_config.dart';

class TokenService {
  static const int _privilegeExpiredTs = 86400; // 24 hours
  
  static String generateToken(String channelName, int uid) {
    final appId = AgoraConfig.appId;
    final appCertificate = _getAppCertificate(); // You'll need to add this
    
    if (appCertificate.isEmpty) {
      // For testing without certificate, return empty string (will use temporary token)
      return "";
    }
    
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final randomInt = Random().nextInt(100000);
    final uidStr = uid.toString();
    
    // Create message
    final message = "$appId$channelName$uidStr$timestamp$randomInt";
    
    // Generate signature
    final key = utf8.encode(appCertificate);
    final bytes = utf8.encode(message);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    final signature = base64.encode(digest.bytes);
    
    // Create token
    final token = "$appId:$signature:$timestamp:$randomInt:$uidStr";
    
    return token;
  }
  
  static String _getAppCertificate() {
    return AgoraConfig.appCertificate;
  }
  
  static String getTemporaryToken() {
    // For testing, we'll use a temporary token approach
    // In production, you should implement a proper token server
    return "";
  }
} 