%% First row powers curves for all cases (inline/staggered + S_x)

clc; close all; clear

% Data locations
projet_path = "/Users/zeinsadek/Desktop/Experiments/Offshore/Power";
mat_path = fullfile(projet_path, "Data/Matfiles");
addpath('/Users/zeinsadek/Documents/MATLAB/colormaps/slanCM')

% Which arangment to process and where to save
farm_types = {'FWF', 'FBF'};
arrangements = {'Inline', 'Staggered'};
spacings = [50, 45, 40, 35, 30];
fancy_titles = {'Floating wind farm', 'Fixed-Bottom wind farm'};

% Loop through and load power curve data
for f = 1:2
    farm_type = farm_types{f};
    for a = 1:length(arrangements)
        arrangement = arrangements{a};
        farm = strcat(farm_type, '_', arrangement);
    
        for s = 1:length(spacings)
            caze = strcat('WT60_SX', num2str(spacings(s)), '_AG0');
            tmp = load(fullfile(mat_path, farm, caze, 'Sweeps', strcat(farm, '_', caze, '_PowerCurve.mat')));
            tmp = tmp.output;
    
            % Save to data structure
            data.(farm_type).(arrangement).(caze) = tmp;
            clear s
        end
        clear a
    end
    clear f
end


%% Plot power curves for all 4 rows for a single representative case (for power measurement figure)
% 1 axes

% What case to plot
farm_type = 'FWF';
arrangement = 'Inline';
spacing = 'SX50';

% Plot details
lw = 2;
inst_sz = 10;
mean_sz = 15;
tickFontSize = 8;
labelFontSize = 10;
colors = slanCM('hawaii', 4);

% Normalizations to get Cp
u_inf = 4.2;
u_rotor = 3.3;
D = 0.15;
A = (pi/4) * D^2;
rho = 1.292;

P_inf = (1/2) * rho * A * (u_inf^3);
P_rotor = (1/2) * rho * A * (u_rotor^3);



% Loading caze
caze = strcat('WT60_', spacing, '_AG0');
fprintf('%s: %s\n', farm, caze)
fprintf('\n')


% Plotting
clc; close all
fig = figure('color', 'white', 'units', 'centimeters', 'position', [10, 10, 7.75, 6.5]);
tiledlayout(1,1,'padding', 'none')
nexttile()
hold on
for row = 1:4

    % Legend label
    label = sprintf('Row %1.0f', row);

    % Load mean values
    % Normalize by rotor average velocity and power
    avg_TS = data.(farm_type).(arrangement).(caze)(row).TS_avg / u_rotor;
    avg_Power = data.(farm_type).(arrangement).(caze)(row).P_avg * 1E-3 / P_rotor;
    optimal_resistor = data.(farm_type).(arrangement).(caze)(row).optimal;
    

    % Load instantaneous values
    % Normalize by rotor average velocity and power
    inst_TS = data.(farm_type).(arrangement).(caze)(row).TS / u_rotor;
    inst_Power = data.(farm_type).(arrangement).(caze)(row).P * 1E-3 / P_rotor;
    inst_Resistors = data.(farm_type).(arrangement).(caze)(row).R;
    resistors = unique(inst_Resistors);

    % Plot Polynomial fit to points (line)
    n = 3;
    FP = polyfit(avg_TS, avg_Power, n);
    fit_TS = linspace(min(avg_TS), max(avg_TS), 40);
    meanPolyFit = polyval(FP, fit_TS);
    plot(fit_TS, meanPolyFit, ...
         'linewidth', lw, 'color', colors(row, :), 'linestyle', '-', ...
         'DisplayName', label);
         
    % Plot Average points (points)
    scatter(avg_TS, avg_Power, ...
            mean_sz, 'filled', 'markerfacecolor', colors(row, :), ...
            'HandleVisibility', 'off');


    %%% Mark operating point
    % peak of curve fit
    [maxCp, idx] = max(meanPolyFit);
    scatter(fit_TS(idx), maxCp, mean_sz, 'filled', 'markerfacecolor', 'red', 'HandleVisibility', 'off')

    % Actual resistor value
    idx = find(resistors == optimal_resistor);
    scatter(avg_TS(idx), avg_Power(idx), mean_sz, 'filled', 'markerfacecolor', 'blue', 'HandleVisibility', 'off')
    




    % Try to compute max/min values at each resistor value
    % Save values for polyfitting
    max_TS = nan(size(resistors));
    max_P = nan(size(resistors));

    min_TS = nan(size(resistors));
    min_P = nan(size(resistors));

    prct_max_TS = nan(size(resistors));
    prct_max_P = nan(size(resistors));

    prct_min_TS = nan(size(resistors));
    prct_min_P = nan(size(resistors));

    % Loop through resistors
    for r = 1:length(resistors)
        resistor = resistors(r);
        disp(resistor)
        tmp_inst_TS = inst_TS(inst_Resistors == resistor);
        tmp_inst_P = inst_Power(inst_Resistors == resistor);

        % Max of inst values within resistor
        % scatter(max(tmp_inst_TS, [], 'omitnan'), max(tmp_inst_P, [], 'omitnan'), ...
        %     mean_sz, 'filled', 'markerfacecolor', 'red', ...
        %     'HandleVisibility', 'off');
        % 
        % max_TS(r) = max(tmp_inst_TS, [], 'omitnan');
        % max_P(r) = max(tmp_inst_P, [], 'omitnan');


        % 95th percentile of inst values within resistor
        % scatter(prctile(tmp_inst_TS, 95), prctile(tmp_inst_P, 95), ...
        %     mean_sz, 'filled', 'markerfacecolor', 'green', ...
        %     'HandleVisibility', 'off');
        prct_max_TS(r) = prctile(tmp_inst_TS, 95);
        prct_max_P(r) = prctile(tmp_inst_P, 95);


        % Min of inst values within resistor
        % scatter(min(tmp_inst_TS, [], 'omitnan'), min(tmp_inst_P, [], 'omitnan'), ...
        %     mean_sz, 'filled', 'markerfacecolor', 'blue', ...
        %     'HandleVisibility', 'off');
        % 
        % min_TS(r) = min(tmp_inst_TS, [], 'omitnan');
        % min_P(r) = min(tmp_inst_P, [], 'omitnan');


        % 5th percentile of inst values within resistor
        % scatter(prctile(tmp_inst_TS, 5), prctile(tmp_inst_P, 5), ...
        %     mean_sz, 'filled', 'markerfacecolor', 'green', ...
        %     'HandleVisibility', 'off');
        prct_min_TS(r) = prctile(tmp_inst_TS, 5);
        prct_min_P(r) = prctile(tmp_inst_P, 5);
    end

    %%% Polyfit the different points
    % Max
    % fit_TS = linspace(min(max_TS), max(max_TS), 20);
    % FP_max = polyfit(max_TS, max_P, n);
    % plot(fit_TS, polyval(FP_max, fit_TS), 'color', 'red', 'linewidth', lw)
    % 
    % % Min
    % fit_TS = linspace(min(min_TS), max(min_TS), 20);
    % FP_min = polyfit(min_TS, min_P, n);
    % plot(fit_TS, polyval(FP_min, fit_TS), 'color', 'blue', 'linewidth', lw)

    % 95th prct
    fit_TS = linspace(min(prct_max_TS), max(prct_max_TS), 40);
    FP_prct_max = polyfit(prct_max_TS, prct_max_P, n);
    P1 = plot(fit_TS, polyval(FP_prct_max, fit_TS), ...
        'color', colors(row,:), 'linewidth', 1, 'HandleVisibility', 'off');

    % 5th prct
    fit_TS = linspace(min(prct_min_TS), max(prct_min_TS), 40);
    FP_prct_min = polyfit(prct_min_TS, prct_min_P, n);
    P2 = plot(fit_TS, polyval(FP_prct_min, fit_TS), ...
        'color', colors(row,:), 'linewidth', 1, 'HandleVisibility', 'off');


    


    % Plot instantaneous scatter
    skip = 3;
    P = scatter(inst_TS(1:skip:end), inst_Power(1:skip:end), ...
                inst_sz, 'filled', 'markerfacecolor', colors(row,:), 'MarkerFaceAlpha', 0.01, ...
                'HandleVisibility', 'off');
    uistack([P, P1, P2], 'bottom')
end

% Dummy legend
% plot(nan, nan, 'color', 'white', 'displayname', ' ')
plot(nan, nan, 'color', 'white', 'displayname', 'Set point')

hold off
box on

ax = gca;
set(ax, 'FontSize', tickFontSize)
set(ax, 'TickLabelInterpreter', 'latex');

leg = legend('box', 'off', 'Interpreter', 'latex', 'fontsize', tickFontSize, 'location', 'northwest');
leg.IconColumnWidth = 8;

xlabel('$\omega R \mathbin{/} \langle \overline{u} \rangle_{A}$', 'interpreter', 'latex', 'FontSize', labelFontSize)
ylabel('$C_p$', 'interpreter', 'latex', 'FontSize', labelFontSize)
xlim([0, 6])
ylim([0, 0.5])
% axis square


% Test save
save_folder = '/Users/zeinsadek/Desktop/Experiments/Offshore/Publishing/PowerMotion/Power';
save_name = 'Offshore_PowerMotion_PowerCurvesSample.pdf';
pause(5)
exportgraphics(fig, fullfile(save_folder, save_name), 'resolution', 600)
close all









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