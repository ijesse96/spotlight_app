class AgoraConfig {
  // Replace this with your actual Agora App ID from https://console.agora.io/
  static const String appId = "2ab023a28a2a4820b4bba8c5ee2ec047";
  
  // For production, you should use a token server
  // For testing, you can leave this as null (but it's not secure for production)
  static const String? token = null;
  
  // Channel name for the spotlight feature
  static const String spotlightChannel = "spotlight_main";
  
  // For testing - use temporary token (valid for 24 hours)
  static const bool useTemporaryToken = true;
  
  // TODO: Add your Agora App Certificate here for production
  // You can find this in your Agora Console under Project Management > Config
  static const String appCertificate = "340bde092a5348e68b31b138d3ab4aff";
} 