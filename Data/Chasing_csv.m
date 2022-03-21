%% Chasing_csv


%% Select CSV File
[fname, path] = uigetfile('*.csv', 'Select csv file');
if fname == 0
    error('Canceled');
end

%% Ask the total number of CS
fprintf('Total number of CS? : ');
numTrial = input('');
while isempty(numTrial)
    fprintf('Wrong input\n');
    fprintf('Total number of CS? : ');
    numTrial = input('');
end

%% Load CSV
% time(day) | cs | freezing
data = readmatrix(strcat(path, filesep, fname), 'NumHeaderLines', 1);
time = data(:,1) * 24 * 60 * 60;
time_diff = diff(time); % time difference btw each data entry
cs = data(:,2);
freezing = data(:,3);

clearvars fname path data;

%% Check if there are 5 CSs
if numel(find(diff(cs)==1)) ~= numTrial
    error(strcat("Total number of CS is not ", num2str(numTrial)));
else
    fprintf('Total %d number of CS is recognized\n', numTrial);
end

cs_on_index = find(diff(cs) == 1)+1; % index where the CS changes from 0 to 1. (the value of cs at this index is 1)
cs_off_index = find(diff(cs) == -1)+1; % index where the CS changes from 1 to 0 (the value of cs at this index is 0)

%% Setup Output Data array
output_hab = [];
output_cs_iti = zeros(numTrial, 2);

%% Calculate Habituation Freezing 
output_hab = sum(time_diff(find(freezing(1:cs_on_index(1)-1) == 1)));

%% Calcualte CS & ITI Freezing
for i = 1 : numTrial
    output_cs_iti(i,1) = sum(time_diff(find(freezing(cs_on_index(i):cs_off_index(i)-1) == 1)));
    if i == numTrial
        output_cs_iti(i,2) = sum(time_diff(find(freezing(cs_off_index(i):end) == 1)));
    else
        output_cs_iti(i,2) = sum(time_diff(find(freezing(cs_off_index(i):cs_on_index(i+1)-1) == 1)));
    end
end

clearvars cs* i freezing numTrial time time_diff

%% Print Output
fprintf('+-------------Complete-------------+\n');
fprintf('| Hab Freezing : % 6.2f sec        |\n', output_hab);
fprintf('| Total CS Freezing : % 6.2f sec   |\n', sum(output_cs_iti(:,1)));
fprintf('| Total ITI Freezing : % 6.2f sec |\n', sum(output_cs_iti(:,2)));
fprintf('+----------------------------------+\n');