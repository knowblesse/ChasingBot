%% BatchStatScript
% Script for batch running other scripts or functions

basePath = uigetdir('D:\mydata\fpdata');

filelist = dir(basePath);
sessionPaths = regexp({filelist.name},'[^.].*','match');
sessionPaths = sessionPaths(~cellfun('isempty',sessionPaths));
fprintf('%d sessions detected.\n', numel(sessionPaths));

numSession = numel(sessionPaths);
outputTable = table(strings(numSession,1), zeros(numSession,1), zeros(numSession,1), 'VariableNames',["Session", "dFF", "AUC"]);

% Session
for session = 1 : numel(sessionPaths)
    TANK_name = cell2mat(sessionPaths{session});
    TANK_location = char(strcat(basePath, filesep, TANK_name));
    %% Load Data
    Data = loadFibData(TANK_location);
    
    %% Preprocess Data
    Data = processFibData(Data, ...
        'timewindow', [-5, 20], ...
        'us_offset', 2.5, ...
        'baseline_correction', "z", ...
        'baseline_mode', "mix", ...
        'baseline_mix_duration', [1, 60], ...
        'baseline_mix_ignore_duration', [0, 60], ...
        'filter', 0, ...
        'initial_artifact_remove_time', 30 ...
        );
    
    %% Get Mean Activation
    [dFF, AUC] = getMeanActivation(Data, [7.5, 10]);

    %% Input
    outputTable.Session(session) = TANK_name;
    outputTable.dFF(session) = dFF;
    outputTable.AUC(session) = AUC;

end
fprintf('DONE\n');
clearvars -except outputTable






