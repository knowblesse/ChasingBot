%% FiberPhotometryScripts
% @Knoblesse 2022
 
 
%% Load TDT data
data = TDTbin2mat('D:\Data\FiberPhotometry\FPM220808\ToneFib-220811-095218-retS');
 
CSON = data.epocs.CSON.onset;
CSOF = data.epocs.CSOF.onset;
fs = data.streams.x405C.fs;
 
if size(CSON, 1) == size(CSOF, 1)
    CS = [CSON, CSOF];
    numTrial = size(CS,1);
else
    error('CS Size mismatch!');
end
fprintf('Total CS : %d\n', size(CS,1));
 
figure('Position', [100, 859, 1083, 120]);
subplot(1,1,1);
hold on;
 
for trial = 1 : numTrial
    fill(...
        [CS(trial,1), CS(trial, 2), CS(trial, 2), CS(trial, 1)],...
        [0, 0, 1, 1],...
        'b',...
        'FaceAlpha', 0.3,...
        'LineStyle', 'None');
end
 
clearvars -except CS data numTrial fs
 
%% Draw CS aligned Data
TIMEWINDOW = [-5, 20];
USoffset = 2.5; % sec. US starts <USoffset>seconds before CS ends.
BaselineDuration = 1; % sec. use the first <BaselineDuration> sec as baseline
figure(2);
clf;
 
wholeTrialData = cell(numTrial,1);
ylim_1 = [inf, -inf];
ylim_2 = [inf, -inf];
ylim_3 = [inf, -inf];
ylim_4 = [inf, -inf];

% Draw Data
for trial = 1 : numTrial
    timeRange = TIMEWINDOW + CS(trial,1);
    timeRangeIndex = round(timeRange * fs);
    timeRangeSeconds =(timeRangeIndex(1) : timeRangeIndex(2)) ./ fs;
 
    % data2plot
    x465C_data = data.streams.x465C.data(timeRangeIndex(1) : timeRangeIndex(2));
    x405C_data = data.streams.x405C.data(timeRangeIndex(1) : timeRangeIndex(2));
    deltaF_data = (x465C_data - x405C_data) ./ x405C_data;
    baseline = mean(deltaF_data(1:round(BaselineDuration*fs)));
    deltaF_data_bc = deltaF_data - baseline;
    wholeTrialData{trial} = deltaF_data;
 
    % x465C
    subplot(4,numTrial,trial);
    title(strcat('Trial ', num2str(trial)));
    hold on;
    plot(timeRangeSeconds, x465C_data);
    ylabel('x465C');
    xlim(timeRangeIndex ./ fs);
    ylim_ = ylim();
    ylim_1(1) = min(ylim_1(1), ylim_(1));
    ylim_1(2) = max(ylim_1(2), ylim_(2));
 
    % x405C
    subplot(4,numTrial,numTrial + trial);
    hold on;
    plot(timeRangeSeconds, x405C_data);...
    ylabel('x465C');
    xlim(timeRangeIndex ./ fs);
    ylim_ = ylim();
    ylim_2(1) = min(ylim_2(1), ylim_(1));
    ylim_2(2) = max(ylim_2(2), ylim_(2));
 
    % delta F 
    subplot(4,numTrial, 2*numTrial + trial);
    hold on;
    plot(timeRangeSeconds, deltaF_data);
    title('\Delta F / F');
    xlim([timeRangeSeconds(1), timeRangeSeconds(end)]);
    ylim_ = ylim();
    ylim_3(1) = min(ylim_3(1), ylim_(1));
    ylim_3(2) = max(ylim_3(2), ylim_(2));

    % delta F (baseline corrected)
    subplot(4,numTrial, 3*numTrial + trial);
    hold on;
    plot(timeRangeSeconds, deltaF_data_bc);
    title('\Delta F / F (baseline corrected)');
    xlim([timeRangeSeconds(1), timeRangeSeconds(end)]);
    ylim_ = ylim();
    ylim_4(1) = min(ylim_4(1), ylim_(1));
    ylim_4(2) = max(ylim_4(2), ylim_(2));


end

% Draw CS and US area and match all axis limits
for trial = 1 : numTrial
    timeRange = TIMEWINDOW + CS(trial,1);
    timeRangeIndex = round(timeRange * fs);
    CSRangeIndex = CS(trial,:);
    USRangeIndex = [CS(trial,2)-2.5, CS(trial,2)];

    % x465C
    subplot(4,numTrial,trial);
    fill([CSRangeIndex(1), CSRangeIndex(2), CSRangeIndex(2), CSRangeIndex(1)],...
        [ylim_1(1), ylim_1(1), ylim_1(2), ylim_1(2)],...
        'b',...
        'FaceAlpha', 0.1,...
        'LineStyle', 'None');
 
    fill([USRangeIndex(1), USRangeIndex(2), USRangeIndex(2), USRangeIndex(1)],...
        [ylim_1(1), ylim_1(1), ylim_1(2), ylim_1(2)],...
        'r',...
        'FaceAlpha', 0.1,...
        'LineStyle', 'None');
    ylim(ylim_1);

    % x405C
    subplot(4,numTrial,numTrial + trial);
    fill([CSRangeIndex(1), CSRangeIndex(2), CSRangeIndex(2), CSRangeIndex(1)],...
        [ylim_2(1), ylim_2(1), ylim_2(2), ylim_2(2)],...
        'b',...
        'FaceAlpha', 0.1,...
        'LineStyle', 'None');
 
    fill([USRangeIndex(1), USRangeIndex(2), USRangeIndex(2), USRangeIndex(1)],...
        [ylim_2(1), ylim_2(1), ylim_2(2), ylim_2(2)],...
        'r',...
        'FaceAlpha', 0.1,...
        'LineStyle', 'None');
    ylim(ylim_2);

    % delta F
    subplot(4,numTrial, 2*numTrial + trial);
    fill([CSRangeIndex(1), CSRangeIndex(2), CSRangeIndex(2), CSRangeIndex(1)],...
        [ylim_3(1), ylim_3(1), ylim_3(2), ylim_3(2)],...
        'b',...
        'FaceAlpha', 0.1,...
        'LineStyle', 'None');
 
    fill([USRangeIndex(1), USRangeIndex(2), USRangeIndex(2), USRangeIndex(1)],...
        [ylim_3(1), ylim_3(1), ylim_3(2), ylim_3(2)],...
        'r',...
        'FaceAlpha', 0.1,...
        'LineStyle', 'None');
    ylim(ylim_3);

    % delta F (baseline corrected)
    subplot(4,numTrial, 3*numTrial + trial);
    fill([CSRangeIndex(1), CSRangeIndex(2), CSRangeIndex(2), CSRangeIndex(1)],...
        [ylim_4(1), ylim_4(1), ylim_4(2), ylim_4(2)],...
        'b',...
        'FaceAlpha', 0.1,...
        'LineStyle', 'None');
 
    fill([USRangeIndex(1), USRangeIndex(2), USRangeIndex(2), USRangeIndex(1)],...
        [ylim_4(1), ylim_4(1), ylim_4(2), ylim_4(2)],...
        'r',...
        'FaceAlpha', 0.1,...
        'LineStyle', 'None');
    ylim(ylim_4);
end





%% Meaned deltaF_data
minSize = inf;
for trial = 1 : numTrial
    minSize = min(minSize, size(wholeTrialData{trial},1));
end
 
meanData = zeros(numTrial, meanData);
for trial = 1 : numTrial
    meanData(trial, :) = wholeTrialData{trial}(1:minSize);
end
 
figure(3);
clf;
plot(mean(sumTrial, 1));
line([5, 5] * data.streams.x465C.fs, ylim_dat+0.05, 'Color', 'r');
line([15, 15] * data.streams.x465C.fs, ylim_dat+0.05, 'Color', 'b');
ylim(ylim_dat+0.05);
xlim([0, 25 * data.streams.x465C.fs]);
 
 
%% Extinction
figure(4);
clf;
 
fs = data.streams.x405C.fs;
dat_size = round(25 * fs)+1;
 
data_465 = zeros(numTrial, dat_size);
data_405 = zeros(numTrial, dat_size);
 
 
for trial = 1 : numTrial
    timeRange = [CS(trial,1)-5, CS(trial,1) + 20];
    startPoint = round(timeRange(1) * fs);
    data_465(trial, :) = data.streams.x465C.data(startPoint : startPoint + dat_size-1);
    data_405(trial, :) = data.streams.x405C.data(startPoint : startPoint + dat_size-1);
end
 
 
fff = (data_465 - data_405) ./ data_405;
 
for block = 1 : 6
    subplot(4,6,block);
    plot(mean(data_465(5 * (block - 1) + 1 : 5 * block, :), 1));
    ylims = ylim();
    hold on;
    fill(...
        [5, 15, 15, 5] * fs,...
        [ylims(1), ylims(1), ylims(2), ylims(2)],...
        'b',...
        'FaceAlpha', 0.3,...
        'LineStyle', 'None');
    ylim(ylims);
    title('465 (Signal)');
    drawnow;
    text(0,ylims(2) + 2, strcat("Trial ", num2str(5 * (block-1) + 1), '~', num2str(5 * block)), 'FontSize', 14, 'FontName', 'Noto Sans');
    
    subplot(4,6,6 + block);
    plot(mean(data_405(5 * (block - 1) + 1 : 5 * block, :), 1));
    ylims = ylim();
    hold on;
    fill(...
        [5, 15, 15, 5] * fs,...
        [ylims(1), ylims(1), ylims(2), ylims(2)],...
        'b',...
        'FaceAlpha', 0.3,...
        'LineStyle', 'None');
    ylim(ylims);
    title('405 (Control)');
    
    subplot(4,6,12 + block);
    plot(mean(fff(5 * (block - 1) + 1 : 5 * block, :), 1));
    ylims = [1,1.4];
    hold on;
    fill(...
        [5, 15, 15, 5] * fs,...
    [ylims(1), ylims(1), ylims(2), ylims(2)],...
    'b',...
    'FaceAlpha', 0.3,...
    'LineStyle', 'None');
    ylim(ylims);
    title('\Delta F / F');
    
    % Normalized
    subplot(4,6,18 + block);
    baseline = mean(fff(5 * (block - 1) + 1 : 5 * block, :), 1);
    baseline = mean(baseline(1 : round(5 * fs)));
    plot(mean(fff(5 * (block - 1) + 1 : 5 * block, :), 1) - baseline);
    ylims = [-0.05, 0.1];
    hold on;
    fill(...
         [5, 15, 15, 5] * fs,...
    [ylims(1), ylims(1), ylims(2), ylims(2)],...
    'b',...
    'FaceAlpha', 0.3,...
    'LineStyle', 'None');
    ylim(ylims);
    title('normalized \Delta F / F');
end
