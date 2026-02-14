# Data Flow Diagram (DFD) - Quietly College App

## 📊 System Overview

Quietly is a comprehensive college management system with geofencing-based automatic phone muting capabilities. The system has four primary user modules: **Admin**, **Student**, **Teacher**, and **Parent**.

---

## 🎯 Context Diagram (Level 0 DFD)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                                                                         │
│                         EXTERNAL ENTITIES                               │
│                                                                         │
│   ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐       │
│   │  ADMIN   │    │ TEACHER  │    │ STUDENT  │    │  PARENT  │       │
│   └─────┬────┘    └─────┬────┘    └─────┬────┘    └─────┬────┘       │
│         │               │               │               │             │
└─────────┼───────────────┼───────────────┼───────────────┼─────────────┘
          │               │               │               │
          ▼               ▼               ▼               ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                                                                         │
│                      QUIETLY COLLEGE SYSTEM                             │
│                                                                         │
│  ┌───────────────────────────────────────────────────────────────┐    │
│  │                    CORE MODULES                                │    │
│  │                                                                 │    │
│  │  • User Management          • Class Management                 │    │
│  │  • Attendance Tracking      • Geofencing Service              │    │
│  │  • Notification System      • Authentication                   │    │
│  │  • Student Enrollment       • Profile Management              │    │
│  │                                                                 │    │
│  └───────────────────────────────────────────────────────────────┘    │
│                                                                         │
│  ┌───────────────────────────────────────────────────────────────┐    │
│  │                    DATA STORES                                 │    │
│  │                                                                 │    │
│  │  • Firebase Authentication  • Firestore Database              │    │
│  │  • SharedPreferences        • Cloud Storage                    │    │
│  │                                                                 │    │
│  └───────────────────────────────────────────────────────────────┘    │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
          │               │               │               │
          ▼               ▼               ▼               ▼
    User Data      Attendance Data   Location Data   Notifications
```

---

## 📋 Level 1 DFD - Main System Processes

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        AUTHENTICATION FLOW                              │
└─────────────────────────────────────────────────────────────────────────┘

    ┌──────────┐
    │   USER   │
    └─────┬────┘
          │ Login Credentials
          ▼
    ┌──────────────────┐
    │  1.0 AUTHENTICATE│
    │      USER        │
    └─────┬────────────┘
          │ UID
          ▼
    ┌──────────────────┐
    │  D1: Firebase    │
    │  Authentication  │
    └─────┬────────────┘
          │ User UID
          ▼
    ┌──────────────────┐
    │  2.0 FETCH USER  │
    │      ROLE        │
    └─────┬────────────┘
          │ User Data + Role
          ▼
    ┌──────────────────┐
    │  D2: Users       │
    │  Collection      │
    └─────┬────────────┘
          │
          ├─────────────┬──────────────┬──────────────┐
          │             │              │              │
          ▼             ▼              ▼              ▼
    ┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────┐
    │  ADMIN  │   │ TEACHER │   │ STUDENT │   │ PARENT  │
    │Dashboard│   │Dashboard│   │Dashboard│   │Dashboard│
    └─────────┘   └─────────┘   └─────────┘   └─────────┘


┌─────────────────────────────────────────────────────────────────────────┐
│                        MAIN DATA PROCESSES                              │
└─────────────────────────────────────────────────────────────────────────┘

┌──────────┐         ┌──────────┐         ┌──────────┐         ┌──────────┐
│  ADMIN   │         │ TEACHER  │         │ STUDENT  │         │  PARENT  │
└────┬─────┘         └────┬─────┘         └────┬─────┘         └────┬─────┘
     │                    │                    │                    │
     │                    │                    │                    │
     ▼                    ▼                    ▼                    ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   3.0       │     │   4.0       │     │   5.0       │     │   6.0       │
│  MANAGE     │     │  MANAGE     │     │  MANAGE     │     │   VIEW      │
│  SYSTEM     │     │ ATTENDANCE  │     │ GEOFENCING  │     │  STUDENT    │
│             │     │             │     │             │     │   DATA      │
└──────┬──────┘     └──────┬──────┘     └──────┬──────┘     └──────┬──────┘
       │                   │                   │                   │
       │                   │                   │                   │
       ▼                   ▼                   ▼                   ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                        DATA STORES                                       │
│                                                                          │
│  D1: Firebase Auth    D2: Users         D3: Classes                     │
│  D4: Students         D5: Attendance    D6: Geofence Settings           │
│  D7: Notifications    D8: Enrollment    D9: SharedPreferences           │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## 🔐 Level 2 DFD - Admin Module (Process 3.0)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        ADMIN MODULE PROCESSES                           │
└─────────────────────────────────────────────────────────────────────────┘

    ┌──────────┐
    │  ADMIN   │
    └─────┬────┘
          │
          ├──────────────┬──────────────┬──────────────┬──────────────┬──────────────┐
          │              │              │              │              │              │
          ▼              ▼              ▼              ▼              ▼              ▼
    ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
    │   3.1    │   │   3.2    │   │   3.3    │   │   3.4    │   │   3.5    │   │   3.6    │
    │  MANAGE  │   │  MANAGE  │   │  MANAGE  │   │  MANAGE  │   │  MANAGE  │   │  VIEW    │
    │ CLASSES  │   │ TEACHERS │   │ STUDENTS │   │ PARENTS  │   │ENROLLMENT│   │DASHBOARD │
    └────┬─────┘   └────┬─────┘   └────┬─────┘   └────┬─────┘   └────┬─────┘   └────┬─────┘
         │              │              │              │              │              │
         │              │              │              │              │              │
         ▼              ▼              ▼              ▼              ▼              ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                                                                         │
│  3.1 MANAGE CLASSES                                                     │
│  ┌────────────────────────────────────────────────────────────┐        │
│  │                                                              │        │
│  │  Input: Class Details (name, code, department, section)     │        │
│  │         ↓                                                    │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 3.1.1 CREATE │ → D3: Classes Collection                  │        │
│  │  │    CLASS     │                                           │        │
│  │  └──────────────┘                                           │        │
│  │         ↓                                                    │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 3.1.2 UPDATE │ ← D3: Classes Collection                  │        │
│  │  │    CLASS     │ → D3: Classes Collection                  │        │
│  │  └──────────────┘                                           │        │
│  │         ↓                                                    │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 3.1.3 DELETE │ ← D3: Classes Collection                  │        │
│  │  │    CLASS     │ → D3: Classes Collection                  │        │
│  │  └──────────────┘                                           │        │
│  │         ↓                                                    │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 3.1.4 ADD    │ → D4: Classes/{classId}/Students          │        │
│  │  │  STUDENTS    │                                           │        │
│  │  │  TO CLASS    │                                           │        │
│  │  └──────────────┘                                           │        │
│  │                                                              │        │
│  └──────────────────────────────────────────────────────────────┘        │
│                                                                         │
│  3.2 MANAGE TEACHERS                                                    │
│  ┌────────────────────────────────────────────────────────────┐        │
│  │                                                              │        │
│  │  Input: Teacher Details (name, email, password, subjects)   │        │
│  │         ↓                                                    │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 3.2.1 CREATE │ → D1: Firebase Auth                       │        │
│  │  │   TEACHER    │ → D2: Users Collection (role: teacher)    │        │
│  │  │   ACCOUNT    │                                           │        │
│  │  └──────────────┘                                           │        │
│  │         ↓                                                    │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 3.2.2 UPDATE │ ← D2: Users Collection                    │        │
│  │  │   TEACHER    │ → D2: Users Collection                    │        │
│  │  │   DETAILS    │                                           │        │
│  │  └──────────────┘                                           │        │
│  │         ↓                                                    │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 3.2.3 DELETE │ ← D2: Users Collection                    │        │
│  │  │   TEACHER    │ → D2: Users Collection                    │        │
│  │  └──────────────┘                                           │        │
│  │                                                              │        │
│  └──────────────────────────────────────────────────────────────┘        │
│                                                                         │
│  3.3 MANAGE STUDENTS                                                    │
│  ┌────────────────────────────────────────────────────────────┐        │
│  │                                                              │        │
│  │  Input: Student Details (name, email, password, class)      │        │
│  │         ↓                                                    │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 3.3.1 CREATE │ → D1: Firebase Auth                       │        │
│  │  │   STUDENT    │ → D2: Users Collection (role: student)    │        │
│  │  │   ACCOUNT    │                                           │        │
│  │  └──────────────┘                                           │        │
│  │         ↓                                                    │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 3.3.2 UPDATE │ ← D2: Users Collection                    │        │
│  │  │   STUDENT    │ → D2: Users Collection                    │        │
│  │  │   DETAILS    │                                           │        │
│  │  └──────────────┘                                           │        │
│  │         ↓                                                    │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 3.3.3 DELETE │ ← D2: Users Collection                    │        │
│  │  │   STUDENT    │ → D2: Users Collection                    │        │
│  │  └──────────────┘                                           │        │
│  │                                                              │        │
│  └──────────────────────────────────────────────────────────────┘        │
│                                                                         │
│  3.4 MANAGE PARENTS                                                     │
│  ┌────────────────────────────────────────────────────────────┐        │
│  │                                                              │        │
│  │  Input: Parent Details (name, email, password, phone)       │        │
│  │         ↓                                                    │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 3.4.1 CREATE │ → D1: Firebase Auth                       │        │
│  │  │   PARENT     │ → D2: Users Collection (role: parent)     │        │
│  │  │   ACCOUNT    │                                           │        │
│  │  └──────────────┘                                           │        │
│  │         ↓                                                    │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 3.4.2 UPDATE │ ← D2: Users Collection                    │        │
│  │  │   PARENT     │ → D2: Users Collection                    │        │
│  │  │   DETAILS    │                                           │        │
│  │  └──────────────┘                                           │        │
│  │         ↓                                                    │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 3.4.3 DELETE │ ← D2: Users Collection                    │        │
│  │  │   PARENT     │ → D2: Users Collection                    │        │
│  │  │              │ → D8: Enrollment Collection (remove links)│        │
│  │  └──────────────┘                                           │        │
│  │                                                              │        │
│  └──────────────────────────────────────────────────────────────┘        │
│                                                                         │
│  3.5 MANAGE ENROLLMENT (Link Parents to Students)                      │
│  ┌────────────────────────────────────────────────────────────┐        │
│  │                                                              │        │
│  │  Input: Parent ID, Student ID(s)                            │        │
│  │         ↓                                                    │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 3.5.1 FETCH  │ ← D2: Users Collection (parents)          │        │
│  │  │   PARENTS    │                                           │        │
│  │  │     LIST     │                                           │        │
│  │  └──────┬───────┘                                           │        │
│  │         ↓                                                    │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 3.5.2 FETCH  │ ← D2: Users Collection (students)         │        │
│  │  │  STUDENTS    │                                           │        │
│  │  │     LIST     │                                           │        │
│  │  └──────┬───────┘                                           │        │
│  │         ↓                                                    │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 3.5.3 CREATE │ → D8: Enrollment Collection               │        │
│  │  │ PARENT-CHILD │   {parentId: uid, studentId: uid,         │        │
│  │  │     LINK     │    relationship: "parent", createdAt}     │        │
│  │  └──────┬───────┘                                           │        │
│  │         ↓                                                    │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 3.5.4 UPDATE │ ← D8: Enrollment Collection               │        │
│  │  │     LINK     │ → D8: Enrollment Collection               │        │
│  │  └──────┬───────┘                                           │        │
│  │         ↓                                                    │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 3.5.5 DELETE │ ← D8: Enrollment Collection               │        │
│  │  │     LINK     │ → D8: Enrollment Collection               │        │
│  │  └──────────────┘                                           │        │
│  │         ↓                                                    │        │
│  │  Output: Parent-Student Link Confirmation                   │        │
│  │                                                              │        │
│  └──────────────────────────────────────────────────────────────┘        │
│                                                                         │
│  3.6 VIEW DASHBOARD                                                     │
│  ┌────────────────────────────────────────────────────────────┐        │
│  │                                                              │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 3.6.1 FETCH  │ ← D2: Users Collection                    │        │
│  │  │ STATISTICS   │ ← D3: Classes Collection                  │        │
│  │  │              │ ← D5: Attendance Collection               │        │
│  │  └──────────────┘                                           │        │
│  │         ↓                                                    │        │
│  │  Display: Total Students, Teachers, Parents, Classes,       │        │
│  │           Attendance %, Enrollment Statistics               │        │
│  │                                                              │        │
│  └──────────────────────────────────────────────────────────────┘        │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 👨‍🏫 Level 2 DFD - Teacher Module (Process 4.0)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                       TEACHER MODULE PROCESSES                          │
└─────────────────────────────────────────────────────────────────────────┘

    ┌──────────┐
    │ TEACHER  │
    └─────┬────┘
          │
          ├──────────────────┬──────────────────┬──────────────────┐
          │                  │                  │                  │
          ▼                  ▼                  ▼                  ▼
    ┌──────────┐       ┌──────────┐       ┌──────────┐       ┌──────────┐
    │   4.1    │       │   4.2    │       │   4.3    │       │   4.4    │
    │   MARK   │       │   VIEW   │       │  MANAGE  │       │  VIEW    │
    │ATTENDANCE│       │ STUDENTS │       │  PROFILE │       │DASHBOARD │
    └────┬─────┘       └────┬─────┘       └────┬─────┘       └────┬─────┘
         │                  │                  │                  │
         │                  │                  │                  │
         ▼                  ▼                  ▼                  ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                                                                         │
│  4.1 MARK ATTENDANCE                                                    │
│  ┌────────────────────────────────────────────────────────────┐        │
│  │                                                              │        │
│  │  Input: Class ID, Period, Date, Student Status              │        │
│  │         ↓                                                    │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 4.1.1 SELECT │ ← D3: Classes Collection                  │        │
│  │  │    CLASS     │                                           │        │
│  │  └──────┬───────┘                                           │        │
│  │         ↓                                                    │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 4.1.2 FETCH  │ ← D4: Classes/{classId}/Students          │        │
│  │  │  STUDENTS    │                                           │        │
│  │  └──────┬───────┘                                           │        │
│  │         ↓                                                    │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 4.1.3 SELECT │                                           │        │
│  │  │   PERIOD &   │                                           │        │
│  │  │     DATE     │                                           │        │
│  │  └──────┬───────┘                                           │        │
│  │         ↓                                                    │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 4.1.4 MARK   │                                           │        │
│  │  │  INDIVIDUAL  │                                           │        │
│  │  │   STUDENT    │                                           │        │
│  │  │  (Present/   │                                           │        │
│  │  │  Absent/Late)│                                           │        │
│  │  └──────┬───────┘                                           │        │
│  │         ↓                                                    │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 4.1.5 SAVE   │ → D5: Classes/{classId}/Students/         │        │
│  │  │ ATTENDANCE   │      {studentId}/attendance/              │        │
│  │  │              │      {date}_{period}                      │        │
│  │  └──────────────┘                                           │        │
│  │         ↓                                                    │        │
│  │  Output: Attendance Saved Confirmation                      │        │
│  │                                                              │        │
│  └──────────────────────────────────────────────────────────────┘        │
│                                                                         │
│  4.2 VIEW STUDENTS                                                      │
│  ┌────────────────────────────────────────────────────────────┐        │
│  │                                                              │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 4.2.1 FETCH  │ ← D3: Classes Collection                  │        │
│  │  │   ASSIGNED   │                                           │        │
│  │  │   CLASSES    │                                           │        │
│  │  └──────┬───────┘                                           │        │
│  │         ↓                                                    │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 4.2.2 FETCH  │ ← D4: Classes/{classId}/Students          │        │
│  │  │  STUDENTS    │                                           │        │
│  │  │   IN CLASS   │                                           │        │
│  │  └──────┬───────┘                                           │        │
│  │         ↓                                                    │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 4.2.3 FETCH  │ ← D5: Attendance Collection               │        │
│  │  │ ATTENDANCE   │                                           │        │
│  │  │   HISTORY    │                                           │        │
│  │  └──────────────┘                                           │        │
│  │         ↓                                                    │        │
│  │  Display: Student List with Attendance Status               │        │
│  │                                                              │        │
│  └──────────────────────────────────────────────────────────────┘        │
│                                                                         │
│  4.3 MANAGE PROFILE                                                     │
│  ┌────────────────────────────────────────────────────────────┐        │
│  │                                                              │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 4.3.1 VIEW   │ ← D2: Users Collection                    │        │
│  │  │   PROFILE    │                                           │        │
│  │  └──────┬───────┘                                           │        │
│  │         ↓                                                    │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 4.3.2 UPDATE │ → D2: Users Collection                    │        │
│  │  │   PROFILE    │                                           │        │
│  │  └──────────────┘                                           │        │
│  │                                                              │        │
│  └──────────────────────────────────────────────────────────────┘        │
│                                                                         │
│  4.4 VIEW DASHBOARD                                                     │
│  ┌────────────────────────────────────────────────────────────┐        │
│  │                                                              │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 4.4.1 FETCH  │ ← D2: Users Collection (students)         │        │
│  │  │ TOTAL        │                                           │        │
│  │  │ STUDENTS     │                                           │        │
│  │  └──────┬───────┘                                           │        │
│  │         ↓                                                    │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 4.4.2 FETCH  │ ← D6: Geofence Settings                   │        │
│  │  │ STUDENTS IN  │                                           │        │
│  │  │ CLASS MODE   │                                           │        │
│  │  └──────────────┘                                           │        │
│  │         ↓                                                    │        │
│  │  Display: Dashboard Statistics                              │        │
│  │                                                              │        │
│  └──────────────────────────────────────────────────────────────┘        │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 🎓 Level 2 DFD - Student Module (Process 5.0)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                       STUDENT MODULE PROCESSES                          │
└─────────────────────────────────────────────────────────────────────────┘

    ┌──────────┐
    │ STUDENT  │
    └─────┬────┘
          │
          ├──────────────────┬──────────────────┬──────────────────┐
          │                  │                  │                  │
          ▼                  ▼                  ▼                  ▼
    ┌──────────┐       ┌──────────┐       ┌──────────┐       ┌──────────┐
    │   5.1    │       │   5.2    │       │   5.3    │       │   5.4    │
    │GEOFENCING│       │   VIEW   │       │  MANAGE  │       │  VIEW    │
    │  SERVICE │       │ATTENDANCE│       │  PROFILE │       │  HOME    │
    └────┬─────┘       └────┬─────┘       └────┬─────┘       └────┬─────┘
         │                  │                  │                  │
         │                  │                  │                  │
         ▼                  ▼                  ▼                  ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                                                                         │
│  5.1 GEOFENCING SERVICE (AUTO MUTE/UNMUTE)                              │
│  ┌────────────────────────────────────────────────────────────┐        │
│  │                                                              │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 5.1.1 INIT   │ ← D9: SharedPreferences (target location) │        │
│  │  │ GEOFENCING   │                                           │        │
│  │  └──────┬───────┘                                           │        │
│  │         ↓                                                    │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 5.1.2 CHECK  │                                           │        │
│  │  │ PERMISSIONS  │                                           │        │
│  │  │ (Location,   │                                           │        │
│  │  │  DND Access) │                                           │        │
│  │  └──────┬───────┘                                           │        │
│  │         ↓                                                    │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 5.1.3 START  │                                           │        │
│  │  │  LOCATION    │                                           │        │
│  │  │  TRACKING    │                                           │        │
│  │  │ (Every 10m)  │                                           │        │
│  │  └──────┬───────┘                                           │        │
│  │         ↓                                                    │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 5.1.4 GET    │ ← GPS Location Service                    │        │
│  │  │ CURRENT GPS  │                                           │        │
│  │  │  POSITION    │                                           │        │
│  │  └──────┬───────┘                                           │        │
│  │         ↓                                                    │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 5.1.5        │                                           │        │
│  │  │ CALCULATE    │                                           │        │
│  │  │ DISTANCE TO  │                                           │        │
│  │  │ TARGET       │                                           │        │
│  │  │ (Haversine)  │                                           │        │
│  │  └──────┬───────┘                                           │        │
│  │         ↓                                                    │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 5.1.6 CHECK  │                                           │        │
│  │  │ GEOFENCE     │                                           │        │
│  │  │ BOUNDARY     │                                           │        │
│  │  │ (≤40m?)      │                                           │        │
│  │  └──────┬───────┘                                           │        │
│  │         │                                                    │        │
│  │         ├──────────────────┬─────────────────┐              │        │
│  │         ▼                  ▼                 ▼              │        │
│  │  ┌──────────┐       ┌──────────┐     ┌──────────┐          │        │
│  │  │  INSIDE  │       │ OUTSIDE  │     │NO CHANGE │          │        │
│  │  │(Distance │       │(Distance │     │          │          │        │
│  │  │  ≤40m)   │       │  \u003e40m)   │     │          │          │        │
│  │  └────┬─────┘       └────┬─────┘     └──────────┘          │        │
│  │       │                  │                                  │        │
│  │       ▼                  ▼                                  │        │
│  │  ┌──────────┐       ┌──────────┐                           │        │
│  │  │ 5.1.7    │       │ 5.1.8    │                           │        │
│  │  │ GEOFENCE │       │ GEOFENCE │                           │        │
│  │  │  ENTRY   │       │   EXIT   │                           │        │
│  │  └────┬─────┘       └────┬─────┘                           │        │
│  │       │                  │                                  │        │
│  │       ▼                  ▼                                  │        │
│  │  ┌──────────┐       ┌──────────┐                           │        │
│  │  │ 5.1.9    │       │ 5.1.10   │                           │        │
│  │  │  SAVE    │       │  SAVE    │                           │        │
│  │  │ PREVIOUS │       │ PREVIOUS │                           │        │
│  │  │  AUDIO   │       │  AUDIO   │                           │        │
│  │  │ SETTINGS │       │ SETTINGS │                           │        │
│  │  └────┬─────┘       └────┬─────┘                           │        │
│  │       │                  │                                  │        │
│  │       ▼                  ▼                                  │        │
│  │  ┌──────────┐       ┌──────────┐                           │        │
│  │  │ 5.1.11   │       │ 5.1.12   │                           │        │
│  │  │  MUTE    │       │ UNMUTE   │                           │        │
│  │  │  PHONE   │       │  PHONE   │                           │        │
│  │  │ (DND ON) │       │(DND OFF) │                           │        │
│  │  └────┬─────┘       └────┬─────┘                           │        │
│  │       │                  │                                  │        │
│  │       ▼                  ▼                                  │        │
│  │  ┌──────────┐       ┌──────────┐                           │        │
│  │  │ 5.1.13   │       │ 5.1.14   │                           │        │
│  │  │  START   │       │   STOP   │                           │        │
│  │  │FOREGROUND│       │FOREGROUND│                           │        │
│  │  │ SERVICE  │       │ SERVICE  │                           │        │
│  │  └────┬─────┘       └────┬─────┘                           │        │
│  │       │                  │                                  │        │
│  │       ▼                  ▼                                  │        │
│  │  ┌──────────┐       ┌──────────┐                           │        │
│  │  │ 5.1.15   │       │ 5.1.16   │                           │        │
│  │  │  SHOW    │       │   HIDE   │                           │        │
│  │  │  NOTIFY  │       │  NOTIFY  │                           │        │
│  │  │"Quietly  │       │          │                           │        │
│  │  │ Active"  │       │          │                           │        │
│  │  └──────────┘       └──────────┘                           │        │
│  │       │                  │                                  │        │
│  │       ▼                  ▼                                  │        │
│  │  ┌──────────────────────────┐                              │        │
│  │  │ 5.1.17 SAVE STATE        │                              │        │
│  │  │ → D9: SharedPreferences  │                              │        │
│  │  │   (isInside, timestamp)  │                              │        │
│  │  └──────────────────────────┘                              │        │
│  │                                                              │        │
│  └──────────────────────────────────────────────────────────────┘        │
│                                                                         │
│  5.2 VIEW ATTENDANCE                                                    │
│  ┌────────────────────────────────────────────────────────────┐        │
│  │                                                              │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 5.2.1 FETCH  │ ← D2: Users Collection (get classId)      │        │
│  │  │  STUDENT     │                                           │        │
│  │  │   CLASS      │                                           │        │
│  │  └──────┬───────┘                                           │        │
│  │         ↓                                                    │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 5.2.2 FETCH  │ ← D5: Classes/{classId}/Students/         │        │
│  │  │ ATTENDANCE   │      {studentId}/attendance               │        │
│  │  │   RECORDS    │                                           │        │
│  │  └──────┬───────┘                                           │        │
│  │         ↓                                                    │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 5.2.3 FILTER │                                           │        │
│  │  │   BY DATE    │                                           │        │
│  │  │  & PERIOD    │                                           │        │
│  │  └──────┬───────┘                                           │        │
│  │         ↓                                                    │        │
│  │  Display: Attendance History (Present/Absent/Late)          │        │
│  │                                                              │        │
│  └──────────────────────────────────────────────────────────────┘        │
│                                                                         │
│  5.3 MANAGE PROFILE                                                     │
│  ┌────────────────────────────────────────────────────────────┐        │
│  │                                                              │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 5.3.1 VIEW   │ ← D2: Users Collection                    │        │
│  │  │   PROFILE    │                                           │        │
│  │  └──────┬───────┘                                           │        │
│  │         ↓                                                    │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 5.3.2 UPDATE │ → D2: Users Collection                    │        │
│  │  │   PROFILE    │                                           │        │
│  │  └──────────────┘                                           │        │
│  │                                                              │        │
│  └──────────────────────────────────────────────────────────────┘        │
│                                                                         │
│  5.4 VIEW HOME SCREEN                                                   │
│  ┌────────────────────────────────────────────────────────────┐        │
│  │                                                              │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 5.4.1 FETCH  │ ← D3: Classes Collection                  │        │
│  │  │ CLASS INFO   │                                           │        │
│  │  └──────┬───────┘                                           │        │
│  │         ↓                                                    │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 5.4.2 FETCH  │ ← D7: Notifications Collection            │        │
│  │  │NOTIFICATIONS │                                           │        │
│  │  └──────┬───────┘                                           │        │
│  │         ↓                                                    │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 5.4.3 CHECK  │ ← D6: Geofence Settings                   │        │
│  │  │ CLASS MODE   │                                           │        │
│  │  │   STATUS     │                                           │        │
│  │  └──────────────┘                                           │        │
│  │         ↓                                                    │        │
│  │  Display: Home Dashboard                                    │        │
│  │                                                              │        │
│  └──────────────────────────────────────────────────────────────┘        │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 👨‍👩‍👧 Level 2 DFD - Parent Module (Process 6.0)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                       PARENT MODULE PROCESSES                           │
└─────────────────────────────────────────────────────────────────────────┘

    ┌──────────┐
    │  PARENT  │
    └─────┬────┘
          │
          ├──────────────────┬──────────────────┬──────────────────┐
          │                  │                  │                  │
          ▼                  ▼                  ▼                  ▼
    ┌──────────┐       ┌──────────┐       ┌──────────┐       ┌──────────┐
    │   6.1    │       │   6.2    │       │   6.3    │       │   6.4    │
    │   VIEW   │       │   VIEW   │       │  MANAGE  │       │  VIEW    │
    │ CHILDREN │       │ATTENDANCE│       │  PROFILE │       │DASHBOARD │
    └────┬─────┘       └────┬─────┘       └────┬─────┘       └────┬─────┘
         │                  │                  │                  │
         │                  │                  │                  │
         ▼                  ▼                  ▼                  ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                                                                         │
│  6.1 VIEW CHILDREN                                                      │
│  ┌────────────────────────────────────────────────────────────┐        │
│  │                                                              │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 6.1.1 FETCH  │ ← D2: Users Collection (parent UID)       │        │
│  │  │   PARENT     │                                           │        │
│  │  │   PROFILE    │                                           │        │
│  │  └──────┬───────┘                                           │        │
│  │         ↓                                                    │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 6.1.2 FETCH  │ ← D8: Enrollment Collection               │        │
│  │  │  LINKED      │   (parent-student relationships)          │        │
│  │  │  CHILDREN    │                                           │        │
│  │  └──────┬───────┘                                           │        │
│  │         ↓                                                    │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 6.1.3 FETCH  │ ← D2: Users Collection (student data)     │        │
│  │  │  CHILDREN    │                                           │        │
│  │  │   DETAILS    │                                           │        │
│  │  └──────┬───────┘                                           │        │
│  │         ↓                                                    │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 6.1.4 FETCH  │ ← D3: Classes Collection                  │        │
│  │  │  CHILDREN    │                                           │        │
│  │  │   CLASSES    │                                           │        │
│  │  └──────────────┘                                           │        │
│  │         ↓                                                    │        │
│  │  Display: List of Children with Class Info                  │        │
│  │                                                              │        │
│  └──────────────────────────────────────────────────────────────┘        │
│                                                                         │
│  6.2 VIEW CHILD ATTENDANCE                                              │
│  ┌────────────────────────────────────────────────────────────┐        │
│  │                                                              │        │
│  │  Input: Selected Child ID                                   │        │
│  │         ↓                                                    │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 6.2.1 GET    │ ← D2: Users Collection                    │        │
│  │  │  CHILD'S     │                                           │        │
│  │  │  CLASS ID    │                                           │        │
│  │  └──────┬───────┘                                           │        │
│  │         ↓                                                    │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 6.2.2 FETCH  │ ← D5: Classes/{classId}/Students/         │        │
│  │  │ ATTENDANCE   │      {studentId}/attendance               │        │
│  │  │   RECORDS    │                                           │        │
│  │  └──────┬───────┘                                           │        │
│  │         ↓                                                    │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 6.2.3        │                                           │        │
│  │  │ CALCULATE    │                                           │        │
│  │  │ STATISTICS   │                                           │        │
│  │  │ (%, Trends)  │                                           │        │
│  │  └──────┬───────┘                                           │        │
│  │         ↓                                                    │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 6.2.4 FILTER │                                           │        │
│  │  │   BY DATE    │                                           │        │
│  │  │   RANGE      │                                           │        │
│  │  └──────────────┘                                           │        │
│  │         ↓                                                    │        │
│  │  Display: Attendance Report with Statistics                 │        │
│  │                                                              │        │
│  └──────────────────────────────────────────────────────────────┘        │
│                                                                         │
│  6.3 MANAGE PROFILE                                                     │
│  ┌────────────────────────────────────────────────────────────┐        │
│  │                                                              │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 6.3.1 VIEW   │ ← D2: Users Collection                    │        │
│  │  │   PROFILE    │                                           │        │
│  │  └──────┬───────┘                                           │        │
│  │         ↓                                                    │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 6.3.2 UPDATE │ → D2: Users Collection                    │        │
│  │  │   PROFILE    │                                           │        │
│  │  └──────────────┘                                           │        │
│  │                                                              │        │
│  └──────────────────────────────────────────────────────────────┘        │
│                                                                         │
│  6.4 VIEW DASHBOARD                                                     │
│  ┌────────────────────────────────────────────────────────────┐        │
│  │                                                              │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 6.4.1 FETCH  │ ← D8: Enrollment Collection               │        │
│  │  │  CHILDREN    │                                           │        │
│  │  │     LIST     │                                           │        │
│  │  └──────┬───────┘                                           │        │
│  │         ↓                                                    │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 6.4.2 FETCH  │ ← D5: Attendance Collection               │        │
│  │  │   TODAY'S    │                                           │        │
│  │  │ ATTENDANCE   │                                           │        │
│  │  └──────┬───────┘                                           │        │
│  │         ↓                                                    │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 6.4.3 CHECK  │ ← D6: Geofence Settings                   │        │
│  │  │   PHONE      │                                           │        │
│  │  │   STATUS     │                                           │        │
│  │  └──────┬───────┘                                           │        │
│  │         ↓                                                    │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 6.4.4 FETCH  │ ← D3: Classes Collection                  │        │
│  │  │  CURRENT     │                                           │        │
│  │  │   CLASS      │                                           │        │
│  │  └──────┬───────┘                                           │        │
│  │         ↓                                                    │        │
│  │  ┌──────────────┐                                           │        │
│  │  │ 6.4.5 FETCH  │ ← D7: Notifications Collection            │        │
│  │  │  RECENT      │                                           │        │
│  │  │  ACTIVITY    │                                           │        │
│  │  └──────────────┘                                           │        │
│  │         ↓                                                    │        │
│  │  Display: Dashboard with Child Statistics                   │        │
│  │                                                              │        │
│  └──────────────────────────────────────────────────────────────┘        │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 💾 Data Stores

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           DATA STORES                                   │
└─────────────────────────────────────────────────────────────────────────┘

D1: FIREBASE AUTHENTICATION
┌────────────────────────────────────────────────────────────────┐
│  • User UID (Primary Key)                                      │
│  • Email                                                        │
│  • Password (Hashed)                                           │
│  • Creation Date                                               │
│  • Last Sign In                                                │
└────────────────────────────────────────────────────────────────┘

D2: USERS COLLECTION (Firestore)
┌────────────────────────────────────────────────────────────────┐
│  • uid (Document ID)                                           │
│  • name                                                         │
│  • email                                                        │
│  • role (admin/teacher/student/parent)                         │
│  • class (for students)                                        │
│  • createdAt (timestamp)                                       │
│  • profileImage (optional)                                     │
│  • phoneNumber (optional)                                      │
└────────────────────────────────────────────────────────────────┘

D3: CLASSES COLLECTION (Firestore)
┌────────────────────────────────────────────────────────────────┐
│  • classId (Document ID)                                       │
│  • departmenttitle (e.g., "Computer Science")                  │
│  • departmentcode (e.g., "CS101")                              │
│  • classname (e.g., "3rd Year BCA")                            │
│  • section (e.g., "A", "B")                                    │
│  • teacherId (assigned teacher)                                │
│  • createdAt (timestamp)                                       │
│  • latitude (geofence center)                                  │
│  • longitude (geofence center)                                 │
│  • radius (geofence radius in meters)                          │
└────────────────────────────────────────────────────────────────┘

D4: STUDENTS SUBCOLLECTION (Firestore)
Path: Classes/{classId}/Students/{studentId}
┌────────────────────────────────────────────────────────────────┐
│  • studentId (Document ID)                                     │
│  • name                                                         │
│  • rollNumber                                                   │
│  • email                                                        │
│  • deviceId (for geofencing)                                   │
│  • enrolledAt (timestamp)                                      │
└────────────────────────────────────────────────────────────────┘

D5: ATTENDANCE SUBCOLLECTION (Firestore)
Path: Classes/{classId}/Students/{studentId}/attendance/{date}_{period}
┌────────────────────────────────────────────────────────────────┐
│  • attendanceId (Document ID: "YYYY-MM-DD_periodId")           │
│  • date (timestamp)                                            │
│  • period (period number/ID)                                   │
│  • status (present/absent/late)                                │
│  • markedBy (teacher/auto)                                     │
│  • markedAt (timestamp)                                        │
│  • autoMarked (boolean)                                        │
│  • entryTime (timestamp, for late detection)                   │
│  • periodTime (e.g., "09:30 AM - 10:30 AM")                    │
│  • lateAfter (e.g., "10:00 AM")                                │
└────────────────────────────────────────────────────────────────┘

D6: GEOFENCE SETTINGS (SharedPreferences - Local)
┌────────────────────────────────────────────────────────────────┐
│  • geomute_is_inside (boolean)                                 │
│  • geomute_target_lat (double)                                 │
│  • geomute_target_lng (double)                                 │
│  • geomute_target_radius (double, default: 40.0)               │
│  • prev_ringer_mode (int)                                      │
│  • prev_ring_volume (int)                                      │
│  • prev_notification_volume (int)                              │
│  • prev_music_volume (int)                                     │
│  • prev_dnd_filter (int)                                       │
│  • last_geofence_event (timestamp)                             │
└────────────────────────────────────────────────────────────────┘

D7: NOTIFICATIONS COLLECTION (Firestore)
┌────────────────────────────────────────────────────────────────┐
│  • notificationId (Document ID)                                │
│  • userId (recipient)                                          │
│  • title                                                        │
│  • message                                                      │
│  • type (attendance/announcement/alert)                        │
│  • read (boolean)                                              │
│  • createdAt (timestamp)                                       │
└────────────────────────────────────────────────────────────────┘

D8: ENROLLMENT COLLECTION (Firestore)
┌────────────────────────────────────────────────────────────────┐
│  • enrollmentId (Document ID)                                  │
│  • parentId (parent UID)                                       │
│  • studentId (student UID)                                     │
│  • relationship (father/mother/guardian)                       │
│  • createdAt (timestamp)                                       │
└────────────────────────────────────────────────────────────────┘

D9: SHARED PREFERENCES (Local Storage)
┌────────────────────────────────────────────────────────────────┐
│  • user_preferences                                            │
│  • app_settings                                                │
│  • cached_data                                                 │
│  • geofence_state                                              │
└────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Data Flow Summary

### **Admin → System**
- Creates/Updates/Deletes: Users (Teachers, Students, Parents), Classes, Parent-Student Enrollments
- Reads: All system data, statistics, reports, enrollment records

### **Teacher → System**
- Creates/Updates: Attendance records
- Reads: Assigned classes, student lists, attendance history

### **Student → System**
- Creates: Profile updates
- Reads: Own attendance, class schedule, notifications
- Triggers: Geofencing service (automatic)

### **Parent → System**
- Reads: Child's attendance, class info, notifications, phone status
- Creates: Profile updates
- Access: Linked to students via enrollment records

### **System → External Services**
- Firebase Authentication: User login/signup
- Firestore Database: All persistent data
- GPS Service: Location tracking for geofencing
- Android DND Service: Phone muting/unmuting

---

## 📱 Key Features Data Flow

### **1. Geofencing Auto-Mute**
```
Student Location → GPS Service → Calculate Distance → Check Boundary
    ↓
If Inside (≤40m):
    Save Audio Settings → Enable DND → Mute Phone → Show Notification
    ↓
If Outside (\u003e40m):
    Restore Audio Settings → Disable DND → Unmute Phone → Hide Notification
```

### **2. Attendance Marking**
```
Teacher Selects Class → Fetch Students → Select Period & Date
    ↓
Mark Individual Status (Present/Absent/Late)
    ↓
Save to Firestore: Classes/{classId}/Students/{studentId}/attendance/{date}_{period}
    ↓
Parent Can View → Fetch Attendance Records → Display Statistics
```

### **3. User Authentication**
```
User Enters Credentials → Firebase Auth → Verify
    ↓
Fetch User Role from Firestore
    ↓
Route to Appropriate Dashboard (Admin/Teacher/Student/Parent)
```

### **4. Parent-Student Enrollment**
```
Admin Creates Parent Account → Firebase Auth + Users Collection
    ↓
Admin Links Parent to Student(s) → Enrollment Collection
    {parentId: uid, studentId: uid, relationship: "parent"}
    ↓
Parent Logs In → Fetch Enrollment Records → Get Linked Children
    ↓
Parent Views Child Data:
    - Attendance Records (from D5)
    - Class Information (from D3)
    - Phone Status (from D6)
    - Recent Activity (from D7)
```

---

## 🎯 System Characteristics

- **Multi-user System**: 4 distinct user roles with different permissions
- **Real-time Data**: Uses Firestore for live updates
- **Location-based**: Geofencing for automatic phone control
- **Hierarchical Data**: Classes → Students → Attendance
- **Parent-Child Linking**: Enrollment system for parent access
- **Automated Processes**: Geofencing service runs in background

---

**Generated for Quietly College Management System**  
**Date**: February 14, 2026  
**Version**: 2.0 - Added Parent Management & Enrollment Features

