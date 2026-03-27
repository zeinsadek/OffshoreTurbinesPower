%%% Mean Power Per Row (Like from Juliaan's paper) for different waves and
%%% spacings

clear; close all; clc;

main_folder   = "/Users/zeinsadek/Desktop/Experiments/Offshore/Power";
figure_folder = fullfile(main_folder, "Figures");
mat_folder    = fullfile(main_folder, "Data", "Matfiles");

turbine_type = 'FWF';
farm_arrangement = 'Inline';

% Make fancy name for farm type
if strcmp(turbine_type, 'FWF')
    fancy_name = ['Floating Wind Farm: ', farm_arrangement];
elseif strcmp(turbine_type, 'FBF')
    fancy_name = ['Fixed-Bottom Wind Farm: ', farm_arrangement];
end

farm_spacings = [5, 4.5, 4, 3.5, 3];

waves_steepness = 0.12;
wavelengths = [0,5,4,3,2];

wave_cases = {};
s = compose('%02d', round(100 * waves_steepness));
for i = 1:length(wavelengths)
    wavelength = wavelengths(i);
    if wavelength ~= 0
        % wave_cases{i} = ['LM', num2str(wavelength), '_AK', num2str(waves_steepness * 100)];
        wave_cases{i} = ['LM', num2str(wavelength), '_AK', s{1}];
    else
        wave_cases{i} = ['LM', num2str(wavelength), '_AK00'];
    end
end
clear s

% Create legend names for each wave case
legend_names = {};
for i = 1:length(wavelengths)
    wave = wavelengths(i);
    if wave ~= 0
        legend_names{i} = ['$\lambda = ', num2str(wave), 'D$'];
    else
        legend_names{i} = 'No Waves';
    end
end



%% Load No Waves to Normalize

clear no_waves_power

% Across entire row
for s = 1:length(farm_spacings)
    farm_spacing = ['SX', num2str(farm_spacings(s) * 10)];
    fprintf('%s\n', farm_spacing)
    no_waves = load(fullfile(mat_folder, strcat(turbine_type, '_', farm_arrangement), strcat('WT60_', farm_spacing, '_AG0'), 'LM0_AK00.mat'));
    no_waves = no_waves.output;
    
    % Average across the first three turbines
    no_waves_power.(farm_spacing) = mean([no_waves(1).Power; no_waves(2).Power; no_waves(3).Power], 'omitnan');

    clear s farm_spacing no_waves
end


%% Average power, center turbines, different wavelengths
% normalized by the first row, no waves

centers = [2,5,8,11];

clear power_per_row
clc;
% Loop through spacings
for s = 1:length(farm_spacings)
    farm_spacing = ['SX', num2str(farm_spacings(s) * 10)];
    fprintf('%s\n', farm_spacing)
    norm_powers = zeros(length(centers), length(wave_cases));
    
    % Loop through waves
    for w = 1:length(wave_cases)
        data = load(fullfile(mat_folder, strcat(turbine_type, '_', farm_arrangement), strcat('WT60_', farm_spacing, '_AG0'), [wave_cases{w}, '.mat']));
        data = data.output;
        fprintf('%s\n', wave_cases{w})

        % Loop through rows
        for r = 1:length(centers)
            center = centers(r);
            fprintf('Row %1.0f\n', r)

            % Averaging across entire row
            row_data = [data(center - 1).Power; data(center).Power; data(center + 1).Power];
            norm_powers(r,w) = mean(row_data, 'omitnan') / no_waves_power.(farm_spacing);
    
            clear r row_data
        end

        % Save to structure
        power_per_row.(farm_spacing) = norm_powers;
    end
    fprintf('\n')
    clear s farm_spacigs norm_powers powers
end

clear data center row_data


%% Plot normalized power against different spacings and waves

wave_colors = {'#0A2239', '#5497A7', '#62A8AC', '#78CAD2', '#A1D2CE'};

figure('color', 'white')
t = tiledlayout(length(farm_spacings), 1);
sgtitle(sprintf('%s $ak = %1.2f$', fancy_name, waves_steepness), 'interpreter', 'latex')

for s = 1:length(farm_spacings)
    farm_spacing = ['SX', num2str(farm_spacings(s) * 10)];
    h(s) = nexttile;
    hb = bar(power_per_row.(farm_spacing));
    title(sprintf('$S_x = %1.1fD$', farm_spacings(s)), 'Interpreter', 'latex')
    ylim([0, 1.1])

    % Apply colors per wave case (column)
    for w = 1:length(hb)
        hb(w).FaceColor = wave_colors{w};
        hb(w).EdgeColor = 'none';
    end

    ax = gca;
    box(ax, 'off');

    if s == 1
        legend(hb, legend_names, 'Interpreter', 'latex','Location','northoutside', ...
               'Orientation', 'horizontal', 'box', 'off');
    end
end

linkaxes(h, 'xy')
ylabel(t, '$\bar{P} / \bar{P}_{Row 1, No Waves}$', 'Interpreter', 'latex')
xlabel(t, 'Turbine Row', 'interpreter', 'latex')


%% Grouped bars: spacing on x, wave cases as grouped bars

row_to_plot = 1;
offset = 0.015;          % vertical offset above bar
min_show = 0.5;            % only annotate if |Δ| > min_show %

nS = numel(farm_spacings);
nW = numel(wave_cases);

clc; close all
Y = nan(nS, nW);
for s = 1:nS
    farm_spacing_str = ['SX', num2str(farm_spacings(s) * 10)];
    fprintf('%s\n', farm_spacing_str)
    M = power_per_row.(farm_spacing_str);   % [4 x nW]
    Y(s,:) = M(row_to_plot, :);
end

figure('color','white');
hb = bar(farm_spacings, Y, 'grouped');  % each column is a wave case
box off
ylim([0 1.4])


% No wave vals
% hb(w) is the same wave condition across the different spacings
% The items within hb(w) are the different values for different spacings
% This indexs the no-wave case across all the different spacings
nowave_xCenters = hb(1).XEndPoints;
nowave_yVals    = hb(1).YEndPoints;

% Look through wave cases
for w = 2:length(hb)
    xCenters = hb(w).XEndPoints;
    yVals    = hb(w).YEndPoints;

    % Loop through spacings
    for i = 1:length(xCenters)
        delta_pct = 100 * (yVals(i) - nowave_yVals(i));

        if abs(delta_pct) >= min_show
            txt = sprintf('%+d\\%%', round(delta_pct));
            text(xCenters(i), yVals(i) + offset, txt, ...
                'HorizontalAlignment','center', ...
                'VerticalAlignment','bottom', ...
                'FontSize', 9, ...
                'Color', [0.25 0.25 0.25], ...
                'Interpreter','latex');
        end
    end
end

% Color each wave case
for w = 1:length(hb)
    hb(w).FaceColor = wave_colors{w};
    hb(w).EdgeColor = 'none';
end

nowave_y = hb(1).YEndPoints;

for i = 1:numel(nowave_y)
    % x centers across all wave cases for this spacing
    x_all = arrayfun(@(k) hb(k).XEndPoints(i), 1:numel(hb));
    xL = min(x_all);
    xR = max(x_all);

    % pad a little so the line extends beyond the outer bars
    pad = 0.1 * (xR - xL);
    xL = xL - pad;
    xR = xR + pad;
    y0 = nowave_y(i);

    P = line([xL xR], [y0 y0], 'Color', 'black', 'LineWidth', 0.5, 'linestyle', ':');
    P.Color(4) = 0.5;
end


% set(gca, 'XDir','reverse')  % optional

xlabel('$S_x / D$', 'Interpreter','latex')
ylabel('$\overline{P} / \overline{P}_{Row 1, No Waves}$', 'Interpreter','latex')
sgtitle(sprintf('%s, $ak = %1.2f$, Row %d', fancy_name, waves_steepness, row_to_plot), 'Interpreter','latex')

legend(hb, legend_names, 'Interpreter', 'latex','Location','northeastoutside', 'Orientation', 'vertical', 'box', 'off');



%% Scatter plot with Normalized power plotted against harmonic ratio S_x / \lambda


% row_to_plot = 1;
% 
% nS = numel(farm_spacings);
% nW = numel(wave_cases);
% 
% clc;
% figure('color','white');
% sz = 100;
% spacing_shapes = {'o', 'diamond', '^', 'v', 'square'};
% 
% hold on
% for s = 1:nS
%     farm_spacing_str = ['SX', num2str(farm_spacings(s) * 10)];
%     fprintf('%s\n', farm_spacing_str)
%     M = power_per_row.(farm_spacing_str);   % [4 x nW]
%     Y = M(row_to_plot, :);
% 
%     for w = 2:nW
%         harmonic_ratio = farm_spacings(s) / wavelengths(w);
%         scatter(harmonic_ratio, Y(w), sz, spacing_shapes{s}, 'filled', 'MarkerFaceColor', wave_colors{w})
%     end
% end
% 
% hold off
% ylim([0, 1.4])
% 
% 
% 
% xlabel('$S_x / \lambda$', 'Interpreter','latex')
% ylabel('$\overline{P} / \overline{P}_{Row 1, No Waves}$', 'Interpreter','latex')
% sgtitle(sprintf('%s: Row %d', fancy_name, row_to_plot), 'Interpreter','latex')
% 
% % legend(hb, legend_names, 'Interpreter', 'latex','Location','northeastoutside', 'Orientation', 'vertical', 'box', 'off');


%% Aggregate farm power vs spacing from power_per_row struct

nS = numel(farm_spacings);

% Assuming power_per_row.(farm_spacing) = [4 x nCases]
% and column 1 is the no-wave case
farm_spacing_strs = strings(nS,1);
for s = 1:nS
    farm_spacing_strs(s) = "SX" + num2str(farm_spacings(s) * 10);
end


% Determine number of cases from the first spacing
M0 = power_per_row.(farm_spacing_strs(1));
nCases = size(M0, 2);

% Build aggregate normalized matrix: [nS x nCases]
Agg = nan(nS, nCases);

for s = 1:nS
    M = power_per_row.(farm_spacing_strs(s));    % [4 x nCases]

    agg_all = sum(M, 1, 'omitnan');              % 1 x nCases (sum over rows)
    Agg(s,:) = agg_all ./ agg_all(1);            % normalize by no-wave aggregate (col 1)
end


figure('color','white');
hb = bar(farm_spacings, Agg(:,1:end), 'grouped');  % skip no-wave column
box off
ylim([0 1.1])

% color each wave case
for w = 1:numel(hb)
    hb(w).FaceColor = wave_colors{w};
    hb(w).EdgeColor = 'none';
end

nowave_xCenters = hb(1).XEndPoints;
nowave_yVals    = hb(1).YEndPoints;

% Look through wave cases
for w = 2:length(hb)
    xCenters = hb(w).XEndPoints;
    yVals    = hb(w).YEndPoints;

    % Loop through spacings
    for i = 1:length(xCenters)
        delta_pct = 100 * (yVals(i) - nowave_yVals(i));

        if abs(delta_pct) >= min_show
            txt = sprintf('%+d\\%%', round(delta_pct));
            text(xCenters(i), yVals(i) + offset, txt, ...
                'HorizontalAlignment','center', ...
                'VerticalAlignment','bottom', ...
                'FontSize', 9, ...
                'Color', [0.25 0.25 0.25], ...
                'Interpreter','latex');
        end
    end
end


% reference line at no-wave baseline
% yline(1,'--','LineWidth',1,'Color',[0.4 0.4 0.4], 'HandleVisibility', 'off');
yline(1, '--', 'LineWidth', 1, 'Color','black', 'HandleVisibility', 'off', 'Alpha', 0.3)

xlabel('$S_x / D$', 'Interpreter','latex')
ylabel('$\overline{P}_{farm} / \overline{P}_{farm,\,NoWaves}$', 'Interpreter','latex')
title(fancy_name + " — aggregate farm power", 'Interpreter','none')

legend(hb, legend_names(1:end), ...
    'Interpreter','latex', ...
    'Location','northeastoutside', ...
    'Box','off');













