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

%% default values for baseline_duration
if options.baseline_mode == "whole"
    options.baseline_duration = 60;
elseif options.baseline_mode == "trial"
    options.baseline_duration = 1; 
end

%% Load Data 
Data = loadFibData(Path, 'verbose', options.verbose);
exp_type = autoDetectExpType(Data.path);
if options.verbose
    fprintf('drawFibFigure : Data loaded.\n');
end

%% Parse Exp Data
exp_info = regexp(Data.path, '.*\.*-(?<exp_date>\d{6})-\d{6}_(?<exp_subject>.*)_.*', 'names');

if isempty(exp_info)
    warning('drawConfFigure : Can not parse the Tank name.');
    exp_info(1).exp_subject = 'Unknown Subject';
    exp_info(1).exp_date = '??/??';
else
    if options.verbose
        fprintf('drawFibFigure : Experiment info parsed from the Tank name.\n');
        fprintf('            └Subject : %s\n', exp_info.exp_subject);
        fprintf('            └Date : %s\n', exp_info.exp_date);
    end
end

%% Process Data
processedData = processFibData(Data,...
    'verbose', options.verbose,...
    'timewindow', options.timewindow,...
    'us_offset', options.us_offset,...
    'baseline_correction', options.baseline_correction,...
    'baseline_mode', options.baseline_mode,...
    'baseline_duration', options.baseline_duration,...
    'baseline_whole_ignore_duration', options.baseline_whole_ignore_duration);
numTrial = size(processedData,2);


%% Set values according to exp_type
if exp_type == "Extinction"
    % number of figures
    numSubFigure = numTrial / options.extinction_trials_per_graph;
    if rem(numTrial, options.extinction_trials_per_graph) ~= 0
        error('drawFibFigure : %d trials can not be divided by %d', numTrial, options.extinction_trials_per_graph);
    end

    % mean trial data
    processedData = ...
        squeeze(...
            mean(...
                reshape(processedData, [], options.extinction_trials_per_graph, numSubFigure) ... % mean by 2nd dimention
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

%% Create a figure
figure(...
    'Name', sprintf("%s : %s - %s", exp_type, exp_info.exp_subject, exp_info.exp_date),...
    'Position', [180, 500, 1600, 300]);

global_ylim = [inf, -inf];

%% Draw data
windowIndexLength = round(diff(options.timewindow) * Data.fs); % the length of all "IndexLength" is 1/Data.fs
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

    % Draw Other trials
    subplot(1,numSubFigure,subfigure);
    hold on;
    plot(linspace(windowInSeconds(1), windowInSeconds(2), windowIndexLength), processedData,...
        'Color', [0.7, 0.7, 0.7],...
        'LineWidth', 0.5,...
        'LineStyle', ':');

    % Draw trial data
    if options.draw_total_result
        plot(linspace(windowInSeconds(1), windowInSeconds(2), windowIndexLength), processedData(:,subfigure),...
            'Color', [64,75,150]./255,...
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
        [69, 184, 220] ./ 255,...
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
