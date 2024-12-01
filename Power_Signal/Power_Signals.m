%%% Plot Power Signals

clear; close all; clc;

caze          = "LM0_AK00";
main_path     = "C:\Users\ofercak\Desktop\PSU_Offshore_Power\Power_Check";
figure_folder = fullfile(main_path, caze, "Figures");
mat_folder    = fullfile(main_path, caze, "Matfiles");
turbines      = [1,2,3,4,5,6,7,8,9,10,11,12];
% turbines = [2,5,8,11];
% turbines = [1,2,3,4,5,6];
% turbines = [12];

data = load(fullfile(mat_folder, caze + '.mat'));
data = data.output;

% Plot
linewidth   = 2;
marker_size = 50;
trans       = 0.05;
window      = 1;
colors      = turbo(length(turbines));

ax = figure('Position', [100, 500, 1400, 400]);
hold on
c = 1;
for i = 1:length(turbines)

    turbine = turbines(i);
    P = data(turbine).P;
    % P = P - mean(P, 'all', 'omitnan');
    t = data(turbine).t;
 
    p = yline(mean(P, 'all', 'omitnan'), 'linestyle', '--', 'color', colors(i,:), 'HandleVisibility', 'off');
    % p.Color(4) = trans;
    % scatter(t, P, marker_size, 'filled', 'MarkerEdgeColor', 'none', 'MarkerFaceColor', colors(i,:), 'MarkerFaceAlpha', trans, 'HandleVisibility', 'off')
    plot(t, movmean(P, window), 'color', colors(i,:), 'DisplayName', strcat('Row ', num2str(c)), 'linewidth', linewidth)
    c = c + 1;
end
hold off
% xlim([0,120])
% ylim([-25,25])
xlabel('Time [s]')
ylabel('Power Fluctuations [mW]')
legend('Location', 'eastoutside', 'Orientation', 'vertical')
title(caze, 'Interpreter', 'none')

% exportgraphics(ax, fullfile(figure_folder, caze + '_center_power_fluctuation_signals.png'), 'Resolution', 200)
% close all










