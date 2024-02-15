sBasePath = string(Experiment.GetDataPath('ImageDataBase'));
stOutcomeDir = dir(sBasePath + "\*REC*");

dNumTumours = 0;
vsUniqueNames = [];
vbOutcomes = [];
vsImagePaths = [];

vsGGOSolidPaths = [];
vsSpherePath = [];
vs20mmSpherePath = [];
vsRECISTSpherePath = [];
vsCapsulePath = [];
vsCylinderPath = [];
vsSlicePath = [];

m2dResolutions = [];

for dOutcomeIndex = 1:length(stOutcomeDir)
    sOutcome = string(stOutcomeDir(dOutcomeIndex).name);
    stPatientDirs = dir(sBasePath + "\" + sOutcome + "\P*");

    for dPatientIndex = 1:length(stPatientDirs)
        dNumTumours = dNumTumours + 1;

        % Get image path
        sPatientName = stPatientDirs(dPatientIndex).name;
        sPatientFolderPath = fullfile(sBasePath, sOutcome, sPatientName);
        stPatientFiles = dir(sPatientFolderPath + "\" + sPatientName + "*.mhd");
        sScanName = string(stPatientFiles.name);
        sImagePath = sPatientFolderPath + "\" + sScanName;

        % Get ROI path
        sROIBasePath = erase(sImagePath, "-IMAGE");
        sGGOSolidPath = strrep(sROIBasePath, "Images", "Segmentations - 4 - Solid and GGO Approx");
        sSpherePath = strrep(sROIBasePath, "Images", "Segmentations - 5 - Sphere");
        s20mmSpherePath = strrep(sROIBasePath, "Images", "Segmentations - 5 - 20mm sphere");
        sRECISTSpherePath = strrep(sROIBasePath, "Images", "Segmentations - 5 - RECIST-sized sphere");
        sCapsulePath = strrep(sROIBasePath, "Images", "Segmentations - 6 - Capsule");
        sCylinderPath = strrep(sROIBasePath, "Images", "Segmentations - 6 - Cyclinder"); 
        sSlicePath = strrep(sROIBasePath, "Images", "Segmentations - 7 - Slice");

        % Get patient outcome, REC is positive
        dOutcome = sOutcome == "REC";

        % Build the unique patient name
        sUniqueName = strrep(sScanName, "IMAGE.mhd", sOutcome);

        % Get the image resolution
        stImageInfo = mha_read_header(sImagePath);
        m2dResolution = stImageInfo.PixelDimensions;

        % Collect info for all
        vsUniqueNames = [vsUniqueNames; sUniqueName];
        vbOutcomes = [vbOutcomes; dOutcome];
        vsImagePaths = [vsImagePaths; sImagePath];

        vsGGOSolidPaths = [vsGGOSolidPaths; sGGOSolidPath];
        vsSpherePath = [vsSpherePath; sSpherePath];
        vs20mmSpherePath = [vs20mmSpherePath; s20mmSpherePath];
        vsRECISTSpherePath = [vsRECISTSpherePath; sRECISTSpherePath];
        vsCapsulePath = [vsCapsulePath; sCapsulePath];
        vsCylinderPath = [vsCylinderPath; sCylinderPath];
        vsSlicePath = [vsSlicePath; sSlicePath];

        m2dResolutions = [m2dResolutions; m2dResolution];
    end
end

disp("Num tumours: " + num2str(dNumTumours))
disp("Num patients: " + num2str(dNumTumours))
disp("Num REC: " + num2str(sum(vbOutcomes)))

tVUMC = table(vsUniqueNames, vbOutcomes, m2dResolutions, vsImagePaths,...
    vsGGOSolidPaths, vsSpherePath, vs20mmSpherePath, vsRECISTSpherePath, vsCapsulePath, vsCylinderPath, vsSlicePath);

save([Experiment.GetResultsDirectory(),'\DatasetInfo.mat'], "dNumTumours","tVUMC");
writetable(tVUMC, [Experiment.GetResultsDirectory(),'\DatasetInfo.csv'])