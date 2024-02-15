% load IVHs
load(Experiment.GetDataPath('VUMC'),"voImageVolumeHandlers")

% No shape and size
voFeatureNames = [...
                FirstOrderFeature.GetAllFeatures2D(),...
                GLCMFeature.GetAllFeatures2D(),...
                GLRLMFeature.GetAllFeatures2D()];

oAllFeatures = Feature.ExtractFeaturesForImageVolumeHandlers(...
    voImageVolumeHandlers,...
    voFeatureNames,...
    FeatureExtractionParameters('FeatureExtractionParameters.xlsx'),...
    "VUMC");
save([Experiment.GetResultsDirectory(), '\AllFeatures.mat'], "oAllFeatures")