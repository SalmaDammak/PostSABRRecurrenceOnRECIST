load(Experiment.GetDataPath('Features'))
load(Experiment.GetDataPath('TopFeatureIDs'))


for iFeatureIdx = 1:length(vsSortedImportantFeatureIds)
    sFeatureName = vsSortedImportantFeatureNames(iFeatureIdx);

    oTopfeature = oAllFeatures(:,oAllFeatures.GetFeatureNames == vsSortedImportantFeatureIds(iFeatureIdx));

    vdTopFeatureValues = oTopfeature.GetFeatures();
    viOutcomes = oTopfeature.GetLabels();

    % point-biserial correlation
    [dRvalue,dPValue,vdConfidenceInterval] = rankbiserial(vdTopFeatureValues, viOutcomes == 1);
    if dPValue < 0.05
        disp(sFeatureName + " is correlated with outcome, r=" + num2str(dRvalue,'%.2f') +...
            " (p=" + num2str(dPValue, '%.2f') + ").")
    else
        disp(sFeatureName + "is NOT correlated with outcome, r=" + num2str(dRvalue,'%.2f') +...
            " (p=" + num2str(dPValue, '%.2f') + ").")
    end

    save(string(Experiment.GetResultsDirectory()) + "\TopFeatureCorrelation_"+ sFeatureName +".mat",...
        "dRvalue", "dPValue","vdConfidenceInterval")

    tFeatureTable = table(vdTopFeatureValues, viOutcomes);
    writetable(tFeatureTable, string(Experiment.GetResultsDirectory()) + "\FeatureTable_"+ sFeatureName +".xlsx")


    % Make into ROC using standardized values
    dMin = min(vdTopFeatureValues);
    dRange = max(vdTopFeatureValues) - dMin;
    vdStandardizedFeatureValues = (vdTopFeatureValues - dMin)./dRange;
   
    % Flip outcomes if they're anti-correlated so we're not getting ROC
    % values < 0.50. This is valid because this is a feature.
    sInverseText = "";
    if dRvalue < 0 
        viROCOutcomes = uint8(~viOutcomes);
        sInverseText = "(inversed due to anti-correlation)";
    else
        viROCOutcomes = uint8(viOutcomes);
    end
    figure
    [vdX, vdY] = perfcurve(viROCOutcomes, vdStandardizedFeatureValues,uint8(1));
    plot(vdX, vdY)
    grid on
    axis('equal');
    xlim([0,1]);
    ylim([0,1]);
    xticks(0:0.1:1);
    yticks(0:0.1:1);
    xlabel('False Positive Rate');
    ylabel('True Positive Rate');
    title("ROC Curve " + sInverseText);
    hold('on');
    plot([0 1],[0 1], 'Color', 'k', 'LineWidth', 1, 'LineStyle', '--');
    saveas(gcf, string(Experiment.GetResultsDirectory()) + "\ROC_"+ sFeatureName +".png")
    hold('off')
    close(gcf)

    % Get error metrics
    [dAUC, dAccuracy, dTrueNegativeRate, dTruePositiveRate, dPPV, tExcelFileMetrics, dThreshold]=...
                MyGeneralUtils.CalculateAllTheMetrics(viROCOutcomes, vdStandardizedFeatureValues, uint8(1));
    save(string(Experiment.GetResultsDirectory()) + "\ErrorMetrics_"+ sFeatureName +".mat",...
        "dPPV", "tExcelFileMetrics");

    % Make box plots
    figure
    boxplot(vdTopFeatureValues,viOutcomes)
    grid on
    xticklabels(["NOREC", "REC"])
    ylabel("Feature value")
    title(sFeatureName)
    saveas(gcf, string(Experiment.GetResultsDirectory()) + "\GroupedByOutcome_"+ sFeatureName +".png")
    close(gcf)

    % Make violin plots
    figure
    c1vdGroupedByOutcome = {vdTopFeatureValues(viOutcomes==0), vdTopFeatureValues(viOutcomes==1)};
    violin(c1vdGroupedByOutcome,'xlabel',["NOREC", "REC"]);
    grid on    
    ylabel("Feature value")
    title(sFeatureName)
    saveas(gcf, string(Experiment.GetResultsDirectory()) + "\ViolinPlotsByOutcome_"+ sFeatureName +".png")
    close(gcf)

    disp(newline)
end
