#### SubSSN Test ####
library(SSN)
library(stringr)

options('scipen' = 100)

##################################################
### Create the Distance Matrix
###################################################
#createDistMat(ssn1, predpts = 'obs_prd', o.write = TRUE, amongpreds = TRUE)

###################################################
### Variable Selection Via Backward Deletion   ###
###################################################
for (i in 1:2) {
  ssn1 <- ssns[[i]]
  obs.bsti <- obs.bsti.lst[[i]]
  obs.vars <- obs.vars.lst[[i]]
  halt = FALSE
  cntr = 1
  th <- 0.05
  vars <- names(obs.bsti)
  
  while (halt == FALSE) {
    start.time <- Sys.time()
    print(paste("Starting model fit", cntr, "at", start.time))
    
    tmp <- glmssn(as.formula(obs.vars[,c('log10_BSTI',vars)]),
                  EstMeth = "ML",
                  ssn1,
                  CorModels = c("locID",'Exponential.Euclid','Exponential.taildown'),
                  addfunccol = "afvArea",
                  family = "Gaussian")
    save_name <- paste0("ssn1_glmssn_std_RUN", i, "_",cntr,'_ML.Rdata')
    assign(paste0("ssn1_glmssn_std_RUN", i, "_",cntr), tmp)
    save(list=paste0("ssn1_glmssn_std_RUN", i , "_",cntr), file = save_name)
    
    stmp <- summary(tmp)
    sum_tab <- stmp$fixed.effects.estimates
    var_to_remove <- sum_tab[which.max(sum_tab$prob.t),'FactorLevel']
    
    end.time <- Sys.time()
    print(paste("Completed model fit", cntr, "and summary at", end.time))
    print(paste("elapsed time was", end.time - start.time))
    cat("\n\n")
    
    if (max(sum_tab$prob.t, na.rm = TRUE) < th) {halt = TRUE}
    
    rm(tmp)
    if (grepl("HDWTR", var_to_remove)) var_to_remove <- "HDWTR"
    vars <- vars[!vars %in% var_to_remove]
    cntr = cntr + 1
  }
  
}

# ssn1_glmssn_9_REML <- glmssn(ssn1_glmssn9$args$formula,
#                              EstMeth = "REML",
#                              ssn1,
#                              CorModels = c("locID",'Exponential.Euclid','Exponential.taildown'),
#                              addfunccol = "afvArea",
#                              family = "Gaussian")

# ssn1_glmssn5 <- glmssn(log10_FSS_26Aug14 ~ MIN_Z + STRMPWR + DIS_1YR_PARSA +
#                          EROD_PARCA + OWN_AGR_PARCA + OWN_PRI_PRCA,
#                        EstMeth = "REML",
#                        ssn1,
#                        CorModels = c("locID",'Exponential.Euclid','Exponential.taildown'), 
#                        addfunccol = "afvArea")
# save(ssn1_glmssn5, file = 'ssn1_glmssn5_20151019.Rdata')
