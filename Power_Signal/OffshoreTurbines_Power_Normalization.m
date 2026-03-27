%%% Mean Power Per Row (Like from Juliaan's paper) for ALL VARIATIONS

clear; close all; clc;

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
                for t = 1:num_turbines
                    tmp_turbine_powers(1,t) = mean(data(t).Power, 'omitnan');
                end

                % Save average power per row for each case
                turbine_mean_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave) = tmp_turbine_powers;
               
            end
        end
        fprintf('\n')
    end
    fprintf('\n')
end
clear sp farm_spacing waves w wave tt turbine_type l farm_arrangement data num_turbines_in_row r t
clear tmp_row_averaged_power tmp_row_power turbine turbine_rows turbines_in_row 


%% Plot mean turbine powers to see if there are bad ones

clc;
% turbine_type = 'FBF';
farm_arrangement = 'Inline';
farm_spacing = 'SX50';
wave = 'LM0_AK00';


figure('color', 'white')
title(sprintf('%s, %s, No Waves', farm_arrangement, farm_spacing))
hold on
scatter(1:12, turbine_mean_power.FBF.(farm_arrangement).(farm_spacing).(wave), 50, 'filled', 'markerfacecolor', 'red', 'DisplayName', 'Fixed-Bottom')
scatter(1:12, turbine_mean_power.FWF.(farm_arrangement).(farm_spacing).(wave), 50, 'filled', 'markerfacecolor', 'blue', 'DisplayName', 'Floating')
hold off
ylim([0, 200])
xlim([0, 13])
xlabel('Turbine')
ylabel('Power [mW]')
legend('location', 'northeast', 'box', 'off')


%% Average across rows

% Turbines per row
% row_map.Inline =    {[1 2 3], [4 5 6], [7 8 9], [10 11 12]};
% row_map.Staggered = {[1 2 3], [4 5], [6 7 8], [9 10]};

% Average over specific turbines since some of them are fucked up
% Fixed-bottom
row_map.FBF.Inline    = {[3],   [4 5 6], [7 8 9], [10 11]};
row_map.FBF.Staggered = {[3],   [4 5],   [7 8],   [9 10]};

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
        turbine_rows = row_map.(turbine_type).(farm_arrangement);

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
                
                % Loop through rows
                tmp_row_averaged_power = nan(1,4);
                for r = 1:4
                    num_turbines_in_row = length(turbine_rows{r});
                    turbines_in_row = turbine_rows{r};

                    % Collect power signals for all turbines in row
                    tmp_row_power = [];
                    for t = 1:num_turbines_in_row
                        turbine = turbines_in_row(t);
                        tmp_row_power = [tmp_row_power, data(turbine).Power(:).'];
                    end

                    % Average across row and save to array
                    tmp_row_averaged_power(r) = mean(tmp_row_power, 'all', 'omitnan');

                end

                % Save average power per row for each case
                row_mean_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave) = tmp_row_averaged_power;
           
            end
        end
        fprintf('\n')
    end
    fprintf('\n')
end
% clear sp farm_spacing waves w wave tt turbine_type l farm_arrangement data num_turbines_in_row r t
% clear tmp_row_averaged_power tmp_row_power turbine turbine_rows turbines_in_row 


%% Plot to see if things make sense

turbine_type = 'FBF';
farm_arrangement = 'Inline';
farm_spacing = 'SX50';
wave = 'LM2_AK12';

figure('color', 'white')
hold on
plot(1:4, row_mean_power.FBF.(farm_arrangement).(farm_spacing).(wave), 'linewidth', 2, 'color', 'red')
plot(1:4, row_mean_power.FWF.(farm_arrangement).(farm_spacing).(wave), 'linewidth', 2, 'color', 'blue')
hold off
ylim([0, 200])





%% Turbine Diagnostic Plots
%  For a given turbine type, farm arrangement, and spacing, plot a heatmap
%  of mean power (turbine x wave case) to identify systematically bad turbines.
%
%  Run AFTER the "turbine_mean_power" structure has been computed 
%  (i.e., after the "Average individual turbines" section in 
%   OffshoreTurbines_Power_Normalization.m)

%% ---- USER SETTINGS ----
plot_turbine_type     = 'FBF';        % 'FBF' or 'FWF'
plot_farm_arrangement = 'Staggered';     % 'Inline' or 'Staggered'
plot_farm_spacing     = 'SX50';       % e.g. 'SX50','SX45','SX40','SX35','SX30'
% -------------------------

% Gather data into a matrix: (num_wave_cases x num_turbines)
waves = wave_cases.(plot_turbine_type).(plot_farm_arrangement).(plot_farm_spacing).wave_cases;
num_waves = length(waves);

if strcmp(plot_farm_arrangement, 'Inline')
    num_turbines = 12;
    row_boundaries = [3.5, 6.5, 9.5];   % vertical lines between rows
    row_labels = {'Row 1', 'Row 2', 'Row 3', 'Row 4'};
elseif strcmp(plot_farm_arrangement, 'Staggered')
    num_turbines = 10;
    row_boundaries = [3.5, 5.5, 8.5];
    row_labels = {'Row 1', 'Row 2', 'Row 3', 'Row 4'};
end

% Build matrix
power_matrix = nan(num_waves, num_turbines);
wave_labels  = cell(num_waves, 1);

for w = 1:num_waves
    wave = waves{w};
    power_matrix(w, :) = turbine_mean_power.(plot_turbine_type).(plot_farm_arrangement).(plot_farm_spacing).(wave);
    
    % Make nicer labels: replace underscores
    wave_labels{w} = strrep(wave, '_', ', ');
end


% FIGURE 1: Heatmap of mean power (wave case x turbine)
figure('color', 'white', 'Position', [100 100 900 600])
imagesc(power_matrix)
colormap(parula)
cb = colorbar;
ylabel(cb, 'Mean Power [mW]')

% Axes
set(gca, 'YTick', 1:num_waves, 'YTickLabel', wave_labels, 'FontSize', 8)
set(gca, 'XTick', 1:num_turbines)
xlabel('Turbine Number')
ylabel('Wave Case')
title(sprintf('Mean Power per Turbine — %s, %s, %s', ...
    plot_turbine_type, plot_farm_arrangement, plot_farm_spacing), 'FontSize', 13)

% Draw row boundaries
hold on
for b = 1:length(row_boundaries)
    xline(row_boundaries(b), 'w--', 'LineWidth', 1.5);
end
hold off



%% Check for zero avg cases

% Zero mean counter
zero_counter = 0;

% Total counter
total_counter = 0;

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

                % Loop through turbines
                tmp_turbine_powers = nan(1, num_turbines);
                tmp = turbine_mean_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave);

                % Check if value is zero
                if any(tmp < 1)
                    disp('XXX')
                    zero_counter = zero_counter + 1;
                end

                total_counter = total_counter + (num_turbines);

            end
        end
        fprintf('\n')
    end
    fprintf('\n')
end
clear sp farm_spacing waves w wave tt turbine_type l farm_arrangement data num_turbines_in_row r t
clear tmp_row_averaged_power tmp_row_power turbine turbine_rows turbines_in_row 




%% Average across rows (with per-case zero-power exclusion)

% Turbines per row — pre-determined exclusions based on diagnostics
% Fixed-bottom
row_map.FBF.Inline    = {[3],   [4 5 6], [7 8 9], [10 11]};
row_map.FBF.Staggered = {[3],   [4 5],   [7 8],   [9 10]};

% Floating
row_map.FWF.Inline    = {[2 3], [4 5 6], [7 8 9], [10 11]};
row_map.FWF.Staggered = {[2 3], [4 5],   [7 8],   [10]};

% Minimum power threshold [mW] — anything below this is treated as bad data
power_threshold = 1;  % mW

% Counters for summary
total_row_averages   = 0;
zero_skipped_count   = 0;
fully_bad_row_count  = 0;

clc;
% Loop over turbine types
for tt = 1:2
    turbine_type = turbine_types{tt};

    % Loop over farm layouts
    for l = 1:2
        farm_arrangement = farm_arrangements{l};
        turbine_rows = row_map.(turbine_type).(farm_arrangement);

        % Loop over farm spacings
        for sp = 1:length(farm_spacings)
            farm_spacing = ['SX', num2str(farm_spacings(sp) * 10)];
            waves = wave_cases.(turbine_type).(farm_arrangement).(farm_spacing).wave_cases;
            fprintf('%s: %s, %s\n', turbine_type, farm_arrangement, farm_spacing)

            % Loop over waves
            for w = 1:length(waves)
                wave = waves{w};

                % Load data
                data = load(fullfile(mat_folder, strcat(turbine_type, '_', farm_arrangement), strcat('WT60_', farm_spacing, '_AG0'), [wave '.mat']));
                data = data.output;

                % Get per-turbine means for this case (already computed)
                all_turbine_means = turbine_mean_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave);
                
                % Loop through rows
                tmp_row_averaged_power = nan(1, 4);
                tmp_used_turbines      = cell(1, 4);
                tmp_skipped_turbines   = cell(1, 4);

                for r = 1:4
                    candidates = turbine_rows{r};

                    % Check each candidate turbine against threshold
                    good_turbines    = [];
                    skipped_turbines = [];

                    for t = 1:length(candidates)
                        turb = candidates(t);
                        if all_turbine_means(turb) >= power_threshold
                            good_turbines = [good_turbines, turb];
                        else
                            skipped_turbines = [skipped_turbines, turb];
                            zero_skipped_count = zero_skipped_count + 1;
                        end
                    end

                    % Log which turbines were used and skipped
                    tmp_used_turbines{r}    = good_turbines;
                    tmp_skipped_turbines{r} = skipped_turbines;
                    total_row_averages = total_row_averages + 1;

                    % Compute row average from surviving turbines
                    if ~isempty(good_turbines)
                        tmp_row_power = [];
                        for t = 1:length(good_turbines)
                            turbine = good_turbines(t);
                            tmp_row_power = [tmp_row_power, data(turbine).Power(:).'];
                        end
                        tmp_row_averaged_power(r) = mean(tmp_row_power, 'all', 'omitnan');
                    else
                        % All turbines in this row were bad — flag as NaN
                        tmp_row_averaged_power(r) = NaN;
                        fully_bad_row_count = fully_bad_row_count + 1;
                        fprintf('  WARNING: All turbines bad — %s, Row %d, %s\n', wave, r, farm_spacing);
                    end
                end

                % Save results
                row_mean_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave) = tmp_row_averaged_power;
                
                % Save metadata: which turbines were actually used and which were skipped
                row_meta.(turbine_type).(farm_arrangement).(farm_spacing).(wave).used    = tmp_used_turbines;
                row_meta.(turbine_type).(farm_arrangement).(farm_spacing).(wave).skipped = tmp_skipped_turbines;

            end
        end
        fprintf('\n')
    end
    fprintf('\n')
end

% Print summary
fprintf('=== Row Averaging Summary ===\n');
fprintf('Total row averages computed:  %d\n', total_row_averages);
fprintf('Turbines skipped (zero/low):  %d\n', zero_skipped_count);
fprintf('Fully bad rows (set to NaN):  %d\n', fully_bad_row_count);

clear sp farm_spacing waves w wave tt turbine_type l farm_arrangement
clear data tmp_row_averaged_power tmp_row_power tmp_used_turbines tmp_skipped_turbines
clear candidates good_turbines skipped_turbines turb turbine turbine_rows
clear r t total_row_averages zero_skipped_count fully_bad_row_count

