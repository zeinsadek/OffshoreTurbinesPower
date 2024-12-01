clear; close all; clc;

resistors = {'ROW_1_SWEEP_START_1_INC_1_STOP_29_PPR_1000_WT60_R20_ROW1',...
             'ROW_1_SWEEP_START_1_INC_1_STOP_29_PPR_1000_WT60_R20_ROW1_WVA',...
             'ROW_1_SWEEP_START_1_INC_1_STOP_29_PPR_1000_WT60_R20_ROW1_WVB',...
             'ROW_1_SWEEP_START_1_INC_1_STOP_29_PPR_1000_WT60_R20_ROW1_WVC'};


colors = parula(length(resistors));
names  = {'WV0', 'WVA', 'WVB', 'WVC'};
trans = 0.01;
linewidth = 2;

ax = figure('Position', [500, 500, 500, 400]);
hold on

% Plot instantaneous data
for i = 1:length(resistors)
    if i == 1
        folder = 'F:\Power\12_21_2023_Sweeps\Matfiles\';
    else
        folder = 'F:\Power\12_23_2023_Sync\Matfiles\';
    end

    data = load(strcat(folder, resistors{i}));
    data = data.output;
    scatter(data.TS, data.P, 'filled', 'MarkerFaceColor', colors(i,:), 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha', trans)
end

% Plot averages
h = zeros(1,length(resistors));
for i = 1:length(resistors)

    if i == 1
        folder = 'F:\Power\12_21_2023_Sweeps\Matfiles\';
    else
        folder = 'F:\Power\12_23_2023_Sync\Matfiles\';
    end

    data = load(strcat(folder, resistors{i}));
    data = data.output;
    plot(data.TS_avg, data.P_avg, 'color', colors(i,:), 'LineWidth', linewidth, 'HandleVisibility', 'off')
    h(1,i) = scatter(data.TS_avg, data.P_avg, 'filled', 'MarkerFaceColor', colors(i,:), 'MarkerEdgeColor', 'none');
end
hold off
% xlim([0,4])
% ylim([0,600])
legend(h,names, 'location', 'northwest')
xlabel('Tip Speed [m/s]')
ylabel('Power [mW]')
title('WT6.0Hz, Power Curve, Different Waves')

exportgraphics(ax, strcat('F:\Power\12_23_2023_Sync\Figures\', 'WT60_ROW1_Power_Curves_Waves.png'), 'Resolution', 100)











