# #Check model fit with unmodified prediction variables
# fit_preds <- predict.glmssn(fit, predpointsID = "preds", 
#                             newdata = 'preds')
# preds <- getSSNdata.frame(fit_preds, Name = 'preds')
# preds <- merge(preds, preds_obs, by = 'pid')
# critval <- qnorm(0.975)
# max_log10_bsti <- min.max[min.max$variable == 'BSTI','max_val']
# preds$uci <- preds$log10_BSTI + (critval * preds$log10_BSTI.predSE)
# preds$lci <- preds$log10_BSTI - (critval * preds$log10_BSTI.predSE)
# preds$BSTI_u <- 10^(preds$log10_BSTI_obs/100 * max_log10_bsti)
# preds$fit_u <- 10^(preds$log10_BSTI/100 * max_log10_bsti)
# preds$uci_u <- 10^(preds$uci/100 * max_log10_bsti)
# preds$lci_u <- 10^(preds$lci/100 * max_log10_bsti)
# 
# ggplot(data = preds, aes(x = BSTI_u, y = fit_u)) + 
#   geom_point() + 
#   xlim(0, 75) + 
#   ylim(0, 75) +
#   geom_abline(intercept = 0, slope = 1) +
#   stat_smooth(aes(x = BSTI_u, y = uci_u), se = FALSE) +
#   stat_smooth(aes(x = BSTI_u, y = lci_u), se = FALSE) + 
#   scale_y_continuous(limits = c(-10,100))

for (i in 1:2) {
  if (i == 1) {
    m <- ssn1_glmssn_std_RUN1_7
  } else {
    m <- ssn1_glmssn_std_RUN2_7
  }

  print(paste("Performing evaluation of model", i, as.character(m$args$formula)[3], sep = "----"))
  
  fit <- glmssn(m$args$formula,
                EstMeth = "REML",
                ssn1,
                CorModels = c("locID",'Exponential.Euclid','Exponential.taildown'),
                addfunccol = "afvArea",
                family = "Gaussian")
  
###################################################
### check the residuals   
###################################################
fit_resid <- residuals(fit)
names( getSSNdata.frame(fit_resid) )
plot(fit_resid)

resids <- getSSNdata.frame(fit_resid, Name = "Obs")

plot(Torgegram(fit_resid, "log10_BSTI"))

###################################################
### plot the residuals
###################################################
#png('residuals.png', width = 6, height = 6, units = 'in', res = 200)
plot.new()
par(mfrow = c(2, 2))
hist(fit_resid, xlab = "Residuals")
#hist(ssn1, "log10_FSS_26Aug14", xlab = 'Observed log10 FSS')
plot(resids$"_fit_",resids$"_resid_", xlab = 'Predicted log10 BSTI', ylab = 'Raw residuals')
plot(resids$"_fit_",resids$"_resid.stand_", xlab = 'Predicted log10 BSTI', ylab = 'Standardized residuals')
qqnorm(resids$"_resid.stand_", ylab = 'Standardized residuals')
abline(0,1)
#dev.off()

###################################################
### cross validation
###################################################
#cv.out <- CrossValidationSSN(fit)
cv.out <- kfold_CrossValidationSSN(fit)
#cv.out$cv.pred.rounded <- round(cv.out$cv.pred)
png('CV.png', width = 6, height = 4, units = 'in', res = 100)
plot.new()
par(mfrow = c(1, 2))
plot(fit$sampinfo$z,
     cv.out[, "cv.pred"], pch = 19,
     xlab = "Observed Data", ylab = "CV Prediction", ylim = c(0,1.8))
abline(0, 1)
plot( na.omit( getSSNdata.frame(ssn1)[, "log10_BSTI"]),
      cv.out[, "cv.se"], pch = 19,
      xlab = "Observed Data", ylab = "CV Prediction SE")
#dev.off()

#Fit line to cv preds
cv.orig <- merge(cv.out, obs[,c("pid","log10_BSTI")], by = 'pid')
summary(lm(cv.orig$log10_BSTI ~ cv.orig$cv.pred))

###################################################
### likelihood ratio test
###################################################
#source('lrtSSN.R')
fit_null <- glmssn(log10_BSTI ~ 1,
                   EstMeth = "REML",
                   ssn1,
                   CorModels = c("locID",'Exponential.Euclid','Exponential.taildown'),
                   addfunccol = "afvArea",
                   family = "Gaussian")
fit_lrt <- lrtSSN(fit, fit_null)
print(fit_lrt)
# $Chisquared
# [1] 91.77002
# 
# $df
# [1] 6
# 
# $p.value
# [1] 0.0000000000000000129906

###################################################
### non-spatial model
###################################################
fit_nonspatial <- glmssn(fit$args$formula,
                       EstMeth = "REML",
                       ssn1,
                       CorModels = c("locID"),
                       addfunccol = "afvArea",
                       family = "Gaussian")
results_nsp <- InfoCritCompare2(list(fit, fit_nonspatial))
results_nsp$dAIC <- min(results_nsp$AIC) - results_nsp$AIC
print(results_nsp)
# 1 log10_BSTI ~ sum_1095_days + XSLOPE_MAP + MIN_Z + OWN_FED_PRCA + DIS_1YR_PARSA + HDWTR
# 2 log10_BSTI ~ sum_1095_days + XSLOPE_MAP + MIN_Z + OWN_FED_PRCA + DIS_1YR_PARSA + HDWTR
# EstMethod                                        Variance_Components  neg2LogL       AIC
# 1      REML Exponential.taildown + Exponential.Euclid + locID + Nugget -265.4579 -253.4579
# 2      REML                                             locID + Nugget -151.7006 -147.7006
# bias    std.bias     RMSPE       RAV std.MSPE    cov.80    cov.90    cov.95
# 1 0.001814155 0.004823082 0.2079650 0.2018214 1.043955 0.8171053 0.9013158 0.9394737
# 2 0.006583228 0.013800082 0.2310032 0.2299688 1.007022 0.8052632 0.8986842 0.9473684
# dAIC
# 1    0.0000
# 2 -105.7574
}