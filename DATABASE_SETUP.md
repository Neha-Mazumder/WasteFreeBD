# 🗄️ Database Setup Guide

## Supabase `signin` Table Creation

### SQL to Create Table

```sql
CREATE TABLE signin (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  full_name VARCHAR(255),
  role VARCHAR(50) NOT NULL DEFAULT 'user',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster email lookups
CREATE INDEX idx_signin_email ON signin(email);

-- Create index for role queries
CREATE INDEX idx_signin_role ON signin(role);
```

### Steps to Create in Supabase Dashboard

1. **Go to Supabase Console** → Your Project
2. **Click "SQL Editor"** on left sidebar
3. **Click "New Query"**
4. **Paste the SQL above**
5. **Click "Run"**
6. **Table created!** ✅

---

## Test Data (Optional)

### Insert Test Users

```sql
-- Admin User
INSERT INTO signin (email, password, full_name, role) 
VALUES ('admin@wastefrebd.com', 'admin123', 'Admin User', 'admin');

-- Manager User
INSERT INTO signin (email, password, full_name, role) 
VALUES ('manager@wastefrebd.com', 'manager123', 'Manager User', 'management');

-- Accountant User
INSERT INTO signin (email, password, full_name, role) 
VALUES ('accountant@wastefrebd.com', 'accountant123', 'Accountant User', 'accountant');

-- Regular User
INSERT INTO signin (email, password, full_name, role) 
VALUES ('user@wastefrebd.com', 'user123', 'Regular User', 'user');

-- Another User
INSERT INTO signin (email, password, full_name, role) 
VALUES ('john@wastefrebd.com', 'password123', 'John Doe', 'user');
```

---

## User Roles & Access Levels

### 1. **Admin Role**
- **Email Pattern**: Any email
- **Can Access**:
  - ✅ Admin Dashboard
  - ✅ Inventory Management
  - ✅ Waste Stock Monitoring
  - ✅ Worker Management
  - ✅ Financial Overview
  - ✅ All System Features
- **Route**: `/admin/dashboard` (after login)

### 2. **Management Role**
- **Email Pattern**: Any email
- **Can Access**:
  - ✅ Inventory Management
  - ✅ Waste Stock Monitoring
  - ✅ Worker Management
  - ❌ Finance (no access)
- **Route**: `/management/inventory` (after login)

### 3. **Accountant Role**
- **Email Pattern**: Any email
- **Can Access**:
  - ✅ Financial Overview
  - ✅ Worker Management
  - ❌ Inventory (no access)
  - ❌ Waste Stock (no access)
- **Route**: `/accountant/finance` (after login)

### 4. **User Role**
- **Email Pattern**: Any email (default for new sign-ups)
- **Can Access**:
  - ✅ Personal Dashboard
  - ✅ Request Pickup
  - ✅ Donate Items
  - ✅ Payment & Billing
  - ✅ Live Tracking
  - ✅ View History
  - ✅ Badges & Rewards
- **Route**: `/dashboard` (after login)

---

## Verification Steps

### 1. **Check if Table Exists**
```sql
SELECT * FROM signin LIMIT 1;
```

### 2. **Check All Users**
```sql
SELECT id, email, full_name, role, created_at FROM signin;
```

### 3. **Check by Role**
```sql
-- Get all admins
SELECT * FROM signin WHERE role = 'admin';

-- Get all managers
SELECT * FROM signin WHERE role = 'management';

-- Get all accountants
SELECT * FROM signin WHERE role = 'accountant';

-- Get all regular users
SELECT * FROM signin WHERE role = 'user';
```

### 4. **Update User Role**
```sql
UPDATE signin 
SET role = 'admin' 
WHERE email = 'user@wastefrebd.com';
```

---

## Troubleshooting

### ❌ Problem: "Relation 'signin' does not exist"
**Solution**: The table hasn't been created. Run the SQL creation query above.

### ❌ Problem: "Duplicate key value violates unique constraint"
**Solution**: Email already exists. Use a different email or delete the duplicate first:
```sql
DELETE FROM signin WHERE email = 'admin@wastefrebd.com';
```

### ❌ Problem: Login fails even with correct credentials
**Solution**: 
- Check that email & password exactly match (case-sensitive password)
- Verify role is one of: `admin`, `management`, `accountant`, `user`
- Check user exists: `SELECT * FROM signin WHERE email = 'your-email@example.com';`

---

## Security Recommendations

### ⚠️ Current State (Development)
- Passwords stored in plain text
- No encryption

### 🔒 For Production
1. **Hash Passwords**
   - Use bcrypt, scrypt, or Argon2
   - Update column: `ALTER TABLE signin ALTER COLUMN password TYPE CHAR(60);`

2. **Enable Row-Level Security (RLS)**
   ```sql
   ALTER TABLE signin ENABLE ROW LEVEL SECURITY;
   
   CREATE POLICY "Users can read own data" ON signin
   FOR SELECT USING (auth.uid()::text = id::text);
   ```

3. **Add Email Verification**
   - Add column: `email_verified BOOLEAN DEFAULT FALSE`
   - Send verification email after signup

4. **Add Rate Limiting**
   - Track failed login attempts
   - Lock account after 5 failed attempts

5. **Add Password Strength Requirements**
   - Minimum 8 characters
   - At least one uppercase letter
   - At least one number
   - At least one special character

---

## Useful Queries

### Count users by role
```sql
SELECT role, COUNT(*) as count 
FROM signin 
GROUP BY role 
ORDER BY count DESC;
```

### Find users created in last 7 days
```sql
SELECT * FROM signin 
WHERE created_at > NOW() - INTERVAL '7 days'
ORDER BY created_at DESC;
```

### List all admins and managers
```sql
SELECT email, full_name, role 
FROM signin 
WHERE role IN ('admin', 'management')
ORDER BY role, email;
```

### Export all user data
```sql
SELECT id, email, full_name, role, created_at 
FROM signin 
ORDER BY created_at DESC;
```

---

## Quick Reference

| Role | Dashboard URL | Can See |
|------|---------------|---------|
| admin | `/admin/dashboard` | Everything |
| management | `/management/inventory` | Inventory, Waste, Workers |
| accountant | `/accountant/finance` | Finance, Workers |
| user | `/dashboard` | Personal dashboard only |

---

**Last Updated**: January 16, 2026  
**Status**: Ready for use ✅
