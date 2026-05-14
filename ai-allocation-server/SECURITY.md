# Security Improvements

This document outlines the security vulnerabilities that were identified and fixed in the AI Allocation Server.

## Vulnerabilities Fixed

### 1. Missing Authentication/Authorization (CRITICAL)
**Issue:** All endpoints were publicly accessible without authentication, allowing unauthorized access to sensitive data and modification capabilities.

**Fix:**
- Implemented Firebase Authentication middleware (`authenticateUser`)
- Added authorization checks to verify user ownership or admin status
- Protected all sensitive endpoints (`/allocations`, `/resolve-conflict`) with authentication
- Users can only access/modify their own allocations unless they have admin privileges

**Code Changes:**
```javascript
// Authentication middleware
async function authenticateUser(req, res, next) {
  // Verifies Firebase ID token from Authorization header
}

// Applied to protected routes
app.get("/allocations", authenticateUser, async (req, res) => {...});
app.post("/resolve-conflict", authenticateUser, async (req, res) => {...});
```

### 2. Insecure Direct Object Reference (IDOR) (CRITICAL)
**Issue:** Users could modify any allocation by providing an allocation ID without permission verification.

**Fix:**
- Added authorization check in `/resolve-conflict` endpoint
- Verifies that the authenticated user is either:
  - The owner of the allocation (`userId` matches)
  - An admin (has `admin` custom claim)
- Returns 403 Forbidden if unauthorized

**Code Changes:**
```javascript
const userId = req.user.uid;
const isAdmin = req.user.customClaims?.admin === true;
const isOwner = allocationData.userId === userId;

if (!isAdmin && !isOwner) {
  return res.status(403).json({ error: "Forbidden..." });
}
```

### 3. Overly Permissive CORS (MEDIUM)
**Issue:** CORS was configured to allow requests from any origin (`*`), enabling potential CSRF attacks.

**Fix:**
- Restricted CORS to specific allowed origins from environment variable
- Default to localhost for development
- Configured proper methods and headers

**Code Changes:**
```javascript
const allowedOrigins = process.env.ALLOWED_ORIGINS 
  ? process.env.ALLOWED_ORIGINS.split(',') 
  : ['http://localhost:3000'];

app.use(cors({
  origin: function(origin, callback) {
    if (!origin) return callback(null, true);
    if (allowedOrigins.indexOf(origin) !== -1) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
```

### 4. Input Validation Missing (MEDIUM)
**Issue:** No validation for date formats, string lengths, or special characters in user inputs.

**Fix:**
- Enhanced `validateResolveConflictPayload` function with comprehensive validation:
  - Date format: YYYY-MM-DD (regex validated)
  - Time format: HH:MM or HH:MM AM/PM (regex validated)
  - Allocation ID: Alphanumeric only, max 50 characters
  - Conflict details: Max 500 characters
  - Type checking for all fields

**Code Changes:**
```javascript
// Validate date format (YYYY-MM-DD)
const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
if (!dateRegex.test(body.date)) {
  return { valid: false, message: "Invalid date format. Use YYYY-MM-DD." };
}

// Validate time format
const timeRegex = /^([0-1]?[0-9]|2[0-3]):[0-5][0-9]\s*(AM|PM|am|pm)?$/;

// Validate allocationId format
if (typeof body.allocationId !== "string" || 
    body.allocationId.length > 50 || 
    !/^[a-zA-Z0-9_-]+$/.test(body.allocationId)) {
  return { valid: false, message: "Invalid allocationId format." };
}
```

### 5. Race Conditions (LOW)
**Issue:** Potential conflicts in concurrent room allocation requests could lead to double-booking.

**Fix:**
- Implemented Firestore transactions for atomic operations
- Ensures read-modify-write operations are atomic
- Prevents race conditions during conflict resolution

**Code Changes:**
```javascript
await db.runTransaction(async (transaction) => {
  const freshAllocDoc = await transaction.get(allocationRef);
  if (!freshAllocDoc.exists) {
    throw new Error("Allocation no longer exists");
  }

  transaction.set(db.collection("resolved_conflicts").doc(), {...});
  transaction.set(allocationRef, {...}, { merge: true });
});
```

### 6. Rate Limiting (MEDIUM)
**Issue:** No rate limiting, making the server vulnerable to brute force and DoS attacks.

**Fix:**
- Implemented express-rate-limit middleware
- General API limit: 100 requests per 15 minutes
- Stricter limit for sensitive endpoints: 20 requests per 15 minutes

**Code Changes:**
```javascript
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  message: { error: 'Too many requests, please try again later.' },
});

const strictLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
});

app.use('/api/', limiter);
app.post("/resolve-conflict", strictLimiter, authenticateUser, ...);
```

### 7. HTTP Security Headers (MEDIUM)
**Issue:** Missing security headers could expose the application to various attacks.

**Fix:**
- Integrated Helmet.js for automatic security headers
- Protects against XSS, clickjacking, MIME sniffing, etc.

**Code Changes:**
```javascript
const helmet = require("helmet");
app.use(helmet());
```

### 8. Network Binding (LOW)
**Issue:** Server bound to all network interfaces (0.0.0.0) unnecessarily.

**Fix:**
- Default binding to localhost (127.0.0.1)
- Configurable via HOST environment variable

**Code Changes:**
```javascript
const host = process.env.HOST || "127.0.0.1";
const server = app.listen(port, host, () => {...});
```

## Environment Variables

New environment variables introduced:

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `ALLOWED_ORIGINS` | Comma-separated list of allowed CORS origins | `http://localhost:3000` | No |
| `HOST` | Network interface to bind to | `127.0.0.1` | No |
| `PORT` | Server port | `3000` | No |
| `GOOGLE_APPLICATION_CREDENTIALS` | Path to Firebase service account | - | Yes |
| `OPENAI_API_KEY` | OpenAI API key for AI features | - | No |

## Usage Examples

### Making Authenticated Requests

```bash
# Get Firebase ID token first (from your frontend app)
TOKEN="your_firebase_id_token"

# Access protected endpoints
curl -H "Authorization: Bearer $TOKEN" \
     http://localhost:3000/allocations

# Resolve a conflict
curl -X POST \
     -H "Authorization: Bearer $TOKEN" \
     -H "Content-Type: application/json" \
     -d '{
       "allocationId": "abc123",
       "date": "2025-07-09",
       "startTime": "10:00 AM",
       "endTime": "12:00 PM",
       "conflictDetails": "Room double-booked"
     }' \
     http://localhost:3000/resolve-conflict
```

### Setting Allowed Origins

```bash
# For production
export ALLOWED_ORIGINS="https://yourapp.com,https://www.yourapp.com"

# For multiple environments
export ALLOWED_ORIGINS="http://localhost:3000,https://dev.yourapp.com,https://yourapp.com"
```

## Testing

Run the test suite to verify all security validations:

```bash
npm test
```

## Additional Recommendations

1. **Enable Firebase Admin Custom Claims**: Set up admin users with custom claims for elevated privileges
2. **Use HTTPS in Production**: Always use HTTPS to encrypt traffic
3. **Regular Security Audits**: Periodically review and update dependencies
4. **Monitor Logs**: Set up logging and monitoring for suspicious activities
5. **Database Rules**: Configure Firestore security rules as an additional layer of protection
6. **API Documentation**: Document all endpoints and their authentication requirements

## Dependencies Added

- `helmet` - HTTP security headers
- `express-rate-limit` - Rate limiting middleware
