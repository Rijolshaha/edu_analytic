# 🔧 API Testing Guide - EduAnalytics Flutter

## 📌 Backend API URL
```
Base URL: https://eduanalytics.pythonanywhere.com/api/v1/
```

## 🧪 Test Credentials (Demo)
```
Username: teacher1
Password: Teacher123!
```

---

## 🔐 **Auth Endpoints Xatosini Tuzatish**

### ✅ **1. Login Test**
```
POST /auth/login/
Headers: Content-Type: application/json

Request:
{
  "username": "teacher1",
  "password": "Teacher123!"
}

Expected Response (✓ Fixed):
{
  "token": "eyJhbGc...",
  "refresh": "eyJhbGc...",
  "user": {
    "id": 1,
    "username": "teacher1",
    "name": "Teacher One",
    "email": "teacher1@edu.uz",
    "phone": null,
    "subject": "Mathematics"
  }
}
```

**❌ Previously:** API response'da "user" field'i noto'g'ri parse qilindi  
**✓ Fixed:** Backend response'ni to'g'ri handle qiladi (wrapper format'i qabul qiladi)

---

### ✅ **2. Register Test**
```
POST /auth/register/
Headers: Content-Type: application/json

Request:
{
  "username": "ali_karimov",
  "name": "Abdulaziz Rajabov",
  "email": "ali@edu.uz",
  "password": "Parol123!",
  "password2": "Parol123!",
  "phone": "+998901234567",
  "subject": "Fizika"
}

Expected Response (201):
{
  "token": "eyJhbGc...",
  "refresh": "eyJhbGc...",
  "user": {...}
}
```

**❌ Previously:** Backend 'auth/register' (trailing slash yo'q) error  
**✓ Fixed:** 'auth/register/' with trailing slash

---

## 📊 **Data Endpoints**

### Test: Get Courses
```
GET /courses/
Headers: Authorization: Bearer <token>

Response Format:
{
  "data": [
    {
      "id": 1,
      "name": "Matematika",
      "subject": "math",
      "group_count": "5",
      "student_count": "120"
    }
  ],
  "meta": {
    "total": 10,
    "page": 1,
    "limit": 20,
    "pages": 1
  }
}
```

---

### Test: Get Students (with pagination)
```
GET /students/?page=1&limit=20
Headers: Authorization: Bearer <token>

Response Format:
{
  "data": [
    {
      "id": 1,
      "name": "Ali Karimov",
      "email": "ali@example.com",
      "group": 1,
      "group_name": "11-A"
    }
  ],
  "meta": {
    "total": 50,
    "page": 1,
    "limit": 20,
    "pages": 3
  }
}
```

---

## 🤖 **ML Prediction Endpoint**

### Test: Single Prediction
```
POST /predict/
Headers: Authorization: Bearer <token>

Request:
{
  "student_id": 3,
  "attendance": 85.0,
  "homework": 90.0,
  "quiz": 78.0,
  "exam": 92.0
}

Response:
{
  "student_id": 3,
  "student_name": "John Doe",
  "predicted_score": 86.25,
  "level": "High Performance",
  "risk_percentage": 5.0,
  "recommendation": "Davom etishni halol qilib ko'ring",
  "predicted_at": "2026-03-13T10:30:00Z"
}
```

---

## 🐛 **Error Handling**

### 401 Unauthorized
```json
{
  "detail": "Invalid username or password"
}
```
✓ **Fixed:** Interceptor automatically refreshes token

### 400 Bad Request (Register)
```json
{
  "username": ["This field must be unique."],
  "email": ["Enter a valid email address."],
  "password": ["This password is too short."]
}
```

### 500 Server Error
```json
{
  "detail": "Internal server error"
}
```
✓ **Fixed:** Error logging added for debugging

---

## 🔑 **Key Fixes Applied**

| Issue | Before | After |
|-------|--------|-------|
| **Trailing Slashes** | ❌ 'auth/login' | ✅ 'auth/login/' |
| **Response Parsing** | ❌ Only expects 'user' field | ✅ Flexible - handles wrapped & unwrapped |
| **Null Safety** | ❌ Crashes if fields missing | ✅ Default values for missing fields |
| **Token Refresh** | ❌ '/auth/refresh/' (absolute) | ✅ 'auth/refresh/' (relative) |

---

## 📱 **Flutter Testing Steps**

1. **App Launch**
   ```
   flutter run
   ```

2. **Login Screen Test**
   - Username: `teacher1`
   - Password: `Teacher123!`
   - ✓ Should navigate to dashboard

3. **Check Console**
   - Look for `🌐 [API]` logs
   - No 404 errors for endpoints

4. **Check Network (Chrome DevTools)**
   - DevTools > Network > XHR
   - All requests should succeed (200, 201, 204)

---

## 🚀 **Production Checklist**

- [ ] SSL Certificate valid on PythonAnywhere
- [ ] CORS headers configured correctly
- [ ] Token expiration: 24 hours
- [ ] Refresh token: 7 days
- [ ] Rate limiting not blocking requests
- [ ] Database migrations applied

---

## 📞 **Common Issues & Solutions**

### Problem: "HTTP 400 Bad Request"
**Solution:** Check request body format - must match API schema exactly

### Problem: "SSL Certificate Error"
**Solution:** Add certificate verification skip (dev only - NOT for production!)
```dart
// lib/core/constants/app_constants.dart
// Dio SSL verification qilmasligi uchun - FAQAT DEV'DA
```

### Problem: "Token Expired"
**Solution:** App automatically refreshes token using refresh_token

---

Last Updated: March 13, 2026
API Version: v1
Backend: Django REST Framework (PythonAnywhere)
