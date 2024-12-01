% Plot Cp curves for all rows

clear; close all; clc;

remote_path    = "/Users/zeinsadek/Library/CloudStorage/GoogleDrive-sadek@pdx.edu/Other computers/Pinhole/Power";
project        = "WT60_SX50_AG0/Sweeps";
matfile_folder = fullfile(remote_path, project, "Matfiles");
figure_folder  = fullfile(remote_path, project, "Figures");

cases = {'ROW1_R20_ST1_SP29_PPR1000',...
         'ROW2_R50_ST1_SP29_PPR1000',...
         'ROW3_R62_ST1_SP29_PPR1000',...
         'ROW4_R62_ST1_SP29_PPR1000'};

names = {'Row 1', 'Row 2', 'Row 3', 'Row 4'};
colors = jet(length(cases));
trans = 0.01;
linewidth = 2;

ax = figure('Position', [200, 200, 500, 400]);
hold on

% Plot instantaneous data
for i = 1:length(cases)
    data = load(fullfile(matfile_folder, cases{i}));
    data = data.output;
    scatter(data.TS, data.P, 'filled', 'MarkerFaceColor', colors(i,:), 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha', trans)
end

% Plot averages
h = zeros(1,length(cases));
for i = 1:length(cases)
    data = load(fullfile(matfile_folder, cases{i}));
    data = data.output;
    plot(data.TS_avg, data.P_avg, 'color', colors(i,:), 'LineWidth', linewidth, 'HandleVisibility', 'off')
    h(1,i) = scatter(data.TS_avg, data.P_avg, 'filled', 'MarkerFaceColor', colors(i,:), 'MarkerEdgeColor', 'black');
end
hold off
xlim([0.25,3.25])
ylim([0,200])
legend(h, names, 'location', 'northwest')
xlabel('Tip Speed [m/s]')
ylabel('Power [mW]')
title('WT = 6.0 Hz, Sx = 5D: Chains on Windscreen')

exportgraphics(ax, fullfile(figure_folder, 'WT60_SX5_AG0_Power_Curves.png'), 'Resolution', 300)











