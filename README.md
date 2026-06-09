

🎓 Smart Lost & Found System for Campus

An AI-Powered Asset Recovery Ecosystem for the University of Gujrat (UOG)

Flutter Django TensorFlow PostgreSQL

🚀 Overview

The Smart Lost & Found System is a full-stack, cross-platform solution designed
to automate asset recovery within academic environments. Traditionally,
universities rely on manual logbooks or unorganized social media groups. This
system introduces Artificial Intelligence to automatically categorize items and
a Weighted Heuristic Matching Engine to connect finders with owners in
real-time.

## 📸 Application Interface

### 1️⃣ Onboarding & Security
| Onboarding UI | User Registration | Secure Authentication |
| :---: | :---: | :---: |
| <img src="screenshots/Wellcome.png" width="220"> | <img src="screenshots/register.png" width="220"> | <img src="screenshots/login.png" width="220"> |
| **Welcome Screen** | **Student Enrollment** | **JWT-Based Login** |

### 2️⃣ Core Features & AI Reporting
| Dynamic Dashboard | Found Item Ingest | Lost Item Submission |
| :---: | :---: | :---: |
| <img src="screenshots/home.png" width="220"> | <img src="screenshots/report_found.png" width="220"> | <img src="screenshots/report_lost.png" width="220"> |
| **Real-time Feed** | **Found Report (AI)** | **Lost Report (AI)** |

### 3️⃣ Interaction & System Management
| AI Match Alerts | User Account | Privacy Settings | My Activity |
| :---: | :---: | :---: | :---: |
| <img src="screenshots/notification.png" width="180"> | <img src="screenshots/profile.png" width="180"> | <img src="screenshots/setting.png" width="180"> | <img src="screenshots/activity.png" width="180"> |
| **Smart Notifications** | **User Profile** | **Preference Control** | **Transaction History** |



🛠 Technical Architecture

The system utilizes a Decoupled 3-Tier Architecture:

1.  Frontend (Flutter): A single codebase for Android and Web utilizing
    Material 3 design and Provider state management.
2.  Backend (Django REST): A Python-based logic layer handling AI inference,
    matching algorithms, and SMTP email services.
3.  Database (Polyglot Persistence):
      - PostgreSQL: For relational data integrity (Claims, Items, Audit Logs).
      - Firebase: For real-time chat synchronization and cloud messaging.

✨ Key Features

  - AI Image Recognition: Automatically extracts item category and color labels
    using MobileNetV2.
  - Weighted Matching: Similarity scoring (Score \ge 60\%) based on AI tags,
    keywords, and location.
  - Real-time Synchronization: Instant chat and notifications via Firebase
    Firestore/FCM.
  - Administrative Oversight: A mediated verification protocol for security
    staff to audit claims.
  - Privacy Guard: Conditional visibility for personal contact details.

📂 Project Structure

  - Uogcampus_backend/: Core Django REST API & AI Service logic.
  - smart_lost_and_found_system_for_campus/: Flutter Mobile & Web client code.
  - screenshots/: High-fidelity UI mockups and app captures.

🧑‍💻 Development Team

  - Abdul Shakoor (@abdulshakoor7) - Full Stack Developer & DevOps
  - Supervised by: Dr. Safi Ullah
