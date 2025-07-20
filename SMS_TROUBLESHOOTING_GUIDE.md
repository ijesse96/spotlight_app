# SMS Troubleshooting Guide

This guide helps you troubleshoot why SMS verification codes are not being received.

## 🔍 **Step-by-Step Debugging**

### **1. Check Console Logs**
Run the app and look for these specific log messages:

```
🔥 [AUTH] Starting phone verification for: +1234567890
🔥 [AUTH] Code sent successfully!
🔥 [AUTH] Verification ID: abc123def4...
```

**If you see "Code sent successfully!" but no SMS:**
- The issue is with SMS delivery, not Firebase configuration
- Continue to step 2

**If you see error messages:**
- Check the specific error code and message
- Refer to the error codes section below

### **2. Verify Firebase Console Settings**

#### **Enable Phone Authentication:**
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: `spotlight-33al5h`
3. Navigate to **Authentication** → **Sign-in method**
4. Click on **Phone**
5. **Enable** the provider
6. **Save** the changes

#### **Add Test Phone Numbers:**
1. In the Phone provider settings
2. Scroll down to **Phone numbers for testing**
3. Click **Add phone number**
4. Add your actual phone number
5. **Save** the changes

**Important:** Test phone numbers bypass SMS quotas and should receive codes immediately.

### **3. Check Phone Number Format**

#### **Correct Format Examples:**
- ✅ `+1234567890` (US)
- ✅ `+447911123456` (UK)
- ✅ `+61412345678` (Australia)
- ✅ `+919876543210` (India)

#### **Incorrect Format Examples:**
- ❌ `1234567890` (missing +)
- ❌ `+1 234 567 890` (spaces)
- ❌ `+1-234-567-890` (dashes)
- ❌ `(123) 456-7890` (parentheses)

### **4. Check Android Configuration**

#### **Verify SHA-1 Fingerprint:**
1. Get your app's SHA-1 fingerprint:
   ```bash
   cd android
   ./gradlew signingReport
   ```
2. Copy the SHA-1 value
3. Go to Firebase Console → Project Settings → Your Apps → Android
4. Add the SHA-1 fingerprint
5. Download the updated `google-services.json`
6. Replace the file in `android/app/`

#### **Check Permissions:**
Ensure these permissions are in `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

### **5. Test with Different Scenarios**

#### **Test 1: Use Test Phone Number**
1. Add your phone number to Firebase Console test numbers
2. Try the authentication flow
3. You should receive SMS immediately

#### **Test 2: Check Network**
1. Ensure device has internet connection
2. Try on WiFi and mobile data
3. Check if firewall is blocking requests

#### **Test 3: Try Different Phone Number**
1. Use a different phone number
2. Try a family member's number
3. Check if the issue is number-specific

### **6. Common Error Codes & Solutions**

| Error Code | Meaning | Solution |
|------------|---------|----------|
| `auth/invalid-phone-number` | Invalid phone format | Add country code (+1234567890) |
| `auth/operation-not-allowed` | Phone Auth disabled | Enable in Firebase Console |
| `auth/quota-exceeded` | SMS quota reached | Add test numbers or upgrade plan |
| `auth/too-many-requests` | Rate limited | Wait and retry |
| `auth/network-request-failed` | Network error | Check internet connection |

### **7. Firebase Project Billing**

#### **Check Billing Status:**
1. Go to Firebase Console → Usage and billing
2. Check if project is on Blaze plan
3. Verify billing is set up correctly

#### **SMS Costs:**
- Free tier: Limited SMS per month
- Blaze plan: Pay per SMS (~$0.01 per SMS)
- Test numbers: Free, unlimited

### **8. Development vs Production**

#### **Development (Recommended):**
- Use test phone numbers from Firebase Console
- These bypass SMS quotas and costs
- Immediate delivery for testing

#### **Production:**
- Requires Blaze (pay-as-you-go) plan
- Real SMS costs apply
- May have delivery delays

### **9. Alternative Testing Methods**

#### **Use Firebase Emulator:**
```bash
# Start Firebase emulator
firebase emulators:start --only auth

# Update your app to use emulator
FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
```

#### **Use Test Phone Numbers:**
- Add your number to Firebase Console test numbers
- These receive SMS codes without quotas
- Perfect for development and testing

### **10. Debugging Checklist**

- [ ] Firebase Phone Auth is enabled
- [ ] Phone number format is correct (+1234567890)
- [ ] SHA-1 fingerprint is added to Firebase Console
- [ ] `google-services.json` is up to date
- [ ] Internet permissions are added to AndroidManifest.xml
- [ ] Test phone number is added to Firebase Console
- [ ] Project is on Blaze plan (for production)
- [ ] Network connection is stable
- [ ] No firewall blocking requests

### **11. Next Steps**

If you're still not receiving SMS:

1. **Add your phone number as a test number** in Firebase Console
2. **Check the console logs** for specific error messages
3. **Try with a different phone number**
4. **Verify Firebase project configuration**
5. **Contact Firebase support** if issues persist

## 📞 **Quick Test**

1. Add your phone number to Firebase Console test numbers
2. Run the app and try authentication
3. You should receive SMS within seconds
4. If still no SMS, check console logs for errors

## 🔧 **Emergency Fix**

If you need immediate testing:
1. Go to Firebase Console → Authentication → Sign-in method → Phone
2. Add your phone number to "Phone numbers for testing"
3. Try authentication again
4. SMS should arrive immediately 