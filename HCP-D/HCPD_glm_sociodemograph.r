# Author: Jingwei Li
# Date: 22/09/2023
# specific for HCP-D dataset because only in this dataset the income values are continuous

# Get command line arguments
args <- commandArgs(trailingOnly = TRUE)

# Get the input filename and output filename
inputFilename <- args[1]
outputDir <- args[2]

data <- read.csv(inputFilename)

# check how many columns are error columns
Nerr <- length(grep("err_class", colnames(data)))

# index education columns
educ_idx <- grep("educ_", colnames(data))
ethnicity_idx <- grep("ethnicity_", colnames(data))

for (n in 1:Nerr) {
    print(paste('GLM models for behavioral group', toString(n)))
    # create formula for full model
    fullModelStr <- paste('err_class', toString(n), ' ~ 1 + age + sex + income', sep = "")
    for (i in 1:length(educ_idx)) {
        fullModelStr <- paste(fullModelStr, '+', colnames(data)[educ_idx[i]])
    }
    for (i in 1:length(ethnicity_idx)) {
        fullModelStr <- paste(fullModelStr, '+', colnames(data)[ethnicity_idx[i]])
    }
    fullModelFormula <- as.formula(fullModelStr)

    # build full model
    fullModel <- glm(fullModelFormula, family = "gaussian", data = data)
    outFullModel = file.path(outputDir, paste('err', toString(n), '_sociodemograph_full_model.csv', sep = ""))
    write.csv(coef(summary(fullModel)), outFullModel)
    print(fullModel)

    # null model: only intercept
    nullModel <- glm(as.formula(paste('err_class', toString(n), ' ~ 1', sep = "")),
                 family = "gaussian", data = data)
    print(nullModel)
    full_pchisq <- pchisq(deviance(nullModel) - deviance(fullModel), 
                      df.residual(nullModel)-df.residual(fullModel), lower.tail=FALSE)
    p_full <- anova(fullModel, nullModel, test = "LRT")
    print(p_full)

    # create formula for model without age
    noAgeStr <- paste('err_class', toString(n), ' ~ 1 + sex + income', sep = "")
    for (i in 1:length(educ_idx)) {
        noAgeStr <- paste(noAgeStr, '+', colnames(data)[educ_idx[i]])
    }
    for (i in 1:length(ethnicity_idx)) {
        noAgeStr <- paste(noAgeStr, '+', colnames(data)[ethnicity_idx[i]])
    }
    noAgeFormula <- as.formula(noAgeStr)

    # build model without age
    modelNoAge <- glm(noAgeFormula, family = "gaussian", data = data)
    lr_test_age <- anova(fullModel, modelNoAge, test = "LRT")
    outModelNoAge = file.path(outputDir, paste('err', toString(n), '_sociodemograph_model_no_age.csv', sep = ""))
    write.csv(coef(summary(modelNoAge)), outModelNoAge)
    #print(modelNoAge)
    outImportanceAge = file.path(outputDir, paste('err', toString(n), '_sociodemograph_importance_age.csv', sep = ""))
    write(lr_test_age$"Pr(>Chi)"[2], file=outImportanceAge)
    #print(lr_test_age)
    noAge_pchisq <- pchisq(deviance(nullModel) - deviance(modelNoAge), 
                           df.residual(nullModel)-df.residual(modelNoAge), lower.tail=FALSE)
    p_noAge <- anova(modelNoAge, nullModel, test = "LRT")

    # create formula for model without sex
    noSexStr <- paste('err_class', toString(n), ' ~ 1 + age + income', sep = "")
    for (i in 1:length(educ_idx)) {
        noSexStr <- paste(noSexStr, '+', colnames(data)[educ_idx[i]])
    }
    for (i in 1:length(ethnicity_idx)) {
        noSexStr <- paste(noSexStr, '+', colnames(data)[ethnicity_idx[i]])
    }
    noSexFormula <- as.formula(noSexStr)

    # build model without sex
    modelNoSex <- glm(noSexFormula, family = "gaussian", data = data)
    lr_test_sex <- anova(fullModel, modelNoSex, test = "LRT")
    outModelNoSex = file.path(outputDir, paste('err', toString(n), '_sociodemograph_model_no_sex.csv', sep = ""))
    write.csv(coef(summary(modelNoSex)), outModelNoSex)
    #print(modelNoSex)
    outImportanceSex = file.path(outputDir, paste('err', toString(n), '_sociodemograph_importance_sex.csv', sep = ""))
    write(lr_test_sex$"Pr(>Chi)"[2], file=outImportanceSex)
    #print(lr_test_sex)
    noSex_pchisq <- pchisq(deviance(nullModel) - deviance(modelNoSex), 
                           df.residual(nullModel)-df.residual(modelNoSex), lower.tail=FALSE)
    p_noSex <- anova(modelNoSex, nullModel, test = "LRT")

    # create formula for model without education
    noEducStr <- paste('err_class', toString(n), ' ~ 1 + age + sex + income', sep = "")
    for (i in 1:length(ethnicity_idx)) {
        noEducStr <- paste(noEducStr, '+', colnames(data)[ethnicity_idx[i]])
    }
    noEducFormula <- as.formula(noEducStr)

    # build model without education
    modelNoEduc <- glm(noEducFormula, family = "gaussian", data = data)
    lr_test_educ <- anova(fullModel, modelNoEduc, test = "LRT")
    outModelNoEduc = file.path(outputDir, paste('err', toString(n), '_sociodemograph_model_no_educ.csv', sep = ""))
    write.csv(coef(summary(modelNoEduc)), outModelNoEduc)
    #print(modelNoEduc)
    outImportanceEduc = file.path(outputDir, paste('err', toString(n), '_sociodemograph_importance_educ.csv', sep = ""))
    write(lr_test_educ$"Pr(>Chi)"[2], file=outImportanceEduc)
    #print(lr_test_educ)
    noEduc_pchisq <- pchisq(deviance(nullModel) - deviance(modelNoEduc), 
                            df.residual(nullModel)-df.residual(modelNoEduc), lower.tail=FALSE)
    p_noEduc <- anova(modelNoEduc, nullModel, test = "LRT")

    # create formula for model without family income
    noIncomeStr <- paste('err_class', toString(n), ' ~ 1 + age + sex', sep = "")
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
    outModelNoIncome = file.path(outputDir, paste('err', toString(n), '_sociodemograph_model_no_income.csv', sep = ""))
    write.csv(coef(summary(modelNoIncome)), outModelNoIncome)
    #print(modelNoIncome)
    outImportanceIncome = file.path(outputDir, paste('err', toString(n), '_sociodemograph_importance_income.csv', sep = ""))
    write(lr_test_income$"Pr(>Chi)"[2], file=outImportanceIncome)
    #print(lr_test_income)
    noIncome_pchisq <- pchisq(deviance(nullModel) - deviance(modelNoIncome), 
                              df.residual(nullModel)-df.residual(modelNoIncome), lower.tail=FALSE)
    p_noIncome <- anova(modelNoIncome, nullModel, test = "LRT")

    # create formula for model without ethnicity
    noEthnStr <- paste('err_class', toString(n), ' ~ 1 + age + sex + income', sep = "")
    for (i in 1:length(educ_idx)) {
        noEthnStr <- paste(noEthnStr, '+', colnames(data)[educ_idx[i]])
    }
    noEthnFormula <- as.formula(noEthnStr)

    # build model without ethnicity
    modelNoEthn <- glm(noEthnFormula, family = "gaussian", data = data)
    lr_test_ethn <- anova(fullModel, modelNoEthn, test = "LRT")
    outModelNoEthn = file.path(outputDir, paste('err', toString(n), '_sociodemograph_model_no_ethnicity.csv', sep = ""))
    write.csv(coef(summary(modelNoEthn)), outModelNoEthn)
    #print(modelNoEthn)
    outImportanceEthn = file.path(outputDir, paste('err', toString(n), '_sociodemograph_importance_ethnicity.csv', sep = ""))
    write(lr_test_ethn$"Pr(>Chi)"[2], file=outImportanceEthn)
    #print(lr_test_ethn)
    noEthn_pchisq <- pchisq(deviance(nullModel) - deviance(modelNoEthn), 
                            df.residual(nullModel)-df.residual(modelNoEthn), lower.tail=FALSE)
    p_noEthn <- anova(modelNoEthn, nullModel, test = "LRT")

    # collect goodness of fit of each model
    goodfit = data.frame(model = c('Full model', 'Model without age', 'Model without education',
                         'Model without ethnicity', 'Model without income', 'Model without sex'), 
                         pseudo_r_squared = c(with(summary(fullModel), 1 - deviance/null.deviance),
                         with(summary(modelNoAge), 1 - deviance/null.deviance), 
                         with(summary(modelNoEduc), 1 - deviance/null.deviance),
                         with(summary(modelNoEthn), 1 - deviance/null.deviance),
                         with(summary(modelNoIncome), 1 - deviance/null.deviance),
                         with(summary(modelNoSex), 1 - deviance/null.deviance)), 
                         AIC = c(AIC(fullModel), AIC(modelNoAge), AIC(modelNoEduc), AIC(modelNoEthn), 
                         AIC(modelNoIncome), AIC(modelNoSex)),
                         p_against_null = c(p_full$"Pr(>Chi)"[2], p_noAge$"Pr(>Chi)"[2], p_noEduc$"Pr(>Chi)"[2], p_noEthn$"Pr(>Chi)"[2], 
                         p_noIncome$"Pr(>Chi)"[2], p_noSex$"Pr(>Chi)"[2]))
    outGoodFit = file.path(outputDir, paste('err', toString(n), '_sociodemograph_goodness.csv', sep = ""))
    write.csv(goodfit, outGoodFit, row.names = FALSE)
}