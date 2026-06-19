# Load the necessary libraries
library(dplyr)
library(ggplot2)
library(lubridate)

# Load the dataset
data <- readRDS("C:\\Users\\a_fic\\Documents\\HITACHI SL PROJECT WORK\\DATA_Fleet_1.rds")

# Filter data where ID_Ph_C equals "S" for all batteries and for train_1
data_filtered <- data %>%
  filter(
    Vehicle == "train_1",  # Filter for train 1
    ID_Ph_C1 == "S" | ID_Ph_C2 == "S" | ID_Ph_C3 == "S" | ID_Ph_C4 == "S",
    !is.na(ID_GR),  # Make sure ID_GR has no NA values
    !is.na(VBatt_C1), !is.na(VBatt_C2), !is.na(VBatt_C3), !is.na(VBatt_C4),
    !is.na(IBatt_C1), !is.na(IBatt_C2), !is.na(IBatt_C3), !is.na(IBatt_C4)
  )

# Add the power columns for each battery with absolute value
data_filtered <- data_filtered %>%
  mutate(
    Power_C1 = abs(VBatt_C1 * IBatt_C1),
    Power_C2 = abs(VBatt_C2 * IBatt_C2),
    Power_C3 = abs(VBatt_C3 * IBatt_C3),
    Power_C4 = abs(VBatt_C4 * IBatt_C4)
  )

# Add a phase ID to identify discharge phases based on the change in ID_GR
data_filtered <- data_filtered %>%
  mutate(phase_group = cumsum(ID_GR != lag(ID_GR, default = first(ID_GR))))

# Convert the Timestamp to a readable datetime format
data_filtered <- data_filtered %>%
  mutate(Timestamp = as.POSIXct(Timestamp, origin = "1970-01-01", tz = "UTC"))

# Extract all the discharge phases and create the graphs
unique_phases <- unique(data_filtered$phase_group)  # Find unique groups
plot_list <- list()  # List for saving graphs

for (phase in unique_phases) {
  # Filter data for the current stage
  phase_data <- data_filtered %>%
    filter(phase_group == phase)
  
  # Skip empty or dataless blocks
  if (nrow(phase_data) == 0) next
  
  # Find the min and max limits of the power
  min_power <- min(phase_data$Power_C1, phase_data$Power_C2, phase_data$Power_C3, phase_data$Power_C4, na.rm = TRUE)
  max_power <- max(phase_data$Power_C1, phase_data$Power_C2, phase_data$Power_C3, phase_data$Power_C4, na.rm = TRUE)
  break_interval <- (max_power - min_power) / 10
  
  # Find the start and end time
  start_time <- min(phase_data$Timestamp, na.rm = TRUE)
  end_time <- max(phase_data$Timestamp, na.rm = TRUE)
  
  # Create a graph for the current stage
  plot <- ggplot(phase_data, aes(x = Timestamp)) +
    geom_line(aes(y = Power_C1, color = "Power_C1")) +
    geom_line(aes(y = Power_C2, color = "Power_C2")) +
    geom_line(aes(y = Power_C3, color = "Power_C3")) +
    geom_line(aes(y = Power_C4, color = "Power_C4")) +
    labs(
      title = paste("Battery Power Over Time - Phase", phase),
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
      date_breaks = "30 min",  # Customize the frequency of time labels
      limits = c(start_time, end_time)  # Limit the time axis
    ) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))  # Angle the X-axis values ​​for readability
  
  # Add chart to list
  plot_list[[paste0("Phase_", phase)]] <- plot
}

# Save or show graphs
for (name in names(plot_list)) {
  print(plot_list[[name]])  # Print graphs to the console
  ggsave(paste0(name, ".png"), plot = plot_list[[name]], width = 10, height = 6)  # Save graphs as PNG files
}
