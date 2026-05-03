# 📵 SilentZone  
![Flutter](https://img.shields.io/badge/Flutter-3.x-blue)
![Dart](https://img.shields.io/badge/Dart-3.x-blue)
![Android](https://img.shields.io/badge/Android-App-green)
![Geofencing](https://img.shields.io/badge/GPS-Geofencing-orange)
![Architecture](https://img.shields.io/badge/Architecture-Service--Based-red)

A Smart GPS-Based Silent Zone Tracker for Automatic Phone Silence Management

SilentZone is a location-aware mobile application that automatically detects when a user enters predefined or custom silent zones (like hospitals, schools, or religious places) and manages the phone’s ringer mode accordingly.

Built using Flutter, SilentZone leverages GPS geofencing and native Android integration to create a seamless, automated silent experience.

---

##  Problem Statement

Mobile phones frequently cause disturbances in sensitive environments because users forget to silence them manually.

- No location-based automatic silence system
- Manual muting is unreliable
- Existing solutions rely on schedules, not real-world location
- Disturbances in hospitals, classrooms, and religious places

SilentZone solves this by automating silence based on **real-time GPS location**.

---

##  Features

- 📍 Real-Time GPS Tracking  
- 🔕 Automatic Silent Mode (Auto-Silence)  
- 🔔 Smart Push Notifications with Vibration  
- 🗺️ Interactive Map (OpenStreetMap)  
- 📌 Predefined Silent Zones (Mumbai-based)  
- ➕ Custom Zone Creation (Long Press on Map)  
- 💾 Local Storage using SharedPreferences  
- ⚡ Battery Efficient (10m distance filter)  
- 🔐 Do Not Disturb Permission Handling  
- 📊 Zone Categories (Hospital, School, Religious, Custom)  

---

##  Tech Stack

- **Framework:** Flutter (Dart)  
- **Maps:** OpenStreetMap (flutter_map)  
- **Location:** Geolocator  
- **Notifications:** flutter_local_notifications  
- **Storage:** SharedPreferences  
- **Permissions:** permission_handler  
- **Native Android:** Kotlin + AudioManager API  

---

##  Architecture

SilentZone follows a **Service-Oriented Architecture**:

- **UI Layer:** Flutter Widgets (Map + Controls)
- **Service Layer:**
  - LocationService → GPS + Zone Detection
  - NotificationService → Alerts & Vibration
  - ZonesStorageService → Data Persistence
- **Data Layer:** Zone Models + Local Storage

This modular approach ensures scalability and maintainability.

---

##  Core Working (Geofencing)

SilentZone uses the **Haversine Formula** to calculate distance between user location and zone center.

When:
- Distance < Zone Radius → User is INSIDE zone → Silent Mode Triggered  
- Distance > Zone Radius → User exits → Sound Restored  

---

##  Screenshots

> Add your screenshots here (replace with your GitHub image links)

| Map View | Notification | Zone Detection |
|---------|-------------|----------------|
| <img src="your-image-link" width="250"/> | <img src="your-image-link" width="250"/> | <img src="your-image-link" width="250"/> |

---

##  How It Works

1. App continuously tracks user GPS  
2. Compares location with stored zones  
3. Detects entry/exit events  
4. Sends notification + vibration  
5. Automatically switches phone to silent mode  
6. Restores sound when user exits  

---

##  Predefined Zones

Includes real locations like:
- Hospitals (Lilavati, Nanavati, KEM)
- Colleges (Somaiya, IIT Bombay)
- Religious Sites (Siddhivinayak, Haji Ali)

---

##  Future Enhancements

-  Cloud-based zone sync  
-  AI-based smart silence prediction  
-  Calendar integration  
-  iOS support with Focus Modes  
-  Background service optimization  

