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
                for t = 1:num_turbines
                    tmp_turbine_powers(1,t) = mean(data(t).Power, 'omitnan');
                end

                % Save average power per row for each case
                turbine_mean_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave) = tmp_turbine_powers;
               
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




%% Violin test

turbine_type = 'FWF';
farm_arrangement = 'Inline';
farm_spacing = 'SX50';
wave = 'LM5_AK12';
turbine = 7;

tmp_data1 = turbine_inst_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave)(1).Power;
tmp_data2 = turbine_inst_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave)(2).Power;
tmp_data3 = turbine_inst_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave)(3).Power;


figure('color', 'white')
hold on
violinplot(1, tmp_data1)
violinplot(2, tmp_data2)
violinplot(3, tmp_data3)
hold off

%% Tes with all turbines

turbine_type = 'FWF';
farm_arrangement = 'Inline';
farm_spacing = 'SX50';
wave = 'LM5_AK12';

figure('color', 'white')
hold on
for i = 1:12
    violinplot(i, turbine_inst_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave)(i).Power)
end
hold off


%% Tes with all turbines (fluctuations)

turbine_type = 'FWF';
farm_arrangement = 'Inline';
farm_spacing = 'SX50';
wave = 'LM5_AK12';
% wave = 'LM0_AK00';

figure('color', 'white')
hold on
for i = 2:3:12
    tmp =  turbine_inst_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave)(i).Power;
    tmp = tmp - mean(tmp, 'all', 'omitnan');
    violinplot(i, tmp)
end
hold off
yline(0)
xticks(1:12)
xlabel('Turbine Number')
ylabel('Power [mW]')
title(sprintf('%s %s %s %s\nPower Fluctuations', turbine_type, farm_arrangement, farm_spacing, wave), 'interpreter', 'none')
ylim([-50, 50])


%% Test appending signals within a row

tmp_data1 = turbine_inst_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave)(1).Power;
tmp_data2 = turbine_inst_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave)(2).Power;
tmp_data3 = turbine_inst_power.(turbine_type).(farm_arrangement).(farm_spacing).(wave)(3).Power;


figure('color', 'white')
hold on
violinplot(1, tmp_data1)
violinplot(2, tmp_data2)
violinplot(3, tmp_data3)

violinplot(4, [tmp_data1; tmp_data2; tmp_data3])
hold off
