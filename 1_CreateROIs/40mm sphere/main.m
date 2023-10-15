% Get image base, whole lung seg, and RECIST base filepaths
chBaseFolderPath = Experiment.GetDataPath('BaseFolder');
chBaseImageFolderPath = [chBaseFolderPath, '\Images'];
chBaseWholeLungFolderPath = [chBaseFolderPath, '\Segmentations - 3 - Whole Lung_CompleteWithSolidFilled - edited'];
load(Experiment.GetDataPath('RECISTTable'), 'tRECISTComplete');

% Create segmentation subfolders, and Copy whole lung
% segmentations over to new segmentation folders
chSphereFolderPath = [chBaseFolderPath,'\Segmentations - 5 - 40mm sphere'];
if ~isfolder(chSphereFolderPath)
    mkdir(chSphereFolderPath)
    copyfile(chBaseWholeLungFolderPath, chSphereFolderPath)
end

% Loop through all patients (i.e., also thorugh all tumours)
stOutcomes = dir([chBaseImageFolderPath, '\*REC']);

vsImagePaths = [];
vs20mmSpherePaths = [];
vsCylinderPaths = [];
for iOutcome = 1:length(stOutcomes)

    chOutcome = stOutcomes(iOutcome).name;
    stPatients = dir([chBaseImageFolderPath, '\', chOutcome, '\P*']);

    for iPatient = 1:length(stPatients)

        chPatient = stPatients(iPatient).name;
        disp(chPatient)

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Get image, lung segmentation, and RECIST info
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % Get image full path
        chImageFolderPath = [chBaseImageFolderPath, '\', chOutcome, '\', chPatient];
        stImages = dir([chImageFolderPath, '\*.mhd']);
        chImageName = stImages.name;
        chImageFilePath = [chImageFolderPath, '\', chImageName];
        vsImagePaths = [vsImagePaths; string(chImageFilePath)];

        % Get whole lung seg full path
        chWholeLungSegFilePath = strrep(erase(chImageFilePath, '-IMAGE'), chBaseImageFolderPath, chBaseWholeLungFolderPath);

        % Read the segmentation one
        stWholeLungSegInfo = mha_read_header(chWholeLungSegFilePath);
        m3iWholeLungSegVolume =  mha_read_volume(stWholeLungSegInfo);

        if any(~ismember(m3iWholeLungSegVolume(:), [0 1]))
            error("Bad voxel values fcleound!")
        end

        chRECISTImageName = [chPatient,'-',chOutcome];
        c1chCTName = regexp(chImageName, '\wCT\d*', 'match');
        [m2dPoint1, m2dPoint2, m2dMidpoint] = QueryRECISTData(tRECISTComplete, chRECISTImageName, c1chCTName{1});
        
        if size(m2dPoint2, 1) > 1
            error("Too many RECIST matches found!")
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % GET 2cm diameter sphere
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        dRadius_mm = 20;

        vdMidpoint = round(m2dMidpoint);
        m3iSphereInputMask = zeros(size(m3iWholeLungSegVolume));
        m3iSphereInputMask(vdMidpoint(1), vdMidpoint(2), vdMidpoint(3)) = 1;
        
        stImageInfo = mha_read_header(chImageFilePath);
        m3dDistanceFromMidpoint = bwdistsc(m3iSphereInputMask, stImageInfo.PixelDimensions);

        m3bSphereMask = (m3dDistanceFromMidpoint <= dRadius_mm);
        m3bSphereMaskInLung = and(m3bSphereMask == 1,  m3iWholeLungSegVolume == 1);

        chRawFileName = strrep(erase(chImageName,'-IMAGE'), '.mhd', '.raw');
        chSphereRawFilePath = [chSphereFolderPath, '\', chOutcome, '\', chPatient, '\', chRawFileName];
        WriteVolumetoMHD(single(m3bSphereMaskInLung), chSphereRawFilePath);
        vs20mmSpherePaths = [vs20mmSpherePaths; string(strrep(chSphereRawFilePath, '.raw', '.mhd'))];

    end
end

save([Experiment.GetResultsDirectory(), '\Paths.mat'], "vsImagePaths", "vs20mmSpherePaths", "vsCylinderPaths");


function CreateImageForEditing(m3iMaskWithRECISTLine, m3iLungSegmentation, chFilePath)
m3dCombo = zeros(size(m3iMaskWithRECISTLine));
m3dCombo(m3iLungSegmentation==1) = 1;
m3dCombo(m3iMaskWithRECISTLine==1) = 2;
m3dCombo(and(m3iMaskWithRECISTLine==1, m3iLungSegmentation==1)) = 4; % 4 is easier to see than 3 on itksnap

WriteVolumetoMHD(single(m3dCombo), chFilePath);
end