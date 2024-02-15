chName = 'Cylinder';
load(Experiment.GetDataPath('ImageVolumes'), "tVUMC");

% create vector of image volume handlers (one per tumour, here one patient == one tumour)
voImageVolumeHandlers = LabelledFeatureExtractionImageVolumeHandler.empty(1,0);

vdExperimentIds = nan(height(tVUMC), 1);

for dRow = 1:height(tVUMC)

    % Get the original unique patient name
    sUniquename = tVUMC.vsUniqueNames(dRow);
    disp(sUniquename)

    % Get patient outcome
    dOutcome = tVUMC.vbOutcomes(dRow);
    oImageVolume = tVUMC.voImageVolumes(dRow); 
    dPatientId = uint16(dRow + 1000);
    vdExperimentIds(dRow) = dPatientId;
    sImageSource = "Follow-up CTs";

    % Make handlers
    voImageVolumeHandlers(dRow) = LabelledFeatureExtractionImageVolumeHandler(...
        oImageVolume, sImageSource,...
        'GroupIds', dPatientId,...
        'SubGroupIds', uint8(1),....
        'SampleOrder', 1,...
        'UserDefinedSampleStrings', sUniquename,...
        'Labels', uint8(dOutcome),...
        'PositiveLabel', uint8(1),...% REC are positive
        'NegativeLabel', uint8(0)); % NOREC are negative
        

end

% Save the experiment Ids with the dataset info to refer to it later
tVUMC = addvars(tVUMC, vdExperimentIds, 'Before', 'vsUniqueNames');
save([Experiment.GetResultsDirectory(),'\DatasetInfo.mat'],"tVUMC");

% Save the handlers
save([Experiment.GetResultsDirectory(),'\IVHs.mat'], "voImageVolumeHandlers");

% Make figures for the ROIs and save them
MakeAndSaveCollages(voImageVolumeHandlers, chName, tVUMC.vbOutcomes)

function MakeAndSaveCollages(voImageVolumeHandlers, chIVHName, vbOutcomes)
vdThreshold = [-600-(1500/2), -600+(1500/2)];

voImageVolumeHandlers.CreateCollageOfRepresentativeFieldsOfView(...
    voImageVolumeHandlers,[6,12],...
    'SetImageDataDisplayThreshold', vdThreshold,...
    'TileDimensions', [120 120],...
    'TilesToHighlight',vbOutcomes)

savefig(gcf,[Experiment.GetResultsDirectory(),'\',chIVHName,'.fig'])
saveas(gcf,[Experiment.GetResultsDirectory(),'\',chIVHName,'.tif'])

close all
end