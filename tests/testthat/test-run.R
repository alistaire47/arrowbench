test_that("run_iteration", {
  b <- Benchmark("test")
  out <- run_iteration(b, ctx = new.env())
  expect_s3_class(out, "data.frame")
  expect_identical(nrow(out), 1L)
})

test_that("run_bm", {
  b <- Benchmark("test",
                 setup = function(param1 = c("a", "b")) {
                   BenchEnvironment(param1 = match.arg(param1))
                 },
                 before_each = result <- NA,
                 run = result <- param1 == "a",
                 after_each = {
                   stopifnot(isTRUE(result))
                   rm(result)
                 }
  )
  out <- run_bm(b, n_iter = 3)

  expect_s3_class(out, "BenchmarkResult")
  expect_identical(nrow(out$result), 3L)

  expect_error(run_bm(b, param1 = "b"), "isTRUE(result) is not TRUE", fixed = TRUE)
})


test_that("run_one", {
  # note: these tests will call an installed version of arrowbench as well as
  # the one being tested (e.g. when using devtools::test())
  run_one(placebo)

  wipe_results()
})

test_that("cases can be versioned", {
  bm_unversioned <- Benchmark(
    "unversioned",
    setup = function(x = c('foo', 'bar')) { force(x) }
  )
  res_unversioned <- run_benchmark(bm_unversioned)
  lapply(res_unversioned$results, function(result) {
    # when version is not supplied, it should not appear in tags
    expect_false("case_version" %in% names(result$tags))
  })

  bm_versioned <- Benchmark(
    "versioned",
    setup = function(x = c('foo', 'bar')) cat(x),
    case_version = function(params) c("foo" = 1L, "bar" = 2L)[params$x]
  )
  res_versioned <- run_benchmark(bm_versioned)
  lapply(res_versioned$results, function(result) {
    expect_true("case_version" %in% names(result$tags))

    expected_version = c(foo = 1L, bar = 2L)[[result$params$x]]
    expect_equal(result$tags$case_version, expected_version)
  })

  expect_error(
    run_bm(bm_versioned, x = "novel value"),
    regexp = "[Cc]ase[ _]version"  # 3.* stopifnot doesn't pass names as messages
  )
})

test_that("get_params_summary returns a data.frame",{
  bm_success <- run_benchmark(placebo, duration = 0.01, grid = TRUE, cpu_count = 1,  output_type = "message")
  success_summary <- get_params_summary(bm_success)
  expect_s3_class(success_summary, "data.frame")

  expected_summary <- dplyr::tibble(
    duration = 0.01, grid = TRUE, cpu_count = 1L,
    output_type = "message", lib_path = "latest", did_error = FALSE
  )
  expect_identical(success_summary, expected_summary)

})

test_that("get_params_summary correctly returns an error column", {
  bm_error <- run_benchmark(placebo, cpu_count = 1, output_type = "message", error_type = "abort")
  error_summary <- get_params_summary(bm_error)
  expect_true(error_summary$did_error)
})


test_that("Argument validation", {
  # note: these tests will call an installed version of arrowbench as well as
  # the one being tested (e.g. when using devtools::test())
  expect_message(
    run_one(placebo, not_an_arg = 1, cpu_count = 1),
    "Error.*unused argument.*not_an_arg"
  )

  expect_message(
    run_one(placebo, cpu_count = 1),
    NA
  )


  expect_true(file.exists(test_path("results/placebo/1.json")))
})

test_that("Path validation and redaction", {
  # note: these tests will call an installed version of arrowbench as well as
  # the one being tested (e.g. when using devtools::test())
  expect_message(
    run_one(placebo, cpu_count = 1, grid = "not/a/file@path"),
    NA
  )

  expect_true(file.exists(test_path("results/placebo/1-not_a_file@path.json")))
})

test_that("form of the results", {
  expect_message(res <- run_benchmark(placebo, cpu_count = 1))

  results_df <- as.data.frame(res)
  expect_identical(
    results_df[,c("iteration", "cpu_count", "lib_path")],
    dplyr::tibble(
      iteration = 1L,
      cpu_count = 1L,
      lib_path = "latest"
    ),
    ignore_attr = TRUE
  )
  expect_true(all(
    c("real", "process", "version_arrow") %in% colnames(results_df)
  ))
})

test_that("form of the results, including output", {
  expect_message(res <- run_benchmark(placebo, cpu_count = 1, output_type = "message"))

  results_df <- as.data.frame(res)

  expected <- dplyr::tibble(
    iteration = 1L,
    cpu_count = 1L,
    lib_path = "latest",
    output = "A message: here's some output\n### RESULTS HAVE BEEN PARSED ###"
  )
  # output is always a character, even < 4.0, where it would default to factors
  expected$output <- as.character(expected$output)

  expect_identical(
    results_df[, c("iteration", "cpu_count", "lib_path", "output")],
    expected,
    ignore_attr = TRUE
  )
  expect_true(all(
    c("real", "process", "version_arrow") %in% colnames(results_df)
  ))

  json_keys <- c(
    "name", "tags", "info", "context", "github", "options", "result", "params",
    "output", "rscript"
  )
  expect_named(res$results[[1]]$list, json_keys, ignore.order = TRUE)

  expect_message(res <- run_benchmark(placebo, cpu_count = 1, output_type = "warning"))
  results_df <- as.data.frame(res)
  expect_identical(
    results_df$output,
    paste(
      "Warning message:",
      "In placebo_func() : A warning:here's some output",
      "",
      "### RESULTS HAVE BEEN PARSED ###",
      sep = "\n"
    )
  )

  expect_message(res <- run_benchmark(placebo, cpu_count = 1, output_type = "cat"))
  results_df <- as.data.frame(res)
  expect_identical(
    results_df$output,
    "A cat: here's some output\n### RESULTS HAVE BEEN PARSED ###"
  )
})

test_that("form of the results during a dry run", {
  res <- run_benchmark(placebo, cpu_count = 10, dry_run = TRUE)

  expect_true(all(sapply(res$results[[1]], class) == "character"))
  expect_true("cat(\"\n##### RESULTS FOLLOW\n\")" %in% res$results[[1]])
  expect_true("cat(\"\n##### RESULTS END\n\")" %in% res$results[[length(res$results)]])
})

test_that("an rscript is added to the results object", {
  res <- run_benchmark(placebo, cpu_count = 1)
  expect_true(file.exists(test_path("results/placebo/1-0.01-TRUE.json")))
  res <- run_benchmark(placebo, cpu_count = 10, duration = 0.1)
  res_path <- test_path("results/placebo/10-0.1-TRUE.json")
  expect_true(file.exists(res_path))

  res <- read_json(res_path)
  expect_true("rscript" %in% names(res))
})

wipe_results()
