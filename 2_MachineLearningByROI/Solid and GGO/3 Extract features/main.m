% load IVHs
load(Experiment.GetDataPath('VUMC'),"voImageVolumeHandlersSolid", "voImageVolumeHandlersGGO")

voFeatureNamesSolid = Feature.GetAllFeatures3D();

oSolidFeatures = Feature.ExtractFeaturesForImageVolumeHandlers(...
    voImageVolumeHandlersSolid,...
    voFeatureNamesSolid,...
    FeatureExtractionParameters('FeatureExtractionParameters.xlsx'),...
    "VUMC");
save([Experiment.GetResultsDirectory(), '\SolidFeatures.mat'], "oSolidFeatures")

% No shape and size
voFeatureNamesGGO = [...
                FirstOrderFeature.GetAllFeatures3D(),...
                GLCMFeature.GetAllFeatures3D(),...
                GLRLMFeature.GetAllFeatures3D()];

oGGOFeatures = Feature.ExtractFeaturesForImageVolumeHandlers(...
    voImageVolumeHandlersGGO,...
    voFeatureNamesGGO,...
    FeatureExtractionParameters('FeatureExtractionParameters.xlsx'),...
    "VUMC");
save([Experiment.GetResultsDirectory(), '\GGOFeatures.mat'], "oGGOFeatures")

oAllFeatures = [oSolidFeatures, oGGOFeatures];
save([Experiment.GetResultsDirectory(), '\AllFeatures.mat'], "oAllFeatures")