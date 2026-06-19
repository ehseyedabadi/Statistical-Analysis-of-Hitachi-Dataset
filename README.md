# Statistical Analysis of Hitachi Rail High-Speed Train Battery Data

Applied Principal Component Analysis (PCA), K-Means Clustering, and Multivariate Statistical Process Control (SPC) to analyze low-voltage battery discharge data across a fleet of high-speed trains. This framework identifies faulty batteries, isolates critical trains, and supports data-driven predictive maintenance pipelines.

---

## 📋 Table of Contents

* [Project Overview](https://www.google.com/search?q=%23-project-overview)
* [Dataset & Key Variables](https://www.google.com/search?q=%23-dataset--key-variables)
* [Methodology & Workflow](https://www.google.com/search?q=%23-methodology--workflow)
* [Key Statistical Insights](https://www.google.com/search?q=%23-key-statistical-insights)
* [How to Run the Code](https://www.google.com/search?q=%23-how-to-run-the-code)
* [Future Perspectives](https://www.google.com/search?q=%23-future-perspectives)
* [Contributors & Course Info](https://www.google.com/search?q=%23-contributors--course-info)

---

## 🎯 Project Overview

Low-voltage Nickel-Cadmium (Ni-Cd) batteries are critical components in high-speed trains, providing peak power during system start-ups, managing Points of Change (POC), and buffering High Voltage faults.

### Project Goals:

* **Identify Faulty Batteries:** Detect disparities and anomalous power/current behavior during discharging phases.


* **Isolate Critical Trains:** Group and rank trains in the fleet based on recurring battery system nonconformities.


* **Statistical Modeling:** Establish a resilient, multivariate process monitoring pipeline using Compositional Data (CoDa) analysis.



---

## 📊 Dataset & Key Variables

The project analyzes telemetry data from **16 high-speed trains** belonging to `FLEET_1`. Each train operates with **4 Ni-Cd low-voltage batteries** configured in a parallel connection.

| Variable Name | Description |
| --- | --- |
| `Timestamp` | Sampling time of telemetry data |
| `Vehicle` | Unique identification code across the 16 trains |
| `IBatt_Ci` | Current intensity for battery module $i$ ($i = 1, 2, 3, 4$) |
| `VBatt_Ci` | Battery voltage level for module $i$ |
| `ID_Ph_Ci` | Operating phase of the battery system |
| `ID_GR` | Discharge-charge cycle group ID |
| `VEHICLE_SPEED` | Current train speed in km/h |
| `GPS_LAT / LON` | Geospatial coordinate mapping of the train |


---

## 🛠 Methodology & Workflow

The analytics pipeline is segmented into three major operational steps:

### 1. Data Preprocessing & Exploratory Analysis

* Filtered telemetry records to isolate only **Discharging Phases ("S")**.


* Derived feature sets per cycle group, including **Median Current, Median Voltage, Starting/Final Voltage, and Discharging Time**.


* Standardized all features to eliminate scaling bias across different units.



### 2. Dimensionality Reduction & Performance Clustering

* Applied **Principal Component Analysis (PCA)** to transform correlated sensor data into orthogonal principal components.


* Selected the optimal number of clusters using the **Elbow Method** on the calculated Principal Components.


* Utilized **K-Means Clustering** to segment battery behaviors into clear performance profiles.



### 3. Multivariate Statistical Process Control (SPC)

* Constructed a multivariate **Hotelling $T^2$ Control Chart** combined with **Compositional Data (CoDa)** transformations.


* Utilized **Isometric Log-Ratio (ilr)** transformations to properly account for the relative nature of power distributions across parallel battery packs.


* Implemented a two-phase control framework:
* **Phase I (80% of Train 1 data):** Outlier elimination and baseline Upper Control Limit (UCL) establishment.


* **Phase II (20% of Train 1 data):** Real-time monitoring validation.


* **Validation:** Model deployment on an entirely separate train profile (`Train 15`) to assess anomaly sensitivity.



---

## 📈 Key Statistical Insights

### PCA Loading & Variance Profile

* **PC1 (~50% Variance Explained):** Strongly driven by *Discharging Time* and *Final Voltage*.


* **PC2 (~20% Variance Explained):** Heavily influenced by *Median Current* and *Starting Voltage*.


* Together, the top two components effectively capture **~70% of the entire dataset's variation**.



### Performance Profiling Metrics

K-Means separated behavior into clear diagnostic profiles:

* **Cluster 1 (Heavy Load / Start-Up):** Characterized by high discharge intensity coupled with shorter durations.


* **Cluster 2 (Normal Operations):** Characterized by standard, steady-state medium discharge durations under lower load intensity.



### Fault Identification Summary Table

When evaluated across behavioral classification algorithms, clear disparities emerged between a standard unit (`Train 1`) and a deteriorating, high-risk unit (`Train 15`):

| Train ID | Low Performance Cycles | Medium Performance Cycles | High Performance Cycles | Status Diagnostic |
| --- | --- | --- | --- | --- |
| **Train 1** | 64 | 63 | 1 | Operational (Stable Baseline) 
| **Train 15** | 80 | 45 | 0 | <br>**Critical Out-of-Control (Faulty Battery 3/4 Module)** 


> ⚠️ **Diagnostic Note:** Boxplot and ternary analysis of `Train 15` revealed a steep drop in median power precisely on its third and fourth battery modules, confirming localized degradation that caused immediate, out-of-control signals across all validation phases.
> 
> 

---

## 🚀 How to Run the Code

### Prerequisites

Make sure you have R installed along with the required spatial and compositional toolkits:

```R
install.packages(c("compositions", "ggplot2", "dplyr", "tidyr", "factoextra", "GGally"))

```

### Execution Steps

1. Clone the repository to your machine:
```bash
git clone https://github.com/ehseyedabadi/Statistical-Analysis-of-Hitachi-Dataset.git
cd Statistical-Analysis-of-Hitachi-Dataset

```


2. Place the raw train telemetry dataset in a folder called `data/`.
3. Open and run your main script (e.g., `analysis.R`) to reproduce the data preprocessing, PCA plots, K-means metrics, and the Hotelling $T^2$ control chart plots.

---

## 🔮 Future Perspectives

* **Framework Scalability:** Optimize the $T^2$ CoDa pipeline to dynamically generalize and compute baseline metrics across the remaining trains in the fleet automatically.


* **Environmental Conditioning:** Integrate operational environmental factors (e.g., ambient external temperature changes) to ensure the baseline control metrics remain highly resilient.


* **Prognostics Integration:** Combine real-time SPC out-of-control triggers with machine learning regression modules to estimate the Remaining Useful Life (RUL) of target battery modules.



---

## 👥 Contributors & Course Info

* **University:** Università degli Studi di Napoli Federico II
* **Course:** Statistical Lab for Industrial Data Analysis 


* **Professor:** Prof. Antonio Lepore 


* **Project Group:** Group 9 


* **Donato D’Ambrosio** (M62002985) 


* **Antonio Fico** (M62002880) 


* **Ehsan Seyedabadi** (P55000046) 


---

Developed as a collaborative project aligning statistics with industrial engineering practices for Hitachi Rail.
