% This code performs the solid segmentations through the use of a
% graph cuts alogorithm by:
%   1) Reading in the RECIST points from a Slicer 4 ruler and converting
%      them from anatomical to image coordinate in Matlab
%   2) Converting input image to greyscale image in lung window/level range
%   3) Creating a foreground (fg) mask my thresholding the HU density of the
%      input image to sample the solid region.  It also saves the
%      thresholded FG mask as a output segmentation.
%   4) Creating a bacground mask (bg) of a spherical ring around the RECIST line
%      (centered at the midpoint) that only overlaps with the cleaned lung
%      segmentation, and on every slice it must be greater than an area
%      threshold to ensure enough sample for the graph cuts
%   5) All three inputs (image, fg, and bg) are cropped to the extent of
%      the bg mask with a border surrounding it, which is set in the parameters
%   6) The images are resized to a constant pixel width/height in the largest
%      diameter for the graph cuts algorithm as it works best with larger
%      samples (around 400 pixels) and sent to graph cuts
%   7) The output is resized back to the original image size and the
%      cropped region is inserted back into the original volume and saved
%   8) It also saves the spherical foreground thresholded mask as an mhd.

%% Change this directory and load current RECIST file.
chBaseDir = Experiment.GetDataPath('BaseDir');
load(Experiment.GetDataPath('RECISTTable'), 'tRECISTComplete');

%% Prepare directories
chBaseImageDir = [chBaseDir, '\Images'];
chBaseLungSegName = 'Segmentations - 2 - Whole Lung_Cleaned';
chWholeLungWithSolidFilledName = 'Segmentations - 3 - Whole Lung_CompleteWithSolidFilled - edited';
chTargetFolderName = 'Segmentations - 4 - Solid and GGO Approx';

chTargetDir = [chBaseDir, '\', chTargetFolderName];
if ~isfolder(chTargetDir)
    mkdir(chTargetDir)
    copyfile([chBaseDir,'\', chWholeLungWithSolidFilledName], chTargetDir)
end

%% Set up parameters
%%%%%%%%%%%%%%%%%%%
% PARAMETERS:
% Set the foreground threshold parameter
dThres = -200;

% Set the background spherical ring radius minimum area threshold (all in mm)
dSphericalRingThickness = 5;
dSphericalRingFromRECIST = 5;

% Set the distance (mm) of the cropped region from the background mask.
dDistanceToCropInMM = 10;

% Graph cuts parameters
dLargestPixelDimension = 400;
dNumBinsPerChannel = 64;
dBha_slope = 0.05;

% For post-processing
dConnectivity = 18;

% For GGO expansion within RECIST
dOuterThresholdInMM = 16;
%%%%%%%%%%%%%%%%%%%
%%

c1chImageTimes = {'Image' 'NumSlices' 'SolidTime' 'GGOTime'};
dSliceIdx = 0;

% Loop throuh all patients in the directory
stOutcomes = dir([chBaseImageDir, '\*REC']);
if isempty(stOutcomes)
    error('Directory empty!')
end

for iOutcome = 1:length(stOutcomes)

    chOutcome = stOutcomes(iOutcome).name;
    stPatientDirs = dir([chBaseImageDir, '\', chOutcome, '\P*']);

    if isempty(stPatientDirs)
        error('Directory empty!')
    end

    for iPatientFolderIdx = 1:length(stPatientDirs)
        chPatientFolder = stPatientDirs(iPatientFolderIdx).name;
        disp(chPatientFolder);

        % Get the images directory, and a list of all images
        chImageDirPath = strcat(chBaseImageDir,'\', chOutcome,'\', chPatientFolder);
        stImageFiles = dir(strcat(chImageDirPath, '\P*.mhd'));
        if isempty(stImageFiles)
            error('Directory empty!')
        end

        % Loop through all images in the directory:
        for iImageIdx = 1:length(stImageFiles)
            chImageName = stImageFiles(iImageIdx).name;
            disp(chImageName);

            % Get image and segmentation name.
            chImagePath = [chImageDirPath, '\', chImageName];
            chNormalLungSegFileName = erase(strrep(chImagePath, 'Images', chBaseLungSegName), '-IMAGE');
            chWholeLungSegFileName = strrep(chNormalLungSegFileName, chBaseLungSegName, chWholeLungWithSolidFilledName);

            % Get the segmentation raw file, which will be used to overwrite image info for solid seg.
            chRawFileName = strrep(erase(chImageName,'-IMAGE'), '.mhd', '.raw');
            chSolidSegRawFileName = [chBaseDir, '\', chTargetFolderName, '\', chOutcome, '\', chPatientFolder, '\', chRawFileName];

            stImageInfo = mha_read_header(chImagePath);
            m3iImageVolume =  mha_read_volume(stImageInfo);

            stNormalLungSegInfo = mha_read_header(chNormalLungSegFileName);
            m3iNormalLungSegVolume =  mha_read_volume(stNormalLungSegInfo);

            stWholeLungSegInfo = mha_read_header(chWholeLungSegFileName);
            m3iWholeLungSegVolume =  mha_read_volume(stWholeLungSegInfo);
            m3bWholeLungSeg = (m3iWholeLungSegVolume == 1);

            % Create the empty final segmentation volume to contain the solid segmentation
            m3dFinalSolidSegVolume = zeros(size(m3iImageVolume));
            m3dFinalGGOSegVolume = zeros(size(m3iImageVolume));

            %% Query RECIST data to obtain point information.
            chRECISTImageName = [chPatientFolder,'-',chOutcome];
            c1chCTName = regexp(chImageName, '\wCT\d*', 'match');
            disp(chRECISTImageName)
            [m2dPoint1, ~, m2dMidpoint, vdEuclideanDistance] = QueryRECISTData(tRECISTComplete, chRECISTImageName, c1chCTName{1});

            % Calculate graph cuts for each RECIST line in the image.
            for iTumourIdx = 1:size(m2dPoint1,1)
                tic

                vdMidpoint = round(m2dMidpoint(iTumourIdx,:));
                dEuclideanDistance = vdEuclideanDistance(iTumourIdx);
                dRadius = dEuclideanDistance/2;

                % BACKGROUND MASK
                % Create a background mask and insert the midpoint of the RECIST line
                m3iBackgroundMask = zeros(size(m3iImageVolume));
                m3iBackgroundMask(vdMidpoint(1), vdMidpoint(2), vdMidpoint(3)) = 1;

                % Set max distance to compute distance transform to save compute time
                dMaxDistance = dEuclideanDistance + dSphericalRingThickness + dSphericalRingFromRECIST + dOuterThresholdInMM;

                % Create the sphere 'ring' around the line
                m2dDistanceTransformFromMidPoint = bwdistsc1(m3iBackgroundMask, stImageInfo.PixelDimensions, dMaxDistance);
                m2bSphereSegVolume = (m2dDistanceTransformFromMidPoint <= (dRadius+dSphericalRingThickness+dSphericalRingFromRECIST) & m2dDistanceTransformFromMidPoint > (dRadius+dSphericalRingFromRECIST));
                m2bSphereSegVolumeWithLung = (m2bSphereSegVolume == 1) & (m3iNormalLungSegVolume == 1);
                m2bSphereSegVolumeWithLung = m2bSphereSegVolumeWithLung*255;
                m3iBackgroundMask = m2bSphereSegVolumeWithLung;
                if isempty(find(m3iBackgroundMask))
                    error("Mask is blank!")
                end

                % Find the extents of the background to set the cropped region
                [dRow,dCol,dSlice] = ind2sub(size(m3iBackgroundMask),find(m3iBackgroundMask));

                dDistanceToCropInPixels = dDistanceToCropInMM/stImageInfo.PixelDimensions(1);

                dStartSlice = min(dSlice);
                dEndSlice = max(dSlice);
                dStartX = min(dCol) - round(dDistanceToCropInPixels);
                dEndX = max(dCol) + round(dDistanceToCropInPixels);
                dStartY = min(dRow) - round(dDistanceToCropInPixels);
                dEndY = max(dRow) + round(dDistanceToCropInPixels);

                % Crop down the input image volume and background mask
                m2dInputMatrix = m3iImageVolume(dStartY:dEndY, dStartX:dEndX, dStartSlice:dEndSlice);
                m3iBackgroundMatrix = uint8(m3iBackgroundMask(dStartY:dEndY, dStartX:dEndX, dStartSlice:dEndSlice));

                % FOREGROUND MASK
                % Treshold for the cropped input matrix to act as the foreground sample
                m3iForegroundMask = (m3iImageVolume >= dThres);
                m3iForegroundMask = (m2dDistanceTransformFromMidPoint <= (dRadius+dSphericalRingFromRECIST)) & (m3iForegroundMask == 1);
                m3iForegroundMask = m3iForegroundMask*255;
                m3iForegrounMatrix = m3iForegroundMask(dStartY:dEndY, dStartX:dEndX, dStartSlice:dEndSlice);

                % Convert the input matrix to a greyscale image and resize the image to approximately 400 pixels in the largest dimension
                % Changed from SPIE to match window/level on manual contouring
                m2dInputMatrix = mat2gray(m2dInputMatrix,[-1350 150]);

                if size(m2dInputMatrix,1) > size(m2dInputMatrix,2)
                    dScale = round(dLargestPixelDimension/size(m2dInputMatrix,1));
                else
                    dScale = round(dLargestPixelDimension/size(m2dInputMatrix,2));
                end

                % Resize images for graph cuts
                m3dInputMatrix2 = zeros(dScale*size(m2dInputMatrix,1), dScale*size(m2dInputMatrix,2), size(m2dInputMatrix,3));
                m3iForegroundMatrix2 = zeros(dScale*size(m2dInputMatrix,1), dScale*size(m2dInputMatrix,2), size(m2dInputMatrix,3));
                m3iBackgroundMatrix2 = zeros(dScale*size(m2dInputMatrix,1), dScale*size(m2dInputMatrix,2), size(m2dInputMatrix,3));

                for dImageDimension=1:size(m2dInputMatrix,3)
                    m3dCurrentInputMatrix = imresize(m2dInputMatrix(:,:,dImageDimension), dScale,'nearest');
                    m3dCurrentForegroundMatrix = imresize(m3iForegrounMatrix(:,:,dImageDimension), dScale,'nearest');
                    m3dCurrentBackgroundMatrix = imresize(m3iBackgroundMatrix(:,:,dImageDimension), dScale,'nearest');

                    m3dInputMatrix2(:,:,dImageDimension) = m3dCurrentInputMatrix;
                    m3iForegroundMatrix2(:,:,dImageDimension) = m3dCurrentForegroundMatrix;
                    m3iBackgroundMatrix2(:,:,dImageDimension) = m3dCurrentBackgroundMatrix;
                end

                % Perform the graph cuts
                chOneCutFolder = pwd;
                m3dOneCutSegmentationMask = OneCut2D(m3dInputMatrix2, dNumBinsPerChannel, dBha_slope, m3iForegroundMatrix2, m3iBackgroundMatrix2, chOneCutFolder);
                m3dOneCutSegmentationMaskFullSize = zeros(size(m2dInputMatrix));

                dSliceIdx = size(m2dInputMatrix,3);

                % Resize the segmentation matrix image back to normal
                for dSliceIdx = 1:size(m3dOneCutSegmentationMask,3)

                    m2dThisSegmenationMask = imresize(m3dOneCutSegmentationMask(:,:,dSliceIdx), [size(m2dInputMatrix,1) size(m2dInputMatrix,2)],'nearest');
                    m3dOneCutSegmentationMaskFullSize(:,:,dSliceIdx) = m2dThisSegmenationMask;

                end

                % Insert the segmentation back into the entire image volume
                m3dSegmentationMaskWithOneCutPiece = zeros(size(m3iImageVolume));
                m3dSegmentationMaskWithOneCutPiece(dStartY:dEndY, dStartX:dEndX, dStartSlice:dEndSlice) = m3dOneCutSegmentationMaskFullSize;
                m3bSegmentationMaskWithOneCutPiece = (m3dSegmentationMaskWithOneCutPiece == 255);

                % Extract only solid segmenation that is contained within the complete lung volume
                m3bSolidSegmentation = m3bSegmentationMaskWithOneCutPiece & m3bWholeLungSeg;

                % Get largest 3D connected component
                m3bLargestSolidComponent = selectCc(m3bSolidSegmentation, dConnectivity, sub2ind(size(m3bSolidSegmentation),vdMidpoint(1),vdMidpoint(2),vdMidpoint(3)));

                % Added in case RECIST midpoint did not fall on solid
                if max(m3bLargestSolidComponent(:)) == 0
                    m3bLargestSolidComponent = getLargestCc(m3bSolidSegmentation, dConnectivity);
                end

                % To remove extra small disconnected vessels, so slice by%
                % slice and take largest connected component
                m3dThisSolidSegMask = zeros(size(m3iImageVolume));

                [dRow,dCol,dSlice] = ind2sub([size(m3bLargestSolidComponent,1) size(m3bLargestSolidComponent,2) size(m3bLargestSolidComponent,3)],find(m3bLargestSolidComponent));

                for dLargestComponentSlice = min(dSlice):max(dSlice)
                    m2bSolid2DCC = getLargestCc(m3bLargestSolidComponent(:,:,dLargestComponentSlice), dConnectivity);
                    m3dThisSolidSegMask(:,:,dLargestComponentSlice) = m2bSolid2DCC;
                end

                % Get largest 3D connected component again to remove
                % distant vessels
                m3bLargestFinalSolidComponent = getLargestCc(logical(m3dThisSolidSegMask), dConnectivity);

                ElapsedSolidTime = toc;

                tic

                % Expand GGO
                m3dDistanceTransformFromSolid = bwdistsc1(m3bLargestFinalSolidComponent, stImageInfo.PixelDimensions,(5+dOuterThresholdInMM));

                m3bSphereAroundRECIST = (m2dDistanceTransformFromMidPoint <= (dRadius+dOuterThresholdInMM));
                m3bGGOSurrogate = (m3dDistanceTransformFromSolid <= dOuterThresholdInMM) & (m3dDistanceTransformFromSolid > 0);

                m3bGGOSurrogateWithinRECISTandLung = (m3bGGOSurrogate == 1 ) & (m3bSphereAroundRECIST == 1) & (m3iNormalLungSegVolume == 1);

                % Add this GGO and solid component to the final segmentation volume
                m3dFinalSolidSegVolume = (m3dFinalSolidSegVolume + m3bLargestFinalSolidComponent);
                m3dFinalGGOSegVolume = (m3dFinalGGOSegVolume + m3bGGOSurrogateWithinRECISTandLung);

                ElapsedGGOTime = toc;
                c1chImageTimes = [c1chImageTimes; {stImageFiles(iImageIdx).name dSliceIdx ElapsedSolidTime ElapsedGGOTime}];

            end

            % Since there may be more than one RECIST line and therefore two potentially overlapping components, simply make this a logical
            % for anything greater than zero then write the new volume
            m3bFinalSOLIDVolume = (m3dFinalSolidSegVolume > 0);

            m3dGGOVolume = (m3dFinalGGOSegVolume > 0);
            m3bFinalGGOVolume = m3dGGOVolume -(m3bFinalSOLIDVolume & m3dGGOVolume);
            m3dFinalSegVolume = imadd(double(m3bFinalSOLIDVolume), 2*m3bFinalGGOVolume);

            WriteVolumetoMHD(single(m3dFinalSegVolume), chSolidSegRawFileName);

        end
    end
end


save([Experiment.GetResultsDirectory(),'\ComputationTimes.mat'], 'c1chImageTimes')