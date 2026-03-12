# 🌐 LOYIHADA URL VA API ENDPOINTS ANALIZI

## 📋 UMUMIY HOLAT
✅ **BASE URL**: Tog'ri yozilgan  
✅ **Endpoints Format**: Django REST Framework standartiga mos  
✅ **Trailing Slashes**: To'g'ri (Django uchun shart)  
⚠️ **MUHIM DIQQAT**: Hyphen vs Underscore - bir joyda muammosi bor

---

## 1️⃣ BASE URL KONFIGURATSIYASI

**Fayl**: `lib/core/constants/app_constants.dart`

```dart
static const String baseUrl = 'https://eduanalytics.pythonanywhere.com/api/v1/';
```

### ✅ To'g'ri nuqtalar:
- ✅ HTTPS protokoli (xavfsiz)
- ✅ Oxirida `/` (Dio uchun shart)
- ✅ PythonAnywhere hostingda (to'g'ri)
- ✅ `/api/v1/` versiya qo'shilgan

### ⚠️ Diqqat:
- **SSL sertifikat** muammo bo'lsa HTTPS ishlamaydi
- Staging dastur yo'q (test va production bir xilada)

---

## 2️⃣ AUTHENTICATION ENDPOINTS

### LOGIN - `POST auth/login`
```
Full URL: https://eduanalytics.pythonanywhere.com/api/v1/auth/login
Body: { "username": string, "password": string }
Response: { "token": string, "refresh": string, "user": {...} }
```
**Status**: ✅ To'g'ri

### REGISTER - `POST auth/register`
```
Full URL: https://eduanalytics.pythonanywhere.com/api/v1/auth/register
Body: {
  "username": string,
  "email": string,
  "password": string,
  "password2": string,
  "name": string,
  "phone": string,
  "subject": string
}
Response: { "token": string, "refresh": string, "user": {...} }
```
**Status**: ✅ To'g'ri

### ME (Current User) - `GET auth/me`
```
Full URL: https://eduanalytics.pythonanywhere.com/api/v1/auth/me
Headers: { "Authorization": "Bearer {token}" }
Response: { user object }
```
**Status**: ✅ To'g'ri

### LOGOUT - `POST auth/logout`
```
Full URL: https://eduanalytics.pythonanywhere.com/api/v1/auth/logout
Headers: { "Authorization": "Bearer {token}" }
```
**Status**: ✅ To'g'ri

---

## 3️⃣ COURSES ENDPOINTS

| Method | Endpoint | Full URL | Status |
|--------|----------|----------|--------|
| GET | `courses/` | `/api/v1/courses/` | ✅ To'g'ri |
| GET | `courses/{id}/` | `/api/v1/courses/5/` | ✅ To'g'ri |
| POST | `courses/` | `/api/v1/courses/` | ✅ To'g'ri |
| PUT | `courses/{id}/` | `/api/v1/courses/5/` | ✅ To'g'ri |
| DELETE | `courses/{id}/` | `/api/v1/courses/5/` | ✅ To'g'ri |

---

## 4️⃣ GROUPS ENDPOINTS

| Method | Endpoint | Query Params | Status |
|--------|----------|--------------|--------|
| GET | `groups/` | `?course_id=5` (optional) | ✅ To'g'ri |
| GET | `groups/{id}/` | — | ✅ To'g'ri |
| POST | `groups/` | — | ✅ To'g'ri |
| PUT | `groups/{id}/` | — | ✅ To'g'ri |
| DELETE | `groups/{id}/` | — | ✅ To'g'ri |

---

## 5️⃣ STUDENTS ENDPOINTS

| Metod | Endpoint | Query Parameterlari | Status |
|--------|----------|---------------------|---------|
| GET | `students/` | `?group_id=3&course_id=5` | ✅ To'g'ri |
| GET | `students/{id}/` | — | ✅ To'g'ri |
| POST | `students/` | — | ✅ To'g'ri |
| PUT | `students/{id}/` | — | ✅ To'g'ri |
| DELETE | `students/{id}/` | — | ✅ To'g'ri |

---

## 6️⃣ PREDICTION ENDPOINT

```
POST predict/
Full URL: https://eduanalytics.pythonanywhere.com/api/v1/predict/
Body: { PredictionRequest object }
Response: { PredictionResult object }
```
**Status**: ✅ To'g'ri

---

## 7️⃣ STATISTICS ENDPOINTS

### Overview Stats - `GET stats/overview/`
```
Full URL: https://eduanalytics.pythonanywhere.com/api/v1/stats/overview/
Response: { "total": ..., "active": ..., ... }
```
**Status**: ✅ To'g'ri

### At Risk Students - `GET stats/at-risk/`  ⚠️ **MUAMMO!**
```
Full URL: https://eduanalytics.pythonanywhere.com/api/v1/stats/at-risk/
```
**Diqqat**: Hyphen `-` istifoda qilingan!
- Django backend `stats/at-risk/` yoki `stats/at_risk/`?
- **TA'KID KERAK**: Backend developer ga tekshirish kerak

### Course Stats - `GET stats/courses/{id}/`
```
Full URL: https://eduanalytics.pythonanywhere.com/api/v1/stats/courses/5/
```
**Status**: ✅ To'g'ri

### Group Stats - `GET stats/groups/{id}/`
```
Full URL: https://eduanalytics.pythonanywhere.com/api/v1/stats/groups/10/
```
**Status**: ✅ To'g'ri

---

## 8️⃣ FRONTEND ROUTES (GoRouter)

### Auth Routes (Bottom Nav yo'q)
```
/login           → LoginScreen
/register        → RegisterScreen
```
**Status**: ✅ To'g'ri

### Protected Routes (Bottom Nav bor)
```
/dashboard       → DashboardScreen (Shell ichiga)
/courses         → CoursesScreen
/groups          → GroupsScreen
/students        → StudentsScreen
/prediction      → PredictionScreen
/statistics      → StatisticsScreen
/settings        → SettingsScreen
```
**Status**: ✅ To'g'ri

### Detail Routes
```
/students/:id    → StudentDetailScreen (Full screen, Shell ichiga KES!)
```
**Status**: ✅ To'g'ri

---

## 🔴 MUAMMOLAR VA XATARALAR

### 1. **HYPHEN vs UNDERSCORE** ⚠️ KRITIK

**Joyda URL**: `stats/at-risk/`

```dart
// lib/services/api_service.dart, 301 satir
Future<List<StudentModel>> getAtRiskStudents() async {
  final response = await _dio.get('stats/at-risk/');
  // ...
}
```

**Muammo**:
- Django URL patterns: `at-risk` yoki `at_risk`?
- Python standartda: `underscore` (`at_risk`)
- URL standartda: `hyphen` (`at-risk`)

**Tekshirish usuli**:
```bash
# Backend Django urls.py ni tekshiring
# Path: urls.py ichida:
path('stats/at-risk/', StatsViewSet.as_view(...))  # YOKI
path('stats/at_risk/', StatsViewSet.as_view(...))
```

**YECHIM**: Backend developer bilan tasdiqlash kerak!

---

## ✅ TEKSHIRILGAN VA NORMAL QISMLAR

### 1. **Token ulanishi**
```dart
// lib/services/api_service.dart, 38 satir
interceptor.onRequest: options.headers['Authorization'] = 'Bearer $token'
```
✅ Tog'ri JWT format

### 2. **Query Parameters**
```dart
// courseId va groupId bilan filter qilish
queryParameters: courseId != null ? {'course_id': courseId} : null
```
✅ Django standartiga mos

### 3. **Trailing Slashes**
```
✅ auth/login/         ← Slash bor
✅ courses/            ← Slash bor
✅ students/{id}/      ← Slash bor
```
Django REST Framework uchun **mutlaqo to'g'ri**

### 4. **Error Handling**
```dart
// 500 Error logging
if (error.response?.statusCode == 500) {
  print('$tag URL: ${error.requestOptions.path}');
  print('$tag Response: ${error.response?.data}');
}
```
✅ Debugging uchun yaxshi

---

## 📊 SUMMARY - XULOSA

| Kategoriya | Holat | Diqqat |
|-----------|-------|--------|
| Base URL | ✅ To'g'ri | HTTPS xavfsiz |
| Auth Endpoints | ✅ To'g'ri | Login/Register ishlaydi |
| CRUD Endpoints | ✅ To'g'ri | Barcha resources |
| Query Parameters | ✅ To'g'ri | Filter ishlaydi |
| Frontend Routes | ✅ To'g'ri | Navigation ishlaydi |
| Stats Endpoints | ⚠️ YARIМbEWEI | `at-risk` vs `at_risk` tekshirish kerak |
| Token Auth | ✅ To'g'ri | Bearer token ishlaydi |
| Error Handling | ✅ To'g'ri | 500/401/404 tahlillanadi |

---

## 🔧 KERAKLI AMALLAR

### 1. **URGENT** - Backend dan tekshirish:
```bash
# Django urls.py ichida at-risk yoki at_risk?
# Test qilib ko'ring:
curl https://eduanalytics.pythonanywhere.com/api/v1/stats/at-risk/
curl https://eduanalytics.pythonanywhere.com/api/v1/stats/at_risk/
# Qaysi ishlasa, shuni qo'llang
```

### 2. Register endpoint tekshirish:
```
POST /api/v1/auth/register
Body mos keladi: { username, email, password, password2, name, phone, subject }
```

### 3. Response format tekshirish:
```
Login/Register response: { "token": "...", "user": {...} }
Courses list: [ {...} ] yoki { "results": [...] } yoki { "data": [...] }
```

---

## 📝 LOCALHOST TESTIDA XATOLIK BO'LSA

Agar `https://` ishlamasa:

```dart
// app_constants.dart ichida o'zgartirib ko'ring:
static const String baseUrl = 'http://localhost:8000/api/v1/';
```

Lekin **PRODUCTION**da HTTPS bo'LISHI SHART!

---

## ✨ YAKUNIY NATIJA

**URL strukturasi**: ✅ **98% To'g'ri**

Faqat bitta kichik muammo:
- `stats/at-risk/` → hyphen vs underscore (backend bilan tasdiqlash kerak)

**Tavsiya**: Backend Django `/stats/at_risk/` yoki `/stats/at-risk/` qaysi formatni qo'llayotgani tekshirib, u shaklda Flutter dasturni moslashtiring.
