%% DrawTwoGraphs
% Script for drawing two graphs

DELPath = uigetdir('D:\mydata\FPMdata\fiber photometry recording');
IMMPath = uigetdir('D:\mydata\FPMdata\fiber photometry recording');

Data_del = loadFibData(DELPath);
Data_imm = loadFibData(IMMPath);

Data_del = processFibData(Data_del, ...
    'timewindow', [-5, 15], ...
    'baseline_correction', "z", ...
    'baseline_mode', "mix", ...
    'baseline_mix_duration', [5, 90], ...
    'baseline_mix_ignore_duration', [0, 60], ...
    'filter', 0.5, ...
    'initial_artifact_remove_time', 30 ...
    );
Data_imm = processFibData(Data_imm, ...
    'timewindow', [-5, 15], ...
    'baseline_correction', "z", ...
    'baseline_mode', "mix", ...
    'baseline_mix_duration', [5, 90], ...
    'baseline_mix_ignore_duration', [0, 60], ...
    'filter', 0.5, ...
    'initial_artifact_remove_time', 30 ...
    );
 
%% Set values according to exp_type

del_m = mean(Data_del.processedData, 2);
del_s = std(Data_del.processedData, 0, 2) ./ 30^0.5;
imm_m = mean(Data_imm.processedData,2);
imm_s = std(Data_imm.processedData, 0, 2) ./ 30^0.5;


%% Create a figure
figure(...
    'Name', 'Two Grpahs1',...
    'Position', [180, 500, 676, 300]);
ax = subplot(1,1,1);
hold on;
%% Draw data
timewindow = [-5, 15];
cs_times = [0, diff(Data_imm.cs(1,:))];
windowIndexLength = round(diff(timewindow) * Data_del.fs); % the length of all "IndexLength" is 1/Data.fs

% Calculate Time 
windowStartIndex = round(timewindow(1) * Data_del.fs);
windowEndIndex = windowStartIndex + windowIndexLength - 1;
windowInSeconds = [windowStartIndex, windowEndIndex] ./ Data_del.fs;

% Draw CS Area
fill([cs_times(1), cs_times(2), cs_times(2), cs_times(1)],...
    [-100, -100, 100, 100],...
    [69, 184, 220] ./ 255,...
    'FaceAlpha', 0.3,...
    'LineStyle', 'None');

% Reduce number of points (too many points result error in AI)
xvalues = linspace(windowInSeconds(1), windowInSeconds(2), windowIndexLength);
xvalues = xvalues(1:20:end);
del_m = del_m(1:20:end);
del_s = del_s(1:20:end);
imm_m = imm_m(1:20:end);
imm_s = imm_s(1:20:end);

addShade(xvalues, del_m, del_s, [160, 0, 0]./255);
addShade(xvalues, imm_m, imm_s, [0, 0, 128]./255);

% Draw Result
ax1 = plot(xvalues, del_m,...
    'Color', [160, 0, 0]./255,...
    'LineWidth', 2);

ax2 = plot(xvalues, imm_m,...
    'Color', [0, 0, 128]./255,...
    'LineWidth', 2);

% Labels
tl = title('\Delta F / F (z score)');
ylabel('Z score \Delta F / F');

% Axis setup
xlim(windowInSeconds);
ylim([-1.5, 2.9])
xlabel('Time');

ax.LineWidth = 2;
ax.FontSize = 12;

% legend
legend([ax1, ax2], ["DEL", "IMM"],'Location','northwest');


