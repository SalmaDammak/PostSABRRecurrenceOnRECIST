function [m2dPoint1, m2dPoint2, m2dMidpoint, vdEuclideanDistance_mm] = QueryRECISTData(tRECISTData, chPatientUniqueID, chScanID)

vdPatientRows = find(...
    and(string(tRECISTData.c1chCompletePatientID) == string(chPatientUniqueID),...
    string(tRECISTData.c1chScanID) == string(chScanID)));

if isempty(vdPatientRows)
    error("Patient not found.")
end

m2dPoint1 = nan(length(vdPatientRows),3);
m2dPoint2 = nan(length(vdPatientRows),3);
vdEuclideanDistance_mm = nan(length(vdPatientRows),1);

for iPatientRowIdx = 1:length(vdPatientRows)
    dCurrentRow = vdPatientRows(iPatientRowIdx);
    
    m2dPoint1(iPatientRowIdx, :) = [tRECISTData.x1(dCurrentRow), tRECISTData.y1(dCurrentRow), tRECISTData.ReverseStackSliceNum(dCurrentRow)];
    m2dPoint2(iPatientRowIdx, :) = [tRECISTData.x2(dCurrentRow), tRECISTData.y2(dCurrentRow), tRECISTData.ReverseStackSliceNum_1(dCurrentRow)];    
    vdEuclideanDistance_mm(iPatientRowIdx) = 10*tRECISTData.Length(dCurrentRow);    
end

m2dMidpoint = (m2dPoint1 + m2dPoint2)./2;

end

