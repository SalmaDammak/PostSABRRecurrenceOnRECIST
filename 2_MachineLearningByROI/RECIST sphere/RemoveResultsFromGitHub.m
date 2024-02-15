path = 'E:\Users\sdammak\Repos\PostSABRRecurrenceOnRECIST\';
a = dir([path, '\*\*\Results.zip']);
for row = 1:length(a)

    delete([a(row).folder, '\Results.zip'])
    mkdir([a(row).folder, '\Results'])

end