test_that("make_valid allows case mismatch and truncation in endpoints", {
  expect_equal(HPZone_make_valid(endpoints="case"), "Cases")
  expect_equal(HPZone_make_valid(endpoints="cases"), "Cases")
  expect_equal(HPZone_make_valid(endpoints=c("cases", "contact", "enq")), c("Cases", "Contacts", "Enquiries"))
  expect_error(HPZone_make_valid(endpoints="casessss"))
})

test_that("make_valid allows case mismatch and truncation in fields", {
  expect_equal(HPZone_make_valid(fields="diagnosis"), "Diagnosis")
  expect_equal(HPZone_make_valid(fields="date of onset"), "Date_of_onset")
  expect_equal(HPZone_make_valid(fields=c("date of onset", "Datum_definitief")), c("Date_of_onset", "Datum_definitief_in_osiris"))
})

test_that("make_valid throws errors for ambiguous names", {
  expect_error(HPZone_make_valid(fields="diag"))
  expect_error(HPZone_make_valid(fields="date of on"))
})
