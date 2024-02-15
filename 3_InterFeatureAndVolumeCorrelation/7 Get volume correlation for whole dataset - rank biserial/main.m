load(Experiment.GetDataPath('features'))


vdFeatures = oAllFeatures.GetFeatures();
vdLabels = double(oAllFeatures.GetLabels());

% Get volume feature and calculate diameter for RECIST
dVolumeFeatureIndex = find(oAllFeatures.GetFeatureNames() == "F020001");
vdVolumeFeature = vdFeatures(:, dVolumeFeatureIndex);
vdDiameter = ((6*vdVolumeFeature)/pi).^(1/3);

% Get results
disp("**VOLUME**")
[dCorrelationCoefficient_vol, dPValue_vol] = TestIfNormalThenCorrelation(vdVolumeFeature, vdLabels);
disp("**DIAMETER**")
[dCorrelationCoefficient_diam, dPValue_diam] = TestIfNormalThenCorrelation(vdDiameter, vdLabels);

save([Experiment.GetResultsDirectory(),'\SizeCorrelations.mat'],...
    "dCorrelationCoefficient_vol", "dPValue_vol", "dCorrelationCoefficient_diam", "dPValue_diam")


function [dCorrelationCoefficient, dPValue] = TestIfNormalThenCorrelation(vdFeature, vdLabels)
[bNotNormal] = kstest(vdFeature);
if bNotNormal
    [dCorrelationCoefficient,dPValue] = rankbiserial(vdFeature, vdLabels == 1);
    disp("RANK-BISERIAL correlation coefficent is: " + num2str(dCorrelationCoefficient, "%.4f") + ...
        " (p=" + num2str(dPValue, "%.4f") + ")")
else
    error('I only have rank biserial implementedatm -\(``/)/-')
end



end
