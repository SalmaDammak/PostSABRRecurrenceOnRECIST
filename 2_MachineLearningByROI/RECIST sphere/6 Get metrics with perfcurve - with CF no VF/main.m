load(Experiment.GetDataPath('features'),"oAllFeatures")
vbIsPositive = oAllFeatures.GetLabels() == 1;
dNumPositives = sum(vbIsPositive);
dNumNegatives = sum(~vbIsPositive);

chExpPath = Experiment.GetDataPath('BaseResultsDirectory');


%% Get error metrics
[m2dXAndCI, m2dYAndCI, vdAUCAndCI, vdAccAndCI,...
    vdFNRAndCI, vdFPRAndCI, vdTNRAndCI, vdTPRAndCI,...
    dPointIndexForOptThres, dAUC_0Point632PlusPerBootstrap] = ...
    GenerateROCAndCIMetrics(chExpPath, dNumPositives, dNumNegatives);

sAUC = num2str(vdAUCAndCI(1),'%1.2f') +...
    " [" + num2str(vdAUCAndCI(2),'%1.2f') + ", " + num2str(vdAUCAndCI(3),'%1.2f') + "]";
sAccuracy = num2str(100*vdAccAndCI(1),'%3.f') +...
    "% [" + num2str(100*vdAccAndCI(2),'%3.f') + "%, " + num2str(100*vdAccAndCI(3),'%3.f') + "%]";
sSensitivity = num2str(100*vdTPRAndCI(1),'%3.f') +...
    "% [" + num2str(100*vdTPRAndCI(2),'%3.f') + "%, " + num2str(100*vdTPRAndCI(3),'%3.f') + "%]";
sSpecificity = num2str(100*vdTNRAndCI(1),'%3.f') +...
    "% [" + num2str(100*vdTNRAndCI(2),'%3.f') + "%, " + num2str(100*vdTNRAndCI(3),'%3.f') + "%]";

tMetrics = table(sAUC, sAccuracy, sSensitivity, sSpecificity);

save([Experiment.GetResultsDirectory(),'\Metrics.mat'], 'tMetrics')

%% Plot ROC

hROC = PlotROCWithErrorBounds(m2dXAndCI, m2dYAndCI, dPointIndexForOptThres, [0 0 0]/255);

savefig([Experiment.GetResultsDirectory(), '\ROC.fig'])
saveas(hROC, [Experiment.GetResultsDirectory(), '\ROC.svg']);
print([Experiment.GetResultsDirectory(), '\ROC.tiff'], '-dtiffn')
close(hROC)
