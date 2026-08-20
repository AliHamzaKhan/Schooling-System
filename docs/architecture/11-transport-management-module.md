# Transport Management Module — Design & Delivery Plan

Status: **Draft for approval** · Owner: engineering · Target module: `transport`

This document expands the existing `transport` module (vehicles, routes, stops,
student assignments) into a full transport-operations feature: driver accounts
with their own login, device-based location tracking, distance-to-destination
and proximity alerts, backend route optimization, a next-destination driver
screen with drag-to-reorder, and trip history.

**No Google Maps / paid maps API for MVP** (see §3). Location comes from the
device, addresses come from an on-device geocoding package, distances are
computed with the haversine formula, and optimization runs on the backend. A map
visualization can be layered on later when a Maps API key is provisioned.

Nothing here is built yet beyond the CRUD foundation in "Current state". This is
the plan to review before implementation begins.

---

## 1. Requirements (from product)

1. Headmaster/Admin can create and manage transport **drivers**.
2. Drivers can be **assigned to students** based on their routes.
3. Each driver has a **dedicated login** to see their assigned students and
   **start/end** daily transport trips.
4. Students & guardians can **track the vehicle** while a trip is active.
5. System shows **distance/ETA** and notifies students/guardians when the driver
   is **approaching the pickup point**.
6. System **optimizes the route** on the backend from assigned students'
   coordinates and **saves the optimized order in the DB**.
7. Driver sees the **optimized order** and can **manually reorder** it.
8. System maintains **trip history**: pickup/drop-off status, timestamps, and
   route information, for tracking and reporting.

### Clarified behaviour (2026-08-18)
- **No Google Maps for now** — integrate later if needed (requires an API key).
- Use a **geocoding package** to turn latitude/longitude into a readable address.
- Driver's **current location is read from the device**.
- Store **both** the coordinates *and* the geocoded address.
- Coordinates are used to **compute distance** between driver and each
  destination/student.
- Driver location is **POSTed to the backend every 1 minute** to stay current.
- **Route optimization runs on the backend**; the optimized order is saved in
  the database.
- On the driver screen, only the **next destination** is shown prominently, at
  the **top/header**.
- Below the header, the **full list of assigned destinations/students** is shown
  **in optimized order**.
- The driver can **drag-and-drop to reorder** destinations.
- Any **manual reorder updates the active route** (persisted).

### Request → approval → assignment flow (2026-08-18, part 2)
- A **student or guardian** raises a **transport support request** from their own
  account, supplying the required details (**pickup address + location/coords**,
  plus any other required fields).
- The request goes to the **headmaster**, who **approves or rejects** it. On
  approval the headmaster **already has the pickup data** (from the request).
- The headmaster then **assigns that student to a driver**.
- **Proximity alert threshold = 500 m.**
- **Tracking:** **guardian + student + headmaster** can track the driver.
  The headmaster can track **every driver they created who is currently online**
  (has an active trip + a recent location ping).

---

## 2. Current state (what already exists)

`backend/app/models/transport.py` + `app/modules/transport/`:

| Entity | Notes |
| --- | --- |
| `Vehicle` | registration, model, capacity, **driver_name/phone as free text** (no account) |
| `Route` | name, optional `vehicle_id`, description |
| `RouteStop` | name, sequence, pickup/dropoff **time** — **no geo-coordinates** |
| `TransportAssignment` | one student → one route (+ optional stop) |

Gated by `Module.TRANSPORT`, headmaster-managed via `/schools/{id}/transport/*`.

**Gaps vs requirements:** no driver identity/login, no coordinates/addresses, no
device location capture, no trip lifecycle, no distance/proximity, no
optimization, no history.

---

## 3. Architecture decisions (recommendations + open questions)

Recommendations in **bold**; please confirm.

| # | Decision | Choice for MVP |
| --- | --- | --- |
| D1 | Driver client | **New module inside the existing Flutter app** with role-based routing (splash/role routing already exists). Reuses auth, theme, CI. |
| D2 | Maps / geo | **No Google Maps.** Device GPS via `geolocator`; reverse-geocode on device via the `geocoding` package (uses the OS geocoder, **no API key**). Straight-line **haversine** distance for all distance math. A real map view is deferred to a later "Maps integration" when a key is available. |
| D3 | Location transport | **Plain REST, one POST per minute** from the driver app while a trip is active. Riders/guardians **poll** the latest location (no WebSocket, no Redis for MVP). |
| D4 | Route optimization | **Backend**, haversine-based **nearest-neighbour from the depot (school)** with an optional **2-opt** improvement for small routes. Order saved to `transport_trips.stop_order`. No external routing service. |
| D5 | Driver route UX | **Next destination in the header**, full stop list below in optimized order, **drag-to-reorder** (`ReorderableListView`). Manual reorder persists to the active trip. No turn-by-turn navigation. |
| D6 | Location retention | Raw pings of minors are sensitive: keep raw `vehicle_locations` for the **active trip + a short window** (default 7 days, confirm), retain trip summary + per-student events long-term. |

> Geocoding note: on-device `geocoding` reverse lookups can be rate-limited or
> occasionally fail offline. The app sends coordinates always and the address
> best-effort; the backend stores whatever address arrives and never blocks a
> ping on geocoding.

---

## 4. Roles & authentication (driver login)

Add a fifth school role: **`driver`**.

- Extend `SystemRole` with `DRIVER = "driver"` and seed a system `driver` role
  per school with a narrow baseline: `TRANSPORT: {view, edit}` — enough to read
  assigned students and update trip state, nothing else.
- Headmaster **creates driver users** the same way teachers are created
  (`ROLE_MODULE_MAP` → `Module.TRANSPORT`), producing a `User` with the driver
  role plus a linked `Driver` profile.
- Driver logs in through the normal `/auth/login`; the app's role router sends a
  driver to the new **Driver module**.
- `deps.py`: add a `require_driver` guard; scope every driver query to *their
  own* assignments/trips.

> The existing `Vehicle.driver_name`/`driver_phone` free-text fields stay for
> backward compatibility but are superseded by the linked `Driver`.

---

## 5. Data model additions

New/changed tables (all `school_id`-scoped, tenant-enforced):

- **`transport_requests`** — `student_id` (FK users), `requested_by` (FK users —
  the student or their guardian), `pickup_address`, `latitude`, `longitude`,
  `notes`/details, `status` (pending/approved/rejected), `reviewed_by`,
  `reviewed_at`, `reject_reason`. The source of a student's pickup coordinates.
- **`drivers`** — `user_id` (FK users, unique), `license_no`, `phone`,
  `assigned_vehicle_id` (FK vehicles, nullable), `status`.
- **`route_stops`** — *add* `latitude`, `longitude`, `address` (nullable).
- **`transport_assignments`** — *add* pickup `latitude`, `longitude`, `address`
  (the student's pickup point, **copied from the approved `transport_request`**),
  plus optional `driver_id`, so optimization + distance have per-student
  coordinates.
- **`transport_trips`** — `route_id`, `vehicle_id`, `driver_id`, `trip_type`
  (pickup/dropoff), `status` (scheduled/in_progress/completed/cancelled),
  `started_at`, `ended_at`, **`stop_order`** (JSON — ordered list of
  student/stop ids, the current active order), `optimized` (bool).
- **`trip_student_events`** — `trip_id`, `student_id`, `status`
  (pending/boarded/absent/dropped/no_show), `event_time`, `latitude`,
  `longitude`. Per-student pickup/drop record + history.
- **`vehicle_locations`** — `trip_id`, `latitude`, `longitude`, `address`,
  `speed`, `heading`, `recorded_at`. One row per ~1-minute ping. "Latest
  location" read indexed on `(trip_id, recorded_at desc)`.

Migrations are additive (new columns, then new tables) — no change to existing
transport data.

---

## 6. Feature designs

### 6.0 Transport request → approval → assignment (reqs 1, 2)
1. **Student/guardian** submits a `transport_request` from their account with
   pickup address + coordinates and any required details → `status = pending`.
2. **Headmaster** sees pending requests, **approves** (or rejects with a reason).
   Approval carries the pickup data forward — no re-entry needed.
3. On approval the headmaster **assigns the student to a route + driver**,
   creating a `transport_assignment` whose coordinates/address are **copied from
   the request**. (Optionally, approval auto-creates a draft assignment the
   headmaster then attaches to a driver.)
4. The assigned student now appears on that driver's trips and can be tracked.

Guardians/students see their own request status; headmasters see all requests
for their school. Gated by `Module.TRANSPORT` (view/create for guardian/student,
approve for headmaster).

### 6.1 Device location + geocoding (clarified reqs)
Driver app reads GPS with `geolocator`, reverse-geocodes with `geocoding`
(on-device, no key), and every **1 minute** POSTs `{lat, lng, address, speed?,
heading?}` to `POST /transport/trips/{id}/location` while the trip is
`in_progress`. Backend stores the ping in `vehicle_locations`. Publishing stops
automatically on trip end.

### 6.2 Distance & proximity alerts (req 5)
On each ping the backend computes **haversine distance** from the driver to the
next pending student's pickup coordinate. When it drops below a threshold (e.g.
≤500 m), fire a **one-shot** "bus approaching" push per student per trip, reusing
the FCM + WhatsApp providers. New `NotificationEvent`s: `TRANSPORT_TRIP_STARTED`,
`BUS_NEAR_PICKUP`, `STUDENT_BOARDED`, `STUDENT_DROPPED` (docs already anticipate
these). A rough ETA can be shown from distance ÷ recent average speed; a precise,
road-aware ETA waits for the later Maps integration.

### 6.3 Backend route optimization (req 6)
When a trip starts (or on demand), the backend orders the assigned students'
pickup coordinates with **nearest-neighbour from the school depot** using
haversine, optionally refined by **2-opt** for small routes, and writes the
result to `transport_trips.stop_order`. Pure computation, no external service.

### 6.4 Driver route screen + manual reorder (req 7)
The driver screen shows:
- **Header:** the **next destination** (student name, address, distance) —
  prominent.
- **Below:** the **full assigned list in optimized order**, drag-to-reorder via
  `ReorderableListView`, with each student's board/absent/drop control.

A manual reorder calls `PUT /transport/trips/{id}/stop-order`, which persists the
new order to the active trip and re-derives "next destination". Marking the head
student boarded/absent advances the header to the next pending stop.

### 6.5 Trip lifecycle & history (req 3, 8)
`start` activates a `transport_trip`, runs optimization, and seeds
`trip_student_events` (all pending). Driver updates each student's status; `end`
stamps `ended_at`. History = completed trips + events, queryable by
route/driver/student/date for reports.

### 6.6 Tracking access (req 4)
- **Student / Guardian:** may track only the driver of the route their student
  is assigned to, and only while a trip is active.
- **Headmaster:** a **fleet view** of **every driver they created who is
  online** — "online" = an `in_progress` trip with a location ping in the last
  ~2 minutes. Lists each online driver's latest coordinates + address; drill
  into one driver's active trip.
- Access is always enforced server-side; a driver's location is never exposed
  outside an active trip.

---

## 7. API surface (new)

Student/Guardian — requests & tracking (assigned users only):
- `POST /transport/requests` — raise a transport request (address, coords, notes)
- `GET /transport/requests/mine` — my request(s) + status
- `GET /transport/trips/active` — is my child's bus running?
- `GET /transport/trips/{id}/location` — latest coordinates + address (polled)
- `GET /transport/trips/{id}/eta` — distance/ETA to my stop

Headmaster (gated `Module.TRANSPORT`):
- `GET /transport/requests` — all requests; `POST /transport/requests/{id}/approve`
  · `/reject`
- `POST /transport/assignments` — assign approved student → route + driver
  (coords copied from the request)
- `POST/GET/PATCH/DELETE /transport/drivers`; `POST /transport/drivers/{id}/assign-vehicle`
- `GET /transport/drivers/online` — **fleet view**: my online drivers + latest location
- `GET /transport/trips`, `GET /transport/trips/{id}` — history/reporting

Driver (role `driver`, own data only):
- `GET /transport/me/assignments`
- `POST /transport/trips/{id}/start` · `/end`
- `GET /transport/trips/{id}` — optimized `stop_order` + next destination
- `PUT /transport/trips/{id}/stop-order` — persist manual reorder
- `POST /transport/trips/{id}/students/{sid}/status` — boarded/absent/dropped
- `POST /transport/trips/{id}/location` — 1-minute GPS + address ping

---

## 8. Frontend work (Flutter / GetX)

- **Guardian/Student:** raise a **transport request** (pickup address + capture
  device location + notes) and see its status; "Track bus" screen showing
  last-known **address + distance/ETA** to their stop (text/list for MVP; map
  view arrives with the later Maps integration), plus push alerts.
- **Headmaster:** **requests inbox** (approve/reject); **assign** approved
  student → route + driver; Drivers CRUD; **fleet view** of online drivers; trip
  history & reports.
- **Driver (new role module):** login → today's trip; **next-destination
  header**; **reorderable** student list in optimized order; board/absent/drop
  controls; **1-minute background location** publishing (device GPS +
  `geocoding`) while a trip is active; start/end trip.

Packages: `geolocator` (device GPS + permissions), `geocoding` (reverse geocode,
no key). Both are free and keyless.

---

## 9. Cross-cutting concerns

- **Privacy/safety:** live location of minors — strict access scoping (only
  assigned guardians/students), driver location only while on trip, retention
  purge (D6), and a school-level toggle to disable live sharing. Confirm
  consent/notice requirements.
- **Battery/permissions:** background location must be throttled to the 1-minute
  cadence and stop on trip end; handle iOS/Android "always" location permission
  and geocoder rate limits gracefully.
- **Offline:** queue pings when the driver has no signal and flush on reconnect;
  never block a ping on geocoding.
- **Permissions:** everything stays under `Module.TRANSPORT` (premium plan),
  consistent with the current catalog.

---

## 10. Phased delivery

| Phase | Scope | Delivers |
| --- | --- | --- |
| **P1 — Foundation** ✅ *backend done* | **Transport request → approve → assign** flow, driver role + login, headmaster driver CRUD, coordinate/address fields, trip lifecycle (start/end + board/absent/drop), trip history endpoints. | Reqs 1, 2, 3, 8 + requests. |
| **P2 — Location + optimization** ✅ *backend done* | 1-minute device location ingestion (coords + geocoded address), backend haversine optimization saved to `stop_order`, `next_student_id` for the driver header. Frontend drag-to-reorder pending. | Reqs 6, 7 + the driver tracking core. |
| **P3 — Tracking + alerts** ✅ *backend done* | Guardian/student + headmaster **fleet** tracking (polling), distance/ETA, 500 m proximity + trip-started/boarded/dropped notifications (new NotificationEvents, opt-in per school). | Reqs 4, 5. |
| **P4 — Maps integration (later, optional)** | Add a real map view for driver + riders once a Google Maps (or alternative) API key is provisioned; road-aware ETA. | Visual upgrade. |

Each phase is independently shippable and testable.

---

## 11. Decisions

**Confirmed (2026-08-18):**
- Proximity alert threshold = **500 m**.
- Tracking scope = **student + guardian + headmaster**; headmaster tracks every
  driver they created who is **online**.
- Pickup coordinates come from the **student/guardian's transport request**
  (approved by the headmaster) — not entered by the headmaster from scratch.

**Still open:**
1. **Location retention window** for raw GPS pings of minors (default 7 days) and
   whether live sharing needs explicit guardian consent/notice.
2. Whether request **approval auto-creates a draft assignment**, or the
   headmaster assigns as a fully separate step after approving.
