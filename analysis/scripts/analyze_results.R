# Post-simulation analysis and figure generation
#
# Usage (from project root inside container):
#   Rscript analysis/scripts/analyze_results.R

library(mixedr2)
library(ggplot2)

results <- readRDS("analysis/data/derived_data/sim_results.rds")
summary_table <- readRDS("analysis/data/derived_data/sim_summary.rds")

fig_dir <- "analysis/figures"
if (!dir.exists(fig_dir)) dir.create(fig_dir, recursive = TRUE)

tab_dir <- "analysis/tables"
if (!dir.exists(tab_dir)) dir.create(tab_dir, recursive = TRUE)

p1 <- plot_bias_heatmap(summary_table)
ggsave(
  file.path(fig_dir, "fig1_bias_heatmap.pdf"),
  p1, width = 10, height = 8
)

sample_scenarios <- c(1, 8, 17, 32)
p2 <- plot_r2_distributions(results, scenario_ids = sample_scenarios)
ggsave(
  file.path(fig_dir, "fig2_r2_distributions.pdf"),
  p2, width = 10, height = 8
)

p3 <- plot_monotonicity_rates(summary_table)
ggsave(
  file.path(fig_dir, "fig3_monotonicity.pdf"),
  p3, width = 10, height = 6
)

p5 <- plot_sample_size_icc_interaction(summary_table)
ggsave(
  file.path(fig_dir, "fig5_sample_icc_interaction.pdf"),
  p5, width = 8, height = 5
)

write.csv(
  summary_table,
  file.path(tab_dir, "performance_summary.csv"),
  row.names = FALSE
)

message("Figures saved to ", fig_dir)
message("Tables saved to ", tab_dir)
