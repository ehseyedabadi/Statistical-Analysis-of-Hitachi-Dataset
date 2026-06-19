# Load necessary libraries
library(ggplot2)
library(GGally)
library(reshape2)
library(dplyr)

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

# Step 3: Box Plots for Each Scaled Feature
output_dir <- "E:/3rd Semester/Statistical/Project/plots"
dir.create(output_dir, showWarnings = FALSE)

# Melt scaled features for box plots
melted_scaled_features <- melt(as.data.frame(scaled_features))
melted_scaled_features$Vehicle <- pca_features$Vehicle

# Save Box Plots
png(filename = file.path(output_dir, "Box_Plots_Scaled.png"), width = 1200, height = 800)
ggplot(melted_scaled_features, aes(x = variable, y = value, fill = variable)) +
  geom_boxplot() +
  labs(title = "Box Plots of Scaled Features", x = "Feature", y = "Scaled Value") +
  theme_minimal()
dev.off()

# Step 4: Scatterplot Matrix of Scaled Features
scaled_features_df <- as.data.frame(scaled_features)
scaled_features_df$Vehicle <- pca_features$Vehicle

png(filename = file.path(output_dir, "Scatterplot_Matrix_Scaled.png"), width = 1200, height = 1200)
ggpairs(scaled_features_df, columns = 1:5, title = "Scatterplot Matrix of Scaled Features", aes(color = Vehicle))
dev.off()

# Step 5: Performing PCA
pca_result <- prcomp(scaled_features, center = TRUE, scale. = TRUE)

# Step 6: Scree Plot (Proportion of Variance Explained)
pve <- pca_result$sdev^2 / sum(pca_result$sdev^2) * 100  # Convert to percentage
png(filename = file.path(output_dir, "PVE_Plot.png"), width = 800, height = 600)
barplot(pve, names.arg = paste0("PC", 1:length(pve)), 
        main = "Proportion of Variance Explained (PVE)", 
        xlab = "Principal Components", ylab = "PVE (%)", col = "skyblue")
dev.off()

# Step 7: Loading Plot
loadings <- as.data.frame(pca_result$rotation)
loadings$Variable <- rownames(loadings)
melted_loadings <- melt(loadings, id.vars = "Variable")

png(filename = file.path(output_dir, "Loading_Plot.png"), width = 1200, height = 800)
ggplot(melted_loadings, aes(Variable, value, fill = variable)) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(title = "Loading Plot of Principal Components", x = "Variable", y = "Loading Value") +
  theme_minimal()
dev.off()

# Step 8: Biplot
png(filename = file.path(output_dir, "Biplot.png"), width = 800, height = 600)
biplot(pca_result, scale = 0, main = "PCA Biplot")
dev.off()

# Step 9: Score Plot with Loading Vectors
scores <- as.data.frame(pca_result$x)
scores$Vehicle <- pca_features$Vehicle  # Add Vehicle column back

# Scale the loading vectors for visualization
loadings$PC1 <- loadings$PC1 * max(abs(scores$PC1))
loadings$PC2 <- loadings$PC2 * max(abs(scores$PC2))

# Save the Score Plot with Loading Vectors
png(filename = file.path(output_dir, "Score_Plot_with_Loadings.png"), width = 800, height = 600)
ggplot() +
  # Add the score points (from the 'scores' dataset)
  geom_point(data = scores, aes(x = PC1, y = PC2, color = Vehicle), alpha = 0.7) +
  # Add the loading vectors (from the 'loadings' dataset)
  geom_segment(data = loadings, aes(x = 0, y = 0, xend = PC1, yend = PC2),
               arrow = arrow(length = unit(0.2, "cm")), color = "red") +
  # Add labels for the loading vectors
  geom_text(data = loadings, aes(x = PC1, y = PC2, label = Variable), hjust = -0.2) +
  # Add labels and formatting
  labs(title = "Score Plot with Loading Vectors", x = "PC1", y = "PC2", color = "Vehicle") +
  theme_minimal()
dev.off()

# Save the Principal Component Scores as CSV
write.csv(scores, file.path(output_dir, "Principal_Components_Scores.csv"), row.names = FALSE)
