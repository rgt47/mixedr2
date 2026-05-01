#' Generate LMM data for one replicate
#'
#' Generates a single dataset from a linear mixed model with
#' known variance components. Predictors are drawn from N(0,1).
#'
#' @param n_clusters Number of clusters (J)
#' @param cluster_size Observations per cluster (n)
#' @param params List from [solve_dgp_params()]
#' @param seed Integer seed for reproducibility
#' @return A tibble with columns: y, x1, x2, ..., cluster_id
#' @importFrom tibble tibble
#' @importFrom stats rnorm
#' @export
generate_lmm_data <- function(n_clusters,
                              cluster_size,
                              params,
                              seed = NULL) {
  if (!is.null(seed)) set.seed(seed)

  n_total <- n_clusters * cluster_size
  n_fixed <- length(params$beta)
  cluster_id <- rep(seq_len(n_clusters), each = cluster_size)

  b0 <- rnorm(n_clusters, mean = 0, sd = params$tau0)
  b0_long <- rep(b0, each = cluster_size)

  x_mat <- matrix(
    rnorm(n_total * n_fixed),
    nrow = n_total,
    ncol = n_fixed
  )
  colnames(x_mat) <- paste0("x", seq_len(n_fixed))

  fixed_effect <- as.numeric(x_mat %*% params$beta)

  if (params$tau1 > 0) {
    b1 <- rnorm(n_clusters, mean = 0, sd = params$tau1)
    b1_long <- rep(b1, each = cluster_size)
    random_slope <- b1_long * x_mat[, 1]
  } else {
    random_slope <- 0
  }

  eps <- rnorm(n_total, mean = 0, sd = params$sigma)
  y <- fixed_effect + b0_long + random_slope + eps

  dat <- tibble::as_tibble(as.data.frame(x_mat))
  dat$y <- y
  dat$cluster_id <- cluster_id
  dat
}


#' Create full-factorial scenario grid
#'
#' Builds the grid of all simulation scenarios from the short plan
#' (32 scenarios) with unique seeds per replicate.
#'
#' @param n_sim Number of replications per scenario (default 500)
#' @param clusters Vector of cluster counts (default c(20, 50))
#' @param cluster_sizes Vector of cluster sizes (default c(5, 20))
#' @param iccs Vector of ICC values (default c(0.10, 0.40))
#' @param r2ms Vector of target marginal R-squared
#'   (default c(0.10, 0.40))
#' @param re_structures Vector of random-effects structures
#'   (default c('intercept', 'slope'))
#' @param master_seed Seed for generating per-replicate seeds
#' @return A tibble with one row per scenario-replicate, columns:
#'   scenario_id, n_clusters, cluster_size, icc, target_r2m,
#'   re_structure, rep_id, seed
#' @importFrom tibble tibble
#' @export
create_scenario_grid <- function(n_sim = 500,
                                 clusters = c(20, 50),
                                 cluster_sizes = c(5, 20),
                                 iccs = c(0.10, 0.40),
                                 r2ms = c(0.10, 0.40),
                                 re_structures = c(
                                   "intercept", "slope"
                                 ),
                                 master_seed = 20260306) {
  scenarios <- expand.grid(
    n_clusters = clusters,
    cluster_size = cluster_sizes,
    icc = iccs,
    target_r2m = r2ms,
    re_structure = re_structures,
    stringsAsFactors = FALSE
  )
  scenarios$scenario_id <- seq_len(nrow(scenarios))

  set.seed(master_seed)
  n_scenarios <- nrow(scenarios)
  total_reps <- n_scenarios * n_sim
  all_seeds <- sample.int(.Machine$integer.max, total_reps)

  grid <- scenarios[rep(seq_len(n_scenarios), each = n_sim), ]
  grid$rep_id <- rep(seq_len(n_sim), times = n_scenarios)
  grid$seed <- all_seeds
  rownames(grid) <- NULL
  tibble::as_tibble(grid)
}
