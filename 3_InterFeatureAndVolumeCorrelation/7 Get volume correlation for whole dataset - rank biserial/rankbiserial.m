function [dCoefficient, dPValue, vd95PercentConfidenceInterval] = rankbiserial(vdFeature, vbBinaryLabel)
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
% This is okay to use if dataset size is >= 20
dTStatistic = dCoefficient * sqrt((dn - 2) / (1 - dCoefficient^2));

% Calculate the two-tailed p-value using the t-distribution
dPValue = 2 * (1 - tcdf(abs(dTStatistic), dn - 2));

% Calculate the confidence interval
dAlpha = 0.05;
dCriticalValue = tinv(1 - dAlpha/2, dn-2);
dStandrdError = 1 / sqrt(dn - 3);
vd95PercentConfidenceInterval = ...
    [dCoefficient - dCriticalValue * dStandrdError,...
    dCoefficient + dCriticalValue * dStandrdError];
end