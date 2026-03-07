#' Consistent publication theme for simulation figures
#'
#' @param base_size Base font size (default 11)
#' @return A ggplot2 theme object
#' @importFrom ggplot2 theme_bw theme element_text element_line
#' @export
theme_sim <- function(base_size = 11) {
  ggplot2::theme_bw(base_size = base_size) +
    ggplot2::theme(
      strip.background = ggplot2::element_blank(),
      strip.text = ggplot2::element_text(face = "bold"),
      panel.grid.minor = ggplot2::element_blank(),
      legend.position = "bottom"
    )
}


#' Plot bias heatmap across scenarios (Fig 1)
#'
#' @param summary_data Tibble from [summarize_all_scenarios()]
#' @return A ggplot object
#' @importFrom ggplot2 ggplot aes geom_tile scale_fill_gradient2
#'   facet_grid labs
#' @importFrom tidyr pivot_longer
#' @export
plot_bias_heatmap <- function(summary_data) {
  plot_data <- summary_data |>
    dplyr::select(
      scenario_id, n_clusters, cluster_size, icc,
      target_r2m, re_structure,
      nak_m_bias, joh_m_bias
    ) |>
    tidyr::pivot_longer(
      cols = c(nak_m_bias, joh_m_bias),
      names_to = "method",
      values_to = "bias"
    ) |>
    dplyr::mutate(
      method = dplyr::case_when(
        method == "nak_m_bias" ~ "Nakagawa-Schielzeth",
        method == "joh_m_bias" ~ "Johnson"
      ),
      icc_label = paste0("ICC = ", icc),
      r2m_label = paste0("R2m = ", target_r2m)
    )

  ggplot2::ggplot(
    plot_data,
    ggplot2::aes(
      x = factor(n_clusters),
      y = factor(cluster_size),
      fill = bias
    )
  ) +
    ggplot2::geom_tile(color = "white", linewidth = 0.5) +
    ggplot2::scale_fill_gradient2(
      low = "#2166AC", mid = "white", high = "#B2182B",
      midpoint = 0, name = "Bias"
    ) +
    ggplot2::facet_grid(
      method + re_structure ~ icc_label + r2m_label
    ) +
    ggplot2::labs(
      x = "Number of clusters (J)",
      y = "Cluster size (n)"
    ) +
    theme_sim()
}


#' Plot R-squared distributions by scenario (Fig 2)
#'
#' @param raw_results Full simulation results tibble
#' @param scenario_ids Integer vector of scenario IDs to plot
#'   (default: all)
#' @return A ggplot object
#' @importFrom ggplot2 ggplot aes geom_density geom_vline
#'   facet_wrap labs
#' @importFrom tidyr pivot_longer
#' @export
plot_r2_distributions <- function(raw_results,
                                  scenario_ids = NULL) {
  if (!is.null(scenario_ids)) {
    raw_results <- raw_results[
      raw_results$scenario_id %in% scenario_ids,
    ]
  }

  plot_data <- raw_results |>
    dplyr::select(
      scenario_id, nak_r2m, joh_r2m, true_r2m
    ) |>
    tidyr::pivot_longer(
      cols = c(nak_r2m, joh_r2m),
      names_to = "method",
      values_to = "r2m"
    ) |>
    dplyr::mutate(
      method = dplyr::case_when(
        method == "nak_r2m" ~ "Nakagawa-Schielzeth",
        method == "joh_r2m" ~ "Johnson"
      )
    )

  ggplot2::ggplot(plot_data, ggplot2::aes(x = r2m, fill = method)) +
    ggplot2::geom_density(alpha = 0.5) +
    ggplot2::geom_vline(
      ggplot2::aes(xintercept = true_r2m),
      linetype = "dashed", color = "black"
    ) +
    ggplot2::facet_wrap(~scenario_id, scales = "free_y") +
    ggplot2::labs(
      x = expression(hat(R)[m]^2),
      y = "Density",
      fill = "Method"
    ) +
    theme_sim()
}


#' Plot monotonicity rates (Fig 3)
#'
#' @param summary_data Tibble from [summarize_all_scenarios()]
#' @return A ggplot object
#' @importFrom ggplot2 ggplot aes geom_point geom_errorbar
#'   geom_hline facet_grid labs coord_cartesian
#' @importFrom tidyr pivot_longer
#' @export
plot_monotonicity_rates <- function(summary_data) {
  plot_data <- summary_data |>
    dplyr::select(
      scenario_id, n_clusters, cluster_size, icc,
      target_r2m, re_structure,
      mono_nak, mono_joh, mcse_mono_nak, mcse_mono_joh
    ) |>
    tidyr::pivot_longer(
      cols = c(mono_nak, mono_joh),
      names_to = "method",
      values_to = "mono_rate"
    ) |>
    dplyr::mutate(
      mcse = dplyr::if_else(
        method == "mono_nak", mcse_mono_nak, mcse_mono_joh
      ),
      method = dplyr::case_when(
        method == "mono_nak" ~ "Nakagawa-Schielzeth",
        method == "mono_joh" ~ "Johnson"
      ),
      scenario_label = paste0(
        "J=", n_clusters, ", n=", cluster_size
      )
    )

  ggplot2::ggplot(
    plot_data,
    ggplot2::aes(
      x = scenario_label, y = mono_rate,
      color = method, shape = method
    )
  ) +
    ggplot2::geom_point(
      position = ggplot2::position_dodge(width = 0.4),
      size = 2
    ) +
    ggplot2::geom_errorbar(
      ggplot2::aes(
        ymin = mono_rate - 1.96 * mcse,
        ymax = mono_rate + 1.96 * mcse
      ),
      position = ggplot2::position_dodge(width = 0.4),
      width = 0.2
    ) +
    ggplot2::geom_hline(yintercept = 1, linetype = "dashed") +
    ggplot2::facet_grid(icc ~ target_r2m, labeller = "label_both") +
    ggplot2::labs(
      x = "Scenario", y = "Monotonicity rate",
      color = "Method", shape = "Method"
    ) +
    ggplot2::coord_cartesian(ylim = c(0.5, 1.05)) +
    theme_sim() +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(
        angle = 45, hjust = 1, size = 8
      )
    )
}


#' Plot sample size by ICC interaction (Fig 5)
#'
#' @param summary_data Tibble from [summarize_all_scenarios()]
#' @return A ggplot object
#' @importFrom ggplot2 ggplot aes geom_point geom_line
#'   facet_grid labs
#' @export
plot_sample_size_icc_interaction <- function(summary_data) {
  plot_data <- summary_data |>
    dplyr::mutate(
      total_n = n_clusters * cluster_size
    )

  ggplot2::ggplot(
    plot_data,
    ggplot2::aes(
      x = total_n, y = nak_m_mse,
      color = factor(icc), shape = re_structure
    )
  ) +
    ggplot2::geom_point(size = 2.5) +
    ggplot2::geom_line(
      ggplot2::aes(group = interaction(icc, re_structure))
    ) +
    ggplot2::facet_wrap(
      ~target_r2m, labeller = "label_both"
    ) +
    ggplot2::labs(
      x = "Total sample size (J x n)",
      y = "MSE (Nakagawa marginal)",
      color = "ICC",
      shape = "RE structure"
    ) +
    theme_sim()
}
