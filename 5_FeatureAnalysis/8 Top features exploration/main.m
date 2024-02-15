% Get the number of features
load(Experiment.GetDataPath('Features'),'oAllFeatures')
load(Experiment.GetDataPath('ResultsDirectory'),'vsSortedImportantFeatureIds')

voFeatureVaueIVHs = oAllFeatures.GetAllImageVolumeHandlersAndExtractionIndicesForFeatureSource("Follow-up CTs");
vdLabels = oAllFeatures.GetLabels();  

for iFeatureIdx = 1:length(vsSortedImportantFeatureIds)
    sFeatureId = vsSortedImportantFeatureIds(iFeatureIdx);    
    dColumnIdx = find(oAllFeatures.GetFeatureNames == sFeatureId);

    oFeature = oAllFeatures(:,dColumnIdx);
    vdFeatures = oFeature.GetFeatures();

    [vdSortedFeatures, vdSortingIdx] = sort(vdFeatures);
    vdSortedLabels = vdLabels(vdSortingIdx);
    voSortedIVHs = voFeatureVaueIVHs(vdSortingIdx);

    % Make figures for the ROIs and save them
    sFeatureName = Feature.GetDisplayNamesFromFeatureNames(sFeatureId);
    MakeAndSaveCollages(voSortedIVHs, char(sFeatureName), vdSortedLabels, string(num2str(vdSortedFeatures,'%2.2f')))
end


function MakeAndSaveCollages(voImageVolumeHandlers, chIVHName, vbOutcomes, vsFeatureValues)
vdThreshold = [-600-(1500/2), -600+(1500/2)];

voImageVolumeHandlers.CreateCollageOfRepresentativeFieldsOfView(...
    voImageVolumeHandlers,[6,12],...
    'SetImageDataDisplayThreshold', vdThreshold,...
    'TileDimensions', [120 120],...
    'TilesToHighlight',vbOutcomes,...
    'HighlightColour', [255, 255, 0]/255,...
    'RegionOfInterestColour',[207, 0, 140]/255,...
    'CustomLabels', vsFeatureValues);

savefig(gcf,[Experiment.GetResultsDirectory(),'\',chIVHName,'.fig'])
saveas(gcf,[Experiment.GetResultsDirectory(),'\',chIVHName,'.tif'])

close all
end