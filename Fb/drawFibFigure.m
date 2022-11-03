function Data = drawFibFigure(Path, options)
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
    options.baseline_mode {mustBeMember(options.baseline_mode, ["whole", "trial", "mix"])} = "mix";
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
    
    options.draw_total_result logical = true; % if false, only draw the signal from each trial.
    options.extinction_trials_per_graph (1,1) double = 6; % number of trials to plot in one graph in Extinction data.
    options.draw_ribbon_result logical = true;
    options.disable_detrending = false
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
Data = processFibData(Data,...
    'verbose', options.verbose,...
    'timewindow', options.timewindow,...
    'us_offset', options.us_offset,...
    'baseline_correction', options.baseline_correction,...
    'baseline_mode', options.baseline_mode,...
    'baseline_trial_duration', options.baseline_trial_duration,...
    'baseline_trial_ignore_duration', options.baseline_trial_ignore_duration,...
    'baseline_whole_duration', options.baseline_whole_duration,...
    'baseline_whole_ignore_duration', options.baseline_whole_duration,...
    'baseline_mix_duration', options.baseline_mix_duration,...
    'baseline_mix_ignore_duration', options.baseline_mix_ignore_duration,...
    'filter', options.filter,...
    'disable_detrending', options.disable_detrending);


%% Set values according to exp_type
if exp_type == "Extinction"
    % number of figures
    numSubFigure = Data.numTrial / options.extinction_trials_per_graph;
    if rem(Data.numTrial, options.extinction_trials_per_graph) ~= 0
        error('drawFibFigure : %d trials can not be divided by %d', Data.numTrial, options.extinction_trials_per_graph);
    end

    % mean trial data
    data2plot = ...
        squeeze(...
            mean(...
                reshape(Data.processedData, [], options.extinction_trials_per_graph, numSubFigure) ... % mean by 2nd dimention
                , 2)...
            );
    % cs times
    cs_times = repmat([0, diff(Data.cs(1,:))], numSubFigure, 1); % beware. only CS duration from the first trial is used.
else
    % data
    data2plot = Data.processedData;

    % number of figures
    numSubFigure = Data.numTrial;
    
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
        windowStartIndex = round(options.timewindow(1) * Data.fs);
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
    plot(linspace(windowInSeconds(1), windowInSeconds(2), windowIndexLength), data2plot,...
        'Color', [0.7, 0.7, 0.7],...
        'LineWidth', 0.5,...
        'LineStyle', ':');

    % Draw trial data
    if options.draw_total_result
        plot(linspace(windowInSeconds(1), windowInSeconds(2), windowIndexLength), data2plot(:,subfigure),...
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
        tl = title('\Delta F / F (%)');
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


%% Create a figure for ribbon plot
if options.draw_ribbon_result == false
    return
end
figure(...
    'Name', sprintf("Ribbon %s : %s - %s", exp_type, exp_info.exp_subject, exp_info.exp_date),...
    'Position', [180, 340, 1300, 500]);
axis = subplot(1,1,1);
hold on;
axis.View = [ 66.5195   42.8032];

%% Prepare Dataset

windowStartIndex = round(options.timewindow(1) * Data.fs);
windowEndIndex = windowStartIndex + windowIndexLength - 1;
windowInSeconds = [windowStartIndex, windowEndIndex] ./ Data.fs;

ribbons = ribbon(linspace(windowInSeconds(1), windowInSeconds(2), windowIndexLength), data2plot);
cdata = jet(numSubFigure);
for subfigure = 1 : numSubFigure
    ribbons(subfigure).LineStyle = 'none';
    ribbons(subfigure).FaceColor = cdata(subfigure,:);
end

axis_x = xlim();
axis_y = ylim();
axis_z = zlim();
grid on;
xlabel('Trials');
ylabel('Time(s)');
zlabel('\Delta');
axis.XTickLabel{1} = "";
axis.XTickLabel{end} = "";

% Draw CS US Area
cs_times = [0, diff(Data.cs(1,:))]; % beware. only CS duration from the first trial is used.
fill3(...
    [axis_x(1), axis_x(1), axis_x(1), axis_x(1)],...
    [cs_times(1), cs_times(2), cs_times(2), cs_times(1)],...
    [axis_z(1), axis_z(1), axis_z(2), axis_z(2)],...
    [69, 184, 220] ./ 255,...
    'FaceAlpha', 0.1,...
    'LineStyle', '-',...
    'EdgeAlpha', 0.1);
fill3(...
    [axis_x(2), axis_x(2), axis_x(2), axis_x(2)],...
    [cs_times(1), cs_times(2), cs_times(2), cs_times(1)],...
    [axis_z(1), axis_z(1), axis_z(2), axis_z(2)],...
    [69, 184, 220] ./ 255,...
    'FaceAlpha', 0.1,...
    'LineStyle', '-',...
    'EdgeAlpha', 0.1);
fill3(...
    [axis_x(1), axis_x(1), axis_x(2), axis_x(2)],...
    [cs_times(1), cs_times(2), cs_times(2), cs_times(1)],...
    [axis_z(2), axis_z(2), axis_z(2), axis_z(2)],...
    [69, 184, 220] ./ 255,...
    'FaceAlpha', 0.1,...
    'LineStyle', '-',...
    'EdgeAlpha', 0.1);
fill3(...
    [axis_x(1), axis_x(1), axis_x(2), axis_x(2)],...
    [cs_times(1), cs_times(2), cs_times(2), cs_times(1)],...
    [axis_z(1), axis_z(1), axis_z(1), axis_z(1)],...
    [69, 184, 220] ./ 255,...
    'FaceAlpha', 0.1,...
    'LineStyle', '-',...
   	'EdgeAlpha', 0.1);
fill3(...
    [axis_x(1), axis_x(1), axis_x(2), axis_x(2)],...
    [cs_times(1), cs_times(1), cs_times(1), cs_times(1)],...
    [axis_z(1), axis_z(2), axis_z(2), axis_z(1)],...
    [69, 184, 220] ./ 255,...
    'FaceAlpha', 0.1,...
    'LineStyle', '-',...
    'EdgeAlpha', 0.1);
fill3(...
    [axis_x(1), axis_x(1), axis_x(2), axis_x(2)],...
    [cs_times(2), cs_times(2), cs_times(2), cs_times(2)],...
    [axis_z(1), axis_z(2), axis_z(2), axis_z(1)],...
    [69, 184, 220] ./ 255,...
    'FaceAlpha', 0.1,...
    'LineStyle', '-',...
    'EdgeAlpha', 0.1);

if exp_type == "Conditioning"
    us_color = [1, 0, 0];
    fill3(...
        [axis_x(1), axis_x(1), axis_x(1), axis_x(1)],...
        [cs_times(2) - options.us_offset, cs_times(2), cs_times(2), cs_times(2) - options.us_offset],...
        [axis_z(1), axis_z(1), axis_z(2), axis_z(2)],...
        us_color,...
        'FaceAlpha', 0.1,...
        'LineStyle', '-',...
        'EdgeAlpha', 0.1);
    fill3(...
        [axis_x(2), axis_x(2), axis_x(2), axis_x(2)],...
        [cs_times(2) - options.us_offset, cs_times(2), cs_times(2), cs_times(2) - options.us_offset],...
        [axis_z(1), axis_z(1), axis_z(2), axis_z(2)],...
        us_color,...
        'FaceAlpha', 0.1,...
        'LineStyle', '-',...
        'EdgeAlpha', 0.1);
    fill3(...
        [axis_x(1), axis_x(1), axis_x(2), axis_x(2)],...
        [cs_times(2) - options.us_offset, cs_times(2), cs_times(2), cs_times(2) - options.us_offset],...
        [axis_z(2), axis_z(2), axis_z(2), axis_z(2)],...
        us_color,...
        'FaceAlpha', 0.1,...
        'LineStyle', '-',...
        'EdgeAlpha', 0.1);
    fill3(...
        [axis_x(1), axis_x(1), axis_x(2), axis_x(2)],...
        [cs_times(2) - options.us_offset, cs_times(2), cs_times(2), cs_times(2) - options.us_offset],...
        [axis_z(1), axis_z(1), axis_z(1), axis_z(1)],...
        us_color,...
        'FaceAlpha', 0.1,...
        'LineStyle', '-',...
   	    'EdgeAlpha', 0.1);
    fill3(...
        [axis_x(1), axis_x(1), axis_x(2), axis_x(2)],...
        [cs_times(2) - options.us_offset, cs_times(2) - options.us_offset, cs_times(2) - options.us_offset, cs_times(2) - options.us_offset],...
        [axis_z(1), axis_z(2), axis_z(2), axis_z(1)],...
        us_color,...
        'FaceAlpha', 0.1,...
        'LineStyle', '-',...
        'EdgeAlpha', 0.1);
    fill3(...
        [axis_x(1), axis_x(1), axis_x(2), axis_x(2)],...
        [cs_times(2), cs_times(2), cs_times(2), cs_times(2)],...
        [axis_z(1), axis_z(2), axis_z(2), axis_z(1)],...
        us_color,...
        'FaceAlpha', 0.1,...
        'LineStyle', '-',...
        'EdgeAlpha', 0.1);
end
legend(ribbons);
end
