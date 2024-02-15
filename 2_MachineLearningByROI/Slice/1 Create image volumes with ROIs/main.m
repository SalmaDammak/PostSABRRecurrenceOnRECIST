load(Experiment.GetDataPath('DatasetInfo'),'tVUMC')

% Get resolution to interpolate to
vdModeResolution = mode(tVUMC.m2dResolutions);

% Preassign arrays
voOrigImageVolumes = MHDImageVolume.empty(1,0);
voImageVolumes = MHDImageVolume.empty(1,0);

for dPatientIndex = 1:height(tVUMC)
    disp(tVUMC.vsUniqueNames(dPatientIndex))

    % Create ROI object
    sROIPath = tVUMC.vsSlicePath(dPatientIndex);
    oROI = MHDLabelMapRegionsOfInterest(sROIPath);

    % Create the image volume for the patient
    sImagePath = tVUMC.vsImagePaths(dPatientIndex);
    oOrigImageVolume = MHDImageVolume(sImagePath, oROI);
    voOrigImageVolumes(dPatientIndex) = oOrigImageVolume;

    % Change resolution to prevent interpolation out of plane, since this
    % might remove the RECIST slice and 
    vdAdjustedModeResolution = vdModeResolution;
    vdAdjustedModeResolution(:,3) = tVUMC.m2dResolutions(dPatientIndex, 3);

    % Interpolate to mode resolution and save as a separte variable
    chImageInterpolationMethod = 'linear';
    chImageExtrapolationValue = 0;
    chROIInterpolationMethod = 'interpolate3D';
    oImageVolume = copy(oOrigImageVolume);

    oImageVolume.LoadVolumeData();
    oImageVolume.InterpolateToNewVoxelResolution(...
        vdAdjustedModeResolution, chImageInterpolationMethod, chImageExtrapolationValue, chROIInterpolationMethod);      
    chOriginalDataType = class(oImageVolume.GetImageData());
    oImageVolume.CastImageDataToType(chOriginalDataType);
    oImageVolume.ForceApplyAllTransforms();    

    voImageVolumes(dPatientIndex)  = oImageVolume;
end

voImageVolumes = voImageVolumes';

tVUMC = addvars(tVUMC, voImageVolumes);
save([Experiment.GetResultsDirectory(),'\ImageVolumes.mat'],"voOrigImageVolumes","voImageVolumes","tVUMC");