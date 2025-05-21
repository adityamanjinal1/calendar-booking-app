
# 📅 Calendar Booking System

A full-stack calendar booking application built with **Flutter (frontend)** and **Node.js (backend)**.  
It allows users to create, edit, view, and delete meeting bookings with time conflict validation.

---

## ✨ Features

- Create, edit, and delete bookings
- Select date & time in **local time** (IST)
- Real-time conflict detection
- Frontend & backend validation
- RESTful API with full **Swagger docs**
- Responsive UI using **Material 3**
-  Safe backend with **mutex-based concurrency control**

---

##  Tech Stack

| Layer    | Tech            |
|----------|-----------------|
| Frontend | Flutter Web     |
| Backend  | Node.js |
| Docs     | Swagger (OpenAPI) |
| Concurrency | async-mutex |

---

## 🚀 Getting Started



### 1. Setup Backend (Node.js)

#### 📁 Go to `calendar_backend/` folder

```bash
cd calendar_backend
```

#### 📦 Install dependencies

```bash
npm install
```

#### ▶️ Start the server

```bash
node index.js
```

✅ API runs at: [http://localhost:3000](http://localhost:3000)  
📚 Swagger docs: [http://localhost:3000/api-docs](http://localhost:3000/api-docs)

---

### 2. Setup Frontend (Flutter)

#### 📁 Go to `lib/` folder (where `main.dart` is)


```bash
cd C:\calender_api
```

#### ✅ Enable web support (only needed once)

```bash
flutter config --enable-web
```

#### 🛠 Get dependencies

```bash
flutter pub get
```

#### ▶️ Run on Chrome

```bash
flutter run -d chrome
```

✅ Frontend loads in your browser (e.g., at http://localhost:12345)

---

## 📁 Folder Structure

```
calender_api/
│
├── calendar_backend/
│   ├── index.js         # Node.js backend
│   ├── package.json
│
├── lib/
│   └── main.dart        # Flutter frontend code
│
├── pubspec.yaml         # Flutter project config
├── README.md
```

---

## ✅ API Endpoints

| Method | Endpoint         | Description             |
|--------|------------------|-------------------------|
| GET    | `/bookings`      | List all bookings       |
| GET    | `/bookings/:id`  | Get booking by ID       |
| POST   | `/bookings`      | Create new booking      |
| PUT    | `/bookings/:id`  | Update existing booking |
| DELETE | `/bookings/:id`  | Delete booking          |

View complete docs at: [http://localhost:3000/api-docs](http://localhost:3000/api-docs)

---

## ⚠️ Notes

- All times are in **local time** (based on device time zone, e.g., IST)
- Backend is in-memory only — all data resets on server restart
- Add DB support (e.g. MongoDB) for production use

---


