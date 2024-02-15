function [dCoefficient, dPValue, vd95PercentConfidenceInterval] = rankbiserial(vdFeature, vbBinaryLabel)
% Assumption #1: One of your two variables should be measured on a continuous scale. Examples of continuous variables include revision time (measured in hours), intelligence (measured using IQ score), exam performance (measured from 0 to 100), weight (measured in kg), and so forth. You can learn more about continuous variables in our article: Types of Variable.
% Assumption #2: Your other variable should be dichotomous. Examples of dichotomous variables include gender (two groups: male or female), employment status (two groups: employed or unemployed), smoker (two groups: yes or no), and so forth.
% Assumption #3: There should be no outliers for the continuous variable for each category of the dichotomous variable. You can test for outliers using boxplots.
% Assumption #4: Your continuous variable should be approximately normally distributed for each category of the dichotomous variable. You can test this using the Shapiro-Wilk test of normality.
% Assumption #5: Your continuous variable should have equal variances for each category of the dichotomous variable. You can test this using Levene's test of equality of variances.


% Calculate the means
dMean0 = mean(vdFeature(~vbBinaryLabel));
dMean1 = mean(vdFeature(vbBinaryLabel));


% Calculate the pooled standard deviation
dn0 = sum(~vbBinaryLabel);
dn1 = sum(vbBinaryLabel);
dStd0 = std(vdFeature(~vbBinaryLabel));
dStd1 = std(vdFeature(vbBinaryLabel));
dPooledStd = sqrt( (((dn0-1)*dStd0^2) +  ((dn1-1)*dStd1^2)) / (dn0+dn1-2) );


% Get the rank-biserial coefficient
dn = length(vdFeature);
dCoefficient  = ((dMean1 - dMean0)/dPooledStd) * sqrt((dn0*dn1)/(dn*(dn-1)));

% Calculate the t-statistic
dTStatistic = dCoefficient * sqrt((dn - 2) / (1 - dCoefficient^2));

% Calculate the two-tailed p-value using the t-distribution
dPValue = 2 * (1 - tcdf(abs(dTStatistic), dn - 2));

% Calculate the confidence interval
dAlpha = 0.05;
dCriticalValue = tinv(1 - dAlpha / 2, dn - 2);
dStandrdError = 1 / sqrt(dn - 3);
vd95PercentConfidenceInterval = [dCoefficient - dCriticalValue * dStandrdError,...
    dCoefficient + dCriticalValue * dStandrdError];
end