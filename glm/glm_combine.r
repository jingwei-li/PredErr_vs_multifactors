# Author: Jingwei Li
# Date: 28/11/2023

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

# index education, income, ethnicity columns
educ_idx <- grep("educ_", colnames(data))
income_idx <- grep("income_", colnames(data))
ethnicity_idx <- grep("ethnicity_", colnames(data))

for (n in 1:Nerr) {
    print(paste('GLM models for behavioral group', toString(n)))

    # create formula for full model
    fullModelStr <- paste('err_class', toString(n), ' ~ 1 + euler + ICV + FD + age + sex', sep = "")
    for (i in 1:length(educ_idx)) {
        fullModelStr <- paste(fullModelStr, '+', colnames(data)[educ_idx[i]])
    }
    for (i in 1:length(income_idx)) {
        fullModelStr <- paste(fullModelStr, '+', colnames(data)[income_idx[i]])
    }
    for (i in 1:length(ethnicity_idx)) {
        fullModelStr <- paste(fullModelStr, '+', colnames(data)[ethnicity_idx[i]])
    }
    fullModelFormula <- as.formula(fullModelStr)

    # build full model
    fullModel <- glm(fullModelFormula, family = "gaussian", data = data)
    outFullModel = file.path(outputDir, paste('err', toString(n), '_combine_full_model.csv', sep = ""))
    write.csv(coef(summary(fullModel)), outFullModel)
    print(fullModel)

    # null model: only intercept
    nullModel <- glm(as.formula(paste('err_class', toString(n), ' ~ 1', sep = "")),
                 family = "gaussian", data = data)
    full_pchisq <- pchisq(deviance(nullModel) - deviance(fullModel), 
                      df.residual(nullModel)-df.residual(fullModel), lower.tail=FALSE)
    p_full <- anova(fullModel, nullModel, test = "LRT")
    print(p_full)

    # create the formula for model without Euler characteristic
    noEulerStr <- paste('err_class', toString(n), ' ~ 1 + ICV + FD + age + sex', sep = "")
    for (i in 1:length(educ_idx)) {
        noEulerStr <- paste(noEulerStr, '+', colnames(data)[educ_idx[i]])
    }
    for (i in 1:length(income_idx)) {
        noEulerStr <- paste(noEulerStr, '+', colnames(data)[income_idx[i]])
    }
    for (i in 1:length(ethnicity_idx)) {
        noEulerStr <- paste(noEulerStr, '+', colnames(data)[ethnicity_idx[i]])
    }
    noEulerFormula <- as.formula(noEulerStr)

    # build model without Euler characteristic
    modelNoEuler <- glm(noEulerFormula, family = "gaussian", data = data)
    lr_test_euler <- anova(fullModel, modelNoEuler, test = "LRT")
    outModelNoEuler = file.path(outputDir, paste('err', toString(n), '_combine_model_no_Euler.csv', sep = ""))
    write.csv(coef(summary(modelNoEuler)), outModelNoEuler)
    outImportanceEuler = file.path(outputDir, paste('err', toString(n), '_combine_importance_Euler.csv', sep = ""))
    write(lr_test_euler$"Pr(>Chi)"[2], file=outImportanceEuler)
    noEuler_pchisq <- pchisq(deviance(nullModel) - deviance(modelNoEuler), 
                           df.residual(nullModel)-df.residual(modelNoEuler), lower.tail=FALSE)
    p_noEuler <- anova(modelNoEuler, nullModel, test = "LRT")

    # create the formula for model without ICV
    noICVStr <- paste('err_class', toString(n), ' ~ 1 + euler + FD + age + sex', sep = "")
    for (i in 1:length(educ_idx)) {
        noICVStr <- paste(noICVStr, '+', colnames(data)[educ_idx[i]])
    }
    for (i in 1:length(income_idx)) {
        noICVStr <- paste(noICVStr, '+', colnames(data)[income_idx[i]])
    }
    for (i in 1:length(ethnicity_idx)) {
        noICVStr <- paste(noICVStr, '+', colnames(data)[ethnicity_idx[i]])
    }
    noICVFormula <- as.formula(noICVStr)

    # build model without ICV
    modelNoICV <- glm(noICVFormula, family = "gaussian", data = data)
    lr_test_ICV <- anova(fullModel, modelNoICV, test = "LRT")
    outModelNoICV = file.path(outputDir, paste('err', toString(n), '_combine_model_no_ICV.csv', sep = ""))
    write.csv(coef(summary(modelNoICV)), outModelNoICV)
    outImportanceICV = file.path(outputDir, paste('err', toString(n), '_combine_importance_ICV.csv', sep = ""))
    write(lr_test_ICV$"Pr(>Chi)"[2], file=outImportanceICV)
    noICV_pchisq <- pchisq(deviance(nullModel) - deviance(modelNoICV), 
                           df.residual(nullModel)-df.residual(modelNoICV), lower.tail=FALSE)
    p_noICV <- anova(modelNoICV, nullModel, test = "LRT")

    # create the formula for model without FD
    noFDStr <- paste('err_class', toString(n), ' ~ 1 + euler + ICV + age + sex', sep = "")
    for (i in 1:length(educ_idx)) {
        noFDStr <- paste(noFDStr, '+', colnames(data)[educ_idx[i]])
    }
    for (i in 1:length(income_idx)) {
        noFDStr <- paste(noFDStr, '+', colnames(data)[income_idx[i]])
    }
    for (i in 1:length(ethnicity_idx)) {
        noFDStr <- paste(noFDStr, '+', colnames(data)[ethnicity_idx[i]])
    }
    noFDFormula <- as.formula(noFDStr)

    # build model without FD
    modelNoFD <- glm(noFDFormula, family = "gaussian", data = data)
    lr_test_FD <- anova(fullModel, modelNoFD, test = "LRT")
    outModelNoFD = file.path(outputDir, paste('err', toString(n), '_combine_model_no_FD.csv', sep = ""))
    write.csv(coef(summary(modelNoFD)), outModelNoFD)
    outImportanceFD = file.path(outputDir, paste('err', toString(n), '_combine_importance_FD.csv', sep = ""))
    write(lr_test_FD$"Pr(>Chi)"[2], file=outImportanceFD)
    noFD_pchisq <- pchisq(deviance(nullModel) - deviance(modelNoFD), 
                           df.residual(nullModel)-df.residual(modelNoFD), lower.tail=FALSE)
    p_noFD <- anova(modelNoFD, nullModel, test = "LRT")

    # create formula for model without age
    noAgeStr <- paste('err_class', toString(n), ' ~ 1 + euler + ICV + FD + sex', sep = "")
    for (i in 1:length(educ_idx)) {
        noAgeStr <- paste(noAgeStr, '+', colnames(data)[educ_idx[i]])
    }
    for (i in 1:length(income_idx)) {
        noAgeStr <- paste(noAgeStr, '+', colnames(data)[income_idx[i]])
    }
    for (i in 1:length(ethnicity_idx)) {
        noAgeStr <- paste(noAgeStr, '+', colnames(data)[ethnicity_idx[i]])
    }
    noAgeFormula <- as.formula(noAgeStr)

    # build model without age
    modelNoAge <- glm(noAgeFormula, family = "gaussian", data = data)
    lr_test_age <- anova(fullModel, modelNoAge, test = "LRT")
    outModelNoAge = file.path(outputDir, paste('err', toString(n), '_combine_model_no_age.csv', sep = ""))
    write.csv(coef(summary(modelNoAge)), outModelNoAge)
    outImportanceAge = file.path(outputDir, paste('err', toString(n), '_combine_importance_age.csv', sep = ""))
    write(lr_test_age$"Pr(>Chi)"[2], file=outImportanceAge)
    noAge_pchisq <- pchisq(deviance(nullModel) - deviance(modelNoAge), 
                           df.residual(nullModel)-df.residual(modelNoAge), lower.tail=FALSE)
    p_noAge <- anova(modelNoAge, nullModel, test = "LRT")

    # create formula for model without sex
    noSexStr <- paste('err_class', toString(n), ' ~ 1 + euler + ICV + FD + age', sep = "")
    for (i in 1:length(educ_idx)) {
        noSexStr <- paste(noSexStr, '+', colnames(data)[educ_idx[i]])
    }
    for (i in 1:length(income_idx)) {
        noSexStr <- paste(noSexStr, '+', colnames(data)[income_idx[i]])
    }
    for (i in 1:length(ethnicity_idx)) {
        noSexStr <- paste(noSexStr, '+', colnames(data)[ethnicity_idx[i]])
    }
    noSexFormula <- as.formula(noSexStr)

    # build model without sex
    modelNoSex <- glm(noSexFormula, family = "gaussian", data = data)
    lr_test_sex <- anova(fullModel, modelNoSex, test = "LRT")
    outModelNoSex = file.path(outputDir, paste('err', toString(n), '_combine_model_no_sex.csv', sep = ""))
    write.csv(coef(summary(modelNoSex)), outModelNoSex)
    outImportanceSex = file.path(outputDir, paste('err', toString(n), '_combine_importance_sex.csv', sep = ""))
    write(lr_test_sex$"Pr(>Chi)"[2], file=outImportanceSex)
    noSex_pchisq <- pchisq(deviance(nullModel) - deviance(modelNoSex), 
                           df.residual(nullModel)-df.residual(modelNoSex), lower.tail=FALSE)
    p_noSex <- anova(modelNoSex, nullModel, test = "LRT")

    # create formula for model without education
    noEducStr <- paste('err_class', toString(n), ' ~ 1 + euler + ICV + FD + age + sex', sep = "")
    for (i in 1:length(income_idx)) {
        noEducStr <- paste(noEducStr, '+', colnames(data)[income_idx[i]])
    }
    for (i in 1:length(ethnicity_idx)) {
        noEducStr <- paste(noEducStr, '+', colnames(data)[ethnicity_idx[i]])
    }
    noEducFormula <- as.formula(noEducStr)

    # build model without education
    modelNoEduc <- glm(noEducFormula, family = "gaussian", data = data)
    lr_test_educ <- anova(fullModel, modelNoEduc, test = "LRT")
    outModelNoEduc = file.path(outputDir, paste('err', toString(n), '_combine_model_no_educ.csv', sep = ""))
    write.csv(coef(summary(modelNoEduc)), outModelNoEduc)
    outImportanceEduc = file.path(outputDir, paste('err', toString(n), '_combine_importance_educ.csv', sep = ""))
    write(lr_test_educ$"Pr(>Chi)"[2], file=outImportanceEduc)
    noEduc_pchisq <- pchisq(deviance(nullModel) - deviance(modelNoEduc), 
                            df.residual(nullModel)-df.residual(modelNoEduc), lower.tail=FALSE)
    p_noEduc <- anova(modelNoEduc, nullModel, test = "LRT")

    # create formula for model without family income
    noIncomeStr <- paste('err_class', toString(n), ' ~ 1 + euler + ICV + FD + age + sex', sep = "")
    for (i in 1:length(educ_idx)) {
        noIncomeStr <- paste(noIncomeStr, '+', colnames(data)[educ_idx[i]])
    }
    for (i in 1:length(ethnicity_idx)) {
        noIncomeStr <- paste(noIncomeStr, '+', colnames(data)[ethnicity_idx[i]])
    }
    noIncomeFormula <- as.formula(noIncomeStr)

    # build model without income
    modelNoIncome <- glm(noIncomeFormula, family = "gaussian", data = data)
    lr_test_income <- anova(fullModel, modelNoIncome, test = "LRT")
    outModelNoIncome = file.path(outputDir, paste('err', toString(n), '_combine_model_no_income.csv', sep = ""))
    write.csv(coef(summary(modelNoIncome)), outModelNoIncome)
    outImportanceIncome = file.path(outputDir, paste('err', toString(n), '_combine_importance_income.csv', sep = ""))
    write(lr_test_income$"Pr(>Chi)"[2], file=outImportanceIncome)
    noIncome_pchisq <- pchisq(deviance(nullModel) - deviance(modelNoIncome), 
                              df.residual(nullModel)-df.residual(modelNoIncome), lower.tail=FALSE)
    p_noIncome <- anova(modelNoIncome, nullModel, test = "LRT")

    # create formula for model without ethnicity
    noEthnStr <- paste('err_class', toString(n), ' ~ 1 + euler + ICV + FD + age + sex', sep = "")
    for (i in 1:length(educ_idx)) {
        noEthnStr <- paste(noEthnStr, '+', colnames(data)[educ_idx[i]])
    }
    for (i in 1:length(income_idx)) {
        noEthnStr <- paste(noEthnStr, '+', colnames(data)[income_idx[i]])
    }
    noEthnFormula <- as.formula(noEthnStr)

    # build model without ethnicity
    modelNoEthn <- glm(noEthnFormula, family = "gaussian", data = data)
    lr_test_ethn <- anova(fullModel, modelNoEthn, test = "LRT")
    outModelNoEthn = file.path(outputDir, paste('err', toString(n), '_combine_model_no_ethnicity.csv', sep = ""))
    write.csv(coef(summary(modelNoEthn)), outModelNoEthn)
    outImportanceEthn = file.path(outputDir, paste('err', toString(n), '_combine_importance_ethnicity.csv', sep = ""))
    write(lr_test_ethn$"Pr(>Chi)"[2], file=outImportanceEthn)
    noEthn_pchisq <- pchisq(deviance(nullModel) - deviance(modelNoEthn), 
                            df.residual(nullModel)-df.residual(modelNoEthn), lower.tail=FALSE)
    p_noEthn <- anova(modelNoEthn, nullModel, test = "LRT")

    # collect goodness of fit of each model
    goodfit = data.frame(model = c('Full model', 'Model without Euler characteristic', 'Model without ICV',
                         'Model without FD', 'Model without age', 'Model without education',
                         'Model without ethnicity', 'Model without income', 'Model without sex'), 
                         pseudo_r_squared = c(with(summary(fullModel), 1 - deviance/null.deviance),
                         with(summary(modelNoEuler), 1 - deviance/null.deviance), 
                         with(summary(modelNoICV), 1 - deviance/null.deviance),
                         with(summary(modelNoFD), 1 - deviance/null.deviance), 
                         with(summary(modelNoAge), 1 - deviance/null.deviance), 
                         with(summary(modelNoEduc), 1 - deviance/null.deviance),
                         with(summary(modelNoEthn), 1 - deviance/null.deviance),
                         with(summary(modelNoIncome), 1 - deviance/null.deviance),
                         with(summary(modelNoSex), 1 - deviance/null.deviance)), 
                         AIC = c(AIC(fullModel), AIC(modelNoEuler), AIC(modelNoICV), AIC(modelNoFD), 
                         AIC(modelNoAge), AIC(modelNoEduc), AIC(modelNoEthn), AIC(modelNoIncome), 
                         AIC(modelNoSex)),
                         p_against_null = c(p_full$"Pr(>Chi)"[2], p_noEuler$"Pr(>Chi)"[2], 
                         p_noICV$"Pr(>Chi)"[2], p_noFD$"Pr(>Chi)"[2], p_noAge$"Pr(>Chi)"[2], 
                         p_noEduc$"Pr(>Chi)"[2], p_noEthn$"Pr(>Chi)"[2], 
                         p_noIncome$"Pr(>Chi)"[2], p_noSex$"Pr(>Chi)"[2]))
    outGoodFit = file.path(outputDir, paste('err', toString(n), '_combine_goodness.csv', sep = ""))
    write.csv(goodfit, outGoodFit, row.names = FALSE)
}