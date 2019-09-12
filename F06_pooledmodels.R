#' #############################################################
#' Metapopulation ecology links antibiotic resistance, consumption
#' and patient transfers in a network of hospital wards
#' 
#' Shapiro et al. 2019
#' (c) Jean-Philippe Rasigade, Julie T Shapiro
#' Université Claude Bernard Lyon 1
#' CIRI Inserm U1111
#' 
#' MIT LICENSE
#' #############################################################
#' 
#' Computations for global generalized linear models and specific antibiotic
#' models for all 3rd generation cephalosporin (3GCR) resistant taxa pooled together.
#' 

library(data.table) # Tested with version 1.12.2 for R version 3.6.0
library(dplyr)      # Tested with version 0.8.0.1 for R version 3.6.0
library(visreg)     #Tested with version 2.5-0 for R version 3.6.0

#Begin with dataframe "mod.dat.raw" from F03 script
load("modeldata.Rdata")
head(mod.dat.raw)

# List of 3GCR taxa
c3gR.list <- c("ESCCOL_C3G_R", "KLEPNE_C3G_R","KLEPNE_CARBA_R",
               "ENTCLO_C3G_R", "ENTCLO_CARBA_R","PSEAER_S","PSEAER_CARBA_R",
               "ACIBAU_CARBA_S", "ACIBAU_CARBA_R","ENCFAC_VANCO_S","ENCFAC_VANCO_R",
               "STAAUR_OXA_R")

# Subset the data to include only taxa in the c3gR.list 
c3gR.dat.raw <- subset(mod.dat.raw, BacType %in% c3gR.list)

# Sum N_patients, C_control, and S_connectivity of different variants by ward
c3gR.dat.raw2 <- c3gR.dat.raw %>%
  group_by(ward) %>%
  summarize(C_controlC3G = sum(C_control),
            N_patsC3G = sum(N_patients),
            S_connC3G = sum(S_connectivity))

# Select ward-level variables
ddd.dat.c3g <- select(c3gR.dat.raw, ward, n_beds, PatStat,  starts_with("ddd_"))
ddd.dat.c3g <- distinct(ddd.dat.c3g)

# Join the summed N, S, C data by taxa to the ward-level variables
c3g.R.dat.raw3 <- left_join(c3gR.dat.raw2, ddd.dat.c3g, by="ward")

# Change data.frame to a data.table
c3g.R.dat.raw3 <- data.table(c3g.R.dat.raw3)

# Select the columns that will be log2 transformed
logVars.c3g <- c("C_controlC3G", "S_connC3G","ddd_total","ddd_carba", "ddd_c1g_c2g",
                 "ddd_c3g_classic","ddd_c3g_pyo","ddd_glyco","ddd_oxa","ddd_fq","ddd_bsp","ddd_nsp","n_beds")

# Transform the selected variables using data.table package
# To avoid infinity values from log-transformation, 
# first convert all 0 values to 1/2 the non-zero minimum value
# Then apply a log-2 transformation
c3g.dat <- c3g.R.dat.raw3[ , (logVars.c3g) := lapply(.SD, function(x) {
  xmin <- min(x[x > 0])
  x[x < xmin] <- xmin / 2
  return(log2(x))
}) , .SDcol = logVars.c3g]


# Global 3GCR model
c3gR.mod1 <- glm(N_patsC3G ~ C_controlC3G + n_beds + S_connC3G + ddd_total + PatStat, 
                 family = poisson, data = c3g.dat)

# Run the 3GCR model using specific antibiotics
c3gR.mod2 <- glm(N_patsC3G ~ C_controlC3G + S_connC3G +
                   ddd_carba + ddd_c1g_c2g
                 + ddd_c3g_classic + ddd_c3g_pyo + ddd_glyco + ddd_oxa
                 + ddd_fq + ddd_bsp + ddd_nsp , 
                 family = poisson, data = c3g.dat)

#' #############################################################
#' 
#' Computations for global generalized linear models and specific antibiotic
#' models for all Carbapenem resistant (CR) taxa pooled together.
#' 

#Begin with dataframe "mod.dat.raw" from F03 script
head(mod.dat.raw)

# List of CR taxa
carbaR.list <-c("ESCCOL_CARBA_R","KLEPNE_CARBA_R","ENTCLO_CARBA_R","PSEAER_CARBA_R","ACIBAU_CARBA_R",
                "ENCFAC_VANCO_S","ENCFAC_VANCO_R","STAAUR_OXA_R")

# Subset the data to include only taxa in the carbaR.list 
carbaR.dat.raw <- subset(mod.dat.raw, BacType %in% carbaR.list)

# Sum N_patients, C_control, and S_connectivity of different variants by ward
carbaR.dat.raw2 <- carbaR.dat.raw %>%
  group_by(ward) %>%
  summarize(C_controlCarba = sum(C_control),
            N_patsCarba = sum(N_patients),
            S_connCarba = sum(S_connectivity))

# Select ward-level variables
ddd.dat.carba <- select(carbaR.dat.raw, ward, n_beds,PatStat,  starts_with("ddd_"))
ddd.dat.carba <- distinct(ddd.dat.carba)

# Join the summed N, S, C data by taxa to the ward-level variables
carbaR.dat.raw3 <- left_join(carbaR.dat.raw2, ddd.dat.carba, by="ward")

#Change data.frame to a data.table
carbaR.dat.raw3 <- data.table(carbaR.dat.raw3)

#Select the columns that will be transformed
logVars.carba <- c("C_controlCarba", "S_connCarba","ddd_total","ddd_carba", "ddd_c1g_c2g",
                   "ddd_c3g_classic","ddd_c3g_pyo","ddd_glyco","ddd_oxa","ddd_fq","ddd_bsp","ddd_nsp","n_beds")

# Transform the selected variables using data.table package
# Note: To avoid infinity values from log-transformation, 
# first convert all 0 values to 1/2 the non-zero minimum value
# Then apply a log-2 transformation
carbaR.dat <- carbaR.dat.raw3[ , (logVars.carba) := lapply(.SD, function(x) {
  xmin <- min(x[x > 0])
  x[x < xmin] <- xmin / 2
  return(log2(x))
}) , .SDcol = logVars.carba]


# Global CR model
carbaR.mod1 <- glm(N_patsCarba ~ C_controlCarba + n_beds + S_connCarba + ddd_total + PatStat, 
                   family = poisson, data = carbaR.dat)

# CR model using specific antibiotics
carbaR.mod2 <- glm(N_patsCarba ~ C_controlCarba + S_connCarba +
                     ddd_carba + ddd_c1g_c2g
                   + ddd_c3g_classic + ddd_c3g_pyo + ddd_glyco + ddd_oxa
                   + ddd_fq + ddd_bsp + ddd_nsp , 
                   family = poisson, data = carbaR.dat)

#' #############################################################
#' 
#' Creates Figure 4, showing the coefficients for the global
#' model and graphs the relationship between the consumption of specific
#' antibiotics and infection incidence
#' 

# Combine 3GCR and CR models into a single list
# Global model list
combined.simplist <- list(c3gR.mod1,carbaR.mod1)

# Specific antibiotic model list
combined.atbslist <- list(c3gR.mod2,carbaR.mod2)

# Calculate 95% confidence interval for each model in each list
coef.combined.simp <- lapply(combined.simplist, function(x) {
  cis.comb <- confint(x)
  return(cbind(cis.comb, coefficients(x)))
}) 

coef.combined.atbs <- lapply(combined.atbslist, function(x) {
  cis.comb <- confint(x)
  return(cbind(cis.comb, coefficients(x)))
}) 

# Rename each object in the list
names(coef.combined.simp) <- c("C3GR","CarbaR")
names(coef.combined.atbs) <- c("C3GR","CarbaR")

###Coefficients #############################

# Prepare Figure:
# Extract from each list (3GCR and CR) the beta coefficient and lower and upper confidence intervals
# for each variable
{
  coef_ps <- unlist(lapply(coef.combined.simp, function(x) x[grep("PatStat", rownames(x)),3]))
  coef_ps_li <- unlist(lapply(coef.combined.simp, function(x) x[grep("PatStat", rownames(x)),1]))
  coef_ps_ui <- unlist(lapply(coef.combined.simp, function(x) x[grep("PatStat", rownames(x)),2]))
  
  
  coef_n <- unlist(lapply(coef.combined.simp, function(x) x[grep("n_beds", rownames(x)),3]))
  coef_n_li <- unlist(lapply(coef.combined.simp, function(x) x[grep("n_beds", rownames(x)),1]))
  coef_n_ui <- unlist(lapply(coef.combined.simp, function(x) x[grep("n_beds", rownames(x)),2]))
  
  
  coef_s <- unlist(lapply(coef.combined.simp, function(x) x[grep("S_", rownames(x)),3]))
  coef_s_li <- unlist(lapply(coef.combined.simp, function(x) x[grep("S_", rownames(x)),1]))
  coef_s_ui <- unlist(lapply(coef.combined.simp, function(x) x[grep("S_", rownames(x)),2]))
  
  coef_atb <- unlist(lapply(coef.combined.simp, function(x) x[grep("ddd_total", rownames(x)),3]))
  coef_atb_li <- unlist(lapply(coef.combined.simp, function(x) x[grep("ddd_total", rownames(x)),1]))
  coef_atb_ui <- unlist(lapply(coef.combined.simp, function(x) x[grep("ddd_total", rownames(x)),2])) 
}

# Assign labels and colors to 3GCR and CR models
buglabs <- c("All 3GCR", "All CR")
bugcols <- c( "deepskyblue", "darkmagenta")

ord <- T

errorbar_width <- 0.04

# Plot the beta coefficients and 95% confidence intervals for each variable in each model
svg(file = "glm_pooled_pane1.svg", 1.5, 6)
{
  p <- length(coef.combined.simp)
  
  par(mfrow = c(5,1))
  par(mar = c(1,4,1,4))
  xl <- c(0.75, 2.25)
  marker.cex <- 1.25
  
  yl <- c(-0.2,0.2)
  plot(coef_ps[ord], xlim = xl, ylim = yl, xaxt = "n", xlab = "", ylab = "Ward type", bty = "n", type = "n")
  abline(0,0, lty = 2, col = "lightgrey")
  arrows(1:p, coef_ps_li[ord], 1:p, coef_ps_ui[ord], length = errorbar_width, angle = 90, code = 3, col = "darkgrey")
  points(coef_ps[ord], pch = 19, col = bugcols, cex = marker.cex)
  
  yl <- c(-0.1,0.1)
  plot(coef_n[ord], xlim = xl, ylim = yl, xaxt = "n", xlab = "", ylab = "Ward size", bty = "n", type = "n")
  abline(0,0, lty = 2, col = "lightgrey")
  arrows(1:p, coef_n_li[ord], 1:p, coef_n_ui[ord], length = errorbar_width, angle = 90, code = 3, col = "darkgrey")
  points(coef_n[ord], pch = 19, col = bugcols, cex = marker.cex)
  
  yl <- c(-0.1,0.1)
  plot(coef_s[ord], xlim = xl, ylim = yl, xaxt = "n", xlab = "", ylab = "Connectivity", bty = "n", type = "n")
  abline(0,0, lty = 2, col = "lightgrey")
  arrows(1:p, coef_s_li[ord], 1:p, coef_s_ui[ord], length = errorbar_width, angle = 90, code = 3, col = "darkgrey")
  points(coef_s[ord], pch = 19, col = bugcols, cex = marker.cex)
  
  yl <- c(-0.1,0.1)
  plot(coef_atb[ord], xlim = xl, ylim = yl, xaxt = "n", xlab = "", ylab = "Antibiotic use", bty = "n", type = "n")
  abline(0,0, lty = 2, col = "lightgrey")
  arrows(1:p, coef_atb_li[ord], 1:p, coef_atb_ui[ord], length = errorbar_width, angle = 90, code = 3, col = "darkgrey")
  points(coef_atb[ord], pch = 19, col = bugcols, cex = marker.cex)
  
  axis(1, at = 1:p, labels = buglabs[ord], las = 2)  
}
dev.off()


# Use visreg package to show the response curve of number of infection episodes 
# to consumption of specific antibiotic classes
# First line = 3GCR, second line = CR, columns = 3GC, Carba, antipseudomonal 3GC, TZP

svg(file = "visreg_pooled.svg", 8, 4)
{
  par(mfrow = c(2, 4))
  par(mar = c(4, 4, 1, 1))
  
  visreg(c3gR.mod2, "ddd_c3g_classic", scale=c("response"),xlab="CTX/CRO use (ddd/bed/y)",ylab="No. 3GCR episodes/ward/y",xlim = c(-6,6)*1.1, ylim=c(0,12), rug = F, xaxt = "n")
  xseq <- seq(-2,2,1)
  axis(1, at = xseq/log(2)*log(10), labels = 10^xseq)
  
  visreg(c3gR.mod2, "ddd_carba", scale=c("response"),xlab="IPM/MEM use (ddd/bed/y)",ylab="No. 3GCR episodes/ward/y",xlim = c(-6,6)*1.1,ylim=c(0,12), rug = F, xaxt = "n")
  xseq <- seq(-2,2,1)
  axis(1, at = xseq/log(2)*log(10), labels = 10^xseq)
  
  visreg(c3gR.mod2, "ddd_c3g_pyo", scale=c("response"),xlab="CTZ/FEP use (ddd/bed/y)",ylab="No. 3GCR episodes/ward/y",xlim = c(-6,6)*1.1, ylim=c(0,12), rug = F, xaxt = "n")
  xseq <- seq(-2,2,1)
  axis(1, at = xseq/log(2)*log(10), labels = 10^xseq)
  
  visreg(c3gR.mod2, "ddd_bsp", scale=c("response"),xlab="TZP use (ddd/bed/y)",ylab="No. 3GCR episodes/ward/y",xlim = c(-6,6)*1.1,ylim=c(0,12), rug = F, xaxt = "n")
  xseq <- seq(-2,2,1)
  axis(1, at = xseq/log(2)*log(10), labels = 10^xseq)
  
  visreg(carbaR.mod2, "ddd_c3g_classic", scale=c("response"),xlab="CTX/CRO use (ddd/bed/y)",ylab="No. CR episodes/ward/y",xlim = c(-6,6)*1.1, ylim=c(0,5), rug = F, xaxt = "n")
  xseq <- seq(-2,2,1)
  axis(1, at = xseq/log(2)*log(10), labels = 10^xseq)
  
  visreg(carbaR.mod2, "ddd_carba", scale=c("response"),xlab="IPM/MEM use (ddd/bed/y)",ylab="No. CR episodes/ward/y", xlim = c(-6,6)*1.1, ylim=c(0,5), rug = F, xaxt = "n")
  xseq <- seq(-2,2,1)
  axis(1, at = xseq/log(2)*log(10), labels = 10^xseq)
  
  visreg(carbaR.mod2, "ddd_c3g_pyo", scale=c("response"),xlab="CTZ/FEP use (ddd/bed/y)",ylab="No. CR episodes/ward/y",xlim = c(-6,6)*1.1, ylim=c(0,5), rug = F, xaxt = "n")
  xseq <- seq(-2,2,1)
  axis(1, at = xseq/log(2)*log(10), labels = 10^xseq)
  
  visreg(carbaR.mod2, "ddd_bsp", scale=c("response"),xlab="TZP use (ddd/bed/y)",ylab="No. CR episodes/ward/y",xlim = c(-6,6)*1.1,ylim=c(0,5), rug = F, xaxt = "n")
  xseq <- seq(-2,2,1)
  axis(1, at = xseq/log(2)*log(10), labels = 10^xseq)
}
dev.off()