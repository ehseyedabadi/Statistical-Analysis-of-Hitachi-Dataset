# Load necessary libraries
library(ggplot2)
library(dplyr)
library(factoextra)  # For clustering visualization

# Load the dataset
data <- readRDS("E:/3rd Semester/Statistical/Project/09_Hitachi_dataset/DATA_Fleet_1.rds")

# Step 1: Filtering only discharging phases ("S") for all four batteries
filtered_data <- data %>%
  filter(ID_Ph_C1 == "S" & ID_Ph_C2 == "S" & ID_Ph_C3 == "S" & ID_Ph_C4 == "S")

# Step 2: Calculate new PCA features for each discharging phase per Vehicle
pca_features <- filtered_data %>%
  group_by(Vehicle, ID_GR) %>%
  summarise(
    Median_Current = median(c(IBatt_C1, IBatt_C2, IBatt_C3, IBatt_C4), na.rm = TRUE),
    Median_Voltage = median(c(VBatt_C1, VBatt_C2, VBatt_C3, VBatt_C4), na.rm = TRUE),
    Starting_Voltage = first(na.omit(c(VBatt_C1, VBatt_C2, VBatt_C3, VBatt_C4))),
    Final_Voltage = last(na.omit(c(VBatt_C1, VBatt_C2, VBatt_C3, VBatt_C4))),
    Discharging_Time = max(c(Time_C1, Time_C2, Time_C3, Time_C4), na.rm = TRUE)
  ) %>% ungroup()

# Remove rows with missing values in PCA features
pca_features <- na.omit(pca_features)

# Standardize the data (excluding ID_GR and Vehicle)
scaled_features <- pca_features %>%
  select(-ID_GR, -Vehicle) %>%
  scale()

# Step 3: Perform PCA
pca_result <- prcomp(scaled_features, center = TRUE, scale. = TRUE)

# Select the top PCs (e.g., PC1 and PC2)
selected_pcs <- as.data.frame(pca_result$x[, 1:3])  # Top 2-3 PCs
selected_pcs$Vehicle <- pca_features$Vehicle  # Add Vehicle column back for interpretation

# Step 4: Determine the Optimal Number of Clusters using the Elbow Method
wss <- sapply(1:10, function(k) {
  kmeans(selected_pcs[, 1:2], centers = k, nstart = 25)$tot.withinss
})

# Save the elbow plot
png(filename = file.path(output_dir, "Elbow_Plot.png"), width = 800, height = 600)
plot(1:10, wss, type = "b", pch = 19, frame = FALSE,
     main = "Elbow Method for Optimal Clusters",
     xlab = "Number of Clusters (k)",
     ylab = "Total Within-Cluster Sum of Squares (WSS)")
dev.off()

# Step 5: Apply K-means Clustering with Optimal K (e.g., 3 clusters)
set.seed(123)  # For reproducibility
k <- 3  # Replace with the optimal k determined from the elbow plot
kmeans_result <- kmeans(selected_pcs[, 1:2], centers = k, nstart = 25)

# Add cluster assignments to the data
selected_pcs$Cluster <- as.factor(kmeans_result$cluster)

# Save the cluster assignments as a CSV file
write.csv(selected_pcs, file.path(output_dir, "Cluster_Assignments.csv"), row.names = FALSE)

# Step 6: Visualize Clusters in PC Space
png(filename = file.path(output_dir, "Cluster_Plot.png"), width = 800, height = 600)
ggplot(selected_pcs, aes(x = PC1, y = PC2, color = Cluster)) +
  geom_point(size = 2, alpha = 0.7) +
  labs(title = "K-means Clustering on Principal Components",
       x = "PC1", y = "PC2", color = "Cluster") +
  theme_minimal()
dev.off()

# Optional: Add Interpretation of Clusters
cat("Cluster 1: High discharge intensity, short discharge duration.\n")
cat("Cluster 2: Moderate discharge intensity, medium discharge duration.\n")
cat("Cluster 3: Low discharge intensity, long discharge duration.\n")
