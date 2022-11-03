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
    options.baseline_mode {mustBeMember(options.baseline_mode, ["whole", "trial", "mix"])} = "trial";
        % Decide how to collect baseline.
        % If whole, get baseline from the beginning of the session.
        %   Ignore first `baseline_whole_ignore_duration` seconds of the data, and use 
        %   `baseline_duration` seconds as baseline. 
        %   For example, if `baseline_whole_ignore_duration` is set as 30, and `baseline_duration` 
        %   is set as 60, session's 30 sec ~ 90 sec data will be used as the baseline.
        % If trial, for each trial, use `baselineduration` seconds from the `timewindow(1)` as the 
        %   baseline. Not from the CS, it's from the timewindow.
        % If mix, mean value for baseline correction is collected by "trial" manner", 
        %   and std is collected from the beginning of the session as "whole" option. 
    % baseline duration : duration of baseline to use
    % baseline ignore duration : ignore this amount of time from the first baseline time
    options.baseline_trial_duration (1,1) double = 1;
    options.baseline_trial_ignore_duration (1,1) double = 0;
    options.baseline_whole_duration (1,1) double = 60;
    options.baseline_whole_ignore_duration (1,1) double = 30;
    options.baseline_mix_duration (1,2) double = [1, 60]; % [trial based mean, whole based std]
    options.baseline_mix_ignore_duration (1,2) double = [0, 30]; % [trial based mean, whole based std]
    options.filter (1,1) {double, mustBeNonnegative} = 0;
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

processedData = zeros(windowIndexLength, numTrial);

%% Matrix for baseline data
if options.baseline_mode == "whole"
    % compute baseline mean and std beforehead
    baseline = Data.delta(...
        round(options.baseline_whole_ignore_duration * Data.fs) : ...
        round((options.baseline_whole_ignore_duration + options.baseline_whole_duration) * Data.fs)...
        );
    init_mean = mean(baseline);
    init_std = std(baseline);
elseif options.baseline_mode == "mix"
    % calculate the std from the beginning of the experiment
    baseline = Data.delta(...
        round(options.baseline_mix_ignore_duration(2) * Data.fs) : ...
        round((options.baseline_mix_ignore_duration(2) + options.baseline_mix_duration(2)) * Data.fs)...
        );
    init_std = ones(numTrial, 1) * std(baseline);
end

%% Calculate data
for trial = 1 : numTrial
    % Calculate Time 
    windowStartIndex = round((Data.cs(trial,1) + options.timewindow(1)) * Data.fs);
    windowEndIndex = windowStartIndex + windowIndexLength - 1;
    delta_data = Data.delta(windowStartIndex : windowEndIndex);
    
    % Caculate baseline for trial and mix mode
    if options.baseline_mode == "whole"
        baseline_mean = init_mean;
        baseline_std = init_std;
    elseif options.baseline_mode == "trial"
        baseline = delta_data(...
            round(options.baseline_trial_ignore_duration * Data.fs)+1 : ...
            round((options.baseline_trial_ignore_duration + options.baseline_trial_duration) * Data.fs)...
            );
        baseline_mean = mean(baseline);
        baseline_std = std(baseline);
    elseif options.baseline_mode == "mix"
        baseline = delta_data(...
            round(options.baseline_mix_ignore_duration(1) * Data.fs)+1 : ...
            round((options.baseline_mix_ignore_duration(1) + options.baseline_mix_duration(1)) * Data.fs)...
            );
        baseline_mean = mean(baseline);
        baseline_std = init_std;
    end
    
    % Correct baseline
    if options.baseline_correction == "z"
        delta_data = (delta_data - baseline_mean(trial)) ./ baseline_std(trial);
    elseif options.baseline_correction == "zero"
        delta_data = delta_data - baseline_mean(trial);
    end
    
    % Filter 
    if options.filter > 0
        delta_data = movmean(delta_data, options.filter * Data.fs);
    end
    processedData(:, trial) = delta_data';
end

end
