% Set up experiment
Experiment.StartNewSection('Prepare experiment');

% Note that BS = BootStrap
dNumBSReps = 500;

load(Experiment.GetDataPath('features'),"oAllFeatures")
oDataSet = oAllFeatures;
dNumUniquePatients = length(unique(oDataSet.GetGroupIds));

% set up boot-strapped partitions (this is set up for default bootstrapping)
dNumGroupsInTrainingSet = dNumUniquePatients;
dNumGroupsInTestingSet = [];
bAtLeastOneOfEachLabelPerPartition = true;

vstBSPartitions = BootstrappingPartition.CreatePartitions(...
    oDataSet, dNumBSReps, dNumGroupsInTrainingSet, dNumGroupsInTestingSet, bAtLeastOneOfEachLabelPerPartition);

% set up an additional "partition" for training and testing on all (to get
% training performance) and add to partition array so it's done on the DCS
stTrainAndTestOnAllDataPartition = struct('TrainingIndices', 1:oDataSet.GetNumberOfSamples(), 'TestingIndices', 1:oDataSet.GetNumberOfSamples());
vstBSPartitions = [vstBSPartitions; stTrainAndTestOnAllDataPartition];

Experiment.EndCurrentSection();

%% Compute bootstrap iterations
Experiment.StartNewSection('Bootstrapped Iterations');

oManager = Experiment.GetLoopIterationManager(dNumBSReps+1, 'AvoidIterationRecomputationIfResumed', true); % "+ 1" for the train and test on full data set iteration needed for AUC_0.632

parfor dBSRepIndex = 1:dNumBSReps+1
    if oManager.IterationWasPreviouslyComputed(dBSRepIndex)
        continue; % don't recomputed it!
    end
    oManager.PerLoopIndexSetup(dBSRepIndex);

    % Use a different filename for the AUC calculated on all samples
    if dBSRepIndex == dNumBSReps+1
        chFilename = 'Train and Test On All Data Results.mat';
    else
        chFilename = ['Iteration ', StringUtils.num2str_PadWithZeros(dBSRepIndex, length(num2str(dNumBSReps))), ' Results.mat'];
    end

    % Declare variables (this avoids warnings)
    oRadiomicTrainingSet = [];
    oRadiomicTestingSet = [];

    % Get radiomic data
    oRadiomicTrainingSet = oDataSet(vstBSPartitions(dBSRepIndex).TrainingIndices,:);
    oRadiomicTestingSet = oDataSet(vstBSPartitions(dBSRepIndex).TestingIndices,:);
   
    % Perform hyper-parameter optimization, this uses the out of bag AUC
    oObjectiveFunction = OutOfBagSampleValidationObjectiveFunction('Parameters\Error Metric Parameters.mat','Parameters\Objective Function Parameters.mat');
    oHyperParameterOptimizer = MATLABBayesianHyperParameterOptimizer('Parameters\HPO Parameters.mat', oObjectiveFunction, oRadiomicTrainingSet);
    oClassifier = MATLABTreeBagger('Parameters\Model Hyper Parameters.mat',oHyperParameterOptimizer, 'JournalingOn', false);
    dHyperParameterOptimizationAUC = 1 - oClassifier.GetHyperParameterOptimizer().GetObjectiveFunctionValueAtOptimalHyperParameters();

    % Train and evaluate classifier
    oRNG = RandomNumberGenerator();

    oRNG.PreLoopSetup(1);
    oRNG.PerLoopIndexSetup(1);

    oTrainedClassifier = oClassifier.Train(oRadiomicTrainingSet, 'JournalingOn', false);
    oGuessResult = oTrainedClassifier.Guess(oRadiomicTestingSet, 'JournalingOn', false);
    oOOBSamplesGuessResult = oTrainedClassifier.GuessOnOutOfBagSamples();

    oRNG.PerLoopIndexTeardown;
    oRNG.PostLoopTeardown;

    % Save results to disk
    FileIOUtils.SaveMatFile(...
        fullfile(Experiment.GetResultsDirectory(), chFilename),...
        'stBootstrappedPartitions', vstBSPartitions(dBSRepIndex),...
        'dHyperParameterOptimizationAUC', dHyperParameterOptimizationAUC,...
        'oConstructedClassifier', oClassifier,...
        'vdFeatureImportanceScores', oTrainedClassifier.GetFeatureImportanceFromOutOfBagSamples(),...
        'oGuessResult', oGuessResult,...
        'oOOBSamplesGuessResult', oOOBSamplesGuessResult,...
        '-v7', '-nocompression');

    % par manager clean-up
    oManager.PerLoopIndexTeardown();
end

oManager.PostLoopTeardown();

% combine all guess results into a single file
c1oGuessResultsPerBSPartition = cell(dNumBSReps,1);
c1oOOBSamplesGuessResultsPerBSPartition = cell(dNumBSReps,1);

chResultsDirPath = Experiment.GetResultsDirectory();

for dBootstrapIndex=1:dNumBSReps
    [c1oGuessResultsPerBSPartition{dBootstrapIndex}, c1oOOBSamplesGuessResultsPerBSPartition{dBootstrapIndex}] = FileIOUtils.LoadMatFile(...
        fullfile(chResultsDirPath, ['Iteration ', StringUtils.num2str_PadWithZeros(dBootstrapIndex, length(num2str(dNumBSReps))), ' Results.mat']),...
        'oGuessResult', 'oOOBSamplesGuessResult');
end

FileIOUtils.SaveMatFile(...
    fullfile(chResultsDirPath, 'Partitions & Guess Results.mat'),...
    'c1oGuessResultsPerPartition', c1oGuessResultsPerBSPartition,...
    'c1oOOBSamplesGuessResultsPerPartition', c1oOOBSamplesGuessResultsPerBSPartition,...
    'vstBootstrapPartitions', vstBSPartitions(1:dNumBSReps));

Experiment.EndCurrentSection();
%% calculate AUC

Experiment.StartNewSection('Performance');

[oTrainAndTestOnAllSamplesGuessResultForFeatureCombination] = FileIOUtils.LoadMatFile(fullfile(chResultsDirPath, 'Train and Test On All Data Results.mat'), 'oGuessResult');

vdAUCPerBootstrap = zeros(dNumBSReps,1);

for dBootstrapIndex=1:dNumBSReps
    vdAUCPerBootstrap(dBootstrapIndex) = ErrorMetricsCalculator.CalculateAUC(c1oGuessResultsPerBSPartition{dBootstrapIndex}, 'JournalingOn', false);
end

vdAUC_0Point632PerBootstrap = AdvancedErrorMetricsCalculator.CalculateAUC_0Point632(c1oGuessResultsPerBSPartition, oTrainAndTestOnAllSamplesGuessResultForFeatureCombination);
vdAUC_0Point632PlusPerBootstrap = AdvancedErrorMetricsCalculator.CalculateAUC_0Point632Plus(c1oGuessResultsPerBSPartition, oTrainAndTestOnAllSamplesGuessResultForFeatureCombination);

dAUCTrainAndTestOnAllSamples = ErrorMetricsCalculator.CalculateAUC(oTrainAndTestOnAllSamplesGuessResultForFeatureCombination, 'JournalingOn', false);

[dLPOBAUC, dLPOBAUCStDev] = AdvancedErrorMetricsCalculator.LeaveOnePairOutBootstrapAUCAndStDev(vstBSPartitions(1:dNumBSReps), c1oGuessResultsPerBSPartition);

FileIOUtils.SaveMatFile(...
    fullfile(Experiment.GetResultsDirectory(), 'AUC Metrics.mat'),...
    'vdAUCPerBootstrap', vdAUCPerBootstrap,...
    'vdAUC_0Point632PerBootstrap', vdAUC_0Point632PerBootstrap,...
    'vdAUC_0Point632PlusPerBootstrap', vdAUC_0Point632PlusPerBootstrap,...
    'dAUCTrainAndTestOnAllSamples', dAUCTrainAndTestOnAllSamples,...
    'dLPOBAUC', dLPOBAUC, 'dLPOBAUCStDev', dLPOBAUCStDev);

Experiment.AddToReport(ReportUtils.CreateParagraphWithBoldLabel('AUC: ', ''));
Experiment.AddToReport(ReportUtils.CreateParagraph("Mean: " + string(mean(vdAUCPerBootstrap))));
Experiment.AddToReport(ReportUtils.CreateParagraph("Median: " + string(median(vdAUCPerBootstrap))));
Experiment.AddToReport(ReportUtils.CreateParagraph("St. Dev.: " + string(std(vdAUCPerBootstrap))));

Experiment.AddToReport(ReportUtils.CreateParagraphWithBoldLabel('AUC 0.632: ', ''));
Experiment.AddToReport(ReportUtils.CreateParagraph("Mean: " + string(mean(vdAUC_0Point632PerBootstrap))));
Experiment.AddToReport(ReportUtils.CreateParagraph("Median: " + string(median(vdAUC_0Point632PerBootstrap))));
Experiment.AddToReport(ReportUtils.CreateParagraph("St. Dev.: " + string(std(vdAUC_0Point632PerBootstrap))));

Experiment.AddToReport(ReportUtils.CreateParagraphWithBoldLabel('AUC 0.632+: ', ''));
Experiment.AddToReport(ReportUtils.CreateParagraph("Mean: " + string(mean(vdAUC_0Point632PlusPerBootstrap))));
Experiment.AddToReport(ReportUtils.CreateParagraph("Median: " + string(median(vdAUC_0Point632PlusPerBootstrap))));
Experiment.AddToReport(ReportUtils.CreateParagraph("St. Dev.: " + string(std(vdAUC_0Point632PlusPerBootstrap))));

Experiment.AddToReport(ReportUtils.CreateParagraphWithBoldLabel('AUC LPOB: ', ''));
Experiment.AddToReport(ReportUtils.CreateParagraph("Mean: " + string(dLPOBAUC)));
Experiment.AddToReport(ReportUtils.CreateParagraph("St. Dev.: " + string(dLPOBAUCStDev)));

hFig = figure();
histogram(vdAUCPerBootstrap, 'BinEdges', 0:0.1:1);
grid on

chFigSavePath = fullfile(Experiment.GetResultsDirectory(), 'AUC Histogram.fig');

savefig(hFig, chFigSavePath);
Experiment.AddToReport(chFigSavePath);

delete(hFig);

Experiment.EndCurrentSection();
