# Firebase Phone Auth Debugging Guide

This guide helps you troubleshoot Firebase Phone Authentication issues in the Spotlight app.

## 🔍 **Debugging Steps**

### 1. **Check Console Logs**
Run the app and look for these log prefixes:
- `🚀 [MAIN]` - Firebase initialization logs
- `🧪 [TEST]` - Firebase Auth test logs  
- `🔥 [AUTH]` - Authentication process logs
- `📱 [UI]` - UI interaction logs

### 2. **Test Firebase Configuration**
1. Open the app and go to the Welcome page
2. Tap "Test Firebase Auth" button
3. Check console for test results
4. Look for any error messages

### 3. **Common Issues & Solutions**

#### **Issue: "Firebase not initialized"**
**Symptoms:**
- App crashes on startup
- `🚀 [MAIN] Firebase initialization failed` in logs

**Solutions:**
1. Check `firebase_options.dart` file exists and is correct
2. Verify Firebase project configuration
3. Ensure all required dependencies are installed

#### **Issue: "Phone Auth not enabled"**
**Symptoms:**
- `🔥 [AUTH] Error code: auth/operation-not-allowed`
- `🔥 [AUTH] Error message: The given sign-in provider is disabled for this Firebase project`

**Solutions:**
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: `spotlight-33al5h`
3. Go to **Authentication** → **Sign-in method**
4. Enable **Phone** provider
5. Add test phone numbers if needed

#### **Issue: "Invalid phone number"**
**Symptoms:**
- `🔥 [AUTH] Error code: auth/invalid-phone-number`
- User sees "Invalid phone number format" message

**Solutions:**
1. Ensure phone number includes country code: `+1234567890`
2. Remove spaces, dashes, and parentheses
3. Use international format

#### **Issue: "Quota exceeded"**
**Symptoms:**
- `🔥 [AUTH] Error code: auth/quota-exceeded`
- User sees "SMS quota exceeded" message

**Solutions:**
1. Check Firebase project billing
2. Upgrade to Blaze plan for production
3. Add test phone numbers in Firebase Console

#### **Issue: "Too many requests"**
**Symptoms:**
- `🔥 [AUTH] Error code: auth/too-many-requests`
- User sees "Too many requests" message

**Solutions:**
1. Wait before retrying
2. Check rate limiting settings
3. Use test phone numbers for development

### 4. **Firebase Console Configuration**

#### **Enable Phone Authentication:**
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select project: `spotlight-33al5h`
3. Navigate to **Authentication** → **Sign-in method**
4. Click on **Phone**
5. Enable it and save

#### **Add Test Phone Numbers:**
1. In Phone provider settings
2. Add your test phone numbers
3. These will receive SMS codes without quota limits

#### **Check Project Settings:**
1. Go to **Project Settings**
2. Verify the project ID matches: `spotlight-33al5h`
3. Check that all platforms are configured

### 5. **Testing Checklist**

- [ ] Firebase initializes without errors
- [ ] Test Firebase Auth button works
- [ ] Phone number format is correct (with country code)
- [ ] Phone Auth provider is enabled in Firebase Console
- [ ] Test phone numbers are added (for development)
- [ ] Network connection is stable
- [ ] App has proper permissions

### 6. **Development vs Production**

#### **Development:**
- Use test phone numbers from Firebase Console
- These bypass SMS quotas
- Add your actual phone number for testing

#### **Production:**
- Requires Blaze (pay-as-you-go) plan
- Real SMS costs apply
- Configure proper billing

### 7. **Error Codes Reference**

| Error Code | Meaning | Solution |
|------------|---------|----------|
| `auth/invalid-phone-number` | Invalid phone format | Add country code (+1234567890) |
| `auth/operation-not-allowed` | Phone Auth disabled | Enable in Firebase Console |
| `auth/quota-exceeded` | SMS quota reached | Upgrade plan or add test numbers |
| `auth/too-many-requests` | Rate limited | Wait and retry |
| `auth/network-request-failed` | Network error | Check internet connection |

### 8. **Next Steps**

If you're still having issues:

1. **Check the console logs** for specific error messages
2. **Verify Firebase Console** settings
3. **Test with a known working phone number**
4. **Check network connectivity**
5. **Review Firebase project billing status**

## 📞 **Support**

If issues persist, check:
- Firebase Console logs
- App console output
- Network connectivity
- Firebase project configuration 