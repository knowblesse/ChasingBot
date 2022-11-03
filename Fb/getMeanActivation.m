function [dFF, AUC] = getMeanActivation(Data, timewindow, trials)
arguments
    Data;
    timewindow;
    trials = [];
end

if isempty(trials)
    trials = 1:Data.numTrial;
end


%% Get Data
processedData = Data.processedData;
% row : time, column : trials

%% Get time window
windowStartIndex = (timewindow(1) - Data.timewindow(1)) * Data.fs;
windowIndexLength = round(diff(timewindow) * Data.fs);
windowEndIndex = windowStartIndex + windowIndexLength - 1;

%% Plot mean signal
figure('Name', 'Mean Activation');
subplot(1,1,1);
hold on;
plot(linspace(Data.timewindow(1), Data.timewindow(2), size(processedData,1)), mean(processedData(:, trials), 2));
global_ylim = ylim();
fill([timewindow, fliplr(timewindow)],...
    [-100, -100, 100, 100],...
    [69, 184, 220] ./ 255,...
    'FaceAlpha', 0.1,...
    'LineStyle', 'None');
ylim(global_ylim);

%% Mean Trial
meanProcessedData = mean(processedData(windowStartIndex : windowEndIndex, trials), 2);

%% dFF during timewindow
dFF = mean(meanProcessedData);

%% AUC during timewindow
AUC = sum(meanProcessedData) * (1/Data.fs);

end
