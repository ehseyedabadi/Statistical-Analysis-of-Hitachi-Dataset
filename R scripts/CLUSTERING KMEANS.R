# Load the necessary libraries
library(dplyr)

# 1. Load the dataset
data <- readRDS("C:\\Users\\a_fic\\Documents\\HITACHI SL PROJECT WORK\\DATA_Fleet_1.rds")

# 2. Filter data to consider only the discharge phases
data_filtered <- data %>%
  filter(
    ID_Ph_C1 == "S" & ID_Ph_C2 == "S" & ID_Ph_C3 == "S" & ID_Ph_C4 == "S",
    !is.na(ID_GR),
    !is.na(VBatt_C1), !is.na(VBatt_C2), !is.na(VBatt_C3), !is.na(VBatt_C4)
  )

# 3. Calculate key metrics for each discharge stage using the median
data_durations <- data_filtered %>%
  group_by(Vehicle, ID_GR) %>%
  summarise(
    start_time = min(as.POSIXct(Timestamp, origin = "1970-01-01", tz = "UTC")),
    end_time = max(as.POSIXct(Timestamp, origin = "1970-01-01", tz = "UTC")),
    discharge_duration = as.numeric(difftime(end_time, start_time, units = "mins")),
    avg_voltage = median(c(VBatt_C1, VBatt_C2, VBatt_C3, VBatt_C4), na.rm = TRUE)  # Changed to median
  ) %>%
  ungroup()

# 4. Remove rows with missing data or invalid durations
data_durations <- data_durations %>%
  filter(!is.na(discharge_duration) & discharge_duration > 0)

# 5. Initialize the cluster column
data_durations <- data_durations %>%
  mutate(cluster = NA)

# 6. Apply clustering for each train
cluster_results <- list()

for (train in unique(data_durations$Vehicle)) {
  train_data <- data_durations %>%
    filter(Vehicle == train) %>%
    select(discharge_duration, avg_voltage)
  
  train_data_scaled <- scale(train_data)
  
  set.seed(42)
  kmeans_result <- kmeans(train_data_scaled, centers = 3, nstart = 10)
  
  data_durations <- data_durations %>%
    mutate(
      cluster = ifelse(Vehicle == train, kmeans_result$cluster, cluster)
    )
  
  cluster_results[[train]] <- kmeans_result
}

# 7. Assign performance labels to clusters
cluster_summary <- data_durations %>%
  group_by(Vehicle, cluster) %>%
  summarise(
    avg_duration = median(discharge_duration, na.rm = TRUE),  # Changed to median
    avg_voltage = median(avg_voltage, na.rm = TRUE)  # Changed to median
  ) %>%
  mutate(
    cluster_type = case_when(
      avg_duration > median(avg_duration) & avg_voltage < median(avg_voltage) ~ "High Performance",
      avg_duration < median(avg_duration) & avg_voltage > median(avg_voltage) ~ "Low Performance",
      TRUE ~ "Medium Performance"
    )
  )

# Merge cluster types into the original dataset
data_durations <- data_durations %>%
  left_join(cluster_summary %>% select(Vehicle, cluster, cluster_type), by = c("Vehicle", "cluster"))

# 8. Prepare data for plotting
pch_values <- c(0:14)
train_markers <- setNames(pch_values[1:length(unique(data_durations$Vehicle))], 
                          unique(data_durations$Vehicle))

# Define colors for clusters
cluster_colors <- c("Low Performance" = "red", 
                    "Medium Performance" = "orange", 
                    "High Performance" = "green")

# 9. Create the plot
par(mar = c(5, 4, 4, 10))

# Calculate the optimal bounds for the y-axis
y_min <- 21
y_max <- 24.5
y_buffer <- (y_max - y_min) * 0.05

# Create the basic plot
plot(data_durations$discharge_duration, 
     data_durations$avg_voltage,
     type = "n",
     xlab = "Discharge Duration (minutes)",
     ylab = "Median Voltage",
     main = "Battery Performance Clustering",
     xlim = c(0, max(data_durations$discharge_duration) * 1.1),
     ylim = c(y_min - y_buffer, y_max + y_buffer),
     yaxp = c(y_min, y_max, 4))

# Add the points for each train and cluster combination
for (train in names(train_markers)) {
  for (perf_type in names(cluster_colors)) {
    subset_data <- data_durations %>%
      filter(Vehicle == train, cluster_type == perf_type)
    
    points(subset_data$discharge_duration,
           subset_data$avg_voltage,
           pch = train_markers[train],
           col = cluster_colors[perf_type])
  }
}

# Add cluster legend
legend("topright",
       inset = c(-0.2, 0),
       xpd = TRUE,
       legend = names(cluster_colors),
       col = cluster_colors,
       pch = 1,
       title = "Performance",
       cex = 0.8)

# Add train legend
legend("topright",
       inset = c(-0.2, 0.3),
       xpd = TRUE,
       legend = names(train_markers),
       pch = train_markers,
       title = "Trains",
       cex = 0.8)

# 10. Save the results
write.csv(data_durations, "clustered_data_with_labels.csv", row.names = FALSE)
