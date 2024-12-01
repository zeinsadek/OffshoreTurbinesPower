%%% Power Code from CSV
% Zein Sadek
% 3/28/2024

clear; close all; clc;

%% Import Data

remote_path = "/Users/zeinsadek/Library/CloudStorage/GoogleDrive-sadek@pdx.edu/Other computers/Pinhole/Power";
project     = "WT60_SX50_AG0/Sweeps";
recording   = "ROW4_R62";
name        = "ROW_4_SWEEP_START_1_INC_1_STOP_29_PPR_1000";

% Save Folders
figure_folder  = fullfile(remote_path, project, "Figures");
matfile_folder = fullfile(remote_path, project, "Matfiles");


keywords    = {'ROW', 'START', 'INC', 'STOP', 'PPR'};
char_name   = char(name);

for i = 1:length(keywords)
    keyword        = keywords{i};
    keyword_length = length(keyword);
    idx        = strfind(char_name, keyword);
    short_name = char_name(idx:end);
    underscore = strfind(short_name, '_');
    if length(underscore) ~= 1
        underscore = underscore(2);
        short_name = short_name(1:underscore);
        value      = str2double(short_name(keyword_length + 2:underscore - 1));
    else
        short_name = short_name(1:end);
        value      = str2double(short_name(keyword_length + 2:end));
    end
    values.(keyword) = value;
    fprintf('%s : %3.0f\n', keyword, value)
end

char_name = char_name(1:end-1);
row   = values.('ROW');
start = values.('START');
stop  = values.('STOP');
inc   = values.('INC');
PPR   = values.('PPR');

path = fullfile(remote_path, project, recording, name + ".csv");
data = readmatrix(path);
data = data(1:(PPR * (stop - start + 1)),:);
resistors = start:inc:stop;
save_name = recording + '_ST' + num2str(start) + '_SP' + num2str(stop) + '_PPR' + num2str(PPR);

%% Compute Power

t    = data(:,1);
R    = data(:,2);
BV   = data(:,3);
SV   = data(:,4);
I    = data(:,5); 
V    = BV + SV;

% Power
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

%% Plots

colors          = jet(length(resistors));
marker_size     = 75;
bkg_marker_size = 20;
marker_trans    = 0.1;
line_trans      = 0.5;
linewidth       = 2;

ax = figure('Position', [200, 200, 1000, 400]);
t = tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
sgtitle(sprintf('%s: PPR = %3.1f', recording, PPR), 'Interpreter', 'none')

% Power vs Resistor
nexttile()
hold on
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
exportgraphics(ax, fullfile(figure_folder, save_name + '.png'), 'Resolution', 300)

% Save to mat file
output.P_avg   = P_avg;
output.TS_avg  = TS_avg;
output.P       = P;
output.TS      = TS;
output.values  = values;
output.optimal = resistors(peak_ind);
save(fullfile(matfile_folder, save_name + '.mat'), 'output')
fprintf("%s Matfile Saved\n", save_name);
















