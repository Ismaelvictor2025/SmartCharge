# SmartCharge — App Store Connect Privacy Nutrition Label Disclosure

This document provides exact responses for the **App Privacy** questionnaire in Apple App Store Connect.

---

## 1. Data Collection Overview

**Question:** Do you or your third-party partners collect data from this app?  
**Answer:** **No, we do not collect data.**

SmartCharge does not collect, harvest, or transmit any user data to external servers or developer backends.

---

## 2. Category-by-Category Verification

| Data Category | Collected? | Linked to User? | Used for Tracking? | Details |
| :--- | :--- | :--- | :--- | :--- |
| **Contact Info** (Name, Email, Phone, Address) | **NO** | N/A | N/A | No user accounts or login required. |
| **Health & Fitness** | **NO** | N/A | N/A | Not applicable to EV navigation. |
| **Financial Info** | **NO** | N/A | N/A | No payment or banking details collected. |
| **Precise Location** | **NO** | N/A | N/A | Background GPS is not requested; coordinates are resolved ephemerally via MapKit. |
| **Coarse Location** | **NO** | N/A | N/A | Processed on-device / ephemerally by Apple MapKit. |
| **Sensitive Info** | **NO** | N/A | N/A | Zero sensitive data collected. |
| **Contacts** | **NO** | N/A | N/A | Address book access is not requested. |
| **User Content** (Photos, Audio, Notes) | **NO** | N/A | N/A | Stored strictly in local Core Data SQLite sandbox. |
| **Browsing / Search History** | **NO** | N/A | N/A | Station and route searches are processed via Apple MapKit APIs. |
| **Identifiers** (Device ID, Advertising ID) | **NO** | N/A | N/A | Zero IDFA or vendor identifiers tracked. |
| **Usage Data** (Product Interaction) | **NO** | N/A | N/A | No telemetry or analytics SDKs integrated. |
| **Diagnostics** (Crash Logs, Performance Data) | **NO** | N/A | N/A | Handled anonymously by Apple iOS opt-in diagnostic reporting only. |

---

## 3. Third-Party Framework Audit

Static analysis of linked frameworks:
- `SwiftUI`: Apple UI framework
- `CoreData`: Apple local encrypted database
- `MapKit`: Apple native navigation & routing
- `Charts`: Apple native data visualization
- `Combine`: Apple reactive streams
- `Testing / XCTest`: Apple native test frameworks

**Third-Party SDKs Present:** **0 (Zero)**

---

## 4. App Store Connect Declaration Summary

In App Store Connect under **App Privacy**:
- Select: **"No, we do not collect data from this app"**.
- Resulting App Store badge: **"Data Not Collected" — The developer does not collect any data from this app.**
