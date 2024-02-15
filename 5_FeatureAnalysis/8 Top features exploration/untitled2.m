% Get the number of features
load(Experiment.GetDataPath('Features'),'oAllFeatures')
load(Experiment.GetDataPath('ResultsDirectory'),'vsSortedImportantFeatureIds')
% load(Experiment.GetDataPath('IVHs'), 'voImageVolumeHandlersSphere')

voFeatureVaueIVHs = oAllFeatures.GetAllImageVolumeHandlersAndExtractionIndicesForFeatureSource("Follow-up CTs");
vdLabels = oAllFeatures.GetLabels();  

for iFeatureIdx = 1%1:length(vsSortedImportantFeatureIds)
    sFeatureId = vsSortedImportantFeatureIds(iFeatureIdx);
    dColumnIdx = find(oAllFeatures.GetFeatureNames == sFeatureId);

    oFeature = oAllFeatures(:,dColumnIdx);
    % vsNames = oFeature.GetUserDefinedSampleStrings();
    % vdIDs = oFeature.GetGroupIds();
    vdFeatures = oFeature.GetFeatures();

    % [dMax, dMaxRow] = max(vdFeatures);
    % sMaxName = vsNames(dMaxRow);
    % dMaxID = vdIDs(dMaxRow);
    % 
    % [vdSortedFeatures, vdSortingIdx] = sort(vdFeatures);
    % dMidIdx = round(length(vdSortedFeatures)/2);
    % dMid = vdSortedFeatures(dMidIdx);
    % vdSortedIds = vdIDs(vdSortingIdx);
    % dMidID = vdSortedIds(dMidIdx);
    % vsSortedNames = vsNames(vdSortingIdx);
    % sMidName = vsSortedNames(dMidIdx);
    % 
    % [dMin, dMinRow] = min(vdFeatures);
    % sMinName = vsNames(dMinRow);
    % dMinID = vdIDs(dMinRow);

    [vdSortedFeatures, vdSortingIdx] = sort(vdFeatures);
    vdSortedLabels = vdLabels(vdSortingIdx);
    voSortedIVHs = voImageVolumeHandlersSphere(vdSortingIdx);

    % Make figures for the ROIs and save them
    MakeAndSaveCollages(voSortedIVHs, 'RECIST sphere', vdSortedLabels, string(num2str(vdSortedFeatures,'%2.2f')))

end



function MakeAndSaveCollages(voImageVolumeHandlers, chIVHName, vbOutcomes)
vdThreshold = [-600-(1500/2), -600+(1500/2)];

voImageVolumeHandlers.CreateCollageOfRepresentativeFieldsOfView(...
    voImageVolumeHandlers,[6,12],...
    'SetImageDataDisplayThreshold', vdThreshold,...
    'TileDimensions', [120 120],...
    'TilesToHighlight',vbOutcomes,...
    'CustomLabels', vsFeatureValues)

savefig(gcf,[Experiment.GetResultsDirectory(),'\',chIVHName,'.fig'])
saveas(gcf,[Experiment.GetResultsDirectory(),'\',chIVHName,'.tif'])

close all
end