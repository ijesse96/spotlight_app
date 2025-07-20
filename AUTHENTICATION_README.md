# Firebase Phone Authentication Flow

This document describes the complete Firebase phone number authentication flow implemented in the Spotlight app.

## Overview

The authentication flow consists of the following steps:

1. **Welcome Page** - Initial landing page with app introduction
2. **Phone Input** - User enters their phone number
3. **OTP Verification** - User enters the 6-digit SMS code
4. **User Registration** - New users provide name and username
5. **Main App** - Authenticated users access the main application

## Flow Details

### 1. Welcome Page (`welcome_page.dart`)
- Displays app logo and welcome message
- "Get Started" button initiates phone authentication
- "Skip for now" option for demo purposes

### 2. Phone Input Page (`phone_input_page.dart`)
- User enters their phone number
- Validates phone number format
- Sends SMS verification code via Firebase Auth
- Navigates to OTP verification page

### 3. OTP Verification Page (`otp_verification_page.dart`)
- 6-digit code input with auto-focus
- Verifies SMS code with Firebase Auth
- Checks if user exists in Firestore `/users` collection
- Routes to registration (new users) or main app (existing users)

### 4. User Registration Page (`user_registration_page.dart`)
- Collects user's full name and username
- Validates username availability
- Creates user document in Firestore with:
  - UID (from Firebase Auth)
  - Phone number
  - Name
  - Username
  - Creation timestamp
- Navigates to main app upon completion

### 5. Authentication Wrapper (`auth_wrapper.dart`)
- Manages authentication state using Firebase Auth streams
- Automatically routes users based on authentication status
- Handles loading states and error scenarios

## Firebase Configuration

### Required Services
- **Firebase Authentication** - Phone number authentication
- **Cloud Firestore** - User data storage

### Firestore Structure
```
/users/{uid}
├── uid: string
├── phoneNumber: string
├── name: string
├── username: string
├── createdAt: timestamp
└── updatedAt: timestamp
```

## Services

### AuthService (`auth_service.dart`)
- Phone number verification
- OTP code verification
- User document creation
- Authentication state management
- Sign out functionality

### UserService (`user_service.dart`)
- User profile management
- Username availability checking
- Profile updates
- User data retrieval

## Security Rules

Ensure your Firestore security rules allow authenticated users to read/write their own data:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Features

- ✅ Complete phone authentication flow
- ✅ User profile creation with name and username
- ✅ Username availability checking
- ✅ Automatic routing based on authentication state
- ✅ Sign out functionality
- ✅ Error handling and user feedback
- ✅ Loading states and validation
- ✅ Modern UI with consistent styling

## Usage

1. Configure Firebase in your project
2. Enable Phone Authentication in Firebase Console
3. Set up Firestore database
4. Configure security rules
5. Test the authentication flow

## Notes

- Phone numbers should include country code (e.g., +1234567890)
- Username validation allows letters, numbers, and underscores only
- Users can sign out from the Settings page
- The app maintains authentication state across sessions 