function processedData = processFibData(Data, options)
%% processFibData
% @Knoblesse 2022
% Process Fiber data according to selected options
% Path : string path to the tank

%% Input Parameters
arguments
    Data;
    options.verbose logical = true; % if false, print no output.
    options.timewindow (1,2) double = [-5, 20]; % draw graph `timewindow(1)` seconds from CS to `timewindow(2)` seconds from CS.
    options.us_offset (1,1) double = 2.5; % US starts `usoffset` seconds before the CS ends.
    options.baseline_correction {mustBeMember(options.baseline_correction, ["z", "zero", "none"])} = "none"
        % Decide how to correct baseline.
        % if z, use zscore method.
        % if zero, subtract mean baseline to move signal to zero.
        % if none, no baseline correction.
    options.baseline_mode {mustBeMember(options.baseline_mode, ["whole", "trial"])} = "trial";
        % Decide how to collect baseline.
        % If whole, get baseline from the beginning of the session.
        %   Ignore first `baseline_whole_ignore_duration` seconds of the data, and use 
        %   `baseline_duration` seconds as baseline. 
        %   For example, if `baseline_whole_ignore_duration` is set as 30, and `baseline_duration` 
        %   is set as 60, session's 30 sec ~ 90 sec data will be used as the baseline.
        % if trial, for each trial, use `baselineduration` seconds from the `timewindow(1)` as the 
            % baseline. Not from the CS, it's from the timewindow.
    options.baseline_duration (1,1) double;% length of the signal in second to use as the baseline
    options.baseline_whole_ignore_duration (1,1) double = 30;
        % Length of the signal to ignore when using whole baseline mode.
        %   Since the signal from the very beginning tend to fluctuate a lot, sufficient value is
        %   necessary.
end

if options.verbose
    if options.baseline_correction ~= "none"
        fprintf('processFibData : Baseline correction is used.\n');
        fprintf('processFibData : Baseline selection method : %s\n', options.baseline_mode);
    else
        fprintf('processFibData : No baseline correction is used.\n');
    end
end

%% Experiment variables
numTrial = size(Data.cs, 1);

windowIndexLength = round(diff(options.timewindow) * Data.fs); % the length of all "IndexLength" is 1/Data.fs
baselineIndexLength = round(options.baseline_duration * Data.fs);

processedData = zeros(windowIndexLength, numTrial);

%% Matrix for baseline data
if options.baseline_correction ~= "none"
    if options.baseline_mode == "whole"
        baseline = Data.delta(...
            round(options.baseline_whole_ignore_duration * Data.fs) : ...
            round(...
                (options.baseline_whole_ignore_duration + options.baseline_duration) * Data.fs)...
            );
        baseline_mean = ones(numTrial, 1) * mean(baseline);
        baseline_std = ones(numTrial, 1) * std(baseline);
    elseif options.baseline_mode == "trial"
        baseline_mean = zeros(numTrial,1);
        baseline_std = zeros(numTrial, 1);
    end
end

%% Calculate data
for trial = 1 : numTrial
    % Calculate Time 
    windowStartIndex = round((Data.cs(trial,1) + options.timewindow(1)) * Data.fs);
    windowEndIndex = windowStartIndex + windowIndexLength - 1;
    delta_data = Data.delta(windowStartIndex : windowEndIndex);
    
    % Caculate baseline for trial mode
    if options.baseline_mode == "trial"
        baseline_mean(trial) = mean(delta_data(1:baselineIndexLength));
        baseline_std(trial) = std(delta_data(1:baselineIndexLength));
    end    
    
    % Correct baseline
    if options.baseline_correction == "z"
        delta_data = (delta_data - baseline_mean(trial)) ./ baseline_std(trial);
    elseif options.baseline_correction == "zero"
        delta_data = delta_data - baseline_mean(trial);
    end

    processedData(:, trial) = delta_data';
end

end