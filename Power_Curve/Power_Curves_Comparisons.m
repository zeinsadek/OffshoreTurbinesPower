%% First row powers curves for all cases (inline/staggered + S_x)

clc; close all; clear


% Data locations
projet_path = "/Users/zeinsadek/Desktop/Experiments/Offshore/Power";
mat_path = fullfile(projet_path, "Data/Matfiles");

% Which arangment to process and where to save
farm_type = 'FWF';
arrangements = {'Inline', 'Staggered'};
spacings = [50, 45, 40, 35, 30];

if strcmp(farm_type, 'FWF')
    fancy_title = 'Floating Wind Farm';
elseif strcmp(farm_type, 'FBF')
    fancy_title = 'Fixed-Bottom Wind Farm';
end

% Loop through and load power curve data
for a = 1:length(arrangements)
    arrangement = arrangements{a};
    farm = strcat(farm_type, '_', arrangement);

    for s = 1:length(spacings)
        caze = strcat('WT60_SX', num2str(spacings(s)), '_AG0');
        tmp = load(fullfile(mat_path, farm, caze, 'Sweeps', strcat(farm, '_', caze, '_PowerCurve.mat')));
        tmp = tmp.output;

        % Save to data structure
        data.(arrangement).(caze) = tmp;

        clear s
    end

    clear a
end

%% Plot all first row power curves together

colors.Inline = parula(length(spacings));
colors.Staggered = cool(length(spacings));
lw = 2;

clc;
figure('color', 'white')
t = tiledlayout(1,4);
sgtitle(fancy_title, 'interpreter', 'latex')

for row = 1:4
    disp(row)
    
    % title(num2str(row))
    h(row) = nexttile;
    title(sprintf('Row %1.0f', row))
    
    hold on
    for a = 1:length(arrangements)
        arrangement = arrangements{a};
        farm = strcat(farm_type, '_', arrangement);
    
        for s = 1:length(spacings)
            caze = strcat('WT60_SX', num2str(spacings(s)), '_AG0');
            fprintf('%s: %s\n', farm, caze)
            disp(data.(arrangement).(caze)(row).file)
            fprintf('\n')
    
            % Plot
            label = sprintf('%s: $S_x = %1.1fD$', arrangement, spacings(s) / 10);
            plot(data.(arrangement).(caze)(row).TS_avg, data.(arrangement).(caze)(row).P_avg, ...
                 'linewidth', lw, 'color', colors.(arrangement)(s,:), 'DisplayName', label)
            clear s
        end
        % plot(nan, nan, 'DisplayName', '\n')
        clear a
    end
    hold off

    if row == 4
        legend('Interpreter', 'latex', 'box', 'off', 'location', 'eastoutside')
    end

    if row == 1
        ylabel('Power [mW]', 'interpreter', 'latex')
    end
    
    xlim([0, 20])
    ylim([0, 250])
end

xlabel(t, 'Tip Speed = $R \omega$ [m/s]', 'interpreter', 'latex')