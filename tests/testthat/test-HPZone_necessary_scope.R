test_that("necessary_scope returns correct scopes", {
  expect_equal(HPZone_necessary_scope(c("Diagnosis", "Case_number", "Entered_by")), "standard")
  expect_equal(HPZone_necessary_scope(c("Diagnosis", "Case_number", "Entered_by", "Family_name")), "extended")
})
