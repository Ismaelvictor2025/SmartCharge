# SmartCharge — App Store Connect Metadata & Submission Package

**Application Name:** SmartCharge  
**Bundle Identifier:** `com.vicky.SmartCharge`  
**Primary Category:** Navigation  
**Secondary Category:** Utilities  
**Target iOS Version:** iOS 17.0+  
**Device Family:** iPhone (Optimized for iPhone 15, 16, and 17 series)  
**Version:** 1.0.0  
**Build Number:** 1  
**Copyright:** © 2026 Vicky Neves Rohr. All rights reserved.  

---

## 1. App Store Strings & Character Limits

### App Name (Max 30 characters)
```text
SmartCharge
```
*(Length: 11 characters)*

### Subtitle (Max 30 characters)
```text
Plan Smarter. Charge Safer.
```
*(Length: 27 characters)*

### Promotional Text (Max 170 characters)
```text
Eliminate EV range anxiety with real MapKit highway routing, deterministic safety buffers, and verified fast-charging corridors across Australia.
```
*(Length: 145 characters)*

### Keywords (Max 100 characters, comma-separated, no spaces after commas)
```text
ev,charging,route,planner,range,battery,tesla,supercharger,mapkit,electric,vehicle,nsw,australia,fast
```
*(Length: 99 characters)*

---

## 2. Full App Store Description

```text
SmartCharge is the production-grade electric vehicle journey planning platform engineered specifically for Australian long-distance EV travel. 

Unlike generic mapping tools that calculate theoretical range in a straight line, SmartCharge computes genuine driving distances using Apple MapKit, factoring in realistic battery degradation, highway cruising speeds, and mandatory safety reserve margins.

KEY CAPABILITIES:

• ACTIVE EV PROFILE INTELLIGENCE
Seamlessly configure your electric vehicle specifications—including theoretical WLTP benchmark range, usable battery capacity (kWh), and supported plug architectures (CCS2, Type 2 Mennekes, and CHAdeMO).

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

Plan smarter. Drive further. Charge safer with SmartCharge.
```

---

## 3. Support & Marketing URLs

- **Support URL:** `https://github.com/vickyneves/SmartCharge/issues`
- **Marketing URL:** `https://github.com/vickyneves/SmartCharge`
- **Privacy Policy URL:** `https://github.com/vickyneves/SmartCharge/blob/main/Docs/PrivacyPolicy.md`

---

## 4. App Store Promotional Screenshot Captions

| Screenshot File | Subject Screen | App Store Marketing Caption |
| :--- | :--- | :--- |
| `01_Dashboard_BatterySafety.png` | Journey Dashboard | **Plan Smarter. Charge Safer.**<br>Real-time battery gauge and safe planning reserve buffers. |
| `02_JourneyPlanner.png` | Journey Planner | **Multi-Stop EV Highway Routing**<br>Apple MapKit driving routes with automatic charging stop allocation. |
| `03_StationFinder.png` | Station Finder | **Verified Australian Fast Chargers**<br>Filter by CCS2, Type 2, power output, and live operational status. |
| `04_SmartRecommendations.png` | Smart Recommendations | **Deterministic Reachability Analysis**<br>Transparent stop recommendations ranked by your travel strategy. |
| `05_RouteAnalytics.png` | Route Analytics | **Visual Range & Risk Analytics**<br>Swift Charts analytics and early infrastructure gap warnings. |

---

## 5. Review Notes for App Store Review Team

```text
SmartCharge is an offline-capable and privacy-respecting EV journey planner. 
- The application stores all vehicle profiles, preferences, and saved trips locally in Core Data.
- Network access is strictly utilised for Apple MapKit routing (MKDirections) and address geocoding (MKLocalSearch).
- No third-party analytics or tracking SDKs are embedded.
- No user account or subscription is required to access all core features.
```
