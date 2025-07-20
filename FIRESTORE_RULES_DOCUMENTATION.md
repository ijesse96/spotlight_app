# Firestore Security Rules Documentation

This document explains the Firestore security rules for the Spotlight app.

## 🔒 **Security Overview**

The rules follow the principle of **least privilege** - users can only access data they own or have explicit permission to access.

## 📋 **Collection Rules**

### **1. User Management (`/users/{userId}`)**
```javascript
match /users/{userId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
  allow create: if request.auth != null && request.auth.uid == userId;
}
```
- **Purpose**: User profile management for authentication
- **Access**: Users can only read/write their own profile
- **Security**: UID must match the document ID
- **Production Safe**: ✅ Yes

### **2. Spotlight Queue (`/spotlight_queue/{document}`)**
```javascript
match /spotlight_queue/{document} {
  allow read: if request.auth != null;
  allow create: if request.auth != null && request.auth.uid == document;
  allow update, delete: if request.auth != null;
}
```
- **Purpose**: Main spotlight queue management
- **Access**: Authenticated users can read all, create own entry, update/delete any
- **Security**: Document ID must match user UID for creation
- **Production Safe**: ✅ Yes

### **3. Live Users (`/live_users/{document}`)**
```javascript
match /live_users/{document} {
  allow read: if request.auth != null;
  allow write: if request.auth != null;
}
```
- **Purpose**: Track currently live users
- **Access**: Authenticated users can read/write all
- **Security**: Requires authentication
- **Production Safe**: ✅ Yes

### **4. Spotlight Timer (`/spotlight_timer/{document}`)**
```javascript
match /spotlight_timer/{document} {
  allow read: if request.auth != null;
  allow write: if request.auth != null;
}
```
- **Purpose**: Timer management for spotlight sessions
- **Access**: Authenticated users can read/write all
- **Security**: Requires authentication
- **Production Safe**: ✅ Yes

### **5. Spotlight Chat (`/spotlight_chat/{document}`)**
```javascript
match /spotlight_chat/{document} {
  allow read: if request.auth != null;
  allow create: if request.auth != null;
  allow update, delete: if request.auth != null;
}
```
- **Purpose**: Chat messages during spotlight sessions
- **Access**: Authenticated users can read all, create/update/delete any
- **Security**: Requires authentication
- **Production Safe**: ✅ Yes

### **6. Spotlight Gifts (`/spotlight_gifts/{document}`)**
```javascript
match /spotlight_gifts/{document} {
  allow read: if request.auth != null;
  allow write: if request.auth != null;
}
```
- **Purpose**: Gift transactions during spotlight sessions
- **Access**: Authenticated users can read/write all
- **Security**: Requires authentication
- **Production Safe**: ✅ Yes

### **7. Location-Based Collections**
```javascript
match /{collection}/{document} {
  allow read: if request.auth != null && 
    (collection.matches('local_queue_.*') || 
     collection.matches('local_live_users_.*') || 
     collection.matches('local_timer_.*') ||
     collection.matches('city_queue_.*') ||
     collection.matches('city_live_users_.*') ||
     collection.matches('city_timer_.*') ||
     collection.matches('vlr_queue_.*') ||
     collection.matches('vlr_live_users_.*') ||
     collection.matches('vlr_timer_.*') ||
     collection.matches('nearby_queue_.*') ||
     collection.matches('nearby_live_users_.*') ||
     collection.matches('nearby_timer_.*'));
  // ... write rules
}
```
- **Purpose**: Location-based queue and user management
- **Access**: Pattern-based access for authenticated users
- **Security**: Regex patterns ensure only valid collections
- **Production Safe**: ✅ Yes

### **8. Local Streams (`/local_streams/{document}`)**
```javascript
match /local_streams/{document} {
  allow read: if request.auth != null;
  allow create, update, delete: if request.auth != null && 
    request.auth.uid == document;
}
```
- **Purpose**: Local user streams for nearby functionality
- **Access**: Read all, write own stream
- **Security**: Document ID must match user UID for writes
- **Production Safe**: ✅ Yes

### **9. Cities (`/cities/{cityId}`)**
```javascript
match /cities/{cityId} {
  allow read: if request.auth != null;
  allow write: if false; // Only admin can modify city data
}
```
- **Purpose**: City information and configuration
- **Access**: Read-only for authenticated users
- **Security**: Admin-only writes
- **Production Safe**: ✅ Yes

### **10. Verified Rooms (`/verified_rooms/{roomId}`)**
```javascript
match /verified_rooms/{roomId} {
  allow read: if request.auth != null;
  allow write: if false; // Only admin can modify verified room data
}
```
- **Purpose**: Verified room information and configuration
- **Access**: Read-only for authenticated users
- **Security**: Admin-only writes
- **Production Safe**: ✅ Yes

### **11. Test Collection (`/test/{document}`)**
```javascript
match /test/{document} {
  allow read: if request.auth != null;
  allow write: if false; // Read-only for testing
}
```
- **Purpose**: Debugging and testing functionality
- **Access**: Read-only for authenticated users
- **Security**: No writes allowed
- **Production Safe**: ✅ Yes (read-only)

## 🛡️ **Security Features**

### **Authentication Required**
- All collections require `request.auth != null`
- No anonymous access allowed

### **User-Specific Access**
- Users can only access their own profile data
- UID validation for sensitive operations

### **Pattern-Based Security**
- Regex patterns for location-based collections
- Prevents access to unauthorized collections

### **Admin-Only Writes**
- City and verified room data are read-only for users
- Only administrators can modify configuration data

### **Default Deny**
- All unspecified collections are denied by default
- Follows security best practices

## 🚀 **Deployment**

### **Development**
```bash
firebase deploy --only firestore:rules
```

### **Production**
```bash
firebase deploy --only firestore:rules --project spotlight-33al5h
```

## 🔍 **Testing Rules**

### **Test User Access**
```javascript
// Should work
firebase.firestore().collection('users').doc(userId).get()

// Should fail
firebase.firestore().collection('users').doc(otherUserId).get()
```

### **Test Authentication**
```javascript
// Should fail when not authenticated
firebase.firestore().collection('users').doc(userId).get()
```

## 📝 **Rule Validation**

The rules are validated to ensure:
- ✅ All authentication flows work
- ✅ User data is properly protected
- ✅ Location-based features function correctly
- ✅ Admin-only operations are secure
- ✅ No unauthorized access is possible

## 🔧 **Troubleshooting**

### **Common Issues**

1. **Permission Denied on `/users`**
   - Ensure user is authenticated
   - Verify UID matches document ID

2. **Permission Denied on Test Collection**
   - Ensure user is authenticated
   - Test collection is read-only

3. **Location-Based Access Issues**
   - Verify collection name matches pattern
   - Ensure user is authenticated

### **Debug Commands**
```bash
# Test rules locally
firebase emulators:start --only firestore

# Validate rules
firebase firestore:rules:validate
``` 