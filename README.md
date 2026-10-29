# Task App 📱

A modern Flutter mobile application featuring Firebase Authentication and Cloud Firestore for user management and task workflows.

---

## 🚀 Features

- **User Registration & Validation**: Clean registration interface with input validation for Full Name, Email format, and Password strength.
- **Firebase Authentication**: Secure user account creation and authentication powered by Firebase Auth.
- **Cloud Firestore Integration**: Automatic creation and synchronization of user profile data (`users` collection) with timestamps.
- **Responsive Navigation**: Seamless navigation between Register, Login, Forgot Password, and Home Dashboard screens.
- **Error Handling & Feedback**: User-friendly alerts and SnackBars for authentication exceptions (e.g., email already in use, weak passwords).

---

## 🛠️ Tech Stack

- **Frontend:** [Flutter](https://flutter.dev/) (Dart SDK `^3.12.1`)
- **Backend / BaaS:** [Firebase](https://firebase.google.com/)
  - **Firebase Authentication** (`firebase_auth`)
  - **Cloud Firestore** (`cloud_firestore`)
  - **Firebase Core** (`firebase_core`)
- **Design System:** Material Design 3

---

## 📂 Project Structure

```text
lib/
├── firebase_options.dart       # Firebase platform configurations
├── main.dart                   # Application entry point & theme setup
├── home_page/
│   └── home_page.dart          # Home dashboard screen
└── user/
    ├── auth_services.dart      # Firebase Auth & Firestore user service
    ├── forget_password.dart    # Password recovery screen
    ├── loging_page.dart        # User sign-in screen
    ├── registation.dart        # User registration form & UI
    └── user_model.dart         # User data model with Firestore mapping
```

---

## 🏁 Getting Started

### Prerequisites

Ensure you have the following installed on your machine:

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (version 3.12+ / 3.44+)
- [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/) with Flutter/Dart extensions
- Git

### Installation & Setup

1. **Clone the repository:**

   ```bash
   git clone https://github.com/Ganidu2004/task_app01.git
   cd task_app01
   ```

   _(or navigate to `task_app` folder)_

2. **Install dependencies:**

   ```bash
   flutter pub get
   ```

3. **Configure Firebase:**
   - Ensure your `google-services.json` is located in `android/app/`.
   - Alternatively, configure with the FlutterFire CLI:
     ```bash
     flutterfire configure
     ```

4. **Run the Application:**

   ```bash
   flutter run
   ```

5. **Build APK for Android:**
   ```bash
   flutter build apk --debug
   ```

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](https://github.com/Ganidu2004/task_app01/issues).

---

## 📄 License

This project is open-source and available under the [MIT License](LICENSE).
