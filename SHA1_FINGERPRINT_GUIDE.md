# SHA-1 Fingerprint Guide for Firebase

This guide helps you get the SHA-1 fingerprint needed for Firebase Phone Authentication.

## 🔑 **Why SHA-1 is Needed**

Firebase requires your app's SHA-1 fingerprint to:
- Verify your app's identity
- Enable Phone Authentication
- Ensure SMS codes are sent to the correct app

## 🛠️ **Method 1: Using the PowerShell Script (Recommended)**

### **Step 1: Run the Script**
```powershell
# Navigate to android directory
cd android

# Run the script
.\get_sha1.ps1
```

### **Step 2: Follow the Output**
The script will:
- Set up Java environment
- Run gradlew signingReport
- Extract the SHA-1 fingerprint
- Show you the next steps

## 🛠️ **Method 2: Using Android Studio**

### **Step 1: Open Android Studio**
1. Open Android Studio
2. Open your project (navigate to the `android` folder)

### **Step 2: Access Gradle Tasks**
1. Go to **View** → **Tool Windows** → **Gradle**
2. Expand your project → **Tasks** → **android**
3. Double-click on **"signingReport"**

### **Step 3: Copy SHA-1**
1. Look for the output in the bottom panel
2. Find the line that says `SHA1: [40-character hex string]`
3. Copy the SHA-1 value

## 🛠️ **Method 3: Using keytool (Alternative)**

### **Step 1: Find Java Installation**
```powershell
# Check if Java is installed
java -version

# If not found, install Java JDK 17
winget install Oracle.JDK.17
```

### **Step 2: Set Environment Variables**
```powershell
# Set JAVA_HOME
$env:JAVA_HOME = "C:\Program Files\Java\jdk-17.0.12"

# Add Java to PATH
$env:PATH += ";C:\Program Files\Java\jdk-17.0.12\bin"
```

### **Step 3: Run keytool**
```powershell
# For debug keystore (development)
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# For release keystore (production)
keytool -list -v -keystore your-release-key.keystore -alias your-key-alias
```

## 🔧 **Method 4: Manual Gradle Command**

### **Step 1: Set Java Environment**
```powershell
$env:JAVA_HOME = "C:\Program Files\Java\jdk-17.0.12"
$env:PATH += ";C:\Program Files\Java\jdk-17.0.12\bin"
```

### **Step 2: Run Gradle**
```powershell
cd android
.\gradlew signingReport
```

### **Step 3: Extract SHA-1**
Look for the output line containing `SHA1:` and copy the 40-character hex string.

## 📋 **Adding SHA-1 to Firebase Console**

### **Step 1: Go to Firebase Console**
1. Visit [Firebase Console](https://console.firebase.google.com)
2. Select your project: `spotlight-33al5h`

### **Step 2: Project Settings**
1. Click the gear icon → **Project settings**
2. Scroll down to **Your apps**
3. Select your Android app

### **Step 3: Add SHA-1**
1. Click **Add fingerprint**
2. Paste your SHA-1 fingerprint
3. Click **Save**

### **Step 4: Download Updated Config**
1. Download the updated `google-services.json`
2. Replace the file in `android/app/`

## 🔍 **Troubleshooting**

### **Java Not Found**
```powershell
# Install Java
winget install Oracle.JDK.17

# Set environment variables
$env:JAVA_HOME = "C:\Program Files\Java\jdk-17.0.12"
$env:PATH += ";C:\Program Files\Java\jdk-17.0.12\bin"
```

### **Gradle Build Failed**
1. Clean the project: `.\gradlew clean`
2. Try again: `.\gradlew signingReport`

### **SHA-1 Not Found in Output**
1. Check if you're in the correct directory (android folder)
2. Ensure the project builds successfully
3. Try using Android Studio method instead

### **Multiple SHA-1 Values**
You might see multiple SHA-1 values:
- **Debug SHA-1**: For development (use this for testing)
- **Release SHA-1**: For production builds

## 📱 **Testing After Adding SHA-1**

### **Step 1: Rebuild App**
```bash
flutter clean
flutter pub get
flutter run
```

### **Step 2: Test Phone Auth**
1. Run the app
2. Go to phone input page
3. Enter phone number with country code
4. Tap "Debug Phone Auth" to test configuration
5. Try sending verification code

### **Step 3: Check Console Logs**
Look for:
```
🧪 [TEST] Firebase Auth configuration is working correctly
🔥 [AUTH] Code sent successfully!
```

## 🚨 **Common Issues**

### **Issue: "Invalid SHA-1"**
- Ensure you copied the entire 40-character SHA-1
- Check for extra spaces or characters
- Verify you're using the debug SHA-1 for development

### **Issue: "App not found"**
- Ensure you're in the correct Firebase project
- Check that the package name matches your app
- Verify the `google-services.json` file is up to date

### **Issue: "Phone Auth still not working"**
- Add your phone number to Firebase Console test numbers
- Ensure Phone Auth is enabled in Firebase Console
- Check that you're using the correct phone number format

## 📞 **Next Steps**

After adding the SHA-1:
1. **Test the app** with phone authentication
2. **Add your phone number** to Firebase Console test numbers
3. **Try sending verification codes**
4. **Check console logs** for any remaining issues

## 🔧 **Quick Reference**

```powershell
# Quick setup
$env:JAVA_HOME = "C:\Program Files\Java\jdk-17.0.12"
$env:PATH += ";C:\Program Files\Java\jdk-17.0.12\bin"
cd android
.\gradlew signingReport
``` 