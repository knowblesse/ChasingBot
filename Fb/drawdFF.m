function drawdFF(Data, exp_type, extinction_trials_per_graph, us_offset, options)
%% drawdFF
% Draw multiple dFF figures
arguments
    Data;
    exp_type;
    extinction_trials_per_graph;
    us_offset;
    options.figureName = "my figure";
end

%% Set values according to exp_type
if exp_type == "Extinction"
    % number of figures
    numSubFigure = Data.numTrial / extinction_trials_per_graph;
    if rem(Data.numTrial, extinction_trials_per_graph) ~= 0
        error('drawFibFigure : %d trials can not be divided by %d', Data.numTrial, extinction_trials_per_graph);
    end

    % mean trial data
    data2plot = ...
        squeeze(...
            mean(...
                reshape(Data.processedData, [], extinction_trials_per_graph, numSubFigure) ... % mean by 2nd dimention
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
    'Name', options.figureName,...
    'Position', [180, 500, 1600, 300]);

global_ylim = [inf, -inf];

%% Draw data
windowIndexLength = round(diff(Data.timewindow) * Data.fs); % the length of all "IndexLength" is 1/Data.fs
for subfigure = 1 : numSubFigure
    % Calculate Time 
    if exp_type == "Extinction"
        windowStartIndex = round(Data.timewindow(1) * Data.fs);
        windowEndIndex = windowStartIndex + windowIndexLength - 1;
        windowInSeconds = [windowStartIndex, windowEndIndex] ./ Data.fs;
    else
        windowStartIndex = round((Data.cs(subfigure,1) + Data.timewindow(1)) * Data.fs);
        windowEndIndex = windowStartIndex + windowIndexLength - 1;
        windowInSeconds = [windowStartIndex, windowEndIndex] ./ Data.fs;
    end
    
    if exp_type == "Conditioning"
        us_time = [cs_times(subfigure,2) - us_offset, cs_times(subfigure,2)];
    else
        us_time = [0,0];
    end

    ax = subplot(1, numSubFigure, subfigure);
    plotdFF(...
        linspace(windowInSeconds(1), windowInSeconds(2), windowIndexLength),...
        data2plot(:, subfigure),...
        cs_times(subfigure,:),...
        us_time,...
        ax);

    % Labels
    if Data.baseline_correction == "z"
        tl = title('\Delta F / F (z score)');
        ylabel('Z');
    elseif Data.baseline_correction == "zero"
        tl = title('\Delta F / F (baseline to zero)');
    else
        tl = title('\Delta F / F (%)');
    end

    if exp_type == "Extinction"
        tl.String = strcat(tl.String, ...
            sprintf(" - Trial %d-%d",...
                extinction_trials_per_graph * (subfigure-1)+1, extinction_trials_per_graph * subfigure)...
                );
    end

    % Axis setup
    ylim_ = ylim();
    global_ylim = [...
        min(global_ylim(1), ylim_(1)),...
        max(global_ylim(2), ylim_(2))...
        ];
end

%% Match all ylims
for subfigure = 1 : numSubFigure
    subplot(1,numSubFigure, subfigure);
    ylim(global_ylim);
end
