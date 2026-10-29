# SmartCharge — Privacy Policy

**Effective Date:** October 21, 2026  
**Developer:** Vicky Neves Rohr  
**Contact:** `privacy@smartcharge-ev.com`  

SmartCharge is designed with privacy at its core. We believe your travel patterns, vehicle specifications, and daily routes belong to you alone. SmartCharge does not sell, broker, or monetize your personal information.

---

## 1. Information Storage & Processing Architecture

### Local-First Persistence (Core Data)
All sensitive application data is stored exclusively on your device using Apple's encrypted Core Data framework:
- **Vehicle Profiles:** Vehicle make, model, usable battery capacity, and connector configurations.
- **Saved Journeys:** Departure and arrival location names, planned charging stops, and selected preferences.
- **User Preferences:** Configured safety reserve percentages and preferred charging strategies.
- **Favourite Stations:** Bookmarked charging hubs.

This information is never transmitted to any third-party server or developer backend.

---

## 2. Apple MapKit & Location Queries

SmartCharge utilizes native Apple MapKit APIs for geographic services:
- **Address Autocomplete (`MKLocalSearchCompleter`):** Natural language search queries typed into the origin/destination fields are processed directly by Apple MapKit to provide relevant Australian geographic suggestions.
- **Geocoding & Directions (`MKLocalSearch`, `MKDirections`):** Departure and destination coordinates are transmitted to Apple to compute realistic highway driving distances, expected travel durations, and road polylines.

All geographic requests are handled under [Apple's Privacy Policy](https://www.apple.com/legal/privacy/). SmartCharge does not track your live GPS position in the background.

---

## 3. Analytics, Tracking & Advertising

- **Zero Tracking SDKs:** SmartCharge contains no third-party tracking libraries (no Google Firebase, Meta SDK, or behavioral trackers).
- **Zero Third-Party Advertising:** The application contains no banner ads, interstitials, or affiliate ad links.
- **Zero Account Requirement:** You do not need to register an account, provide an email address, or link personal credentials to use SmartCharge.

---

## 4. Children’s Privacy

SmartCharge does not knowingly collect or solicit personal data from children under the age of 13.

---

## 5. Changes to This Privacy Policy

Any minor updates to this Privacy Policy will be reflected in future App Store releases and documented within the open-source repository.

---

## 6. Questions & Contact

For questions regarding this privacy policy, please contact:  
**Vicky Neves Rohr**  
Author & Lead Engineer — SmartCharge  
GitHub: `https://github.com/vickyneves/SmartCharge`
