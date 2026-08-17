library(tinytest)
test_package("mixedr2")

# Integration tests (end-to-end grid -> simulation -> summary path)
# live in tests/integration/ per CLAUDE.md, separate from the
# per-function unit tests in inst/tinytest/. test_package() above
# does not discover this directory, so it is run explicitly here.
if (requireNamespace("mixedr2", quietly = TRUE)) {
  library(mixedr2)
  integration_dir <- file.path("integration")
  if (dir.exists(integration_dir)) {
    tinytest::run_test_dir(integration_dir)
  }
}
