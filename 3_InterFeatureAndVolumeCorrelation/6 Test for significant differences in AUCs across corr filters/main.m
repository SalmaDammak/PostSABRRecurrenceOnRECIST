% loop through folders to load AUC vectors
load('Folders.mat')

dNumIterations = 500;
m2dAllAUCs = nan(dNumIterations,length(vsFolders));
vsGroupNames = strings(length(vsFolders), 1);

for iFolderIdx = 1:length(vsFolders)
    sCurr = vsFolders(iFolderIdx) + "\Results\02 Bootstrapped Iterations\Partitions & Guess Results.mat";
    load(sCurr, "c1oGuessResultsPerPartition")

    vdAUCPerBS = zeros(dNumIterations,1);
    for iIterIdx = 1:length(c1oGuessResultsPerPartition)
        oGuessResult = c1oGuessResultsPerPartition{iIterIdx};
        vdAUCPerBS(iIterIdx) = ErrorMetricsCalculator.CalculateAUC(oGuessResult,'JournalingOn', false);
    end

    save([Experiment.GetResultsDirectory(),'\',num2str(iFolderIdx),'.mat'],'vdAUCPerBS')
    m2dAllAUCs(:, iFolderIdx) = vdAUCPerBS';

    vsFolderPathParts = strsplit(vsFolders(iFolderIdx), "\");
    vsGroupNames(iFolderIdx) = vsFolderPathParts(8);

end
writematrix(vsGroupNames, [Experiment.GetResultsDirectory(),'\GroupNameOrderedByGroupNumber.csv'])
save([Experiment.GetResultsDirectory(),'\AllAUCs.mat'],'m2dAllAUCs')

% Test all variables for for normality
% "returns a test decision for the null hypothesis that the data in vector
% x comes from a standard normal distribution...The result h is 1 if the
% test rejects the null hypothesis at the 5% significance level"
vbNonNormal = nan(1, size(m2dAllAUCs, 2));
for iVarIdx = 1:size(m2dAllAUCs, 2)
    vbNonNormal(iVarIdx) = kstest(m2dAllAUCs(:,iVarIdx));
end

if any(vbNonNormal)
    [dAllPValue,tbl,stGroupStats] = kruskalwallis(m2dAllAUCs);
    disp("Not nromal")
else
    [dAllPValue,tbl,stGroupStats] = anova1(m2dAllAUCs);
end

% This is uses ranks if kruskalwallis is used, and that information is
% passed on in stGroupStats
m2dMultipleComparisons = multcompare(stGroupStats, 'CriticalValueType', 'bonferroni');

% Get only rows with p-values < 0.05
m2dSignificantlyDifferentGroups = m2dMultipleComparisons(m2dMultipleComparisons(:, 6) < 0.05,:);

% Built readable tables
c1chHeader = {'group1 #', 'group2 #', 'lowerCI', 'difference', 'upperCI', 'p-value'}; 
tSignificantlyDifferentGroups = array2table(m2dSignificantlyDifferentGroups, 'VariableNames',c1chHeader);
tMultipleCmparisons = array2table(m2dMultipleComparisons, 'VariableNames',c1chHeader);

writetable(tSignificantlyDifferentGroups, [Experiment.GetResultsDirectory(),'\tSignificantlyDifferentGroups.csv'])
writetable(tMultipleCmparisons, [Experiment.GetResultsDirectory(),'\tMultipleCmparisons.csv'])

% with and without th inter-corr filter
if vbNonNormal(1) == 1 || vbNonNormal(2) == 1

    % Wilcoxon Rank-Sum test
    [hDifferentCentralTendencyInterfeature,dInterFeatureCorrPValue] = ranksum(m2dAllAUCs(:,1), m2dAllAUCs(:,2));
    disp("Not nromal")
else
    [hDifferentCentralTendencyInterfeature,dInterFeatureCorrPValue] = ttest2(m2dAllAUCs(:,1), m2dAllAUCs(:,2));
end
if hDifferentCentralTendencyInterfeature
    disp("Correlation filter makes a significant difference. p=" + num2str(dInterFeatureCorrPValue))
end


% with and without the volume-corr filter
if vbNonNormal(3) == 1 || vbNonNormal(2) == 1

    % Wilcoxon Rank-Sum test
    [hDifferentCentralTendencyVolume,dVolumeCorrPValue] = ranksum(m2dAllAUCs(:,3), m2dAllAUCs(:,2));
    disp("Not nromal")
else
    [hDifferentCentralTendencyVolume,dVolumeCorrPValue] = ttest2(m2dAllAUCs(:,3), m2dAllAUCs(:,2));
end
if hDifferentCentralTendencyVolume
    disp("Volume filter makes a significant difference. p=" + num2str(dVolumeCorrPValue))
end

save([Experiment.GetResultsDirectory(),'\Comparisons.mat'],...
    'tSignificantlyDifferentGroups', 'tMultipleCmparisons','dAllPValue', 'stGroupStats',...
    'hDifferentCentralTendencyInterfeature', 'dInterFeatureCorrPValue',...
    'hDifferentCentralTendencyVolume', 'dVolumeCorrPValue','vsGroupNames');
