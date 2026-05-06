# does not work top to bottom... is meant to be run in pieces to explore
# "REDCapSync & RosyREDCap"
#"Advanced REDCap API for Even the Basic R User; R Med 26 Demo"
# "Brandon Rose, MD, MPH"

# this will allow REDCapSync to ignore your cache of real projects for demo
# withr::local_envvar(R_USER_CACHE_DIR = withr::local_tempdir())

# 0. Install and Load -------

# install pak package if you don't have it
install.packages("pak")

pak::pkg_install("thecodingdocs/REDCapSync") # installs REDCapSync from github
# install.packages("REDCapSync") # once on CRAN install like this

pak::pkg_install("thecodingdocs/RosyREDCap") # installs RosyREDCap from github
# install.packages("RosyREDCap") # once on CRAN install like this

library("REDCapSync") # load the library
library("RosyREDCap") # load the library

getNamespaceExports("REDCapSync")
getNamespaceExports("RosyREDCap")

# see what projects exist with your current setup
projects$any()
projects$n()
projects$df()$project_name # if you have projects already
projects$print()

# 1. Setup Project(s) ------

## 1A. TEST Projects (No REDCap Required)

your_directory <- getwd() # make sure you have an R project set up and that you are okay with files being stored here (be very careful with cloud drives and git repos!)

#test projects can be loaded but will not know where
project <- load_project("TEST_CLASSIC")
project$dir_path # is NA

project <- setup_project(
  project_name = "TEST_CLASSIC",
  redcap_uri = "https://redcap.fake.edu/api/",
  dir_path = your_directory
)
project$dir_path # your chosen directory

## 1B. REAL Projects (requires API token)

your_directory <- getwd() # make sure you have an R project set up and that you are okay with files being stored here (be very careful with cloud drives and git repos!)
help(setup_project)

project <- setup_project(
  project_name = "FIRST_PROJECT",
  redcap_uri = "https://redcap.fake.edu/api/", # see API playground
  dir_path = your_directory,
  sync_frequency = "daily", # default
  get_entire_log = TRUE # not default but helpful for datasets
)

# 2. Setup Token(s) ------

## 2A. Setting Your Token using User Environment Variables (preferred)

# 1.  Open the .Renviron file with `usethis::edit_r_environ()`
# 2.  Add the token like this... `REDCAPSYNC_FIRST_PROJECT = "faKeTokeN"`
# 3.  Save the file and Close
# 4.  Restart R Session (Session tab or `.rs.restartR()`).
# 5.  Confirm with `Sys.getenv("REDCAPSYNC_FIRST_PROJECT")`

#Install usethis if you don't have it.
#install.packages("usethis")
usethis::edit_r_environ()
# Now save your token.... (without the comment symbol '#')
# REDCAPSYNC_FIRST_PROJECT = "faKeTokeN"
# Save the file and Close
# Restart R Session (session tab)
# .rs.restartR() # this will also restart R session for you.
Sys.getenv("REDCAPSYNC_FIRST_PROJECT") # now should contain your token

## 2B. Setting Your Token using `keyring` package

# enter token in pop-up window
project$set_keyring_token()
# internally the package checks ...
#1. Sys.getenv()
token <- Sys.getenv(project$.internal$token_name)
#2. followed by keyring
token <- keyring::key_get(service = config$keyring.service(),
                          username = project$project_name,
                          keyring = config$keyring())
# you could set with the following; not preferred because token in script
# if you do this set in securely in file that no one can ever see; never github!
keyring::key_set_with_value(service = config$keyring.service(),
                            username = project$project_name,
                            password = "VeryNOTsecureWayToSetYourTOKEN",
                            keyring = config$keyring())


## 2C. Setting Your Token for One Session

# Set your token manually
# again having this in a script is not advised but possible
Sys.setenv(REDCAPSYNC_FIRST_PROJECT="a_FaKe_TOkEn_NEVER_in_a_script")

# Get your token
Sys.getenv("REDCAPSYNC_FIRST_PROJECT")
#>[1] "a_FaKe_TOkEn"

## Testing Token (optional)

project$test_token()

# 3. Sync Project(s) ------

# now sync everything (will save files to directory by default)
project$sync()

#if you have multiple projects this will sync them all!
sync()

project$url_launch() # brings you to project home in browser
# Choose one of "base", "home", "record_home", "records_dashboard", "api", "api_playground", "codebook", "user_rights", "setup", "logging", "designer", "dictionary", "data_quality", or "identifiers".
project$url_launch("dictionary") # brings you to project home in browser

project$url_record_launch(record = "5") # brings you to record in browser

# 4. Explore Project ------

forms <- project$metadata$forms # unchanged metadata
fields <- project$metadata$fields # unchanged metadata
choices <- project$metadata$choices # unchanged metadata

users <- project$redcap$users # unchanged users
log <- project$redcap$log # unchanged log

project$data |> list2env(globalenv()) # add raw data to envir

# the current public methods (more in development such add_field)
REDCapSyncProject$public_methods |> names() |> setdiff("initialize")
#  [1] "print"             "sync"              "add_dataset"
#  [4] "load_dataset"      "remove_datasets"   "generate_dataset"
#  [7] "save_datasets"     "save_dataset"      "save"
# [10] "set_keyring_token" "test_token"        "url_launch"
# [13] "url_record_launch" "upload"

# unlike above fields, forms, choices are annotated
project$load_dataset("REDCapSync", envir = globalenv())

# 5. Define Datasets ------

## project$generate_dataset(...)

your_directory <- getwd() # make sure you have an R project set up and that you are okay with files being stored here (be very careful with cloud drives and git repos!)
project <- setup_project(
  project_name = "TEST_CLASSIC",
  redcap_uri = "https://redcap.fake.edu/api/",
  dir_path = your_directory
)
project$metadata$fields$field_name # view field_names

dataset <- project$generate_dataset(
  dataset_name = "add_age_at_diagnosis",
  envir = globalenv(), # puts in global R environment
  transformation_type = "default",
  merge_form_name = "merged",
  exclude_identifiers = FALSE,
  exclude_free_text = TRUE,
  date_handling = "random_shift_by_project",
  include_metadata = TRUE,
  include_records = TRUE,
  include_users = TRUE,
  include_log = TRUE,
  annotate_from_log = TRUE,
  include_comments = TRUE
)
#if you wanted you could modify and save custom (without add_dataset)
calc_age <- function(dob, age.day){
  (lubridate::interval(dob, age.day)/lubridate::duration(num = 1,
        units = "years")) |> floor() |>  as.integer()
}
dataset$data$merged$age_at_diagnosis <-
  dataset$data$merged$var_birth_date |>
  calc_age(dataset$data$merged$diagnosis_start)

dataset$save()
# future dev will have this functionality parallel to add_dataset but as add_field and will be passed to all datasets and added to metadata (available for filter)

## project$add_dataset(...)

your_directory <- getwd() # make sure you have an R project set up and that you are okay with files being stored here (be very careful with cloud drives and git repos!)
project <- setup_project(
  project_name = "TEST_CLASSIC",
  redcap_uri = "https://redcap.fake.edu/api/",
  dir_path = your_directory
)
project$metadata$fields$field_name # view field_names

project$add_dataset(
  dataset_name = "stage_three_and_four",
  transformation_type = "default",
  merge_form_name = "merged",
  filter_field = "stage_at_diagnosis",
  filter_choices = c("III","IV"),
  exclude_identifiers = TRUE,
  exclude_free_text = FALSE,
  date_handling = "random_shift_by_project",
  include_metadata = TRUE,
  include_records = TRUE,
  include_users = TRUE,
  include_log = TRUE,
  annotate_from_log = TRUE,
  include_comments = TRUE
)
# project$remove_datasets("stage_three_and_four")

project$add_dataset(
  dataset_name = "ecog_zero",
  transformation_type = "default",
  merge_form_name = "merged",
  filter_field = "ecog_at_diagnosis",
  filter_choices = "0",
  exclude_identifiers = TRUE,
  exclude_free_text = FALSE,
  date_handling = "random_shift_by_project",
  include_metadata = TRUE,
  include_records = TRUE,
  include_users = TRUE,
  include_log = TRUE,
  annotate_from_log = TRUE,
  include_comments = TRUE
)
# project$remove_datasets("ecog_zero")

project$.internal$datasets |> names() # now stored internally


project$save_datasets()

# 6. RosyREDCap ------

## Launch the app!!!

run_RosyREDCap(test_mode = TRUE)


## Metadata Network

### Multiarm

projects$load("TEST_MULTIARM") |>
  REDCap_diagram(duplicate_forms = F, hierarchical = T)


### Classic


projects$load("TEST_CLASSIC") |> REDCap_diagram(include_fields = T)


## Tables


projects$load("TEST_CLASSIC")$load_dataset("REDCapSync")$data$merged |>
  make_table1(
    group = "var_branching",
    variables = c("stage_at_diagnosis", "ecog_at_diagnosis", "deceased")
  )



load_project("TEST_CLASSIC")$
  generate_dataset(filter_field = "ecog_at_diagnosis",
                   filter_choices = "0",
                   drop_blanks = TRUE
  )$data$merged |>
  make_table1(group = "var_branching",
              variables = c("stage_at_diagnosis", "deceased"))


## Parcats/Sankey


DF <- load_project("TEST_CLASSIC")$load_dataset("REDCapSync")$data$merged
DF$ecog_strat <- ifelse(DF$ecog_at_diagnosis %in% c("2", "3","4"),
                        "Poor",
                        "Good") |>
  factor(levels = c("Poor", "Good"), ordered = T)
attr(DF$ecog_strat, "label") <- "Performance Status"
vars <-  c("ecog_strat", "stage_at_diagnosis", "deceased")
DF |> dplyr::select(vars) |> plotly_parcats()

## Survival

DF <- load_project("TEST_CLASSIC")$load_dataset("REDCapSync")$data$merged
DF$ecog_strat <- ifelse(DF$ecog_at_diagnosis %in% c("2", "3","4"),
                        "Poor",
                        "Good") |>
  factor(levels = c("Poor", "Good"), ordered = T)
attr(DF$ecog_strat, "label") <- "Performance Status"
DF$deceased <- as.integer(DF$deceased == "True")
DF |>
  make_survival(start_col = "diagnosis_start",
                end_col = "last_contact",
                strat_col = "ecog_strat",
                status_col = "deceased",
                units = "years",
                xlim = c(0, 4))

# 7. Advanced/Dev ------

projects$load("TEST_MULTIARM")$.internal |> listviewer::jsonedit()

## Uploads

project <- load_project("TEST_CLASSIC")$sync()

upload_this <- data.frame(record_id = as.character(51:100),
                          var_branching = sample(c("Yes", "No"),
                                                 size = 50,
                                                 replace = TRUE),
                          ecog_at_diagnosis = "0")

# project$upload(upload_this)
# future dev will have comparisons/checks and calculated fields (from R).

project <- setup_project(
  project_name = "TEST_CLASSIC",
  redcap_uri = "https://redcap.fake.edu/api/",
  dir_path = getwd()
)
excel_edits <- project$.internal |> REDCapSync:::read_dataset_from_file("REDCapSync")

# project$upload(excel_edits) # in dev testing!

## PDF Rmarkdown reports (dev)

REDCapSync:::TEST_PROJECT_NAMES
# need to specify dir for tests, not real projs
dir_other <- getwd() |> file.path("output")
projects$load("TEST_CLASSIC")$sync() |> rmarkdown_project(dir_other)
projects$load("TEST_REPEATING")$sync() |> rmarkdown_project(dir_other)
projects$load("TEST_LONGITUDINAL")$sync() |> rmarkdown_project(dir_other)
projects$load("TEST_REDCAPR_SIMPLE")$sync() |> rmarkdown_project(dir_other)

