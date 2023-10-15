[r1,c1,s1] = ind2sub(size(m3iMaskWithRECISTLineOnly), find(m3iMaskWithRECISTLineOnly == 1));
m2dRECIST = [r1,c1,s1] ; 
m2dIm = zeros(size(m3iMaskWithRECISTLineOnly,1), size(m3iMaskWithRECISTLineOnly,2));
indRECIST = sub2ind(size(m2dIm),m2dRECIST(:,1), m2dRECIST(:,2));

vdPoint1 = m2dPoint1;
vdPoint2 = m2dPoint2;
dPlane = vdPoint1(1,3);

[r2,c2,s2] = ind2sub(size(m3iMaskWithRECISTLineOnly), find(m3bCapsuleMask == 1));
m2dCapsule = [r2,c2,s2];
m2dCapsuleInPlane = m2dCapsule(m2dCapsule(:,3) == dPlane,:);
ind = sub2ind(size(m2dIm),m2dCapsuleInPlane(:,1), m2dCapsuleInPlane(:,2));
m2dIm(ind) = 2;
m2dIm(indRECIST) = 1;
imshow(m2dIm,[])

%m2dIm(m2dCapsuleInPlane(:,1:2)) = 2;
%%

% Get base axis equation
m1 = (vdPoint2(1) - vdPoint1(1))/(vdPoint2(2) - vdPoint1(2));
b1 = vdPoint1(1) - m1*(vdPoint1(2));

m2 = -1/m1;
%%

% % loop through capsule points
vdIsPerpindicular = nan(length(m2dCapsuleInPlane), 1);
for iCapPointRow = 1:length(m2dCapsuleInPlane)
    vdCurrentPoint = m2dCapsuleInPlane(iCapPointRow,:);

    indPoint = sub2ind(size(m2dIm),vdCurrentPoint(:,1), vdCurrentPoint(:,2));
    m2dIm(indPoint) = 3;
    imshow(m2dIm,[])

    
    b2 = vdCurrentPoint(1) - m2*vdCurrentPoint(2);

    x = round((b2-b1)/(m1-m2));
    y = round(m1*x+b1);

    indIntersectionPoint = sub2ind(size(m2dIm),vdCurrentPoint(:,1), vdCurrentPoint(:,2));
    m2dIm(indIntersectionPoint) = 4;
    imshow(m2dIm,[])


    
    vdIsPerpindicular(iCapPointRow) = sum(ismember([x,y], [r1,c1])) == 2;

end

m2dPerp = m2dCapsuleInPlane(vdIsPerpindicular==1, :);
m2dperp2D = m2dCapsuleInPlane(vdIsPerpindicular==1, 1:2);
indPerp= sub2ind(size(m2dIm),m2dperp2D(:,1), m2dperp2D(:,2));
m2dIm(indPerp) = 2;
m2dIm(indRECIST) = 1;
imshow(m2dIm,[])

m2dPerpMask = zeros(size(m3iMaskWithRECISTLineOnly, 1), size(m3iMaskWithRECISTLineOnly, 2));
m2dPerpMask(indPerp) = 1;
m3dPerpCubeMask = repmat(m2dPerpMask, 1, 1, size(m3iMaskWithRECISTLineOnly, 3));


m3dCylinder = and(m3dPerpCubeMask==1, m3bCapsuleMaskInLung == 1);
imshow3D(m3dCylinder)
