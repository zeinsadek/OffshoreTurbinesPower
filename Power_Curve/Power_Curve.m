%%% Power Code from PCB
% Zein Sadek
% 12/18/2023

clear; close all; clc;
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% IMPORT DATA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

main_path     = "/Volumes/Zein_PIV_3/Zein_APS_Tracking/Power/WT60_SX50_AG0/Sweeps/ROW4_R62";
name          = "ROW_4_SWEEP_START_1_INC_1_STOP_29_PPR_1000_";
keywords      = {'ROW', 'START', 'INC', 'STOP', 'PPR'};
char_name     = char(name);

out_folder    = '/Volumes/Zein_PIV_3/Power_Results/WT60_SX50_AG0/Power_Curve';


for i = 1:length(keywords)
    keyword        = keywords{i};
    keyword_length = length(keyword);
    idx        = strfind(char_name, keyword);
    short_name = char_name(idx:end);
    underscore = strfind(short_name, '_');
    underscore = underscore(2);
    short_name = short_name(1:underscore);
    value      = str2double(short_name(keyword_length + 2:underscore - 1));
    values.(keyword) = value;
    fprintf('%s : %3.0f\n', keyword, value)
end

char_name = char_name(1:end-1);
row   = values.('ROW');
start = values.('START');
stop  = values.('STOP');
inc   = values.('INC');
PPR   = values.('PPR');

out_name = strcat('ROW', num2str(row), '_Power_Curve.mat');

path = fullfile(main_path, [char_name, '.csv']);
data = readmatrix(path);
data = data(1:(PPR * (stop - start + 1)),:);
resistors = start:inc:stop;

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COMPUTE POWER
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

t    = data(:,1);
R    = data(:,2);
BV   = data(:,3);
SV   = data(:,4);
I    = data(:,5); 
V    = BV + SV;
P    = V .* I;

% Tip Speed
delta_t = gradient(t) * 1E-6;
omega   = (2*pi) ./ delta_t;
D       = 0.15;
TS      = (D/2) ./ delta_t;

% Averages per Resistor
P_avg  = zeros(1, length(resistors));
TS_avg = zeros(1, length(resistors));

for i = 1:length(resistors)
    resistor = resistors(i);
    x = find(R == resistor);
    x = x(1:PPR);
    P_avg(i)  = mean(P(x), 'all', 'omitnan');
    TS_avg(i) = mean(TS(x), 'all', 'omitnan');
end

[peak, peak_ind] = max(P_avg, [], 'all');

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PLOTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

colors          = jet(length(resistors));
marker_size     = 75;
bkg_marker_size = 20;
marker_trans    = 0.1;
line_trans      = 0.5;
linewidth       = 2;

ax = figure('Position', [500, 500, 1000, 400]);
t = tiledlayout(1, 2, 'TileSpacing', 'compact');
sgtitle(name, 'Interpreter', 'none')

% Power vs Resistor
nexttile()
hold on
% scatter(R, P, bkg_marker_size, 'MarkerFaceColor', 'k', 'MarkerFaceAlpha', marker_trans, 'MarkerEdgeColor', 'none')
for i = 1:length(resistors)
    resistor = resistors(i);
    x = find(R == resistor);
    x = x(1:PPR);
    scatter(R(x), P(x), bkg_marker_size, 'MarkerFaceColor', colors(i,:), 'MarkerFaceAlpha', marker_trans, 'MarkerEdgeColor', 'none')
end
plt = plot(resistors, P_avg, 'k', 'LineWidth', linewidth);
plt.Color(:, 4) = line_trans;
for i = 1:length(resistors)
    scatter(resistors(i), P_avg(i), marker_size, 'MarkerFaceColor', colors(i,:), 'MarkerEdgeColor', 'none')
end
hold off
xlabel('Resistor')
ylabel('Power [mW]')
xlim([0,30])
grid on

% Power vs Tip Speed
nexttile()
hold on
% scatter(TS, P, bkg_marker_size, 'MarkerFaceColor', 'k', 'MarkerFaceAlpha', marker_trans, 'MarkerEdgeColor', 'none')
for i = 1:length(resistors)
    resistor = resistors(i);
    x = find(R == resistor);
    x = x(1:PPR);
    scatter(TS(x), P(x), bkg_marker_size, 'MarkerFaceColor', colors(i,:), 'MarkerFaceAlpha', marker_trans, 'MarkerEdgeColor', 'none')
end
plt = plot(TS_avg, P_avg, 'k', 'LineWidth', linewidth);
plt.Color(:, 4) = line_trans;
for i = 1:length(resistors)
    scatter(TS_avg(i), P_avg(i), marker_size, 'MarkerFaceColor', colors(i,:), 'MarkerEdgeColor', 'k')
end
hold off
xlabel('Tip Speed [m/s]')
grid on

% Save Figure
fprintf('Optimal Resistor Value: %2.1f\n\n', resistors(peak_ind))
% exportgraphics(ax, strcat(figure_folder, '/', caze, '_PPR', num2str(PPR), '.png'), 'Resolution', 100)

% Save to mat file
output.P_avg   = P_avg;
output.TS_avg  = TS_avg;
output.P       = P;
output.TS      = TS;
output.values  = values;
output.optimal = resistors(peak_ind);
save(fullfile(out_folder, out_name), 'output')

















