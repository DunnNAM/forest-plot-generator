
set.seed(48197)

## variables to be included in the data
vars <- c("AgeAtDiagnosis", "Sex", "IndigenousStatus", "SocioeconomicStatus", 
          "ComorbidityCount", "Remoteness", "DxYearGroup", "ASA", "FacilityType",
          "Stage", "IND_1", "IND_2", "IND_3", "Time_1", "Time_2", "Time_3")

# mean value
mu <- rep(0, length(vars))
names(mu) <- vars

# sd (assuming multivariate normal distribution)
sigma <- diag(length(vars))
rownames(sigma) <- vars
colnames(sigma) <- vars

# correlations between covariates
sigma[2,1] <- sigma[1,2] <- 0.1   ## correlation between age and sex
sigma[3,1] <- sigma[1,3] <- 0.2   ## correlation between age and First Nations status
sigma[5,1] <- sigma[1,5] <- 0.2   ## correlation between age and comorbidity count
sigma[6,1] <- sigma[1,6] <- -0.05 ## correlation between age and remoteness
sigma[7,1] <- sigma[1,7] <- 0.02  ## correlation between age and diagnosis time period
sigma[8,1] <- sigma[1,8] <- 0.3   ## correlation between age and ASA score
sigma[9,1] <- sigma[1,9] <- 0.2   ## correlation between facility type and age
sigma[6,3] <- sigma[3,6] <- -0.1  ## correlation between remoteness and First Nations Status
sigma[7,3] <- sigma[3,7] <- -0.9  ## correlation between facility type and First Nations status
sigma[5,4] <- sigma[4,5] <- 0.3   ## correlation between SES and comorbidities
sigma[9,4] <- sigma[4,9] <- -0.4  ## correlation between SES and facility type 
sigma[11,] <- sigma[,11] <- sigma[14,] <- sigma[,14] <- ## IND_1 correlations
  c(0.05, -0.4, -0.2, -0.05, -0.03, 0, 0.2, 0, 0, 0, 1, 0, 0, 1, 0, 0)
sigma[12,] <- sigma[,12] <- sigma[15,] <- sigma[,15] <-     ## IND_2 correlations
  c(-0.2, -0.02, -0.1, -0.1, -0.5, 0.1, 0.3, -0.3, -0.2, -0.2, 0, 1, 0, 0, 1, 0) 
sigma[13,] <- sigma[,13] <- sigma[16,] <- sigma[,16] <-      ## IND_3 correlations
  c(0.1, -0.2, -0.04, 0.3, 0.25, 0.3, -0.05, 0.3, 0, 0.15, 0, 0, 1, 0, 0, 1)

### note that sigma must be symmetrical about the main diagonal, which should all be 1

dat <- mvtnorm::rmvnorm(n = 5000, mean = mu, sigma = sigma)

dat <- dat %>% 
  as_tibble() %>% 
  dplyr::transmute(PatientID = 1:5000,
                   Sex = case_when(Sex <= qnorm(0.55) ~ "Male",
                                   Sex > qnorm(0.55) ~ "Female"),
                   Sex = factor(Sex, levels = c("Female", ## ref for reg
                                                "Male")),
                   AgeAtDiagnosis =  round(qgamma(pnorm(AgeAtDiagnosis), 60, scale = 1.1)),
                   AgeGroupAtDiagnosis = case_when(AgeAtDiagnosis < 50 ~ "<50",
                                                   AgeAtDiagnosis < 60 ~ "50-59",
                                                   AgeAtDiagnosis < 70 ~ "60-69",
                                                   AgeAtDiagnosis < 80 ~ "70-79",
                                                   AgeAtDiagnosis >= 80 ~ "80+"),
                   AgeGroupAtDiagnosis = factor(AgeGroupAtDiagnosis,
                                                levels = c("60-69", ## ref for reg
                                                           "<50", "50-59",
                                                           "70-79", "80+")),
                   IndigenousStatus = case_when(IndigenousStatus <= qnorm(0.04) ~ 
                                                  "First Nations peoples",
                                                IndigenousStatus > qnorm(0.04) ~
                                                  "Non First Nations peoples"),
                   IndigenousStatus = factor(IndigenousStatus,
                                             levels = c("Non First Nations peoples", ## ref for reg
                                                        "First Nations peoples")),
                   SocioeconomicStatus = case_when(SocioeconomicStatus <= qnorm(0.25) ~
                                                     "Affluent", 
                                                   SocioeconomicStatus <= qnorm(0.7) ~
                                                     "Middle", 
                                                   SocioeconomicStatus > qnorm(0.7) ~
                                                     "Disadvantaged"),
                   SocioeconomicStatus = factor(SocioeconomicStatus, 
                                                levels = c("Affluent", ## ref for reg
                                                           "Middle", "Disadvantaged")),
                   ComorbidityCount = qpois(pnorm(ComorbidityCount), 1),
                   ComorbidityCountGroup = case_when(ComorbidityCount == 0 ~ "0",
                                                     ComorbidityCount == 1 ~ "1",
                                                     TRUE ~ "2+"),
                   ComorbidityCountGroup = factor(ComorbidityCountGroup,
                                                  levels = c("0", "1", "2+")),
                   Remoteness = case_when(Remoteness <= qnorm(0.62) ~ "Major City",
                                          Remoteness <= qnorm(0.84) ~ "Inner Regional",
                                          Remoteness <= qnorm(0.97) ~ "Outer Regional",
                                          Remoteness > qnorm(0.97) ~ "Remote & Very Remote"),
                   Remoteness = factor(Remoteness,
                                       levels = c("Major City", "Inner Regional",
                                                  "Outer Regional", "Remote & Very Remote")),
                   DxYearGroup = case_when(DxYearGroup <= qnorm(0.47) ~ "2012-2016", 
                                           DxYearGroup > qnorm(0.47) ~ "2017-2021"),
                   DxYearGroup = factor(DxYearGroup,
                                        levels = c("2012-2016", "2017-2021")),
                   ASA = case_when(IND_1 > qnorm(0.8) ~ NA,
                                   ASA < 0 ~ "1-2",
                                   ASA >= 0 ~ "3+"),
                   ASA = factor(ASA, levels = c("1-2", "3+")),
                   FacilityType = case_when(IND_1 > qnorm(0.8) ~ NA,
                                            FacilityType <= qnorm(0.6) ~ "Public",
                                            FacilityType > qnorm(0.6) ~ "Private"),
                   FacilityType = factor(FacilityType, levels = c("Public", "Private")),
                   Stage = case_when(Stage <= qnorm(0.3) ~ 1,
                                     Stage <= qnorm(0.6) ~ 2,
                                     Stage <= qnorm(0.85) ~ 3,
                                     Stage > qnorm(0.85) ~ 4),
                   Stage = factor(Stage, levels = 1:4),
                   AdmissionStatus = sample(1:2, 5000, replace = TRUE,
                                            prob = c(0.8,0.2)),
                   AdmissionStatus = case_when(IND_1 > qnorm(0.8) ~ NA,
                                               TRUE ~ AdmissionStatus),
                   AdmissionStatus = factor(AdmissionStatus, levels = 1:2,
                                            labels = c("Elective", "Emergency")),
                   Time_1 = case_when(IND_1 <= qnorm(0.8) 
                                      ~qexp(pnorm(Time_1)),
                                      TRUE ~ qexp(pnorm(Time_1)) + 5),
                   Time_2 = case_when(IND_2 <= qnorm(0.5) 
                                      ~qexp(pnorm(Time_2), rate = 0.1),
                                      TRUE ~ qexp(pnorm(Time_2), rate = 0.1) + 5),
                   Time_3 = case_when(IND_3 <= qnorm(0.92) 
                                      ~qexp(pnorm(Time_3), rate = 0.05),
                                      TRUE ~ qexp(pnorm(Time_3), rate = 0.05) + 5),
                   IND_1 = case_when(IND_1 <= qnorm(0.8) ~ "Yes",
                                     IND_1 > qnorm(0.8) ~ "No"),
                   IND_2 = case_when(IND_2 <= qnorm(0.5) ~ "Yes",
                                     IND_2 > qnorm(0.5) ~ "No"),
                   IND_3 = case_when(IND_1 == "No" ~ NA_character_,
                                     IND_3 >= qnorm(0.92) ~ "Yes",
                                     IND_3 < qnorm(0.92) ~ "No"),
                   across(starts_with("IND_"), 
                          ~factor(., levels = c("Yes", "No"))),
                   across(starts_with("IND_"), 
                          ~case_when(. == "Yes"~ 1,
                                     . == "No" ~ 0),
                          .names = "{.col}_bin"))

