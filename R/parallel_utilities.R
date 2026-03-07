#' Set up parallel processing for simulations
#'
#' Configures [future::plan()] for furrr-based parallel
#' simulation. Falls back to sequential on single-core machines.
#'
#' @param workers Number of workers (default: detectCores() - 1)
#' @param strategy One of 'multisession' or 'sequential'
#' @return Invisibly returns the previous plan
#' @importFrom future plan multisession sequential
#' @export
setup_parallel <- function(workers = NULL,
                           strategy = "multisession") {
  if (is.null(workers)) {
    workers <- max(1, parallel::detectCores() - 1)
  }

  if (strategy == "multisession" && workers > 1) {
    old_plan <- future::plan(
      future::multisession, workers = workers
    )
  } else {
    old_plan <- future::plan(future::sequential)
  }

  options(future.globals.maxSize = 500 * 1024^2)
  invisible(old_plan)
}


#' Tear down parallel processing
#'
#' Resets the [future::plan()] to sequential.
#'
#' @return Invisibly returns the previous plan
#' @importFrom future plan sequential
#' @export
teardown_parallel <- function() {
  old_plan <- future::plan(future::sequential)
  invisible(old_plan)
}
