# PostSABRRecurrenceOnRECIST

Code for the journal article: [Distinguishing recurrence from radiation-induced lung injury at the time of RECIST progressive disease on post-SABR CT scans using radiomics](https://doi.org/10.1038/s41598-024-52828-4)

IMPORTANT: due to storage restrictions, I had to remove the data files from this GitHub repo. A version of the repo with the datafiles included exists [here](https://uwoca-my.sharepoint.com/:f:/g/personal/sdammak_uwo_ca/ErQBBaxJoBxEkdXYB-QnHsIBJKUf4ptOfFzPrgEmQkTo8Q?e=PjtzSN).

As a first step, please unzip the "Code.zip" folder in each parent folder and put a copy in each of its experiment subfolders.
An experiment subfolder is one that has "Experiment.m" in it.

## 1. Data
The predicted probabilities and ground truth labels for each ML experiment are all placed within the experiment folder with the code files that produced them under "./Results/02 Bootstrapped Iterations/Iteration ### Results.mat", where ### is the bootstrap iteration number. 
To load the .mat file, first add the experiment folder's "Code" folder to the MATLAB path then load the file and unzip the "Results" folder.
To get the predictions, use ```oGuessResult.GetPositiveLabelConfidences()```, to get the ground truth labels, use ```oGuessResult.GetLabels()```
The partitions are under "./Results/02 Bootstrapped Iterations/Partitions & Guess Results.mat" under the ```vstBootstrapPartitions``` variable.

Folders containing this data are denoted in the folder name by "[HAS DATA]", for example "./2_MachineLearningByROI/20mm sphere/5 Random forest [HAS DATA]"

## 2. Code
Whenever a folder contains Experiment.m, it is an "experiment folder" that must be run as following. In MATLAB, change directory to the folder of interest and type ```Experiment.Run()``` in the command prompt then hit Enter. The results will be produced in a time-stamped copy of the folder.
For this to work, the paths in datapath.txt should have the exact path to the correct directory/file on your computer.


note that CF = inter-feature Correlation Filter and VF = Volume correlation Filter
