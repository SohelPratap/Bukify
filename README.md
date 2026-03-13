# 📦 Bukify

**Bukify** is a local service marketplace app that connects **customers** with **workers**. Customers can post jobs, discover nearby workers, and manage bookings — while workers can find jobs, showcase their skills, and set their service areas.

Built with **Flutter** on the frontend and **Express.js + MySQL** on the backend.

---

## ✨ Features

### For Customers
- 🔍 **Search Workers** — Find workers by skill and location
- 🗺️ **Map View** — Browse available workers on an interactive map
- 📝 **Post Jobs** — Create service requests with skill, address, title, and description
- 📋 **Job History** — Track active and past bookings
- 👤 **Profile Management** — Manage profile and saved addresses

### For Workers
- 🔍 **Search Jobs** — Discover jobs by skill and location
- 🗺️ **Nearby Jobs Map** — View jobs on an interactive map
- ⚡ **Latest Jobs Feed** — Stay up-to-date with new job postings
- 📍 **Service Area** — Set a working radius and center location
- 🟢 **Online Status** — Toggle availability and share real-time location
- 🛠️ **Skill Management** — Add and remove skills from your profile
- 📋 **Job History** — View completed and active jobs

### Common
- 🔐 **Authentication** — Register and log in with role selection (worker or customer)
- 🎫 **JWT Session Management** — Secure token-based authentication
- ⭐ **Ratings** — Worker rating system
- 📍 **Location Services** — GPS-based location and permission handling

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Mobile App** | Flutter (Dart) |
| **Backend API** | Express.js (Node.js) |
| **Database** | MySQL |
| **Auth** | JWT + bcrypt |
| **Maps** | flutter_map + OpenStreetMap |
| **Location** | geolocator + latlong2 |

---

## 📁 Project Structure

```
Bukify/
├── lib/                        # Flutter app source code
│   ├── main.dart               # App entry point
│   ├── onboarding/             # Splash, Login, Register screens
│   ├── auth/                   # Auth services & models
│   ├── customer/               # Customer pages & controllers
│   ├── worker/                 # Worker pages & controllers
│   ├── map/                    # Map page & widgets
│   ├── services/               # API service layer
│   ├── models/                 # Data models
│   ├── widgets/                # Reusable UI components
│   └── utils/                  # Helpers & utilities
├── assets/                     # Images and static resources
├── backend/                    # Express.js API server
│   ├── src/
│   │   ├── server.js           # Server entry point
│   │   ├── app.js              # Express app setup
│   │   ├── config/             # DB & env configuration
│   │   ├── controllers/        # Request handlers
│   │   ├── routes/             # API route definitions
│   │   ├── middlewares/        # Auth & role middleware
│   │   ├── services/           # Business logic
│   │   └── utils/              # Backend utilities
│   └── package.json
├── pubspec.yaml                # Flutter dependencies
└── .env                        # Frontend environment config
```

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK** ≥ 3.6.0 — [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Node.js** — [Install Node.js](https://nodejs.org/)
- **MySQL** — A running MySQL server

### 1. Clone the Repository

```bash
git clone https://github.com/SohelPratap/Bukify.git
cd Bukify
```

### 2. Backend Setup

```bash
cd backend
npm install
```

Create a `.env` file in the `backend/` directory:

```env
DB_HOST=localhost
DB_USER=your_db_user
DB_PASSWORD=your_db_password
DB_NAME=bukify_db
JWT_SECRET=your_jwt_secret
PORT=5050
```

Start the backend server:

```bash
# Development (with auto-reload)
npm run dev

# Production
npm start
```

The API server runs at `http://localhost:5050`.

### 3. Frontend Setup

From the project root:

```bash
flutter pub get
```

Create a `.env` file in the project root:

```env
API_BASE_URL=http://<your-server-ip>:5050
```

Run the app:

```bash
# On a connected device or emulator
flutter run

# On web
flutter run -d chrome
```

### 4. Build for Production

```bash
flutter build apk        # Android APK
flutter build appbundle   # Android App Bundle
flutter build ios         # iOS
flutter build web         # Web
```

---

## 🔌 API Endpoints

All routes (except auth and health) require a JWT token in the `Authorization: Bearer <token>` header.

### Auth
| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/auth/register` | Register a new user |
| `POST` | `/auth/login` | Log in and receive a JWT token |

### Jobs
| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/api/jobs` | Create a new job |
| `GET` | `/api/jobs/search` | Search jobs by skill and location |
| `GET` | `/api/jobs/latest` | Get latest job listings |
| `GET` | `/api/jobs/nearby` | Get jobs near a location |
| `PUT` | `/api/jobs/:id/accept` | Accept a job (worker) |
| `PUT` | `/api/jobs/:id/status` | Update job status |
| `GET` | `/api/jobs/history` | Get job history |

### Workers
| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/worker/profile` | Get worker profile |
| `PUT` | `/api/worker/status` | Toggle online/offline status |
| `GET` | `/api/worker/service-area` | Get service area |
| `PUT` | `/api/worker/service-area` | Update service area |
| `POST` | `/api/worker/skills` | Add a skill |
| `DELETE` | `/api/worker/skills/:id` | Remove a skill |
| `GET` | `/api/workers/search` | Search workers by skill/location |

### Customers
| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/customer/profile` | Get customer profile |
| `GET` | `/api/customer/addresses` | Get saved addresses |
| `POST` | `/api/customer/addresses` | Add a new address |

### Skills & Location
| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/skills/search` | Search available skills |
| `POST` | `/api/location/update` | Update user location |

---

## 🏗️ Architecture

```
┌──────────────────────────────────────┐
│           Flutter App (Client)       │
│  ┌────────────────────────────────┐  │
│  │  UI Layer (Pages & Widgets)    │  │
│  ├────────────────────────────────┤  │
│  │  Service Layer (API Calls)     │  │
│  ├────────────────────────────────┤  │
│  │  Storage (SecureStorage/Prefs) │  │
│  └────────────────────────────────┘  │
└──────────────┬───────────────────────┘
               │ REST API (HTTP)
┌──────────────▼───────────────────────┐
│        Express.js Backend            │
│  ┌────────────────────────────────┐  │
│  │  Routes → Controllers          │  │
│  ├────────────────────────────────┤  │
│  │  Middleware (Auth + Role)       │  │
│  ├────────────────────────────────┤  │
│  │  Services (Business Logic)      │  │
│  └────────────────────────────────┘  │
└──────────────┬───────────────────────┘
               │ SQL
┌──────────────▼───────────────────────┐
│          MySQL Database              │
└──────────────────────────────────────┘
```

---

## 📄 License

This project is open source. Feel free to use and modify it.
