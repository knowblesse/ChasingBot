function [ax, l] = plotdFF(timevector, Data, cs_time, us_time, ax, options)
%% plotdFF
% Draw single dFF graph
% Data can either be n x 1 or n x t.
%   n x 1 : draw a single line
%   n x t : draw a single line using the mean(Data,2) value.
arguments
    timevector (1,:) double;
    Data double;
    cs_time (1,2) double;
    us_time (1,2) double = [0, 0];
    ax = [];
    options.LineColor = [64,75,150]./255;
end

% Setup Axis
if isempty(ax)
    ax = gca();
end
hold(ax, "on");

% Draw Trial data
if size(Data,2) == 1
    l = plot(ax, timevector, Data,...
        'Color', options.LineColor,...
        'LineWidth', 1.2);
else
    [~, l, ~] = shadeplot(timevector, Data', 'SD', 'sd', 'Color', options.LineColor, 'LineWidth', 1.2, 'ax', ax);
end

% Axis setup
xlim(ax, [timevector(1), timevector(end)]);
ylim_ = ylim(ax);

% Draw CS US Area
fill(ax, [cs_time(1), cs_time(2), cs_time(2), cs_time(1)],...
    [-100, -100, 100, 100],...
    [69, 184, 220] ./ 255,...
    'FaceAlpha', 0.1,...
    'LineStyle', 'None');

if all(us_time ~=0)
    fill(ax, [us_time(1), us_time(2), us_time(2), us_time(1)],...
        [-100, -100, 100, 100],...
        'r',...
        'FaceAlpha', 0.1,...
        'LineStyle', 'None');
end

ylim(ax, ylim_);
end

