function drawFibFigure(Path, options)
%% drawFigure
% @Knoblesse 2022
% Select Tank to open, and gather draw figure
% Path : string path to the tank

%% Input Parameters
arguments
    Path {mustBeText} = "";
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
    options.draw_total_result logical = true; % if false, only draw the signal from each trial.
    options.extinction_trials_per_graph (1,1) double = 6; % number of trials to plot in one graph in Extinction data.
    
end

% default values for baseline_duration
if options.baseline_mode == "whole"
    options.baseline_duration = 60;
elseif options.baseline_mode == "trial"
    options.baseline_duration = 1; 
end

if options.verbose
    if options.baseline_correction ~= "none"
        fprintf('drawFibFigure : Baseline correction is used.\n');
        fprintf('drawFibFigure : Baseline selection method : %s\n', options.baseline_mode);
    else
        fprintf('drawFibFigure : No baseline correction is used.\n');
    end
end

%% Load Data 
Data = loadFibData(Path, 'verbose', options.verbose);
exp_type = autoDetectExpType(Data.path);
if options.verbose
    fprintf('drawFibFigure : Data loaded.\n');
end

%% Parse Exp Data
exp_info = regexp(Data.path, '.*\.*-(?<exp_date>\d{6})-\d{6}_(?<exp_subject>.*)_.*', 'names');

if isempty(exp_info.exp_subject) || isempty(exp_info.exp_date)
    warning('drawConfFigure : Can not parse the Tank name.');
    exp_info.exp_subject = 'Unknown Subject';
    exp_info.exp_date = '??/??';
else
    if options.verbose
        fprintf('drawFibFigure : Experiment info parsed from the Tank name.\n');
        fprintf('            └Subject : %s\n', exp_info.exp_subject);
        fprintf('            └Date : %s\n', exp_info.exp_date);
    end
end

%% Create a figure
fig = figure(...
    'Name', sprintf("%s : %s - %s", exp_type, exp_info.exp_subject, exp_info.exp_date),...
    'Position', [180, 500, 1600, 300]);

%% Experiment variables
numTrial = size(Data.cs, 1);

% check if num CS can be divided by extinction_trials_per_graph value 
if exp_type == "Extinction"
    if rem(numTrial, options.extinction_trials_per_graph) ~= 0
        error('drawFibFigure : %d trials can not be divided by %d', numTrial, options.extinction_trials_per_graph);
    end
end

windowIndexLength = round(diff(options.timewindow) * Data.fs); % the length of all "IndexLength" is 1/Data.fs
baselineIndexLength = round(options.baseline_duration * Data.fs);

wholeTrialData = zeros(windowIndexLength, numTrial);
global_ylim = [inf, -inf];

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

    wholeTrialData(:, trial) = delta_data';
end

%% Set values according to exp_type
if exp_type == "Extinction"
    % number of figures
    numSubFigure = numTrial / options.extinction_trials_per_graph;
    % mean trial data
    wholeTrialData = ...
        squeeze(...
            mean(...
                reshape(wholeTrialData, [], options.extinction_trials_per_graph, numSubFigure) ... % mean by 2nd dimention
                , 2)...
            );
    % cs times
    cs_times = repmat([0, diff(Data.cs(1,:))], numSubFigure, 1); % beware. only CS duration from the first trial is used.
else
    % number of figures
    numSubFigure = numTrial;
    
    % cs times
    cs_times = Data.cs;
end

%% Draw data

for subfigure = 1 : numSubFigure
    % Calculate Time 
    if exp_type == "Extinction"
        windowStartIndex = round(-5 * Data.fs);
        windowEndIndex = windowStartIndex + windowIndexLength - 1;
        windowInSeconds = [windowStartIndex, windowEndIndex] ./ Data.fs;
    else
        windowStartIndex = round((Data.cs(subfigure,1) + options.timewindow(1)) * Data.fs);
        windowEndIndex = windowStartIndex + windowIndexLength - 1;
        windowInSeconds = [windowStartIndex, windowEndIndex] ./ Data.fs;
    end

    % Draw 
    subplot(1,numSubFigure,subfigure);
    hold on;
    plot(linspace(windowInSeconds(1), windowInSeconds(2), windowIndexLength), wholeTrialData,...
        'Color', [0.8, 0.8, 0.8],...
        'LineWidth', 0.5,...
        'LineStyle', ':');

    % Draw other trial data
    if options.draw_total_result
        plot(linspace(windowInSeconds(1), windowInSeconds(2), windowIndexLength), wholeTrialData(:,subfigure),...
            'Color', [0.1294, 0.7647, 0.4253],...
            'LineWidth', 1.2);
    end

    % Labels
    if options.baseline_correction == "z"
        tl = title('\Delta F / F (z score)');
        ylabel('Z');
    elseif options.baseline_correction == "zero"
        tl = title('\Delta F / F (baseline to zero)');
    else
        tl = title('\Delta F / F');
    end

    if exp_type == "Extinction"
        tl.String = strcat(tl.String, ...
            sprintf(" - Trial %d-%d",...
                options.extinction_trials_per_graph * (subfigure-1)+1, options.extinction_trials_per_graph * subfigure)...
                );
    end

    % Axis setup
    xlim(windowInSeconds);
    ylim_ = ylim();
    global_ylim = [...
        min(global_ylim(1), ylim_(1)),...
        max(global_ylim(2), ylim_(2))...
        ];

    % Draw CS US Area
    fill([cs_times(subfigure,1), cs_times(subfigure,2), cs_times(subfigure,2), cs_times(subfigure,1)],...
        [-100, -100, 100, 100],...
        'b',...
        'FaceAlpha', 0.1,...
        'LineStyle', 'None');
    
    if exp_type == "Conditioning"
        fill([cs_times(subfigure,2) - options.us_offset, cs_times(subfigure,2), cs_times(subfigure,2), cs_times(subfigure,2) - options.us_offset],...
            [-100, -100, 100, 100],...
            'r',...
            'FaceAlpha', 0.1,...
            'LineStyle', 'None');
    end
end

%% Match all ylims
for subfigure = 1 : numSubFigure
    subplot(1,numSubFigure, subfigure);
    ylim(global_ylim);
end

end
