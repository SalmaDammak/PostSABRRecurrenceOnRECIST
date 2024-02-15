% Get the number of features
load(Experiment.GetDataPath('Features'),'oAllFeatures')
dTotalNumFeatures = length(oAllFeatures.GetFeatureNames());

chBaseResultsDir = Experiment.GetDataPath('BaseResultsDirectory');
stIterations = dir([chBaseResultsDir, '\Iteration*']);

m2dNormalizedFeatureScores = zeros(length(stIterations),dTotalNumFeatures);
vdAllFeatureScores = nan(1, dTotalNumFeatures);

for dIterationIdx = 1:length(stIterations)

    % Load iteration results
    chIterationResultsPath = [chBaseResultsDir, '\', stIterations(dIterationIdx).name];
    load(chIterationResultsPath, "vdFeatureImportanceScores","vdCorrelationCoefficientToVolume", "vdPValuePerRadiomicFeatureForVolume")

    % Normalize between 0 and 1
    vdAllNormalizedFeatureScores = (vdFeatureImportanceScores - min(vdFeatureImportanceScores)) / (max(vdFeatureImportanceScores) - min(vdFeatureImportanceScores));
   
    % Set volume-correlated features to 0
    vbHighlyVolumeCorrelatedFeatures = ...
        and((abs(vdCorrelationCoefficientToVolume) > 0.5),...
        (vdPValuePerRadiomicFeatureForVolume < 0.05));

    vdAllFeatureScores(~vbHighlyVolumeCorrelatedFeatures) = vdAllNormalizedFeatureScores;
    vdAllFeatureScores(vbHighlyVolumeCorrelatedFeatures) = 0;
        
    if length(oAllFeatures.GetFeatureNames()) ~= length(vdAllFeatureScores)
        error("Feature length mismatch")
    end

    % Save in matrix
    m2dNormalizedFeatureScores(dIterationIdx, :) = vdAllFeatureScores;
end

% Average across iterations
vdFeatureScoresAcrossIterations = mean(m2dNormalizedFeatureScores, 1);

% Normalize between 0 and 1
vdNormalizedFeatureScoresAcrossIterations = (vdFeatureScoresAcrossIterations - min(vdFeatureScoresAcrossIterations)) / (max(vdFeatureScoresAcrossIterations) - min(vdFeatureScoresAcrossIterations));
%histogram(vdNormalizedFeatureScoresAcrossIterations)

% Get highly important features and a ranking
vbHighImportantFeaturesIndices = vdNormalizedFeatureScoresAcrossIterations > 0.80;
vdHighlyImportantFeatureScores = vdNormalizedFeatureScoresAcrossIterations(vbHighImportantFeaturesIndices);
[vdSorted, vdSortingIndex] = sort(vdHighlyImportantFeatureScores, 'descend');

% Get feature names
vsFeatureIds = oAllFeatures.GetFeatureNames();
vsFeatureNames = Feature.GetDisplayNamesFromFeatureNames(vsFeatureIds);

% Get the names of the highly important features, with most important first
vsImportantFeatureNames = vsFeatureNames(vbHighImportantFeaturesIndices);
vsSortedImportantFeatureNames = vsImportantFeatureNames(vdSortingIndex);

vsImportantFeatureIds = vsFeatureIds(vbHighImportantFeaturesIndices);
vsSortedImportantFeatureIds = vsImportantFeatureIds(vdSortingIndex);

disp("Most important features (highest to lowest): ")
disp(vsSortedImportantFeatureNames')

save([Experiment.GetResultsDirectory(), '\TopFeatures.mat'], 'vsSortedImportantFeatureNames','vsSortedImportantFeatureIds')



