# 📱 ComMobi-Tracker

### 📄 PROTOTYPE PROOF OF CONCEPT DOCUMENT
**Project:** ComMobi-Tracker  
**Institutional Partners:** MINPROFF (Ministry of Women's Empowerment and the Family) / UNICEF Cameroon

---

## 📝 Project Overview
**ComMobi-Tracker** is a mobile application and decision-making dashboard designed for field facilitators and institutional leaders in Cameroon. It streamlines household tracking, promotes positive parenting, supports community sessions, and enables rapid child protection alert reporting—even in areas with low connectivity.

---

## 🚀 Key Features

### 1. Mobile Interface & Facilitator Onboarding
The application features a clean dashboard designed for quick and intuitive use on the ground:
* **Emergency Reporting:** A prominent red top banner allows instant reporting of critical cases like abuse, early marriage, and exploitation.
* **Field KPIs:** Real-time display of registered households, pending evaluations, and GPS tracking status.
* **Positive Masculinity Calculator:** A synthetic Positive Masculinity Index (PMI) measures fathers' actual engagement in awareness tracks.
* **Simplified Navigation:** A bottom navigation bar provides one-click access to *Families*, *Support Groups (GSP)*, *Map*, and *Settings*.

<div align="center">
  <img src="images/interface_dashboard.png" width="31%" alt="Dashboard View" />
  <img src="images/interface_alerts.png" width="31%" alt="Alert Banner View" />
  <img src="images/interface_navigation.png" width="31%" alt="Navigation Menu" />
</div>

### 2. Individual Household Tracking & Offline-First Collection
Family management operates on a personalized support model with fully functional offline capabilities:
* **Family Portfolio Management:** Quick household lists using color-coded indicators to spot emergencies (**Red**), partial tracking (**Orange**), and complete tracking (**Green**).
* **Detailed Household Profile:** Instant access to visit histories, topics covered (Civil Status, WASH), and visit dates.
* **Registration Form & GIS:** Structured data capture for the head of household, child count, and precise GPS coordinates (latitude and longitude).
* **Administrative Mapping:** Rigorous family classification by Region, Division, and Sub-division.

<div align="center">
  <img src="images/tracking_portfolio.png" width="31%" alt="Family Portfolio" />
  <img src="images/tracking_profile.png" width="31%" alt="Household Profile" />
  <img src="images/tracking_gps_form.png" width="31%" alt="GPS Registration Form" />
</div>

### 3. Educational Modules & Community Session Facilitation
To ensure contextualized awareness training, the app embeds the full facilitator’s guide broken down into **10 official modules**:
* **Structured Content:** Direct access to core themes like child rights, the first 1000 days, non-violent discipline, and family budgeting.
* **Voice Assistance (TTS):** Integrated Text-to-Speech functionality reads key messages aloud for vulnerable or low-literacy parents.
* **Flexible Note-Taking:** Field observations can be captured via traditional typing or voice dictation.
* **GSP Community Session Reports:** Gender-disaggregated participant counting, automated male participation index calculation, and field photo proof attachment.

<div align="center">
  <img src="images/modules_list.png" width="31%" alt="10 Educational Modules" />
  <img src="images/modules_tts.png" width="31%" alt="Voice Assistance Interface" />
  <img src="images/modules_gsp_report.png" width="31%" alt="GSP Session Reporting" />
</div>

### 4. GIS Mapping & Rapid Alert Response
An interactive mapping module helps field agents and regional delegates visualize vulnerabilities and act fast:
* **Map Visualization:** Pinpoints families on road or satellite views using status markers (Green, Orange, Red).
* **Priority Alert Management:** Clicking a red marker instantly opens an emergency intervention form, kicking off evaluations in under 10 minutes.
* **Location Filtering:** Targeted data views based on the user's exact area (e.g., Maroua, Mabanda).

<details>
  <summary>📸 Click to expand mapping screenshots (3 views)</summary>
  <br>
  <p align="center">
    <img src="images/map_satellite_view.png" width="90%" alt="Satellite Cluster Map" /><br><br>
    <img src="images/map_alert_popup.png" width="90%" alt="Emergency Intervention Form" /><br><br>
    <img src="images/map_zone_filter.png" width="90%" alt="Regional Filter View" />
  </p>
</details>

---

## 🌍 Inclusion, Accessibility & Bilingualism
Built to meet digital accessibility standards and respect the national linguistic context of Cameroon:
* **Instant Bilingualism:** Seamless toggle of the entire interface between **English** and **French**.
* **High Contrast Mode:** Color inversion (black background with yellow outlines) for high-sunlight readability and low-vision users.
* **Accessibility Settings:** Dynamic font size adjustments and Text-to-Speech screen reading options for visually impaired field agents.

<div align="center">
  <img src="images/access_bilingual_toggle.png" width="31%" alt="Language Switch" />
  <img src="images/access_high_contrast.png" width="31%" alt="High Contrast Mode" />
  <img src="images/access_font_scaling.png" width="31%" alt="Dynamic Font Scaling" />
</div>

---

## 📊 Strategic Decision Dashboard (Power BI)
A centralized business intelligence platform for **MINPROFF** and **UNICEF** managers to track program impact in real time:
* **Performance Indicators (KPIs):** Live tracking of accompanied families, completed community sessions, and adoption rates of non-violent discipline.
* **Consolidated Regional Mapping:** Spatial analysis across regional clusters (*Littoral, Centre, Far-North*) powered by Azure Maps.
* **Trend Analysis:** Comparative charts monitoring the decline of corporal punishment against the rise of positive reinforcement.
* **Confidential Registry & Exports:** Secure tracking of sensitive alerts (early marriage, neglect) with quick data exports to **PDF, Excel, and CSV** for official reporting.

<details>
  <summary>📸 Click to expand Power BI analytics dashboards (3 views)</summary>
  <br>
  <p align="center">
    <img src="images/dashboard_main_kpis.png" width="90%" alt="Main Program KPIs" /><br><br>
    <img src="images/dashboard_regional_clusters.png" width="90%" alt="Azure Maps Spatial Analysis" /><br><br>
    <img src="images/dashboard_trend_analytics.png" width="90%" alt="Trend Charts & Secure Exports" />
  </p>
</details>

---

## 🛠️ How to Add Your Screenshots
To ensure your pictures appear flawlessly in these grids, follow these steps:
1. In your project's root folder, create a directory called `images`.
2. Save your screenshots into that folder.
3. Rename your image files to match the filenames inside the `src="..."` tags exactly (e.g., save your dashboard image as `interface_dashboard.png`).
