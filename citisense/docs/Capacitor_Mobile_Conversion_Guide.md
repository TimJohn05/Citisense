# Converting a Web App to a Mobile Application with Capacitor

This guide explains how to transform any modern web application (HTML/JS/CSS) into a native mobile application (APK or IPA) using **Capacitor**.

---

## 1. What is Capacitor?
Capacitor is a cross-platform native runtime that allows you to turn any web project into a native iOS or Android app. It provides a "bridge" between the web code and the native mobile platform.

---

## 2. Prerequisites
Before starting, ensure you have the following installed:
*   **Node.js & NPM**: To manage packages and the build process.
*   **Android Studio**: For building Android APKs.
*   **Xcode**: (Mac only) For building iOS apps.

---

## 3. Step-by-Step Conversion Process

### Step A: Initialize Capacitor
Navigate to your project folder and install the Capacitor core and CLI:
```bash
npm install @capacitor/core @capacitor/cli
npx cap init [App Name] [Package ID] --web-dir [dist/build folder]
```
*   **App Name**: e.g., "CitiSense"
*   **Package ID**: e.g., "com.citisense.app" (Must be unique)
*   **Web Dir**: The folder where your production-ready web files are located (Vite uses `dist`).

### Step B: Build your Web Project
Before Capacitor can use your files, they must be compiled for production:
```bash
npm run build
```

### Step C: Add Mobile Platforms
Add the specific native projects you want to build for:
```bash
# For Android
npm install @capacitor/android
npx cap add android

# For iOS (Mac only)
npm install @capacitor/ios
npx cap add ios
```

### Step D: Syncing Code
Whenever you make a change to your JavaScript or CSS, you must "Sync" the files to the mobile folders:
```bash
npm run build
npx cap sync
```

---

## 4. Building the Final Binary

### For Android (APK)
1.  Open the project in Android Studio:
    ```bash
    npx cap open android
    ```
2.  Wait for Gradle to finish syncing.
3.  Go to **Build > Build Bundle(s) / APK(s) > Build APK(s)**.
4.  Locate the `.apk` in the folder suggested by the notification.

### For iOS (IPA)
1.  Open the project in Xcode:
    ```bash
    npx cap open ios
    ```
2.  Select your target device (or simulator).
3.  Click the **"Play"** button to run or **Product > Archive** to build the final app file.

---

## 5. Why use this method?
*   **Code Sharing**: 99% of your code is shared between the website, Android, and iOS.
*   **Performance**: Capacitor uses the system's native WebView, ensuring the app is fast and smooth.
*   **Access to Native APIs**: You can easily add features like Camera, GPS, and Push Notifications using Capacitor plugins.
