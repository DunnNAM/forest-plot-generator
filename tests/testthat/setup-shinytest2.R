# load_app_env() is intentionally omitted. AppDriver launches the app in a
# separate process so the app environment does not need to be sourced into the
# test session. Only here is loaded for path resolution in test files.
library(here)
