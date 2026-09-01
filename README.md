# GovQ - Smart Queue Ticketing System for Government Offices

## Project Overview
GovQ is a smart queue management system currently tailored for the **Department of Registration of Persons (NIC Office)** in Sri Lanka. It replaces traditional "first-in, first-out" all-day queueing with an **hourly slot booking model**. This allows citizens to book a specific hour for their service, making arrival times more predictable, reducing physical waiting times, and preventing overcrowding.

### Multi-Step Workflow Model
Government services (like One-Day ID Service) require visiting multiple counters in sequence:
1. **Document Submission** (e.g., Counter 1) - ~5 mins
2. **Payment** (e.g., Counter 4) - ~3-5 mins
3. **Collection** (e.g., Counter 6)
The system tracks the citizen's progress across these stages in real-time, calling them to the correct counter sequentially without them needing to re-queue manually.

### Key Business Rules:
- **Hourly Slots:** Administrators define the capacity for each hour. Citizens book a token for a specific hour.
- **4-Hour Cancellation Rule:** Citizens can only cancel a token if there are more than 4 hours remaining before their scheduled slot.
- **7-Day No-Show Block:** If a citizen does not attend their booked slot and does not cancel legitimately, they are marked as a "no-show" and are blocked from booking further tokens for 7 days.
- **Check-In Feature:** Citizens must "Check-In" upon arriving at the lobby. The option is only available when their booked hour arrives.
- **Late Arrivals:** If a citizen arrives late but still within their booked hour, they check in and wait for the current on-time tokens in that hour to finish, maintaining flow without losing their opportunity.

## System Architecture (Three-Tier)
The system is built as a distributed application with three front-end clients communicating with a shared backend.

### 1. Citizen App (`citizen_app`)
- **Tech Stack:** Flutter / Dart
- **Role:** Citizen-facing mobile application.
- **Features:** Account registration/management, browsing services, booking hourly slots, tracking real-time queue status, and receiving push/SMS notifications (via FCM and Twilio).

### 2. Counter/Admin Dashboard (`admin_dashboard`)
- **Tech Stack:** React (Vite)
- **Role:** Web portal for office staff and administrators.
- **Features:** Staff authentication, defining hourly slots and capacities, managing tokens (Call Next, Complete, Skip/No-show, Cancel), and viewing daily statistics/analytics.

### 3. TV Display Unit (`tv_display`)
- **Tech Stack:** React (Vite)
- **Role:** Waiting area display monitor.
- **Features:** Real-time display of current and next tokens for each counter, along with automated voice announcements using the Web Speech API (supported in Chromium-based browsers).

### 4. Backend (REST API & Real-time Engine)
- **Tech Stack:** Node.js, Express, Socket.IO, Firebase Firestore.
- **Role:** Central server handling business logic and data persistence.
- **Features:** REST API for CRUD operations, Socket.IO for real-time event broadcasting (queue updates, availability, TV updates), and Firebase Firestore for scalable document storage.

## Future Development Roadmap
Based on the final report, future enhancements include:
1. **Live Pilot Deployment:** Gathering pre/post deployment waiting time data in a real government office.
2. **AI-Based Counter Allocation:** Suggesting the number of counters to open based on arrival rate patterns.
3. **Priority Queuing:** Extending the model to handle priority/fast-pass tokens.
4. **Backend System Integration:** Deep integration with existing office back-end record systems via the REST API.
5. **Multilingual Support:** Dynamic language switching (Sinhala/Tamil/English) for the UI and TV voice announcements.
6. **Load Testing:** Formal scalability analysis for high concurrent user volumes.
