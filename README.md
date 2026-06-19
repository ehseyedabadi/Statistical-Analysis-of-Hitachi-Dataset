# Statistical Analysis of Hitachi Rail High-Speed Train Battery Data

## Overview

This project was developed as part of the **Statistical Lab for Industrial Data Analysis** course under the supervision of **Prof. Antonio Lepore**.

The objective is to analyze low-voltage battery data collected from Hitachi Rail high-speed trains using statistical techniques, exploratory data analysis, machine learning, and Statistical Process Control (SPC).

The project focuses on identifying abnormal battery behavior, detecting potential faults, and supporting predictive maintenance strategies through data-driven decision-making.

---

## Team Members

- Ehsan Seyedabadi (P55000046)
- Donato D’Ambrosio (M62002985)
- Antonio Fico (M62002880)

---

## Project Objectives

The main goals of this project are:

- Identify faulty batteries through statistical analysis.
- Detect critical trains based on battery behavior.
- Analyze discharge patterns of low-voltage battery systems.
- Apply machine learning techniques for battery classification.
- Develop Statistical Process Control models for process monitoring.
- Support predictive maintenance activities.

---

## About Hitachi Rail

Hitachi Rail is a global leader in railway transportation systems and mobility solutions.

- Founded: 1924
- Presence: 140+ countries
- Employees: 270,000+
- Revenue: €54.55 billion

The company focuses on sustainable mobility and advanced railway technologies.

---

## Dataset Description

The dataset contains operational data collected from **FLEET_1 high-speed trains**.

### Battery System

- Ni-Cd Low Voltage Batteries
- 4 batteries connected in parallel for each train
- 16 trains monitored

### Main Variables

| Variable | Description |
|-----------|------------|
| IBatt_Ci | Battery current intensity |
| VBatt_Ci | Battery voltage |
| ID_Ph_Ci | Battery phase |
| ID_GR | Charge/Discharge group |
| Timestamp | Sampling time |
| Vehicle | Train identifier |
| GPS_LAT | Latitude |
| GPS_LON | Longitude |
| VEHICLE_SPEED | Speed (km/h) |
| Status_ID | Operational status |

---

## System Analysis

The low-voltage battery system supports:

- Train start-up operations
- Power peaks
- Point of Change (POC) events
- High-voltage fault support
- Auxiliary electrical loads

Special attention was given to battery discharge phases because:

- Current imbalances between batteries may indicate faults.
- Voltage behavior reflects battery health conditions.

---

## Data Processing

The following preprocessing steps were performed:

- Data filtering
- Timestamp conversion
- Discharge phase identification
- Power calculation
- Data visualization

---

## Exploratory Data Analysis

### Feature Extraction

For each discharge cycle:

- Median Current
- Median Voltage
- Starting Voltage
- Final Voltage
- Discharge Duration

### Visualization Techniques

- Scatter plots
- Box plots
- Correlation analysis
- Scatter plot matrices

---

## Principal Component Analysis (PCA)

PCA was applied to:

- Reduce dimensionality
- Preserve maximum variance
- Identify hidden patterns in battery behavior

### Results

- PC1 explains approximately 50% of variance
- PC2 explains approximately 20% of variance
- PC1 + PC2 explain approximately 70% of total variance

### Interpretation

**PC1**
- Discharge Time
- Final Voltage

**PC2**
- Median Current
- Starting Voltage

---

## K-Means Clustering

K-Means clustering was applied on PCA components to identify groups of similar battery behaviors.

### Elbow Method

The optimal number of clusters was found to be:

**K = 2**

### Cluster Interpretation

#### Cluster 1

- High discharge intensity
- Short discharge duration
- Heavy-load batteries
- Possible start-up operations

#### Cluster 2

- Lower discharge intensity
- Medium discharge duration
- Normal operating conditions

---

## Statistical Process Control (SPC)

### Multivariate Monitoring

The project implements:

### T² CoDa Control Charts

Methodology:

1. Extraction of median battery powers
2. Compositional Data Analysis (CoDa)
3. Isometric Log-Ratio (ILR) transformation
4. Phase I model building
5. Phase II monitoring
6. Anomaly detection

### Phase I

- Training dataset (80%)
- Estimation of mean vector
- Covariance matrix calculation
- Control limit definition
- Removal of outliers

### Phase II

- Monitoring of new observations
- Calculation of Hotelling's T² statistics
- Detection of abnormal battery behavior

---

## Model Validation

The control chart model developed using **Train 1** was validated on **Train 15**.

Validation tools:

- Boxplots
- Ternary diagrams
- T² Control Charts

The results demonstrate the potential of compositional multivariate SPC techniques for monitoring train battery systems.

---

## Technologies Used

- R Programming Language
- Statistical Analysis
- Principal Component Analysis (PCA)
- K-Means Clustering
- Statistical Process Control (SPC)
- Compositional Data Analysis (CoDa)

---

## Key Results

✅ Identification of battery discharge patterns

✅ Detection of anomalous battery behavior

✅ Classification of battery operating conditions

✅ Development of a multivariate monitoring framework

✅ Validation on independent train data

---

## Future Work

Future developments include:

- Extending the T² CoDa framework to all trains
- Improving model robustness across operational conditions
- Developing predictive maintenance models
- Integrating machine learning algorithms for battery degradation forecasting
- Real-time monitoring implementation

---

## Repository Structure

```text
├── README.md
├── LICENSE
├── scripts/
├── figures/
```

---

## Course Information

**Course:** Statistical Lab for Industrial Data Analysis

**Professor:** Antonio Lepore

**Academic Year:** 2025–2026

---

## License

This project is released under the MIT License.

---

## Acknowledgements

Special thanks to:

- Hitachi Rail
- Prof. Antonio Lepore
