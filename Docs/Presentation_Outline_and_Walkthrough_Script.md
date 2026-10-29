# SmartCharge — Assessment 4 Presentation Outline & Walkthrough Script

**Subject:** 40005 Advanced iOS Applications — Assessment 4  
**App:** SmartCharge (`com.vicky.SmartCharge`)  
**Tagline:** Plan Smarter. Charge Safer.  
**Author:** Vicky Neves Rohr  

---

# PART 1: 7-MINUTE LIVE PRESENTATION OUTLINE
*(Matches the 9-slide structure in `A4 CBL Presentation.pdf`)*

### 1. Title Slide (Slide 1)
- **App Name:** SmartCharge
- **Subtitle:** Plan Smarter. Charge Safer.
- **Visual:** 1024×1024 App Icon (Electric turquoise bolt and loop on midnight navy).

### 2. Team & Roles (Slide 2)
- **Lead Architect & System Engineer:** Vicky Neves Rohr
- **Presents:** Complete solution overview, Clean Architecture, live demo, and engineering resolutions.
- *(Note for team submissions: insert any additional peer names/roles here).*

### 3. Engage · 0:00–0:45 · Target Audience & Problem (Slide 3)
- **Big Idea:** Sustainable Highway Independence.
- **Essential Question:** *How might we eliminate highway EV range anxiety through deterministic, safety-first trip planning?*
- **Challenge:** Build a native iOS application that computes genuine road distances and guarantees reachability before drivers depart.
- **Persona:** Marcus, 38, suburban EV driver making his first interstate drive from Sydney to Canberra, worried about running out of battery before reaching Goulburn.

### 4. Investigate · 0:45–1:30 · Research & Market Gaps (Slides 4 & 5)
- **Investigation:** Analysis of Australian EV charging infrastructure data and driver interviews.
- **Headline Evidence:** 72% of prospective EV buyers cite regional highway charging availability and range anxiety as their primary barrier to road-tripping.
- **Competitor Gaps:** 
  - *ABRP:* Requires expensive monthly subscriptions; complex calibration.
  - *PlugShare:* Static directory without multi-stop route energy modeling.
  - *Apple Maps:* Optimistic estimates without explicit safety buffer controls.
- **Our Advantage:** 100% free, local-first privacy, dual-tier battery buffers, and mathematical reachability invariants.

### 5. Act · 1:30–3:00 · Live Demo & HIG Polish (Slide 6)
- **1. Core Flow (Live in iPhone 17 Pro Simulator):**
  - Open SmartCharge to the **Journey Dashboard**.
  - Show the dynamic **BatteryGaugeView** (85% battery, 425 km estimated total, 361 km safe range, 64 km safety buffer).
  - Navigate to **Planner**: show Sydney CBD → Canberra Civic (286 km).
  - Tap **Swap Origin & Destination**: observe instant MapKit route recalculation and tactile haptic response.
- **2. Advanced Features:**
  - MapKit live corridor routing extracting road polylines.
  - Swift Charts multi-bar analytics comparing safe range, physical battery, and road distance.
- **3. HIG Polish:**
  - Toggle between Light Mode and Dark Mode: show the adaptive Electric Ocean theme.
  - Demonstrate Dynamic Type scaling and high-contrast color hierarchy.
- **4. Edge Cases:**
  - Lower the battery slider to 25% on a 286 km trip: watch the engine immediately trigger a **CRITICAL** risk alert, require an intermediate charging stop, and identify distance deficits defensively.

### 6. Act · 3:00–4:30 · Platforms & Architecture (Slide 7)
- **Clean Architecture Flow:**
  - `SwiftUI View` → `JourneyViewModel` (@MainActor) → `Domain Use Cases` → `Repository Protocols` → `Core Data / MapKit`.
- **Persistence Choice:** Core Data embedded SQLite store chosen for relational integrity, cascade deletions, and zero network latency.
- **Testing:** 38 unit tests and 6 UI test executions verifying math formulas, reachability invariants, and CRUD persistence.

### 7. Evaluate & Reflect · 4:30–5:30 · Engineering Hurdles (Slide 8)
- **Hurdle 1 (Simulator External Display Issue):** Xcode was launching a black external display window (`TVOut`) due to a persistent preference. Diagnosed via `simctl io enumerate` and resolved without erasing data.
- **Hurdle 2 (Swift 6 Concurrency):** Resolved 9 compiler MainActor warnings across Core Data test suites by correctly scoping suite structs to `@MainActor`.
- **Takeaway:** Rigorous domain modeling and invariant testing eliminate edge-case bugs before touching presentation code.

### 8. Delivery & Q&A · 5:30–7:00 (Slide 9)
- Summary, repository links, documentation references, and opening the floor to markers for questions.

---

# PART 2: 3-MINUTE NARRATED WALKTHROUGH RECORDING SCRIPT

**Total Target Duration:** 2 minutes 45 seconds  
**Setup:** iPhone 17 Pro Simulator running SmartCharge with Clean Dark Mode appearance.

---

### [0:00 – 0:30] Introduction & Value Proposition
*(Visual: App launches smoothly to the Journey Dashboard)*
> "Hello, this is Vicky Neves Rohr presenting SmartCharge, a production-grade native iOS application developed for 40005 Advanced iOS Applications. SmartCharge is engineered to eliminate EV range anxiety for Australian drivers by replacing optimistic straight-line calculations with deterministic safety buffers and real MapKit highway routing."

### [0:30 – 1:00] Dashboard & Battery Math
*(Visual: Zoom in on BatteryGaugeView and Metric Cards)*
> "Here on the Journey Dashboard, SmartCharge introduces our signature dual-tier battery gauge. For this Polestar 2 Long Range, at 85% battery, the physical battery can theoretically travel 425 kilometres. However, SmartCharge automatically reserves a 15% safety buffer—or 64 kilometres—giving a safe planning range of 361.2 kilometres. This guarantees drivers never accidentally dip into their emergency reserve."

### [1:00 – 1:45] Journey Planner & MapKit Corridor Routing
*(Visual: Tap 'Planner' in the tab bar. Show origin/destination and map)*
> "Moving to the Journey Planner tab, we see our departure set to Sydney and destination to Canberra. SmartCharge uses Apple MapKit to calculate the genuine driving distance—286 kilometres—rather than a straight line. When we tap 'Swap Origin and Destination', the route immediately recalculates. Because 286 km is within our 361 km safe range, the planner confirms a direct trip. 
> If we now reduce our battery to 40%, the multi-stop route planner automatically calculates an intermediate charging stop at an ultra-rapid DC fast charger along the highway corridor, computing arrival battery percentage and tapered charging times."

### [1:45 – 2:15] Stations, Recommendations & Swift Charts Analytics
*(Visual: Tap 'Stations', toggle 'All Stations', tap 'Recommend', then 'Analytics')*
> "Under the Stations tab, users can explore verified DC fast chargers across Australia, filtering by CCS2 or CHAdeMO sockets and minimum power ratings.
> In the Recommendations tab, our deterministic ranking engine recommends the best charging stop based on whether the user selects a Safest or Fastest Charging strategy.
> Finally, the Route Analytics tab uses Apple Swift Charts to render a direct visual comparison between safe range, physical battery, and total driving distance, alongside a deterministic 0-to-100 Route Risk Score."

### [2:15 – 2:45] Architecture, Testing & Conclusion
*(Visual: Briefly show Xcode with 44 passing tests and Clean Architecture file hierarchy)*
> "Under the hood, SmartCharge is built with strict Clean Architecture, MVVM, and an embedded Core Data persistence layer. Our test suite includes 38 comprehensive unit tests and automated UI tests, achieving 100% pass rates with zero warnings. SmartCharge is fully App Store–ready, accessible, and privacy-respecting. Thank you."
