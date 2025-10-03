test_that("HPZone_request throws error on multiple endpoints per query", {
  expect_error(HPZone_request(c("cases", "situations"), "all"))
})
