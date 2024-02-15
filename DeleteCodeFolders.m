path = 'E:\Users\sdammak\Repos\PostSABRRecurrenceOnRECIST\5_FeatureAnalysis';
a = dir([path, '\*\Code.zip']);
for row = 1:length(a)

    delete([a(row).folder, '\Code.zip'])

end