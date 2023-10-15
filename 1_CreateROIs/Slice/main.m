% Get image base, whole lung seg, and RECIST base filepaths
chBaseFolderPath = Experiment.GetDataPath('BaseFolder');
chBaseImageFolderPath = [chBaseFolderPath, '\Images'];
chBaseWholeLungFolderPath = [chBaseFolderPath, '\Segmentations - 3 - Whole Lung_CompleteWithSolidFilled - edited'];
load(Experiment.GetDataPath('RECISTTable'), 'tRECISTComplete');

% Create segmentation subfolders
chSliceFolderPath = [chBaseFolderPath,'\Segmentations - 7 - Slice'];
if ~isfolder(chSliceFolderPath)
    mkdir(chSliceFolderPath)
    copyfile(chBaseWholeLungFolderPath, chSliceFolderPath)
end

% Loop through all patients (i.e., also thorugh all tumours)
stOutcomes = dir([chBaseImageFolderPath, '\*REC']);

vsImagePaths = [];
vsSlicePaths = [];

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
        % Get RECIST slice
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        dRECISTSliceNum = m2dPoint1(3);
        m2dLungSegRECISTSlice = m3iWholeLungSegVolume(:,:, dRECISTSliceNum);
        stConnectedComponents = bwconncomp(m2dLungSegRECISTSlice);
        
        % Draw RECIST line
        m2dPoint1 = round(m2dPoint1);
        m2dPoint2 = round(m2dPoint2);
        [vdRECISTLineX, vdRECISTLineY] = bresenham(m2dPoint1(1),m2dPoint1(2),m2dPoint2(1),m2dPoint2(2));
        vdRECISTLineIndices = sub2ind(size(m2dLungSegRECISTSlice),vdRECISTLineX,vdRECISTLineY);
        
        % Find which lung the RECIST line is in
        c1vdIndexIntersections = cell(stConnectedComponents.NumObjects  , 1);
        
        for iComponentIndex = 1:stConnectedComponents.NumObjects
            c1vdIndexIntersections{iComponentIndex} = intersect(...
                vdRECISTLineIndices, stConnectedComponents.PixelIdxList{iComponentIndex});
        end
        
        % Check matches
        vbIsMatch = ~cellfun(@isempty, c1vdIndexIntersections);
        if sum(vbIsMatch) > 1
            error("too many matches")
        elseif sum(vbIsMatch) == 0
            warning("No matches found!, skipping this one.")            
            continue
        end       

        dComponentNum = find(vbIsMatch);
        
        if length(c1vdIndexIntersections{dComponentNum}) ~= length(vdRECISTLineIndices)
            warning("RECIST line not fully in lung!")
        end

        m2iRECISTLungMask = zeros(size(m2dLungSegRECISTSlice));
        m2iRECISTLungMask(stConnectedComponents.PixelIdxList{dComponentNum}) = 1;

        m3iRECISTLungMask = zeros(size(m3iWholeLungSegVolume));
        m3iRECISTLungMask(:,:,dRECISTSliceNum) = m2iRECISTLungMask;

        chRawFileName = strrep(erase(chImageName,'-IMAGE'), '.mhd', '.raw');
        chSliceRawFilePath = [chSliceFolderPath, '\', chOutcome, '\', chPatient, '\', chRawFileName];
        WriteVolumetoMHD(single(m3iRECISTLungMask), chSliceRawFilePath);
        vsSlicePaths = [vsSlicePaths; string(strrep(chSliceRawFilePath, '.raw', '.mhd'))];
    end
end

save([Experiment.GetResultsDirectory(), '\Paths.mat'], "vsImagePaths", "vsSlicePaths");


function CreateImageForEditing(m3iMaskWithRECISTLine, m3iLungSegmentation, chFilePath)
m3dCombo = zeros(size(m3iMaskWithRECISTLine));
m3dCombo(m3iLungSegmentation==1) = 1;
m3dCombo(m3iMaskWithRECISTLine==1) = 2;
m3dCombo(and(m3iMaskWithRECISTLine==1, m3iLungSegmentation==1)) = 4; % 4 is easier to see than 3 on itksnap

WriteVolumetoMHD(single(m3dCombo), chFilePath);
end