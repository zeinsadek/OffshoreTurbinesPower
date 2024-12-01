%%% Plot all power curves together

clear; close all; clc;
fprintf('Workspace Cleared... \n')

%%

%%% Inputs
clc;
main_path = '/Volumes/Zein_PIV_3/Power_Results';
setup     = 'WT60_SX50_AG0';
rows      = [1,2,3,4];

%%% Colors
colors = {'#710627', '#EF6461', '#9CE37D', '#8ACDEA'};

%%% Plotting Params
main_marker_size    = 80;
shadow_marker_size  = 10;
shadow_transparency = 0.01;
linewidth           = 3;

ax = figure();
hold on
for i = 1:length(rows)
    data = load(fullfile(main_path, setup, 'Power_Curve', strcat('ROW', num2str(i), '_Power_Curve.mat')));
    data = data.output;

    % Plot all instantaneous power
    scatter(data.TS, data.P, shadow_marker_size, ...
                'filled', 'MarkerFaceColor', colors{i}, 'MarkerFaceAlpha', shadow_transparency, ...
                'MarkerEdgeColor', 'none', ...
                'HandleVisibility', 'off');

    % Plot line plot betwen avgs
    plot(data.TS_avg, data.P_avg, 'linewidth', linewidth, 'color', colors{i}, 'HandleVisibility', 'off')

    % Plot avg power per resistor
    % scatter(data.TS_avg, data.P_avg, main_marker_size, ...
    %         'filled', 'MarkerFaceColor', colors{i}, 'MarkerEdgeColor', 'none', ...
    %         'displayname', strcat('ROW', " ", num2str(i)))

    % Curve fit data
    p = polyfit(data.TS_avg, data.P_avg, 6);
    TS_fit = linspace(min(data.TS_avg), max(data.TS_avg), 29);
    P_fit = polyval(p, TS_fit);

    scatter(TS_fit, P_fit, main_marker_size, ...
            'filled', 'MarkerFaceColor', colors{i}, 'MarkerEdgeColor', 'none', ...
            'displayname', strcat('ROW', " ", num2str(i)))

    
    
end
hold off
title(setup, 'Interpreter', 'none')
legend('location', 'northeast')
xlabel('Tip Speed [m/s]')
ylabel('Power [mW]')
exportgraphics(ax, fullfile(main_path, setup, 'Power_Curve', 'PowerCurves_Fitted.png'), 'Resolution', 200)
close all

