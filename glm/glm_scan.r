# Author: Jingwei Li
# Date: 22/09/2023

# Get command line arguments
args <- commandArgs(trailingOnly = TRUE)

# Get the input filename and output filename
inputFilename <- args[1]
outputDir <- args[2]

data <- read.csv(inputFilename)

# check how many columns are error columns
Nerr <- length(grep("err_class", colnames(data)))

# normalization
data$euler = scale(data$euler)
data$ICV = scale(data$ICV)
data$FD = scale(data$FD)

for (n in 1:Nerr) {
    print(paste('GLM models for behavioral group', toString(n)))

    # full model
    fullModel <- glm(as.formula(paste('err_class', toString(n), ' ~ 1 + euler + ICV + FD', sep = "")),
                 family = "gaussian", data = data)
    outFullModel = file.path(outputDir, paste('err', toString(n), '_scan_full_model.csv', sep = ""))
    write.csv(coef(summary(fullModel)), outFullModel)
    print(fullModel$coefficients)

    # null model: only intercept
    nullModel <- glm(as.formula(paste('err_class', toString(n), ' ~ 1', sep = "")),
                 family = "gaussian", data = data)
    full_pchisq <- pchisq(deviance(nullModel) - deviance(fullModel), 
                      df.residual(nullModel)-df.residual(fullModel), lower.tail=FALSE)
    p_full <- anova(fullModel, nullModel, test = "LRT")
    print(p_full)

    # model without Euler characteristic
    modelNoEuler <- glm(as.formula(paste('err_class', toString(n), ' ~ 1 + ICV + FD', sep = "")),
                    family = "gaussian", data = data)
    lr_test_euler <- anova(fullModel, modelNoEuler, test = "LRT")
    outModelNoEuler = file.path(outputDir, paste('err', toString(n), '_scan_model_no_Euler.csv', sep = ""))
    write.csv(coef(summary(modelNoEuler)), outModelNoEuler)
    #print(modelNoEuler$coefficients)
    outImportanceEuler = file.path(outputDir, paste('err', toString(n), '_scan_importance_Euler.csv', sep = ""))
    write(lr_test_euler$"Pr(>Chi)"[2], file=outImportanceEuler)
    #print(lr_test_euler$"Pr(>Chi)"[2])
    noEuler_pchisq <- pchisq(deviance(nullModel) - deviance(modelNoEuler), 
                             df.residual(nullModel)-df.residual(modelNoEuler), lower.tail=FALSE)
    p_noEuler <- anova(modelNoEuler, nullModel, test = "LRT")

    # model without ICV
    modelNoICV <- glm(as.formula(paste('err_class', toString(n), ' ~ 1 + euler + FD', sep = "")),
                  family = "gaussian", data = data)
    lr_test_ICV <- anova(fullModel, modelNoICV, test = "LRT")
    outModelNoICV = file.path(outputDir, paste('err', toString(n), '_scan_model_no_ICV.csv', sep = ""))
    write.csv(coef(summary(modelNoICV)), outModelNoICV)
    #print(modelNoICV$coefficients)
    outImportanceICV = file.path(outputDir, paste('err', toString(n), '_scan_importance_ICV.csv', sep = ""))
    write(lr_test_ICV$"Pr(>Chi)"[2], file=outImportanceICV)
    #print(lr_test_ICV$"Pr(>Chi)"[2])
    noICV_pchisq <- pchisq(deviance(nullModel) - deviance(modelNoICV), 
                           df.residual(nullModel)-df.residual(modelNoICV), lower.tail=FALSE)
    p_noICV <- anova(modelNoICV, nullModel, test = "LRT")

    # model without FD
    modelNoFD <- glm(as.formula(paste('err_class', toString(n), ' ~ 1 + euler + ICV', sep = "")),
                 family = "gaussian", data = data)
    lr_test_FD <- anova(fullModel, modelNoFD, test = "LRT")
    outModelNoFD = file.path(outputDir, paste('err', toString(n), '_scan_model_no_FD.csv', sep = ""))
    write.csv(coef(summary(modelNoFD)), outModelNoFD)
    #print(summary(modelNoFD))
    outImportanceFD = file.path(outputDir, paste('err', toString(n), '_scan_importance_FD.csv', sep = ""))
    write(lr_test_FD$"Pr(>Chi)"[2], file=outImportanceFD)
    #print(lr_test_FD$"Pr(>Chi)"[2])
    noFD_pchisq <- pchisq(deviance(nullModel) - deviance(modelNoFD), 
                          df.residual(nullModel)-df.residual(modelNoFD), lower.tail=FALSE)
    p_noFD <- anova(modelNoFD, nullModel, test = "LRT")

    # collect goodness of fit of each model
    goodfit = data.frame(model = c('Full model', 'Model without Euler characteristic', 'Model without ICV',
                         'Model without FD'), 
                         pseudo_r_squared = c(with(summary(fullModel), 1 - deviance/null.deviance),
                         with(summary(modelNoEuler), 1 - deviance/null.deviance), 
                         with(summary(modelNoICV), 1 - deviance/null.deviance),
                         with(summary(modelNoFD), 1 - deviance/null.deviance)), 
                         AIC = c(AIC(fullModel), AIC(modelNoEuler), AIC(modelNoICV), AIC(modelNoFD)),
                         p_against_null = c(p_full$"Pr(>Chi)"[2], p_noEuler$"Pr(>Chi)"[2], p_noICV$"Pr(>Chi)"[2], p_noFD$"Pr(>Chi)"[2]))
    outGoodFit = file.path(outputDir, paste('err', toString(n), '_scan_goodness.csv', sep = ""))
    write.csv(goodfit, outGoodFit, row.names = FALSE)
}
