function m2dPerpendicularPointsMask = GetPerpendicularPointsMask(m2dSliceWithRECISTLine, m2dMaskOfPointsToConsider)
% m2dPerpendicularPointsMask = GetPerpendicularPointsMask(m2dRECISTSlice, m3bCapsuleMask);
% This was developed based on a idea from David DeVries when I was trying
% to figure out how to remove the caps from the capped cylinder (i.e.
% capsule) ROI. I first make the capsule because that allows me to easily
% calculate distance in real space (given the anistropy of the image) with
% the bwdistsc function. Then, I use this function for finding which points
% of the capsule are perpindicular to the RECIST line so I can then remove
% the caps. You can imagine this as drawing a line from each point that has
% to be perpindicular with the RECIST line, and if that line crosses the
% RECIST line, then it is part of the cylinder, otherwise it's part of the
% caps. After I do this in 3D, I tack the slices to a get a sort of cube
% and run an "and" with the capsule to get the capsule without the caps.
% e.g.,
% Get capsule mask
% m3dDistanceFromRECIST = bwdistsc(m3iMaskWithRECISTLineOnly, stImageInfo.PixelDimensions);
% m3bCapsuleMask = (m3dDistanceFromRECIST <= dDistance_mm);
% m3bCapsuleMaskInLung = and(m3bCapsuleMask == 1,  m3iWholeLungSegVolume == 1);
% 
% % Get cylinder mask
% m2bCapsuleInPlane = m3bCapsuleMask(:,:,m2dPoint1(3));
% m2dPerpendicularPointsMask = GetPerpendicularPointsMask(m2dRECISTSlice, m2bCapsuleInPlane);
% 
% % Repeat slice as a stack in 3D since the RECIST line is always in
% % plane, this will work for removing the caps
% m3dPerpendicularPointsMask = repmat(m2dPerpendicularPointsMask, 1, 1, size(m3iMaskWithRECISTLineOnly, 3));
% m3dCylinder = and(m3dPerpendicularPointsMask==1, m3bCapsuleMaskInLung == 1);


[vdRECISTRows,vdRECISTCols] = ind2sub(size(m2dSliceWithRECISTLine), find(m2dSliceWithRECISTLine == 1));
[vdPointsRows,vdPointsCols] = ind2sub(size(m2dMaskOfPointsToConsider), find(m2dMaskOfPointsToConsider == 1));
vdRECISTStart = [vdRECISTRows(1), vdRECISTCols(1)];
vdRECISTEnd = [vdRECISTRows(end), vdRECISTCols(end)];

% Get equation for RECIST line
% solve for m1 and b1 in y = m1x + b1
dRECISTSlope = (vdRECISTEnd(1) - vdRECISTStart(1))/(vdRECISTEnd(2) - vdRECISTStart(2));
dRECISTIntercept = vdRECISTStart(1) - dRECISTSlope*(vdRECISTStart(2));

% Get the perpendicular slope
dSlopePerpindicularToRECIST = -1/dRECISTSlope;

% loop through capsule points
vdIsPerpindicular = nan(length(vdPointsRows), 1);

if isempty(vdPointsRows)
    error("No points!")
end
for iPointIdx = 1:length(vdPointsRows)
    vdCurrentPoint = [vdPointsRows(iPointIdx), vdPointsCols(iPointIdx)];
    
    % Find the intercept of the line that would form when the point is on 
    % a line perpindicular to the RECIST line 
    dPointToRECISTLineIntercept = vdCurrentPoint(1) - dSlopePerpindicularToRECIST*vdCurrentPoint(2);

    % Given the RECIST line and the line between the point the RECIST line,
    % we can find the point where the RECIST line and the line extending
    % from this point intersect
    dIntersectionPointX = round((dPointToRECISTLineIntercept-dRECISTIntercept)/(dRECISTSlope-dSlopePerpindicularToRECIST));
    dIntersectionPointY = round(dRECISTSlope*dIntersectionPointX+dRECISTIntercept);
    
    % If that intersection is part of the RECIST points, it means that it
    % didn't go beyond it.
    vdIsPerpindicular(iPointIdx) = sum(ismember([dIntersectionPointX,dIntersectionPointY], [vdRECISTRows,vdRECISTCols])) == 2;
end

vdIndices = sub2ind(size(m2dSliceWithRECISTLine),vdPointsRows(vdIsPerpindicular==1), vdPointsCols(vdIsPerpindicular==1));
m2dPerpendicularPointsMask = zeros(size(m2dSliceWithRECISTLine));
m2dPerpendicularPointsMask(vdIndices) = 1;

end
