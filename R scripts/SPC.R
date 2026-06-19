# Load required libraries
library(dplyr)
library(ggplot2)
library(lubridate)

# Load the dataset
data <- readRDS("DATA_Fleet_1.rds")

# Filter data where ID_Ph_C equals "S" for all batteries and train_1
data_filtered <- data %>%
  filter(
    Vehicle == "train_1",  # Filter for train 1
    ID_Ph_C1 == "S" & ID_Ph_C2 == "S" & ID_Ph_C3 == "S" & ID_Ph_C4 == "S",
    !is.na(ID_GR),  # Ensure ID_GR contains no NA values
    !is.na(VBatt_C1), !is.na(VBatt_C2), !is.na(VBatt_C3), !is.na(VBatt_C4),
    !is.na(IBatt_C1), !is.na(IBatt_C2), !is.na(IBatt_C3), !is.na(IBatt_C4)
  )

# Add power columns for each battery
data_filtered <- data_filtered %>%
  mutate(
    Power_C1 = VBatt_C1 * IBatt_C1,
    Power_C2 = VBatt_C2 * IBatt_C2,
    Power_C3 = VBatt_C3 * IBatt_C3,
    Power_C4 = VBatt_C4 * IBatt_C4
  )

# Add a phase ID to identify discharge phases based on changes in ID_GR
data_filtered <- data_filtered %>%
  mutate(phase_group = cumsum(ID_GR != lag(ID_GR, default = first(ID_GR))))

# Convert Timestamp to a readable datetime format
data_filtered <- data_filtered %>%
  mutate(Timestamp = as.POSIXct(Timestamp, origin = "1970-01-01", tz = "UTC"))

# Extract all discharge phases and create plots
unique_phases <- unique(data_filtered$phase_group)  # Find unique groups
plot_list <- list()  # List to store plots

for (phase in unique_phases) {
  # Filter data for the current phase
  phase_data <- data_filtered %>%
    filter(phase_group == phase)
  
  # Skip empty blocks or blocks without data
  if (nrow(phase_data) == 0) next
  
  # Find minimum and maximum power limits
  min_power <- min(phase_data$Power_C1, phase_data$Power_C2, phase_data$Power_C3, phase_data$Power_C4, na.rm = TRUE)
  max_power <- max(phase_data$Power_C1, phase_data$Power_C2, phase_data$Power_C3, phase_data$Power_C4, na.rm = TRUE)
  break_interval <- (max_power - min_power) / 10
  
  # Find start and end times
  start_time <- min(phase_data$Timestamp, na.rm = TRUE)
  end_time <- max(phase_data$Timestamp, na.rm = TRUE)
  
  # Read the ID_GR value for the current phase
  current_ID_GR <- unique(phase_data$ID_GR)
  
  # Create a plot for the current phase
  plot <- ggplot(phase_data, aes(x = Timestamp)) +
    geom_line(aes(y = Power_C1, color = "Power_C1")) +
    geom_line(aes(y = Power_C2, color = "Power_C2")) +
    geom_line(aes(y = Power_C3, color = "Power_C3")) +
    geom_line(aes(y = Power_C4, color = "Power_C4")) +
    labs(
      title = paste("Battery Power Over Time - Phase", phase, "- ID_GR:", current_ID_GR),
      subtitle = paste("Start:", start_time, "- End:", end_time),
      x = "Time",
      y = "Power"
    ) +
    theme_minimal() +
    scale_y_continuous(
      limits = c(min_power, max_power),
      breaks = seq(min_power, max_power, by = break_interval)
    ) +
    scale_x_datetime(
      date_labels = "%Y-%m-%d %H:%M:%S", 
      date_breaks = "30 min",  # Customize the time-label frequency
      limits = c(start_time, end_time)  # Limit the time axis
    ) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))  # Rotate X-axis labels for readability
  
  # Add the plot to the list
  plot_list[[paste0("Phase_", phase)]] <- plot
}

# Save or display the plots
for (name in names(plot_list)) {
  print(plot_list[[name]])  # Print plots in the console
}



### STATISTICAL QUALITY CONTROL PART ###


library(qcc)
library(dplyr)


# Example with 4 different columns:
batteries <- list(
  C1 = data_filtered$Power_C1,
  C2 = data_filtered$Power_C2,
  C3 = data_filtered$Power_C3,
  C4 = data_filtered$Power_C4
)


#consider initial voltage, median voltage, capacity to predict the voltage
#to make the coda cc, we have to put the median power for every observation:
#Phase 1: training the cc with 80% of obs
#Phase 2: testing the cc with 20% of obs
#Evaluation phase: evaluate the model with data of another train



# Calculating the median power for each battery and discharge group
median_power <- data_filtered %>%
  group_by(phase_group) %>%  # Group by phase_group
  summarise(
    Median_Power_C1 = median(Power_C1, na.rm = TRUE),
    Median_Power_C2 = median(Power_C2, na.rm = TRUE),
    Median_Power_C3 = median(Power_C3, na.rm = TRUE),
    Median_Power_C4 = median(Power_C4, na.rm = TRUE)
  )



# Cleaning the environment
rm(list = ls()) 
dev.off() 
cat("\f")

# Necessary libraries
library(readxl)
library(dplyr)

# Loading data
battery_data <- median_power

# Divide data into Phase I (80%) and Phase II (20%)
set.seed(42)  # For reproducibility
n_total <- nrow(battery_data)
n_phase1 <- floor(0.8 * n_total)

phase1_data <- battery_data[1:n_phase1, ]
phase2_data <- battery_data[(n_phase1 + 1):n_total, ]

# Calculate means and covariances for Phase I
p <- ncol(phase1_data)  # Number of variables
n <- nrow(phase1_data)  # Number of Phase I observations

x_bar_phase1 <- as.matrix(colMeans(phase1_data))
S_phase1 <- cov(phase1_data)

# Calculating T^2 for Phase I
T2_phase1 <- apply(phase1_data, 1, function(x) {
  t(as.matrix(x) - x_bar_phase1) %*% solve(S_phase1) %*% (as.matrix(x) - x_bar_phase1)
})

# Phase I Limits
alpha <- 0.001  # Level of significance
UCL_phase1 <- p * (n - 1) / (n - p) * qf(1 - alpha, df1 = p, df2 = n - p)

# Calculating T^2 for Phase II
T2_phase2 <- apply(phase2_data, 1, function(x) {
  t(as.matrix(x) - x_bar_phase1) %*% solve(S_phase1) %*% (as.matrix(x) - x_bar_phase1)
})

# Phase II Limits
n_phase2 <- nrow(phase2_data)
UCL_phase2 <- p * (n + 1) * (n - 1) / (n * (n - p)) * qf(1 - alpha, df1 = p, df2 = n - p)

# Control chart plots
plot(T2_phase1, type = "o", pch = 16, lwd = 1.8, cex = 0.7, ylim = c(0, max(T2_phase1, UCL_phase1)), 
     ylab = parse(text = "T^2"), xlab = "Observation Index", main = "Hotelling T^2 Control Chart (Phase I)")
abline(h = UCL_phase1, col = "red", lty = 2)
text(x = length(T2_phase1), y = UCL_phase1 + 0.2, labels = paste("UCL (Phase I) =", round(UCL_phase1, 2)))

plot(T2_phase2, type = "o", pch = 16, lwd = 1.8, cex = 0.7, ylim = c(0, max(T2_phase2, UCL_phase2)), 
     ylab = parse(text = "T^2"), xlab = "Observation Index", main = "Hotelling T^2 Control Chart (Phase II)")
abline(h = UCL_phase2, col = "red", lty = 2)
text(x = length(T2_phase2), y = UCL_phase2 + 0.2, labels = paste("UCL (Phase II) =", round(UCL_phase2, 2)))


### EVALUATION OF THE METHOD ###


#LOADING OF TRAIN 2 DATA


data_train2 <- data %>%
  filter(
    Vehicle == "train_2",  # Filter for train 2
    ID_Ph_C1 == "S" & ID_Ph_C2 == "S" & ID_Ph_C3 == "S" & ID_Ph_C4 == "S",
    !is.na(ID_GR),  # Ensure ID_GR contains no NA values
    !is.na(VBatt_C1), !is.na(VBatt_C2), !is.na(VBatt_C3), !is.na(VBatt_C4),
    !is.na(IBatt_C1), !is.na(IBatt_C2), !is.na(IBatt_C3), !is.na(IBatt_C4)
  )

# Add power columns for each battery
data_train2 <- data_train2 %>%
  mutate(
    Power_C1 = VBatt_C1 * IBatt_C1,
    Power_C2 = VBatt_C2 * IBatt_C2,
    Power_C3 = VBatt_C3 * IBatt_C3,
    Power_C4 = VBatt_C4 * IBatt_C4
  )


data_train2 <- data_train2 %>%
  mutate(phase_group = cumsum(ID_GR != lag(ID_GR, default = first(ID_GR))))

# Convert Timestamp to a readable datetime format
data_train2 <- data_train2 %>%
  mutate(Timestamp = as.POSIXct(Timestamp, origin = "1970-01-01", tz = "UTC"))

# Extract all discharge phases and create plots
unique_phases <- unique(data_train2$phase_group)  # Find unique groups

# Calculating the median power for each battery and discharge group
median_power_2 <- data_train2 %>%
  group_by(phase_group) %>%  # Group by phase_group
  summarise(
    Median_Power_C1 = median(Power_C1, na.rm = TRUE),
    Median_Power_C2 = median(Power_C2, na.rm = TRUE),
    Median_Power_C3 = median(Power_C3, na.rm = TRUE),
    Median_Power_C4 = median(Power_C4, na.rm = TRUE)
  )



# Calculate T^2 for the second train
T2_treno2 <- apply(data_train2, 1, function(x) {
  x <- as.numeric(x)  # Make sure x is numeric
  t(as.matrix(x) - x_bar_phase1) %*% solve(S_phase1) %*% (as.matrix(x) - x_bar_phase1)
})

# Comparison with Phase II limit
UCL_phase2 <- p * (nrow(battery_data) + 1) * (nrow(battery_data) - 1) /
  (nrow(battery_data) * (nrow(battery_data) - p)) * qf(1 - alpha, p, nrow(battery_data) - p)

# Plot of the T^2 values ​​of the second train
plot(T2_treno2, type = "o", pch = 16, lwd = 1.8, cex = 0.7, ylim = c(0, max(T2_treno2, UCL_phase2)),
     ylab = parse(text = "T^2"), xlab = "Observation Index", main = "Hotelling T^2 (Treno 2)")
abline(h = UCL_phase2, col = "red", lty = 2)
text(x = length(T2_treno2), y = UCL_phase2 + 0.2, labels = paste("UCL (Phase II) =", round(UCL_phase2, 2)))




