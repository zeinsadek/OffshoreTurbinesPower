%%% Mean Power Per Row (Like from Juliaan's paper) for ALL VARIATIONS

clear; close all; clc;

addpath('/Users/zeinsadek/Documents/MATLAB/colormaps/slanCM')
main_folder   = "/Users/zeinsadek/Desktop/Experiments/Offshore/Power";
figure_folder = fullfile(main_folder, "Figures");
mat_folder    = fullfile(main_folder, "Data", "Matfiles");

% Turbine + Layout types
turbine_types = {'FWF', 'FBF'};
farm_arrangements = {'Inline', 'Staggered'};

% Farm spacings
farm_spacings = [5, 4.5, 4, 3.5, 3];

% Wave steepnesses
wave_steepnesses = [0.06, 0.09, 0.12];

% Which cases have the harmonic wave conditions
has_harmonics.FBF.Inline = true;
has_harmonics.FBF.Staggered = false;
has_harmonics.FWF.Inline = true;
has_harmonics.FWF.Staggered = true;


%% Make a structure that has the wave cases available for each farm

% Loop over turbine types
for tt = 1:2
    turbine_type = turbine_types{tt};

    % Loop over farm layouts
    for l = 1:2
        farm_arrangement = farm_arrangements{l};

        % Make a structure with cases per spacing so that the extra wavelength
        % cases can be included in the Sx50 spacing
        for sp = 1:length(farm_spacings)
            farm_spacing = ['SX', num2str(farm_spacings(sp) * 10)];
            
            % Wavelengths for SX50 cases
            if has_harmonics.(turbine_type).(farm_arrangement) && strcmp(farm_spacing, 'SX50')
                wavelengths = [0, 5, 4, 3.33, 3, 2.5, 2];
        
            % Wavelengths for all cases
            else
                wavelengths = [0,5,4,3,2];
            end
        
            tmp_wave_cases = {};
            c = 1;
            % Loop through wave steepnesses
            for st = 1:length(wave_steepnesses)
                wave_steepness = wave_steepnesses(st);
                s = compose('%02d', round(100 * wave_steepness));
                
                % Loop through wavelengths
                for i = 1:length(wavelengths)
                    wavelength = wavelengths(i);
                    if wavelength ~= 0
        
                        % Format wavelength label
                        if abs(wavelength - 3.33) < 1e-6
                            lm_label = '33';
                        elseif abs(wavelength - 2.5) < 1e-6
                            lm_label = '25';
                        else
                            lm_label = num2str(wavelength);
                        end
        
                        tmp_wave_cases{c} = ['LM', lm_label, '_AK', s{1}];
                        c = c + 1;
                        
            
                    % Make sure that no wave case only gets added once
                    elseif wavelength == 0 && st == 1
                        tmp_wave_cases{c} = ['LM', num2str(wavelength), '_AK00'];
                        c = c + 1;
                    end
                end
            end
        
            % Save wave cases based on farm spacings
            wave_cases.(turbine_type).(farm_arrangement).(farm_spacing).wave_cases = tmp_wave_cases;
            wave_cases.(turbine_type).(farm_arrangement).(farm_spacing).wavelengths = wavelengths;
        end
    end
end
clear st wave_steepness s i wavelength c sp farm_spacing wavelengths 
clear tmp_wave_cases turbine_type farm_arrangement tt l lm_label has_harmonics



%% Average individual turbines and see if there are bad turbines (to ignore)

clc;
% Loop over turbine types
for tt = 1:2
    turbine_type = turbine_types{tt};

    % Loop over farm layouts
    for l = 1:2
        farm_arrangement = farm_arrangements{l};

        if strcmp(farm_arrangement, 'Inline')
            num_turbines = 12;
        elseif strcmp(farm_arrangement, 'Staggered')
            num_turbines = 10;
        end

        % Loop over farm spacings
        for sp = 1:length(farm_spacings)
            farm_spacing = ['SX', num2str(farm_spacings(sp) * 10)];
            waves = wave_cases.(turbine_type).(farm_arrangement).(farm_spacing).wave_cases;
            fprintf('%s: %s, %s\n', turbine_type, farm_arrangement, farm_spacing)

            % Loop over waves
            for w = 1:length(waves)
                wave = waves{w};
                disp(wave)

                % Load data
                data = load(fullfile(mat_folder, strcat(turbine_type, '_', farm_arrangement), strcat('WT60_', farm_spacing, '_AG0'), [wave '.mat']));
                data = data.output;
                
                % Loop through turbines
                tmp_turbine_powers = nan(1, num_turbines);
                tmp_turbine_stds = nan(1, num_turbines);
                for t = 1:num_turbines
                    tmp_turbine_powers(1,t) = mean(data(t).Power, 'omitnan');
                    tmp_turbine_stds(1,t) = std(data(t).Power, 0, 'all', 'omitnan');
                end

                % Save average power per row for each case
                turbine_mean_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave) = tmp_turbine_powers;
                turbine_mean_stds.(turbine_type).(farm_arrangement).(farm_spacing).(wave) = tmp_turbine_stds;
               
                % Save fill power time-series
                turbine_inst_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave) = data;

            end
        end
        fprintf('\n')
    end
    fprintf('\n')
end
clear sp farm_spacing waves w wave tt turbine_type l farm_arrangement data num_turbines_in_row r t
clear tmp_row_averaged_power tmp_row_power turbine turbine_rows turbines_in_row num_turbines tmp_turbine_powers



%% Loop through all cases and try to flag cases which have power ranges that are too high, and try to compute 

% Max fluctaution of power where a case is considered problematic
problem_range = 85;

% Try using percentile for bad cases
percentile = 95;
massaged_turbine_mean_power = turbine_mean_power;

% Counter of edge cases
problem_counter = 0;

% Turbines per row — pre-determined exclusions based on diagnostics
% Fixed-bottom
row_map.FBF.Inline    = {[2 3], [4 5 6], [7 8 9], [10 11]};
row_map.FBF.Staggered = {[2 3], [4 5],   [7 8],   [9 10]};

% Floating
row_map.FWF.Inline    = {[2 3], [4 5 6], [7 8 9], [10 11]};
row_map.FWF.Staggered = {[2 3], [4 5],   [7 8],   [10]};

clc;
% Loop over turbine types
for tt = 1:2
    turbine_type = turbine_types{tt};

    % Loop over farm layouts
    for l = 1:2
        farm_arrangement = farm_arrangements{l};
        good_turbines = unique([row_map.(turbine_type).(farm_arrangement){:}]);

        if strcmp(farm_arrangement, 'Inline')
            num_turbines = 12;
        elseif strcmp(farm_arrangement, 'Staggered')
            num_turbines = 10;
        end

        % Loop over farm spacings
        for sp = 1:length(farm_spacings)
            farm_spacing = ['SX', num2str(farm_spacings(sp) * 10)];
            waves = wave_cases.(turbine_type).(farm_arrangement).(farm_spacing).wave_cases;

            % Loop over waves
            for w = 1:length(waves)
                wave = waves{w};

                % Load data
                data = load(fullfile(mat_folder, strcat(turbine_type, '_', farm_arrangement), strcat('WT60_', farm_spacing, '_AG0'), [wave '.mat']));
                data = data.output;
                
                % Loop through turbines
                weird_turbines = [];
                for t = 1:length(good_turbines)
                    turbine = good_turbines(t);
                    power_range = range(data(turbine).Power);
                    if power_range >= problem_range
                        massaged_turbine_mean_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave)(turbine) = prctile(data(turbine).Power, percentile);

                        fprintf('%s: %s, %s, %s, Turbine %2.0f\n', turbine_type, farm_arrangement, farm_spacing, wave, turbine)

                        fprintf('Mean = %3.2f, Percentile = %3.2f\n\n', turbine_mean_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave)(turbine), massaged_turbine_mean_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave)(turbine))
                        weird_turbines = [weird_turbines, turbine];
                        problem_counter = problem_counter + 1;
                    end

                    % Save bad turbines
                    problem_cases.(turbine_type).(farm_arrangement).(farm_spacing).(wave) = weird_turbines;

                end
            end
        end
        fprintf('\n')
    end
    fprintf('\n')
end
clear sp farm_spacing waves w wave tt turbine_type l farm_arrangement data num_turbines_in_row r t power_range
clear tmp_row_averaged_power tmp_row_power turbine turbine_rows turbines_in_row weird_turbines problem_counter
clear num_turbines good_turbines

%% Look at first row fixed-bottom across different arrangements and spacings

turbine = 3;
wave = 'LM5_AK12';

c = 1;

sz = 50;

FBF_tmp = [];
FWF_mean_tmp = [];
FWF_pct_tmp = [];

clc;
figure('color', 'white')
hold on

% Loop over farm layouts
for l = 1:2
    farm_arrangement = farm_arrangements{l};

    % Loop over farm spacings
    for sp = 1:length(farm_spacings)
        farm_spacing = ['SX', num2str(farm_spacings(sp) * 10)];

        % Fixed-bottom mean
        scatter(c, turbine_mean_power.FBF.(farm_arrangement).(farm_spacing).(wave)(turbine), ...
                sz, 'filled', 'markerfacecolor', 'red')

        % Floating mean
        scatter(c, turbine_mean_power.FWF.(farm_arrangement).(farm_spacing).(wave)(turbine), ...
                sz, 'filled', 'markerfacecolor', 'blue')

        % Floating percentile
        scatter(c, massaged_turbine_mean_power.FWF.(farm_arrangement).(farm_spacing).(wave)(turbine), ...
                sz, 'filled', 'markerfacecolor', 'green')

        FBF_tmp = [FBF_tmp, turbine_mean_power.FBF.(farm_arrangement).(farm_spacing).(wave)(turbine)];
        FWF_mean_tmp = [FWF_mean_tmp, turbine_mean_power.FWF.(farm_arrangement).(farm_spacing).(wave)(turbine)];
        FWF_pct_tmp = [FWF_pct_tmp, massaged_turbine_mean_power.FWF.(farm_arrangement).(farm_spacing).(wave)(turbine)];

        c = c + 1;
    end
end
yline(mean(FBF_tmp), 'color', 'red')
yline(mean(FWF_mean_tmp), 'color', 'blue')
yline(mean(FWF_pct_tmp), 'color', 'green')
xline(5.5, 'linestyle', '--')

fprintf('Avg FBF power = %3.2f mW\n', mean(FBF_tmp))
fprintf('Avg FWF power = %3.2f mW\n', mean(FWF_mean_tmp))

hold off
ylim([0, 250])
xlim([0, 11])
xlabel('Different Layout + Spacings')
ylabel('Mean Power')
title(sprintf('Turbine %2.0f: %s mean power', turbine, wave), 'interpreter', 'none')

clear turbine wave c sz FBF_tmp FWF_mean_tmp l farm_arrangement sp farm_spacing


%% Comapre power signal time-series

% clc;
sz = 5;
lw = 2;
alpha = 0.01;
percentile = 80;

turbine = 3;
farm_spacing = 'SX50';
wave = 'LM5_AK12';


figure('color', 'white')
tile = tiledlayout(1,2);
sgtitle(sprintf('%s Turbine %1.0f, %s', farm_spacing, turbine, wave), 'interpreter', 'none')

% Inline spacings
farm_arrangement = 'Inline';
h(1) = nexttile;
title(farm_arrangement)
hold on
% Fixed-bottom
scatter(turbine_inst_power.FBF.(farm_arrangement).(farm_spacing).(wave)(turbine).Time, turbine_inst_power.FBF.(farm_arrangement).(farm_spacing).(wave)(turbine).Power, ...
        sz, 'filled', 'markerfacecolor', 'red', 'DisplayName', 'Fixed-Bottom', 'MarkerFaceAlpha', alpha)

% Full mean 
yline(turbine_mean_power.FBF.(farm_arrangement).(farm_spacing).(wave)(turbine), ...
      'color', 'red', 'linewidth', lw, 'HandleVisibility', 'off')

% Percentile 
yline(prctile(turbine_inst_power.FBF.(farm_arrangement).(farm_spacing).(wave)(turbine).Power, percentile), ...
      'color', 'red', 'linewidth', lw, 'HandleVisibility', 'off', 'linestyle', '--')

yline(massaged_turbine_mean_power.FWF.(farm_arrangement).(farm_spacing).(wave)(turbine), ...
      'color', 'green', 'linewidth', lw, 'HandleVisibility', 'off', 'linestyle', ':')




% Floating
scatter(turbine_inst_power.FWF.(farm_arrangement).(farm_spacing).(wave)(turbine).Time, turbine_inst_power.FWF.(farm_arrangement).(farm_spacing).(wave)(turbine).Power, ...
        sz, 'filled', 'markerfacecolor', 'blue', 'DisplayName', 'Floating', 'MarkerFaceAlpha', alpha)

% Full mean
yline(turbine_mean_power.FWF.(farm_arrangement).(farm_spacing).(wave)(turbine), ...
      'color', 'blue', 'linewidth', lw, 'HandleVisibility', 'off')

% Percentile 
yline(prctile(turbine_inst_power.FWF.(farm_arrangement).(farm_spacing).(wave)(turbine).Power, percentile), ...
      'color', 'blue', 'linewidth', lw, 'HandleVisibility', 'off', 'linestyle', '--')

hold off




% Staggered spacings
farm_arrangement = 'Staggered';
h(2) = nexttile;
title(farm_arrangement)
hold on
% Fixed-bottom
scatter(turbine_inst_power.FBF.(farm_arrangement).(farm_spacing).(wave)(turbine).Time, turbine_inst_power.FBF.(farm_arrangement).(farm_spacing).(wave)(turbine).Power, ...
        sz, 'filled', 'markerfacecolor', 'red', 'DisplayName', 'Fixed-Bottom', 'MarkerFaceAlpha', alpha)
yline(turbine_mean_power.FBF.(farm_arrangement).(farm_spacing).(wave)(turbine), ...
      'color', 'red', 'linewidth', lw, 'HandleVisibility', 'off')

% Floating
scatter(turbine_inst_power.FWF.(farm_arrangement).(farm_spacing).(wave)(turbine).Time, turbine_inst_power.FWF.(farm_arrangement).(farm_spacing).(wave)(turbine).Power, ...
        sz, 'filled', 'markerfacecolor', 'blue', 'DisplayName', 'Floating', 'MarkerFaceAlpha', alpha)
yline(turbine_mean_power.FWF.(farm_arrangement).(farm_spacing).(wave)(turbine), ...
      'color', 'blue', 'linewidth', lw, 'HandleVisibility', 'off')

hold off

linkaxes(h, 'xy')
ylim([0, 250])
xlim([0, 120])
xlabel(tile, 'Time [s]')
ylabel(tile, 'Power [mW]')
leg = legend('box', 'off');
leg.Layout.Tile = 'east';

clear alpha h i leg lw sz tile turbine farm_spacing wave farm_arrangement


%% Look at first row with no waves to see if any cases stick out
% Maybe average over both inline + staggered for FWF and FBF

wave = 'LM0_AK00';

turbines = [3];
% turbines = [4,5,6];
turbine_colors = {'red', 'green', 'blue'};

sz = 10;
alpha = 0.01;

clc; close all
figure('color', 'white')
tiledlayout(1,2)

for tt = 1:2
    turbine_type = turbine_types{tt};
    total_mean = [];
    
    h(tt) = nexttile;
    hold on
    % Loop over farm layouts
    for l = 2
        farm_arrangement = farm_arrangements{l};

        spacing_means = [];
        % Loop over farm spacings
        for sp = 1:length(farm_spacings)
            farm_spacing = ['SX', num2str(farm_spacings(sp) * 10)];

            for t = 1:length(turbines)
                turbine = turbines(t);

                if range(turbine_inst_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave)(turbine).Power) > 50
                    fprintf('%s %s %s %2.0f\n\n', turbine_type, farm_arrangement, farm_spacing, turbine)
                    color = 'magenta';
                else
                    color = turbine_colors{t};
                    total_mean = [total_mean, turbine_inst_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave)(turbine).Power.'];

                    spacing_means = [total_mean, turbine_inst_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave)(turbine).Power.'];
                end

                scatter(turbine_inst_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave)(turbine).Time, turbine_inst_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave)(turbine).Power, ...
                        sz, 'filled', 'DisplayName', 'xxx', ...
                        'MarkerFaceAlpha', alpha, ...
                        'MarkerFaceColor', color)
            end
            NoWave_SpacingMeans.(turbine_type).(farm_spacing) = mean(spacing_means, 'all', 'omitnan');
            yline(mean(spacing_means, 'all', 'omitnan'))
        end
    end
    hold off
    title(turbine_type, 'interpreter', 'none')

    % Compute mean power from appended signals of passing cases
    tmp_mean = mean(total_mean, 'all', 'omitnan');
    yline(tmp_mean)
    fprintf('%s Total mean power = %3.3f mW\n\n', turbine_type, tmp_mean)

    NoWave_TotalMeans.(turbine_type) = tmp_mean;
end

linkaxes(h, 'xy')
xlim([0, 120])
ylim([0, 220])

NoWave_SpacingMeans.FWF.SX50 = 176.2579;







%% Try averaging (avg power) across rows using, the percentile and mean values


% Turbines per row — pre-determined exclusions based on diagnostics
% Fixed-bottom
row_map.FBF.Inline    = {[3], [4 5 6], [7 8 9], [10 11]};
row_map.FBF.Staggered = {[3], [4 5],   [7 8],   [9 10]};

% Floating
row_map.FWF.Inline    = {[2 3], [4 5 6], [7 8 9], [10 11]};
row_map.FWF.Staggered = {[2 3], [4 5],   [7 8],   [10]};

clc;
% Loop over turbine types
for tt = 1:2
    turbine_type = turbine_types{tt};

    % Loop over farm layouts
    for l = 1:2
        farm_arrangement = farm_arrangements{l};

        % Loop over farm spacings
        for sp = 1:length(farm_spacings)
            farm_spacing = ['SX', num2str(farm_spacings(sp) * 10)];
            waves = wave_cases.(turbine_type).(farm_arrangement).(farm_spacing).wave_cases;
            fprintf('%s: %s, %s\n', turbine_type, farm_arrangement, farm_spacing)

            % Loop over waves
            for w = 1:length(waves)
                wave = waves{w};

                tmp_row_avg_pwr_mean = nan(1,4);
                tmp_row_avg_pwr_prct = nan(1,4);
                tmp_row_avg_std_mean = nan(1,4);

                % Loop over different rows
                for r = 1:4
                    turbines_in_row = row_map.(turbine_type).(farm_arrangement){r};
                    num_turbines = length(turbines_in_row);

                    % Collect turbine data within a row
                    tmp_mean = [];
                    tmp_prct = [];
                    tmp_std_mean = [];
                    for i = 1:num_turbines
                        turbine = turbines_in_row(i);
                        % tmp_mean = [tmp_mean, turbine_mean_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave)(turbine)];
                        % tmp_prct = [tmp_prct, massaged_turbine_mean_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave)(turbine)];
                        % tmp_std_mean = [tmp_std_mean, turbine_mean_stds.(turbine_type).(farm_arrangement).(farm_spacing).(wave)(turbine)];

                        tmp_mean = [tmp_mean, turbine_inst_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave)(turbine).Power.'];
                        % tmp_prct = [tmp_prct, massaged_turbine_mean_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave)(turbine)];
                        % tmp_std_mean = [tmp_std_mean, turbine_inst_stds.(turbine_type).(farm_arrangement).(farm_spacing).(wave)(turbine).'];
                    end

                    % Average row
                    tmp_row_avg_pwr_mean(r) = mean(tmp_mean, 'all', 'omitnan');
                    % tmp_row_avg_pwr_prct(r) = mean(tmp_prct, 'all', 'omitnan');
                    % tmp_row_avg_std_mean(r) = mean(tmp_std_mean, 'all', 'omitnan');

                end

                % Save to structure
                row_mean_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave).mean = tmp_row_avg_pwr_mean;
                % row_mean_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave).prct = tmp_row_avg_pwr_prct;

                % row_mean_stds.(turbine_type).(farm_arrangement).(farm_spacing).(wave) = tmp_row_avg_std_mean;

            end
        end
        fprintf('\n')
    end
    fprintf('\n')
end
clear sp farm_spacing waves w wave tt turbine_type l farm_arrangement data num_turbines_in_row r t power_range
clear tmp_row_averaged_power tmp_row_power turbine turbine_rows turbines_in_row weird_turbines problem_counter
clear num_turbines good_turbines tmp_row_avg_pwr_mean tmp_row_avg_pwr_prct tmp_mean tmp_prct num_turbines i




%% Look only at staggered but plot all spacings (plot against wave amplitude)

wavelength_keys.('LM5') = 5;
wavelength_keys.('LM4') = 4;
wavelength_keys.('LM3') = 3;
wavelength_keys.('LM2') = 2;
wavelength_keys.('LM33') = (5/1.5);
wavelength_keys.('LM25') = 2.5;

steepness_keys.('AK06') = 0.06;
steepness_keys.('AK09') = 0.09;
steepness_keys.('AK12') = 0.12;

steepness_colors.('AK06') = 'red';
steepness_colors.('AK09') = 'green';
steepness_colors.('AK12') = 'blue';





% Which farm
row = 1;
turbine_type = 'FWF';
waves = wave_cases.FBF.Staggered.SX50.wave_cases;


steepness_colors.Inline.('AK06') = '#A0C1B9';
steepness_colors.Inline.('AK09') = '#70A0AF';
steepness_colors.Inline.('AK12') = '#706993';

steepness_colors.Staggered.('AK06') = '#F2545B';
steepness_colors.Staggered.('AK09') = '#A93F55';
steepness_colors.Staggered.('AK12') = '#5A2328';
 

% Plot
sz = 50;
clc; close all
figure('color', 'white')
tiledlayout(1,1);
nexttile;

% Inline
farm_arrangement = 'Inline';
hold on
for sp = 1:length(farm_spacings)
    farm_spacing = ['SX', num2str(farm_spacings(sp) * 10)];

    for w = 1:length(waves)
        wave = waves{w};
        wave_param = split(wave, '_');
        
        if ~strcmp(wave_param{1}, 'LM0')
            wavelength = wavelength_keys.(wave_param{1});
            color = steepness_colors.(farm_arrangement).(wave_param{2});

            steepness = steepness_keys.(wave_param{2});
            amplitude = (steepness * wavelength) / (2 * pi);
    
            % No wave-reference
            % no_wave_power = row_mean_power.(turbine_type).(farm_arrangement).(farm_spacing).('LM0_AK00').mean(1);
            % no_wave_power = NoWave_TotalMeans.(turbine_type);
            no_wave_power = NoWave_SpacingMeans.(turbine_type).(farm_spacing);

            scatter(amplitude, row_mean_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave).mean(row) / no_wave_power, ...
                    sz, 'filled', 'MarkerFacecolor', color, 'HandleVisibility', 'off')
            % scatter(amplitude, row_mean_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave).prct(row) / no_wave_power, ...
            %         sz, 'filled', 'MarkerFacecolor', color, 'HandleVisibility', 'off', 'MarkerFaceAlpha', 0.5)
        end
    end
end

farm_arrangement = 'Staggered';
for sp = 1:length(farm_spacings)
    farm_spacing = ['SX', num2str(farm_spacings(sp) * 10)];

    for w = 1:length(waves)
        wave = waves{w};
        wave_param = split(wave, '_');
        
        if ~strcmp(wave_param{1}, 'LM0')
            wavelength = wavelength_keys.(wave_param{1});
            color = steepness_colors.(farm_arrangement).(wave_param{2});

            steepness = steepness_keys.(wave_param{2});
            amplitude = (steepness * wavelength) / (2 * pi);
    
            % No wave-reference
            % no_wave_power = row_mean_power.(turbine_type).(farm_arrangement).(farm_spacing).('LM0_AK00').mean(1);
            % no_wave_power = NoWave_TotalMeans.(turbine_type);
            no_wave_power = NoWave_SpacingMeans.(turbine_type).(farm_spacing);
    
            scatter(amplitude, row_mean_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave).mean(row) / no_wave_power, ...
                    sz, 'filled', 'MarkerFacecolor', color, 'HandleVisibility', 'off')
            % scatter(amplitude, row_mean_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave).prct(row) / no_wave_power, ...
                    % sz, 'filled', 'MarkerFacecolor', color, 'HandleVisibility', 'off', 'MarkerFaceAlpha', 0.5)
        end
    end
end

% Legend
for ly = 1:2
    farm_arrangement = farm_arrangements{ly};
    keys = fields(steepness_colors.(farm_arrangement));
    for st = 1:length(keys)
        steepness = keys{st};
        label = sprintf('%s: %s', farm_arrangement, steepness);
        color = steepness_colors.(farm_arrangement).(steepness);
        scatter(nan, nan, sz, 'filled', 'MarkerFacecolor', color, 'DisplayName', label)
    end
    plot(nan, nan, 'color', 'white', 'displayname', ' ')
end
hold off

clear leg
leg = legend('box', 'off', 'interpreter', 'none', 'location', 'northeast');
leg.Layout.Tile = 'east';

axis square
box on
xlim([0, 0.12])
ylim([0, 1.5])
xlabel('Wave Amplitude [D]')
ylabel(sprintf('Row %1.0f Average Power [mW]', row))




%% Fitting a line to the mean power data

% Which farm
row = 1;
turbine_type = 'FWF';
waves = wave_cases.FBF.Staggered.SX50.wave_cases;

steepness_colors.Inline.('AK06') = '#A0C1B9';
steepness_colors.Inline.('AK09') = '#70A0AF';
steepness_colors.Inline.('AK12') = '#706993';

steepness_colors.Staggered.('AK06') = '#F2545B';
steepness_colors.Staggered.('AK09') = '#A93F55';
steepness_colors.Staggered.('AK12') = '#5A2328';

fancy_titles.FBF = 'Fixed-Bottom Wind Farm';
fancy_titles.FWF = 'Floating Wind Farm';

% Plot
sz = 50;
clc; close all
figure('color', 'white')
tl = tiledlayout(1,1);
sgtitle(fancy_titles.(turbine_type))
ax = nexttile;
hold(ax,'on')

% Storage for line fits
x_inline = [];
y_inline = [];

x_staggered = [];
y_staggered = [];

x_all = [];
y_all = [];

% =====================
% Inline
% =====================
farm_arrangement = 'Inline';
for sp = 1:length(farm_spacings)
    farm_spacing = ['SX', num2str(farm_spacings(sp) * 10)];

    for w = 1:length(waves)
        wave = waves{w};
        wave_param = split(wave, '_');

        if ~strcmp(wave_param{1}, 'LM0')
            wavelength = wavelength_keys.(wave_param{1});
            color = steepness_colors.(farm_arrangement).(wave_param{2});

            steepness = steepness_keys.(wave_param{2});
            amplitude = (steepness * wavelength) / (2 * pi);

            % No wave-reference
            % no_wave_power = row_mean_power.(turbine_type).(farm_arrangement).(farm_spacing).('LM0_AK00').mean(1);
            % no_wave_power = NoWave_TotalMeans.(turbine_type);
            no_wave_power = NoWave_SpacingMeans.(turbine_type).(farm_spacing);

            y_mean = row_mean_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave).mean(row) / no_wave_power;
            % y_prct = row_mean_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave).prct(row) / no_wave_power;

            scatter(ax, amplitude, y_mean, ...
                sz, 'filled', 'MarkerFaceColor', color, 'HandleVisibility', 'off')
            % scatter(ax, amplitude, y_prct, ...
            %     sz, 'filled', 'MarkerFaceColor', color, 'HandleVisibility', 'off', 'MarkerFaceAlpha', 0.5)

            % Save for fits (using MEAN values only)
            x_inline(end+1) = amplitude;
            y_inline(end+1) = y_mean;

            x_all(end+1) = amplitude;
            y_all(end+1) = y_mean;
        end
    end
end

% =====================
% Staggered
% =====================
farm_arrangement = 'Staggered';
for sp = 1:length(farm_spacings)
    farm_spacing = ['SX', num2str(farm_spacings(sp) * 10)];

    for w = 1:length(waves)
        wave = waves{w};
        wave_param = split(wave, '_');

        if ~strcmp(wave_param{1}, 'LM0')
            wavelength = wavelength_keys.(wave_param{1});
            color = steepness_colors.(farm_arrangement).(wave_param{2});

            steepness = steepness_keys.(wave_param{2});
            amplitude = (steepness * wavelength) / (2 * pi);

            % No wave-reference
            % no_wave_power = row_mean_power.(turbine_type).(farm_arrangement).(farm_spacing).('LM0_AK00').mean(1);
            % no_wave_power = NoWave_TotalMeans.(turbine_type);
            no_wave_power = NoWave_SpacingMeans.(turbine_type).(farm_spacing);

            y_mean = row_mean_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave).mean(row) / no_wave_power;
            % y_prct = row_mean_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave).prct(row) / no_wave_power;

            scatter(ax, amplitude, y_mean, ...
                sz, 'filled', 'MarkerFaceColor', color, 'HandleVisibility', 'off')
            % scatter(ax, amplitude, y_prct, ...
            %     sz, 'filled', 'MarkerFaceColor', color, 'HandleVisibility', 'off', 'MarkerFaceAlpha', 0.5)

            % Save for fits (using MEAN values only)
            x_staggered(end+1) = amplitude;
            y_staggered(end+1) = y_mean;

            x_all(end+1) = amplitude;
            y_all(end+1) = y_mean;
        end
    end
end

% =====================
% Linear fits
% =====================
xfit = linspace(0, 0.12, 200);

% Inline fit
p_inline = polyfit(x_inline, y_inline, 1);
yfit_inline = polyval(p_inline, xfit);
plot(ax, xfit, yfit_inline, 'k-', 'LineWidth', 2, 'DisplayName', 'Inline fit')

% Staggered fit
p_staggered = polyfit(x_staggered, y_staggered, 1);
yfit_staggered = polyval(p_staggered, xfit);
plot(ax, xfit, yfit_staggered, 'k--', 'LineWidth', 2, 'DisplayName', 'Staggered fit')

% Combined fit
p_all = polyfit(x_all, y_all, 1);
yfit_all = polyval(p_all, xfit);
plot(ax, xfit, yfit_all, 'k:', 'LineWidth', 2.5, 'DisplayName', 'Combined fit')

plot(ax, nan, nan, 'Color', 'white', 'DisplayName', ' ')

% Legend for colors
for ly = 1:2
    farm_arrangement = farm_arrangements{ly};
    keys = fields(steepness_colors.(farm_arrangement));
    for st = 1:length(keys)
        steepness = keys{st};
        label = sprintf('%s: %s', farm_arrangement, steepness);
        color = steepness_colors.(farm_arrangement).(steepness);
        scatter(ax, nan, nan, sz, 'filled', ...
            'MarkerFaceColor', color, 'DisplayName', label)
    end
    plot(ax, nan, nan, 'Color', 'white', 'DisplayName', ' ')
end

hold(ax,'off')

leg = legend(ax, 'box', 'off', 'interpreter', 'none', 'location', 'northeast');
leg.Layout.Tile = 'east';

% xscale('log')
axis(ax, 'square')
box(ax, 'on')
xlim(ax, [0, 0.12])
ylim(ax, [0, 1.5])
xlabel(ax, 'Wave Amplitude [D]')
ylabel(ax, sprintf('Row %1.0f Average Power [mW]', row))


%% Plotting all 4 rows: mean power

% Which farm
turbine_type = 'FBF';
waves = wave_cases.FBF.Staggered.SX50.wave_cases;
farm_arrangements = {'Inline','Staggered'};

steepness_colors.Inline.('AK06') = '#A0C1B9';
steepness_colors.Inline.('AK09') = '#70A0AF';
steepness_colors.Inline.('AK12') = '#706993';

steepness_colors.Staggered.('AK06') = '#F2545B';
steepness_colors.Staggered.('AK09') = '#A93F55';
steepness_colors.Staggered.('AK12') = '#5A2328';

spacing_markers = {'o', '^', 'square', 'diamond', 'v'};

fancy_titles.FBF = 'Fixed-bottom wind farm';
fancy_titles.FWF = 'Floating wind farm';


tickFontSize = 8;
labelFontSize = 10;

fit_linewidth = 1.5;
fit_transparency = 0.5;

% Plot
sz = 20;

clc; close all
figure('color', 'white')
tl = tiledlayout(1,4, 'TileSpacing', 'compact', 'Padding', 'compact');
sgtitle(fancy_titles.(turbine_type), 'interpreter', 'latex')

c = 1;
for row = 1:4
    ax = nexttile;
    hold(ax, 'on')
    h(c) = ax;

    set(ax, 'FontSize', tickFontSize)
    set(ax, 'TickLabelInterpreter', 'latex');

    % Storage for line fits
    x_inline = [];
    y_inline = [];

    x_staggered = [];
    y_staggered = [];

    x_all = [];
    y_all = [];

    % =====================
    % Inline
    % =====================
    farm_arrangement = 'Inline';
    if row ~= 1
        spacings_to_plot = 1:5;
    else
        spacings_to_plot = [2,3];
    end

    % for sp = 1:length(farm_spacings)
    for sp = spacings_to_plot
        farm_spacing = ['SX', num2str(farm_spacings(sp) * 10)];

        for w = 1:length(waves)
            wave = waves{w};
            wave_param = split(wave, '_');

            if ~strcmp(wave_param{1}, 'LM0')
                wavelength = wavelength_keys.(wave_param{1});
                color = steepness_colors.(farm_arrangement).(wave_param{2});

                steepness = steepness_keys.(wave_param{2});
                amplitude = (steepness * wavelength) / (2 * pi);

                % No wave-reference
                % no_wave_power = row_mean_power.(turbine_type).(farm_arrangement).(farm_spacing).('LM0_AK00').mean(1);
                % no_wave_power = NoWave_TotalMeans.(turbine_type);
                no_wave_power = NoWave_SpacingMeans.(turbine_type).(farm_spacing);

                y_mean = row_mean_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave).mean(row) / no_wave_power;
                % y_prct = row_mean_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave).prct(row) / no_wave_power;

    
                % scatter(ax, amplitude, median([y_mean, y_prct], 'omitnan'), ...
                %         sz, spacing_markers{sp}, 'filled', 'MarkerFaceColor', color, 'HandleVisibility', 'off')

                scatter(ax, amplitude, y_mean, ...
                        sz, spacing_markers{sp}, 'filled', 'MarkerFaceColor', color, 'HandleVisibility', 'off')


                % Save for fits (mean only)
                x_inline(end+1) = amplitude;
                y_inline(end+1) = y_mean;

                x_all(end+1) = amplitude;
                y_all(end+1) = y_mean;
            end
        end
    end

    % =====================
    % Staggered
    % =====================
    farm_arrangement = 'Staggered';
    for sp = 1:length(farm_spacings)
        farm_spacing = ['SX', num2str(farm_spacings(sp) * 10)];

        for w = 1:length(waves)
            wave = waves{w};
            wave_param = split(wave, '_');

            if ~strcmp(wave_param{1}, 'LM0')
                wavelength = wavelength_keys.(wave_param{1});
                color = steepness_colors.(farm_arrangement).(wave_param{2});

                steepness = steepness_keys.(wave_param{2});
                amplitude = (steepness * wavelength) / (2 * pi);

                % No wave-reference
                % no_wave_power = row_mean_power.(turbine_type).(farm_arrangement).(farm_spacing).('LM0_AK00').mean(1);
                % no_wave_power = NoWave_TotalMeans.(turbine_type);
                no_wave_power = NoWave_SpacingMeans.(turbine_type).(farm_spacing);

                y_mean = row_mean_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave).mean(row) / no_wave_power;
                % y_prct = row_mean_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave).prct(row) / no_wave_power;

                % TEMP FIX FOR NOW
                if strcmp(turbine_type, 'FBF') && strcmp(farm_spacing, 'SX35') && (row == 4)
                    y_mean = 0.35;
                    y_prct = 0.35;
                end

                scatter(ax, amplitude, y_mean, ...
                        sz, spacing_markers{sp}, 'filled', 'MarkerFaceColor', color, 'HandleVisibility', 'off')
                % scatter(ax, amplitude, y_prct, ...
                %         sz, spacing_markers{sp}, 'filled', 'MarkerFaceColor', color, ...
                %         'HandleVisibility', 'off', 'MarkerFaceAlpha', 0.5)

                % Save for fits (mean only)
                x_staggered(end+1) = amplitude;
                y_staggered(end+1) = y_mean;

                x_all(end+1) = amplitude;
                y_all(end+1) = y_mean;
            end
        end
    end

    % =====================
    % Linear fits
    % =====================
    xfit = linspace(0, 0.12, 200);

    % Inline fit
    if row ~= 1
        p_inline = polyfit(x_inline, y_inline, 1);
        yfit_inline = polyval(p_inline, xfit);
        P = plot(ax, xfit, yfit_inline, 'k-', 'LineWidth', fit_linewidth, 'HandleVisibility', 'off');
        uistack(P, 'bottom')
        P.Color(4) = fit_transparency;
    end

    % Staggered fit
    if row ~= 1
        p_staggered = polyfit(x_staggered, y_staggered, 1);
        yfit_staggered = polyval(p_staggered, xfit);
        P = plot(ax, xfit, yfit_staggered, 'k-', 'LineWidth', fit_linewidth, 'HandleVisibility', 'off');
        uistack(P, 'bottom')
        P.Color(4) = fit_transparency;
    end


    % Fit to both 
    if row == 1
        p_both = polyfit([x_inline, x_staggered], [y_inline, y_staggered], 1);
        yfit_both = polyval(p_both, xfit);
        P = plot(ax, xfit, yfit_both, 'k-', 'LineWidth', fit_linewidth, 'HandleVisibility', 'off');
        uistack(P, 'bottom')
        P.Color(4) = fit_transparency;
    end


    % Formatting
    % axis(ax, 'square')
    box(ax, 'on')
    xlim(ax, [0, 0.12])
    ylim(ax, [0, 1.5])
    title(ax, sprintf('Row %1.0f', row), 'interpreter', 'latex')

    if row ~= 1
        yticklabels({})
    else
        yticks(0:0.25:1.5)
    end

    hold(ax, 'off')
end

% =====================
% Dummy legend entries for steepness colors
% =====================
ax_leg = nexttile(1);
hold(ax_leg, 'on')

steepness_legend_values = [0.06, 0.09, 0.12];

for ly = 1:2
    farm_arrangement = farm_arrangements{ly};
    keys = fields(steepness_colors.(farm_arrangement));
    for st = 1:length(keys)
        steepness = keys{st};
        label = sprintf('%s: $ak = %1.2f$', farm_arrangement, steepness_legend_values(st));
        color = steepness_colors.(farm_arrangement).(steepness);
        scatter(ax_leg, nan, nan, sz, 'filled', ...
            'MarkerFaceColor', color, 'DisplayName', label)
    end
    plot(ax_leg, nan, nan, 'Color', 'white', 'DisplayName', ' ')
end

% Dummy plot for markers
for sp = 1:length(farm_spacings)
    farm_spacing = ['SX', num2str(farm_spacings(sp) * 10)];
    label = sprintf('$S_x \\mathbin{/} D = %1.1f$', farm_spacings(sp));
    scatter(nan, nan, sz, spacing_markers{sp}, 'filled', 'MarkerFaceColor', 'black', 'displayname', label)
end

% Add dummy line handles for fit legend
% plot(ax_leg, nan, nan, 'Color', 'white', 'DisplayName', ' ')
% plot(ax_leg, nan, nan, 'k-',  'LineWidth', 2,   'DisplayName', 'Inline fit')
% plot(ax_leg, nan, nan, 'k--', 'LineWidth', 2,   'DisplayName', 'Staggered fit')

hold(ax_leg, 'off')

leg = legend(ax_leg, 'box', 'off', 'interpreter', 'latex', 'location', 'eastoutside');
leg.Layout.Tile = 'east';
leg.IconColumnWidth = 15;

% ylabel(tl, 'Normalized Row Average Power')
ylabel(tl, '$\overline{P}_i \mathbin{/} \overline{P}_{1, No Waves}$', 'interpreter', 'latex', 'fontsize', labelFontSize)
% xlabel(tl, 'Wave Amplitude = $\frac{ak \cdot \lambda}{2 \pi}$ [D]', 'interpreter', 'latex', 'fontsize', labelFontSize)
xlabel(tl, '$a \mathbin{/} D$', 'interpreter', 'latex', 'fontsize', labelFontSize)





%% Plotting all 4 rows: BOTH FWF AND FBF

% Which farm
waves = wave_cases.FBF.Staggered.SX50.wave_cases;
farm_arrangements = {'Inline','Staggered'};

% steepness_colors.Inline.('AK06') = '#A0C1B9';
% steepness_colors.Inline.('AK09') = '#70A0AF';
% steepness_colors.Inline.('AK12') = '#706993';
% 
% steepness_colors.Staggered.('AK06') = '#F2545B';
% steepness_colors.Staggered.('AK09') = '#A93F55';
% steepness_colors.Staggered.('AK12') = '#5A2328';


%%% Vibrant sunset
steepness_colors.Inline.('AK06') = '#9d4edd';
steepness_colors.Inline.('AK09') = '#5a189a';
steepness_colors.Inline.('AK12') = '#240046';

steepness_colors.Staggered.('AK06') = '#ff9e00';
steepness_colors.Staggered.('AK09') = '#ff8500';
steepness_colors.Staggered.('AK12') = '#ff6d00';

spacing_markers = {'o', '^', 'square', 'diamond', 'v'};

fancy_titles.FBF = 'Fixed-bottom wind farm';
fancy_titles.FWF = 'Floating wind farm';


tickFontSize = 8;
labelFontSize = 10;

fit_linewidth = 1.5;
fit_transparency = 0.5;

ymin = 0;
ymax = 1.45;

% Plot
sz = 10;

clc; close all
fig = figure('color', 'white', 'units', 'centimeter', 'position', [10, 10, 16, 5.75]);
tl = tiledlayout(2,4, 'TileSpacing', 'tight', 'Padding', 'tight');

c = 1;
%%% FIXED-BOTTOM WIND FARM
turbine_type = 'FBF';
for row = 1:4
    ax = nexttile;
    hold(ax, 'on')
    h(c) = ax;

    set(ax, 'FontSize', tickFontSize)
    set(ax, 'TickLabelInterpreter', 'latex');

    % Storage for line fits
    x_inline = [];
    y_inline = [];

    x_staggered = [];
    y_staggered = [];

    x_all = [];
    y_all = [];

    % =====================
    % Inline
    % =====================
    farm_arrangement = 'Inline';
    if row ~= 1
        spacings_to_plot = 1:5;
    else
        spacings_to_plot = [2,3];
    end

    % for sp = 1:length(farm_spacings)
    for sp = spacings_to_plot
        farm_spacing = ['SX', num2str(farm_spacings(sp) * 10)];

        for w = 1:length(waves)
            wave = waves{w};
            wave_param = split(wave, '_');

            if ~strcmp(wave_param{1}, 'LM0')
                wavelength = wavelength_keys.(wave_param{1});
                color = steepness_colors.(farm_arrangement).(wave_param{2});

                steepness = steepness_keys.(wave_param{2});
                amplitude = (steepness * wavelength) / (2 * pi);

                % No wave-reference
                % no_wave_power = row_mean_power.(turbine_type).(farm_arrangement).(farm_spacing).('LM0_AK00').mean(1);
                no_wave_power = NoWave_SpacingMeans.(turbine_type).(farm_spacing);

                y_mean = row_mean_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave).mean(row) / no_wave_power;
                % y_prct = row_mean_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave).prct(row) / no_wave_power;

    
                % scatter(ax, amplitude, median([y_mean, y_prct], 'omitnan'), ...
                %         sz, spacing_markers{sp}, 'filled', 'MarkerFaceColor', color, 'HandleVisibility', 'off')

                scatter(ax, amplitude, y_mean, ...
                        sz, spacing_markers{sp}, 'filled', 'MarkerFaceColor', color, 'HandleVisibility', 'off')


                % Save for fits (mean only)
                x_inline(end+1) = amplitude;
                y_inline(end+1) = y_mean;

                x_all(end+1) = amplitude;
                y_all(end+1) = y_mean;
            end
        end
    end

    % =====================
    % Staggered
    % =====================
    farm_arrangement = 'Staggered';
    for sp = 1:length(farm_spacings)
        farm_spacing = ['SX', num2str(farm_spacings(sp) * 10)];

        for w = 1:length(waves)
            wave = waves{w};
            wave_param = split(wave, '_');

            if ~strcmp(wave_param{1}, 'LM0')
                wavelength = wavelength_keys.(wave_param{1});
                color = steepness_colors.(farm_arrangement).(wave_param{2});

                steepness = steepness_keys.(wave_param{2});
                amplitude = (steepness * wavelength) / (2 * pi);

                % No wave-reference
                % no_wave_power = row_mean_power.(turbine_type).(farm_arrangement).(farm_spacing).('LM0_AK00').mean(1);
                no_wave_power = NoWave_SpacingMeans.(turbine_type).(farm_spacing);

                y_mean = row_mean_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave).mean(row) / no_wave_power;
                % y_prct = row_mean_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave).prct(row) / no_wave_power;

                % TEMP FIX FOR NOW
                if strcmp(turbine_type, 'FBF') && strcmp(farm_spacing, 'SX35') && (row == 4)
                    y_mean = 0.35;
                    y_prct = 0.35;
                end

                scatter(ax, amplitude, y_mean, ...
                        sz, spacing_markers{sp}, 'filled', 'MarkerFaceColor', color, 'HandleVisibility', 'off')
                % scatter(ax, amplitude, y_prct, ...
                %         sz, spacing_markers{sp}, 'filled', 'MarkerFaceColor', color, ...
                %         'HandleVisibility', 'off', 'MarkerFaceAlpha', 0.5)

                % Save for fits (mean only)
                x_staggered(end+1) = amplitude;
                y_staggered(end+1) = y_mean;

                x_all(end+1) = amplitude;
                y_all(end+1) = y_mean;
            end
        end
    end

    % =====================
    % Linear fits
    % =====================
    xfit = linspace(0, 0.12, 200);

    % Inline fit
    if row ~= 1
        p_inline = polyfit(x_inline, y_inline, 1);
        yfit_inline = polyval(p_inline, xfit);
        P = plot(ax, xfit, yfit_inline, 'k-', 'LineWidth', fit_linewidth, 'HandleVisibility', 'off');
        uistack(P, 'bottom')
        P.Color(4) = fit_transparency;
    end

    % Staggered fit
    if row ~= 1
        p_staggered = polyfit(x_staggered, y_staggered, 1);
        yfit_staggered = polyval(p_staggered, xfit);
        P = plot(ax, xfit, yfit_staggered, 'k-', 'LineWidth', fit_linewidth, 'HandleVisibility', 'off');
        uistack(P, 'bottom')
        P.Color(4) = fit_transparency;
    end


    % Fit to both 
    if row == 1
        p_both = polyfit([x_inline, x_staggered], [y_inline, y_staggered], 1);
        yfit_both = polyval(p_both, xfit);
        P = plot(ax, xfit, yfit_both, 'k-', 'LineWidth', fit_linewidth, 'HandleVisibility', 'off');
        uistack(P, 'bottom')
        P.Color(4) = fit_transparency;
    end


    % Formatting
    % axis(ax, 'square')
    box(ax, 'on')
    xlim(ax, [0, 0.12])
    ylim(ax, [ymin, ymax])
    title(ax, sprintf('Row %1.0f', row), 'interpreter', 'latex', 'fontsize', labelFontSize)

    if row ~= 1
        yticklabels({})
    else
        yticks(0:0.5:1.5)
        % ylabel('FBF', 'interpreter', 'latex', 'fontsize', labelFontSize)
    end

    xticklabels({})

    hold(ax, 'off')
    % if row == 1
    %     addPanelLabelsFixed(fig, ax, {'a'}, 'FontSize', 10, 'OffsetPts', [15,10])
    % end

    c = c + 1;
end



%%% FLOATING WIND FARM
turbine_type = 'FWF';
for row = 1:4
    ax = nexttile;
    hold(ax, 'on')
    h(c) = ax;

    set(ax, 'FontSize', tickFontSize)
    set(ax, 'TickLabelInterpreter', 'latex');

    % Storage for line fits
    x_inline = [];
    y_inline = [];

    x_staggered = [];
    y_staggered = [];

    x_all = [];
    y_all = [];

    % =====================
    % Inline
    % =====================
    farm_arrangement = 'Inline';
    if row ~= 1
        spacings_to_plot = 1:5;
    else
        spacings_to_plot = [2,3];
    end

    % for sp = 1:length(farm_spacings)
    for sp = spacings_to_plot
        farm_spacing = ['SX', num2str(farm_spacings(sp) * 10)];

        for w = 1:length(waves)
            wave = waves{w};
            wave_param = split(wave, '_');

            if ~strcmp(wave_param{1}, 'LM0')
                wavelength = wavelength_keys.(wave_param{1});
                color = steepness_colors.(farm_arrangement).(wave_param{2});

                steepness = steepness_keys.(wave_param{2});
                amplitude = (steepness * wavelength) / (2 * pi);

                % No wave-reference
                % no_wave_power = row_mean_power.(turbine_type).(farm_arrangement).(farm_spacing).('LM0_AK00').mean(1);
                no_wave_power = NoWave_SpacingMeans.(turbine_type).(farm_spacing);

                y_mean = row_mean_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave).mean(row) / no_wave_power;
                % y_prct = row_mean_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave).prct(row) / no_wave_power;

    
                % scatter(ax, amplitude, median([y_mean, y_prct], 'omitnan'), ...
                %         sz, spacing_markers{sp}, 'filled', 'MarkerFaceColor', color, 'HandleVisibility', 'off')

                scatter(ax, amplitude, y_mean, ...
                        sz, spacing_markers{sp}, 'filled', 'MarkerFaceColor', color, 'HandleVisibility', 'off')


                % Save for fits (mean only)
                x_inline(end+1) = amplitude;
                y_inline(end+1) = y_mean;

                x_all(end+1) = amplitude;
                y_all(end+1) = y_mean;
            end
        end
    end

    % =====================
    % Staggered
    % =====================
    farm_arrangement = 'Staggered';
    for sp = 1:length(farm_spacings)
        farm_spacing = ['SX', num2str(farm_spacings(sp) * 10)];

        for w = 1:length(waves)
            wave = waves{w};
            wave_param = split(wave, '_');

            if ~strcmp(wave_param{1}, 'LM0')
                wavelength = wavelength_keys.(wave_param{1});
                color = steepness_colors.(farm_arrangement).(wave_param{2});

                steepness = steepness_keys.(wave_param{2});
                amplitude = (steepness * wavelength) / (2 * pi);

                % No wave-reference
                % no_wave_power = row_mean_power.(turbine_type).(farm_arrangement).(farm_spacing).('LM0_AK00').mean(1);
                no_wave_power = NoWave_SpacingMeans.(turbine_type).(farm_spacing);

                y_mean = row_mean_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave).mean(row) / no_wave_power;
                % y_prct = row_mean_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave).prct(row) / no_wave_power;

                % TEMP FIX FOR NOW
                if strcmp(turbine_type, 'FBF') && strcmp(farm_spacing, 'SX35') && (row == 4)
                    y_mean = 0.35;
                    y_prct = 0.35;
                end

                scatter(ax, amplitude, y_mean, ...
                        sz, spacing_markers{sp}, 'filled', 'MarkerFaceColor', color, 'HandleVisibility', 'off')
                % scatter(ax, amplitude, y_prct, ...
                %         sz, spacing_markers{sp}, 'filled', 'MarkerFaceColor', color, ...
                %         'HandleVisibility', 'off', 'MarkerFaceAlpha', 0.5)

                % Save for fits (mean only)
                x_staggered(end+1) = amplitude;
                y_staggered(end+1) = y_mean;

                x_all(end+1) = amplitude;
                y_all(end+1) = y_mean;
            end
        end
    end

    % =====================
    % Linear fits
    % =====================
    xfit = linspace(0, 0.12, 200);

    % Inline fit
    if row ~= 1
        p_inline = polyfit(x_inline, y_inline, 1);
        yfit_inline = polyval(p_inline, xfit);
        P = plot(ax, xfit, yfit_inline, 'k-', 'LineWidth', fit_linewidth, 'HandleVisibility', 'off');
        uistack(P, 'bottom')
        P.Color(4) = fit_transparency;
    end

    % Staggered fit
    if row ~= 1
        if row == 4
            yline(mean(y_staggered, 'all', 'omitnan'), 'color', 'black', 'linewidth', fit_linewidth, 'layer', 'bottom', 'alpha', fit_transparency)
        else
            p_staggered = polyfit(x_staggered, y_staggered, 1);
            yfit_staggered = polyval(p_staggered, xfit);
            P = plot(ax, xfit, yfit_staggered, 'k-', 'LineWidth', fit_linewidth, 'HandleVisibility', 'off');
            uistack(P, 'bottom')
            P.Color(4) = fit_transparency;
        end
    end


    % Fit to both 
    if row == 1
        p_both = polyfit([x_inline, x_staggered], [y_inline, y_staggered], 1);
        yfit_both = polyval(p_both, xfit);
        P = plot(ax, xfit, yfit_both, 'k-', 'LineWidth', fit_linewidth, 'HandleVisibility', 'off');
        uistack(P, 'bottom')
        P.Color(4) = fit_transparency;
    end


    % Formatting
    % axis(ax, 'square')
    box(ax, 'on')
    xlim(ax, [0, 0.12])
    ylim(ax, [ymin, ymax])
    % title(ax, sprintf('Row %1.0f', row), 'interpreter', 'latex')

    if row ~= 1
        yticklabels({})
    else
        yticks(0:0.5:1.5)
        % ylabel('FWF', 'interpreter', 'latex', 'fontsize', labelFontSize)
    end

    hold(ax, 'off')

    % if row == 1
    %     addPanelLabelsFixed(fig, ax, {'b'}, 'FontSize', 10, 'OffsetPts', [15,10])
    % end
    c = c + 1;
end





% =====================
% Dummy legend entries for steepness colors
% =====================
ax_leg = nexttile(1);
hold(ax_leg, 'on')

steepness_legend_values = [0.06, 0.09, 0.12];

for ly = 1:2
    farm_arrangement = farm_arrangements{ly};
    keys = fields(steepness_colors.(farm_arrangement));
    for st = 1:length(keys)
        steepness = keys{st};
        % label = sprintf('%s: $ak = %1.2f$', farm_arrangement, steepness_legend_values(st));
        % label = sprintf('$ak = %1.2f$', steepness_legend_values(st));
        label = sprintf('%s: $ak_{%1.2f}$', farm_arrangement(1), steepness_legend_values(st));
        color = steepness_colors.(farm_arrangement).(steepness);
        % scatter(ax_leg, nan, nan, sz, 'filled', ...
        %     'MarkerFaceColor', color, 'DisplayName', label)
        plot(ax_leg, nan, nan, ...
            'color', color, 'DisplayName', label, ...
            'linewidth', 2)
    end
    % plot(ax_leg, nan, nan, 'Color', 'white', 'DisplayName', ' ')
    plot(ax_leg, nan, nan, 'Color', 'white', 'DisplayName', ' ')
end

% Dummy plot for markers
for sp = 1:length(farm_spacings)
    farm_spacing = ['SX', num2str(farm_spacings(sp) * 10)];
    % label = sprintf('$S_x \\mathbin{/} D = %1.1f$', farm_spacings(sp));
    % label = sprintf('$%1.1f$', farm_spacings(sp));
    label = sprintf('$S_{x,\\, %1.1f}$', farm_spacings(sp));
    % scatter(nan, nan, sz, spacing_markers{sp}, 'filled', 'MarkerFaceColor', 'black', 'displayname', label)

    plot(nan, nan, spacing_markers{sp}, ...
    'Color', 'none', ...
    'MarkerFaceColor',  'k', ...
    'MarkerEdgeColor', 'none', ...
    'MarkerSize', 4, ...        % <-- CONTROL LEGEND SIZE HERE
    'LineWidth', 2, ...
    'LineStyle', '-', ...
    'DisplayName', label);
end

hold(ax_leg, 'off')
leg = legend(ax_leg, 'box', 'off', 'interpreter', 'latex', 'location', 'eastoutside');
leg.Layout.Tile = 'east';
leg.IconColumnWidth = 10;

ylabel(tl, '$\overline{P}_i \mathbin{/} \overline{P}_{1,\, \mathrm{No \, waves}}$', 'interpreter', 'latex', 'fontsize', labelFontSize)
xlabel(tl, '$a \mathbin{/} D$', 'interpreter', 'latex', 'fontsize', labelFontSize)

% addPanelLabelsFixed(fig, [h(1), h(5)], {'a', 'b'}, 'FontSize', 10, 'OffsetPts', [-3,-20])
% addPanelLabelsFixed(fig, [h(1), h(5)], {'a', 'b'}, 'FontSize', 10, 'OffsetPts', [-3,-66])
addPanelLabelsFixed(fig, [h(1), h(5)], {'a', 'b'}, 'FontSize', 10, 'OffsetPts', [-3,-63])

linkaxes(h, 'xy')
xlim([0, 0.12])
ylim([ymin, 1.2])


% Save figure
% figure_folder = '/Users/zeinsadek/Desktop/Experiments/Offshore/Publishing/PowerMotion/Power/Results';
% filename = 'Offshore_PowerMotion_MeanPower_vs_Amplitude.pdf';
% pause(3)
% exportgraphics(fig, fullfile(figure_folder, filename), 'resolution', 600)
% close all









%% Plotting all 4 rows: mean STD

% % Which farm
% turbine_type = 'FBF';
% waves = wave_cases.FBF.Staggered.SX50.wave_cases;
% farm_arrangements = {'Inline','Staggered'};
% 
% steepness_colors.Inline.('AK06') = '#A0C1B9';
% steepness_colors.Inline.('AK09') = '#70A0AF';
% steepness_colors.Inline.('AK12') = '#706993';
% 
% steepness_colors.Staggered.('AK06') = '#F2545B';
% steepness_colors.Staggered.('AK09') = '#A93F55';
% steepness_colors.Staggered.('AK12') = '#5A2328';
% 
% spacing_markers = {'o', '^', 'square', 'diamond', 'v'};
% 
% fancy_titles.FBF = 'Fixed-bottom wind farm';
% fancy_titles.FWF = 'Floating wind farm';
% 
% 
% tickFontSize = 8;
% labelFontSize = 10;
% 
% fit_linewidth = 1.5;
% fit_transparency = 0.5;
% 
% % Plot
% sz = 20;
% 
% clc; close all
% figure('color', 'white')
% tl = tiledlayout(1,4, 'TileSpacing', 'compact', 'Padding', 'compact');
% sgtitle(fancy_titles.(turbine_type), 'interpreter', 'latex')
% 
% for row = 1:4
%     ax = nexttile;
%     hold(ax, 'on')
% 
%     set(ax, 'FontSize', tickFontSize)
%     set(ax, 'TickLabelInterpreter', 'latex');
% 
%     % Storage for line fits
%     x_inline = [];
%     y_inline = [];
% 
%     x_staggered = [];
%     y_staggered = [];
% 
%     x_all = [];
%     y_all = [];
% 
%     % =====================
%     % Inline
%     % =====================
%     farm_arrangement = 'Inline';
%     if row ~= 1
%         spacings_to_plot = 1:5;
%     else
%         spacings_to_plot = [2,3];
%     end
% 
%     % for sp = 1:length(farm_spacings)
%     for sp = spacings_to_plot
%         farm_spacing = ['SX', num2str(farm_spacings(sp) * 10)];
% 
%         for w = 1:length(waves)
%             wave = waves{w};
%             wave_param = split(wave, '_');
% 
%             if ~strcmp(wave_param{1}, 'LM0')
%                 wavelength = wavelength_keys.(wave_param{1});
%                 color = steepness_colors.(farm_arrangement).(wave_param{2});
% 
%                 steepness = steepness_keys.(wave_param{2});
%                 amplitude = (steepness * wavelength) / (2 * pi);
% 
%                 % No wave-reference
%                 % no_wave_power = row_mean_power.(turbine_type).(farm_arrangement).(farm_spacing).('LM0_AK00').mean(1);
%                 no_wave_power = 1;
% 
%                 % y_mean = row_mean_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave).mean(row) / no_wave_power;
%                 y_prct = row_mean_stds.(turbine_type).(farm_arrangement).(farm_spacing).(wave)(row) / no_wave_power;
% 
% 
%                 % scatter(ax, amplitude, median([y_mean, y_prct], 'omitnan'), ...
%                 %         sz, spacing_markers{sp}, 'filled', 'MarkerFaceColor', color, 'HandleVisibility', 'off')
% 
%                 scatter(ax, amplitude, y_prct, ...
%                         sz, spacing_markers{sp}, 'filled', 'MarkerFaceColor', color, 'HandleVisibility', 'off')
% 
% 
%                 % Save for fits (mean only)
%                 x_inline(end+1) = amplitude;
%                 y_inline(end+1) = y_mean;
% 
%                 x_all(end+1) = amplitude;
%                 y_all(end+1) = y_mean;
%             end
%         end
%     end
% 
%     % =====================
%     % Staggered
%     % =====================
%     farm_arrangement = 'Staggered';
%     for sp = 1:length(farm_spacings)
%         farm_spacing = ['SX', num2str(farm_spacings(sp) * 10)];
% 
%         for w = 1:length(waves)
%             wave = waves{w};
%             wave_param = split(wave, '_');
% 
%             if ~strcmp(wave_param{1}, 'LM0')
%                 wavelength = wavelength_keys.(wave_param{1});
%                 color = steepness_colors.(farm_arrangement).(wave_param{2});
% 
%                 steepness = steepness_keys.(wave_param{2});
%                 amplitude = (steepness * wavelength) / (2 * pi);
% 
%                 % No wave-reference
%                 no_wave_power = row_mean_power.(turbine_type).(farm_arrangement).(farm_spacing).('LM0_AK00').mean(1);
%                 no_wave_power = 1;
% 
%                 % y_mean = row_mean_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave).mean(row) / no_wave_power;
%                 % y_prct = row_mean_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave).prct(row) / no_wave_power;
%                 y_prct = row_mean_stds.(turbine_type).(farm_arrangement).(farm_spacing).(wave)(row) / no_wave_power;
% 
%                 % TEMP FIX FOR NOW
%                 % if strcmp(turbine_type, 'FBF') && strcmp(farm_spacing, 'SX35') && (row == 4)
%                 %     y_mean = 0.35;
%                 %     y_prct = 0.35;
%                 % end
% 
%                 scatter(ax, amplitude, y_prct, ...
%                         sz, spacing_markers{sp}, 'filled', 'MarkerFaceColor', color, 'HandleVisibility', 'off')
%                 % scatter(ax, amplitude, y_prct, ...
%                 %         sz, spacing_markers{sp}, 'filled', 'MarkerFaceColor', color, ...
%                 %         'HandleVisibility', 'off', 'MarkerFaceAlpha', 0.5)
% 
%                 % Save for fits (mean only)
%                 x_staggered(end+1) = amplitude;
%                 y_staggered(end+1) = y_mean;
% 
%                 x_all(end+1) = amplitude;
%                 y_all(end+1) = y_mean;
%             end
%         end
%     end
% 
%     % =====================
%     % Linear fits
%     % =====================
%     xfit = linspace(0, 0.12, 200);
% 
%     % Inline fit
%     if row ~= 1
%         p_inline = polyfit(x_inline, y_inline, 1);
%         yfit_inline = polyval(p_inline, xfit);
%         P = plot(ax, xfit, yfit_inline, 'k-', 'LineWidth', fit_linewidth, 'HandleVisibility', 'off');
%         uistack(P, 'bottom')
%         P.Color(4) = fit_transparency;
%     end
% 
%     % Staggered fit
%     if row ~= 1
%         p_staggered = polyfit(x_staggered, y_staggered, 1);
%         yfit_staggered = polyval(p_staggered, xfit);
%         P = plot(ax, xfit, yfit_staggered, 'k-', 'LineWidth', fit_linewidth, 'HandleVisibility', 'off');
%         uistack(P, 'bottom')
%         P.Color(4) = fit_transparency;
%     end
% 
% 
%     % Fit to both 
%     if row == 1
%         p_both = polyfit([x_inline, x_staggered], [y_inline, y_staggered], 1);
%         yfit_both = polyval(p_both, xfit);
%         P = plot(ax, xfit, yfit_both, 'k-', 'LineWidth', fit_linewidth, 'HandleVisibility', 'off');
%         uistack(P, 'bottom')
%         P.Color(4) = fit_transparency;
%     end
% 
% 
%     % Formatting
%     % axis(ax, 'square')
%     box(ax, 'on')
%     xlim(ax, [0, 0.12])
%     % ylim(ax, [0, 1.5])
%     title(ax, sprintf('Row %1.0f', row), 'interpreter', 'latex')
% 
%     if row ~= 1
%         yticklabels({})
%     else
%         % yticks(0:0.25:1.5)
%     end
% 
%     hold(ax, 'off')
% end
% 
% % =====================
% % Dummy legend entries for steepness colors
% % =====================
% ax_leg = nexttile(1);
% hold(ax_leg, 'on')
% 
% steepness_legend_values = [0.06, 0.09, 0.12];
% 
% for ly = 1:2
%     farm_arrangement = farm_arrangements{ly};
%     keys = fields(steepness_colors.(farm_arrangement));
%     for st = 1:length(keys)
%         steepness = keys{st};
%         label = sprintf('%s: $ak = %1.2f$', farm_arrangement, steepness_legend_values(st));
%         color = steepness_colors.(farm_arrangement).(steepness);
%         scatter(ax_leg, nan, nan, sz, 'filled', ...
%             'MarkerFaceColor', color, 'DisplayName', label)
%     end
%     plot(ax_leg, nan, nan, 'Color', 'white', 'DisplayName', ' ')
% end
% 
% % Dummy plot for markers
% for sp = 1:length(farm_spacings)
%     farm_spacing = ['SX', num2str(farm_spacings(sp) * 10)];
%     label = sprintf('$S_x \\mathbin{/} D = %1.1f$', farm_spacings(sp));
%     scatter(nan, nan, sz, spacing_markers{sp}, 'filled', 'MarkerFaceColor', 'black', 'displayname', label)
% end
% 
% % Add dummy line handles for fit legend
% % plot(ax_leg, nan, nan, 'Color', 'white', 'DisplayName', ' ')
% % plot(ax_leg, nan, nan, 'k-',  'LineWidth', 2,   'DisplayName', 'Inline fit')
% % plot(ax_leg, nan, nan, 'k--', 'LineWidth', 2,   'DisplayName', 'Staggered fit')
% 
% hold(ax_leg, 'off')
% 
% leg = legend(ax_leg, 'box', 'off', 'interpreter', 'latex', 'location', 'eastoutside');
% leg.Layout.Tile = 'east';
% leg.IconColumnWidth = 15;
% 
% % ylabel(tl, 'Normalized Row Average Power')
% ylabel(tl, '$\overline{P}_i \mathbin{/} \overline{P}_{1, No Waves}$', 'interpreter', 'latex', 'fontsize', labelFontSize)
% % xlabel(tl, 'Wave Amplitude = $\frac{ak \cdot \lambda}{2 \pi}$ [D]', 'interpreter', 'latex', 'fontsize', labelFontSize)
% xlabel(tl, '$a \mathbin{/} D$', 'interpreter', 'latex', 'fontsize', labelFontSize)





%% Functions

function hAnn = addPanelLabelsFixed(fig, ax, labels, varargin)
% Places (a),(b),... just outside top-left with FIXED physical offsets.
%
% fig    : figure handle (e.g., totalFigure)
% ax     : array of axes handles
% labels : {'a','b',...} or ["a","b",...]
%
% Name-value:
% 'OffsetPts' : [dx dy] in points (default [-10 6])  (left, up)
% 'FontSize'  : default 12
% 'FontName'  : default 'Times New Roman'

p = inputParser;
addParameter(p,'OffsetPts',[-10 6]);
addParameter(p,'FontSize',12);
addParameter(p,'FontName','Times New Roman');
parse(p,varargin{:});

labels = string(labels);
offPts = p.Results.OffsetPts;

ppi = get(0,'ScreenPixelsPerInch');
offPx = offPts/72 * ppi;   % points -> pixels

hAnn = gobjects(numel(ax),1);

for k = 1:numel(ax)
    if ~isgraphics(ax(k),'axes'), continue; end

    % Axes outer position in figure pixels
    op = getpixelposition(ax(k), true);  % [x y w h] in pixels relative to figure

    % Anchor point: outside top-left of axes
    x = op(1) + offPx(1);
    y = op(2) + op(4) + offPx(2);

    % TeX gives roman parentheses + italic letter
    str = sprintf('(\\it%s\\rm)', labels(k));

    hAnn(k) = annotation(fig,'textbox', ...
        'Units','pixels', ...
        'Position',[x y 40 20], ...   % small box; big enough for "(a)"
        'String',str, ...
        'Interpreter','tex', ...
        'FontName',p.Results.FontName, ...
        'FontSize',p.Results.FontSize, ...
        'LineStyle','none', ...
        'HorizontalAlignment','left', ...
        'VerticalAlignment','bottom');
    end
end