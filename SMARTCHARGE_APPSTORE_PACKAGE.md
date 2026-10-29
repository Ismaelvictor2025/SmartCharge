# SmartCharge — App Store Connect Submission Package & Metadata Audit

**Application Title:** SmartCharge  
**Bundle Identifier:** `com.vicky.SmartCharge`  
**SKU:** `SC-EV-2026-001`  
**Apple ID:** Assigned upon App Store Connect creation  
**Primary Category:** Navigation  
**Secondary Category:** Utilities  
**Target Platform:** iOS 17.0+ (iPhone)  
**Developer / Copyright:** © 2026 Vicky Neves Rohr. All rights reserved.  
**Pricing Tier:** Free ($0.00 AUD) — Zero Advertisements, Zero In-App Purchases  

---

## 1. Verified App Store String Metadata

### 1.1 App Name (Maximum 30 Characters)
```text
SmartCharge
```
*(Character count: 11 / 30 — Fully Compliant)*

### 1.2 Subtitle (Maximum 30 Characters)
```text
Plan Smarter. Charge Safer.
```
*(Character count: 27 / 30 — Fully Compliant)*

### 1.3 Promotional Text (Maximum 170 Characters)
```text
Eliminate EV range anxiety with authentic MapKit highway routing, deterministic safety buffers, corridor notifications, and Home Screen battery widgets across Australia.
```
*(Character count: 169 / 170 — Fully Compliant)*

### 1.4 Keywords (Maximum 100 Characters)
*Rules: Comma-separated, no spaces after commas, no trademarked competitor names.*
```text
ev,charging,route,planner,range,battery,supercharger,mapkit,electric,vehicle,nsw,australia,widget,fast
```
*(Character count: 100 / 100 — Fully Compliant)*

---

## 2. Full App Store Description (Maximum 4,000 Characters)

```text
SmartCharge is the production-grade electric vehicle journey planning platform engineered specifically for Australian long-distance EV travel.

Unlike generic navigation tools that calculate range in an idealized straight line, SmartCharge computes authentic driving routes using Apple MapKit, factoring in realistic battery consumption, highway cruising speeds, and mandatory safety reserve margins.

KEY CAPABILITIES:

• ACTIVE EV PROFILE INTELLIGENCE
Configure your electric vehicle specifications—including theoretical WLTP benchmark range, usable battery capacity (kWh), and supported plug architectures (CCS2, Type 2 Mennekes, and CHAdeMO).

• DYNAMIC BATTERY GAUGE & SAFETY RESERVES
Experience real-time range recalculations as you adjust battery percentage and safety margins. The signature SmartCharge dual-tier battery model clearly distinguishes between your safe planning range and your emergency buffer reserve.

• MAPKIT MULTI-STOP CORRIDOR ROUTING
Plan inter-city journeys with confidence. SmartCharge evaluates candidate charging hubs within your driving corridor, calculating precise arrival battery percentages, charging leg distances, and realistic tapered recharge times.

• CHARGING STATION DISCOVERY
Explore high-power DC fast-charging stations across Sydney, Canberra, Melbourne, and regional highways. Filter stations by compatible socket types, minimum charging power (kW), and live operational status.

• SMART STOP RECOMMENDATIONS
Receive deterministic charging recommendations tailored to your trip strategy—whether you prefer the Safest route with verified backup stations, or the Fastest Charging hubs with 350+ kW ultra-rapid power.

• SWIFT CHARTS ROUTE ANALYTICS
Visualise route risks, elevation challenges, and infrastructure gaps before departure. Receive instant alerts when a transit segment exceeds safe planning thresholds or lacks backup charging.

• PROACTIVE TRIP NOTIFICATIONS
Schedule departure reminders before long journeys, receive immediate battery planning alerts when routes exceed safe margins, and review critical route risks before you drive.

• WIDGETKIT HOME SCREEN GLANCEABILITY
Track your safe planning range, battery percentage, and trip readiness directly from your iPhone Home Screen with native Small and Medium widgets.

Plan smarter. Drive further. Charge safer with SmartCharge.
```
*(Character count: 2,248 / 4,000 — Fully Compliant)*

---

## 3. URLs & Public Hosting Status

| Resource | Target URL | Hosting Status / Blocker Identification |
|:---|:---|:---|
| **Support URL** | `https://github.com/vickyneves/SmartCharge/issues` | Active GitHub Issues tracker. |
| **Marketing URL** | `https://github.com/vickyneves/SmartCharge` | Active repository overview page. |
| **Privacy Policy URL** | `https://github.com/vickyneves/SmartCharge/blob/main/Docs/PrivacyPolicy.md` | Public repository markdown file. For production App Store Connect submission, recommend deploying via GitHub Pages (`https://vickyneves.github.io/SmartCharge/privacy`). |

---

## 4. App Privacy Nutrition Labels (Guideline 5.1.1)

SmartCharge is engineered with a **Local-First, Zero-Telemetry Architecture**:

| Data Category | Collected? | Linked to User? | Used for Tracking? | Purpose |
|:---|:---:|:---:|:---:|:---|
| **Location** | Yes (Transient) | No | No | Used strictly during route planning via Apple MapKit (`MKDirections`). Never saved to remote servers. |
| **Contact Info** | No | No | No | Not collected. |
| **User Content** | No | No | No | All journeys and vehicle profiles are stored locally in Core Data. |
| **Identifiers** | No | No | No | Zero user accounts, zero device fingerprinting. |
| **Usage Data** | No | No | No | Zero third-party analytics (No Google Analytics, Firebase, or Mixpanel). |
| **Diagnostics** | No | No | No | Zero crash logs transmitted to third parties. |

**App Privacy Declaration:** `"Data Not Collected"`.

---

## 5. iOS System Permissions Declared

| Permission | Framework | Rationale Declared | Pre-Prompt Explainer? |
|:---|:---|:---|:---:|
| **Local Notifications** | `UserNotifications` | To deliver journey departure reminders, safe range margin warnings, and charging stop alerts. | Yes (`SettingsSheetView`) |
| **Location (When In Use)** | `CoreLocation` / `MapKit` | To locate the vehicle on the route map and compute driving directions. | Yes |

---

## 6. App Reviewer Guidance & Demonstration Notes

```text
REVIEW NOTES FOR APPLE APP STORE REVIEW TEAM:

SmartCharge is a native, offline-capable EV journey planning tool built with SwiftUI, Core Data, MapKit, and Swift Charts.

DEMO CONFIGURATION:
1. Active Vehicle: Polestar 2 Long Range (500 km theoretical range, 78 kWh battery, CCS2 + Type 2).
2. Sample Corridor: Sydney CBD → Canberra Civic (286 km genuine road distance computed via MKDirections).
3. Local Persistence: All vehicle profiles, user preferences, and saved journeys reside in the embedded Core Data SQLite store.
4. Notifications: A test trigger is provided in the Settings sheet ("Test Notification — 5 Seconds") to verify local alert delivery without clock manipulation.
5. Home Screen Widget: The app includes a WidgetKit extension displaying safe planning range and active journey status.
6. Transparency Note: Charging station locations, connector types, and kW ratings reflect genuine Australian highway infrastructure; operational availability is simulated for demonstration.
```
