%%% Mean Power Per Row (Like from Juliaan's paper)

clear; close all; clc;

main_folder   = "/Users/zeinsadek/Desktop/Experiments/Offshore/Power";
figure_folder = fullfile(main_folder, "Figures");
mat_folder    = fullfile(main_folder, "Data", "Matfiles");

turbine_type = 'FWF';
farm_arrangement = 'Inline';
wave_steepness = 'AK12';

farm_spacings = {'SX50', 'SX45', 'SX40', 'SX35', 'SX30'};

% Loop thrugh farm spacings
for s = 1:length(farm_spacings)

    farm_spacing = farm_spacings{s};
    disp(farm_spacing)

    % Get wave cases from folder
    folder = dir(fullfile(mat_folder, strcat(turbine_type, '_', farm_arrangement), strcat('WT60_', farm_spacing, '_AG0'), '*.mat'));
    
    % Only keep a specific wave steepness
    wave_cases = {folder(~[folder.isdir]).name};
    wave_cases = wave_cases(contains(wave_cases, wave_steepness));
    
    % Sort based on wavelength
    wavelengths = nan(1, length(wave_cases));
    
    for w = 1:length(wavelengths)
        wave_properties = split(wave_cases{w}, '_');
        wavelength = wave_properties{1};
        
        if length(wavelength) > 3
             wavelength = str2double(wavelength(3:end)) * 1E-1;
        else
            wavelength = str2double(wavelength(3:end));
        end
        wavelengths(w) = wavelength;

        clear w
    end
    
    [~, sort_indicies] = sort(wavelengths);
    wavelengths = wavelengths(sort_indicies);
    wave_cases = wave_cases(sort_indicies);
    disp(wavelengths)

    % Streamwise spacing in D
    streamwise_spacing = str2double(farm_spacing(3:end)) * 1E-1;

    % Save this to loop through later
    case_data.(farm_spacing).wave_cases = wave_cases;
    case_data.(farm_spacing).wavelengths = wavelengths;
    case_data.(farm_spacing).spacing = streamwise_spacing;

    clear s
end

clear farm_spacing folder sort_indicies streamwise_spacing wave_cases
clear wave_properties wavelength wavelengths

%% Load No Waves to Normalize (per spacing)

for s = 1:length(farm_spacings)

    farm_spacing = farm_spacings{s};

    % Across entire row
    no_waves = load(fullfile(mat_folder, strcat(turbine_type, '_', farm_arrangement), strcat('WT60_', farm_spacing, '_AG0'), 'LM0_AK00.mat'));
    no_waves = no_waves.output;
    
    % Average across the three turbines
    no_waves_first_row_power.(farm_spacing) = mean([no_waves(1).Power; no_waves(2).Power; no_waves(3).Power], 'omitnan');

    no_waves_first_row_power.(farm_spacing) = 1.1 * no_waves_first_row_power.(farm_spacing);

    clear s farm_spacing no_waves
end


%% Average power, center turbines, different wavelengths


% Generate unique colormaps for each farm spacing
colors.('SX50') = parula(length(case_data.('SX50').wavelengths));
colors.('SX45') = hot(length(case_data.('SX50').wavelengths));
colors.('SX40') = cool(length(case_data.('SX50').wavelengths));
colors.('SX35') = winter(length(case_data.('SX50').wavelengths));
colors.('SX30') = nebula(length(case_data.('SX50').wavelengths));

centers = [2,5,8,11];

clc; close all;
figure('color', 'white')
hold on

for s = 1:length(farm_spacings)
    farm_spacing = farm_spacings{s};

    wave_cases = case_data.(farm_spacing).wave_cases;
    wavelengths = case_data.(farm_spacing).wavelengths;
    streamwise_spacing = case_data.(farm_spacing).spacing;
    wave_colors = colors.(farm_spacing); 

    fprintf('Sx = %1.1fD\n', streamwise_spacing)

    norm_powers = zeros(length(centers), length(wave_cases));
    powers      = zeros(length(centers), length(wave_cases));
    row = 1;


    % Get power values
    for t = 1:length(centers)
        fprintf('\n')
        for f = 1:length(wave_cases)
    
            % Get wavelength from case name
            wave_properties = split(wave_cases{f}, '_');
            wavelength = wave_properties{1};

            if length(wavelength) > 3
                 wavelength = str2double(wavelength(3:end)) * 1E-1;
            else
                wavelength = str2double(wavelength(3:end));
            end
    
            % Compute H
            if wavelength ~= 0
                if strcmp(wave_properties{1}, 'LM33')
                    H = 1.5;
                else
                    H = streamwise_spacing / wavelength;
                end
            end
    
            % Print for tracking
            fprintf('Row %1.0f: H = %1.2f\n', row, H);
    
            data = load(fullfile(mat_folder, strcat(turbine_type, '_', farm_arrangement), strcat('WT60_', farm_spacing, '_AG0'), wave_cases{f}));
            data = data.output;
    
            %%% Averaging across entire row
            center = centers(t);
            row_data = [data(center - 1).Power; data(center).Power; data(center + 1).Power];
            mean_row_power = mean(row_data, 'omitnan');
            norm_power = mean_row_power / no_waves_first_row_power.(farm_spacing);
    
            % Add a legend
            if t == 1
                vis = 'on';
            else 
                vis = 'off';
            end
    
            % Plot
            if wavelength ~= 0
                scatter(H * (row - 1), norm_power, 50, 'filled', 'MarkerFaceColor', wave_colors(f,:), ...
                        'HandleVisibility', vis, 'Displayname', sprintf('$S_x = %1.1fD, H = %1.2f$', streamwise_spacing, H))
            end
            
            % Save to plot as a line plot
            x_tmps(t,f) = H * (row - 1);
            y_tmps(t,f) = norm_power;
    
            clear f wavelength wave_properties H data
        end
        row = row + 1;
        clear t
    end
    
    % Plot line plots
    for f = 1:length(wave_cases)
        plot(x_tmps(:,f), y_tmps(:,f), 'linewidth', 2, 'color', wave_colors(f,:), 'HandleVisibility', 'off')
    end
end

hold off

legend('location', 'northeastoutside', 'Interpreter', 'latex', 'box', 'off')
xlabel("$\left( \frac{S_x}{\lambda} \right) \cdot \left( Row \# - 1\right)$", ...
       'Interpreter', 'latex')
xlim([-1, inf])
ylim([0,1])
xticks(0:1:100)

clear data center row_data row



%% 3D scatter plot (farm spacing vs wavelength vs power)



% Generate unique colormaps for each farm spacing
colors.('SX50') = parula(length(case_data.('SX50').wavelengths));
colors.('SX45') = hot(length(case_data.('SX50').wavelengths));
colors.('SX40') = cool(length(case_data.('SX50').wavelengths));
colors.('SX35') = winter(length(case_data.('SX50').wavelengths));
colors.('SX30') = nebula(length(case_data.('SX50').wavelengths));


% centers = [2,5,8,11];
centers = 5;


clc; close all;
figure('color', 'white')
hold on

for s = 1:length(farm_spacings)
    farm_spacing = farm_spacings{s};

    wave_cases = case_data.(farm_spacing).wave_cases;
    wavelengths = case_data.(farm_spacing).wavelengths;
    streamwise_spacing = case_data.(farm_spacing).spacing;
    wave_colors = colors.(farm_spacing); 

    fprintf('Sx = %1.1fD\n', streamwise_spacing)

    norm_powers = zeros(length(centers), length(wave_cases));
    powers      = zeros(length(centers), length(wave_cases));
    row = 1;


    % Get power values
    for t = 1:length(centers)
        fprintf('\n')
        for f = 1:length(wave_cases)
    
            % Get wavelength from case name
            wave_properties = split(wave_cases{f}, '_');
            wavelength = wave_properties{1};

            if length(wavelength) > 3
                 wavelength = str2double(wavelength(3:end)) * 1E-1;
            else
                wavelength = str2double(wavelength(3:end));
            end
    
            % Compute H
            if wavelength ~= 0
                if strcmp(wave_properties{1}, 'LM33')
                    H = 1.5;
                else
                    H = streamwise_spacing / wavelength;
                end
            end
    
            % Print for tracking
            fprintf('Row %1.0f: H = %1.2f\n', row, H);
    
            data = load(fullfile(mat_folder, strcat(turbine_type, '_', farm_arrangement), strcat('WT60_', farm_spacing, '_AG0'), wave_cases{f}));
            data = data.output;
    
            %%% Averaging across entire row
            center = centers(t);
            row_data = [data(center - 1).Power; data(center).Power; data(center + 1).Power];
            mean_row_power = mean(row_data, 'omitnan');
            norm_power = mean_row_power / no_waves_first_row_power.(farm_spacing);
    
            % Add a legend
            if t == 1
                vis = 'on';
            else 
                vis = 'off';
            end
    
            % Plot
            if wavelength ~= 0
                scatter3(streamwise_spacing, wavelength, norm_power, 100, 'filled', 'MarkerFaceColor', wave_colors(f,:), ...
                        'HandleVisibility', vis, 'Displayname', sprintf('$S_x = %1.1fD, H = %1.2f$', streamwise_spacing, H))
            end

    
            clear f wavelength wave_properties H data
        end
        row = row + 1;
        clear t
    end
end

hold off

legend('location', 'northeastoutside', 'Interpreter', 'latex', 'box', 'off')
xlabel("$S_x$ [D]", ...
       'Interpreter', 'latex')
ylabel("$\lambda$ [D]", 'Interpreter', 'latex')

xlim([2.8, 5.2])
ylim([1.8, 5.2])
zlim([0, 1])

xticks([3, 3.5, 4, 4.5, 5])
yticks([2, 2.5, 3, 3.33, 4, 5])

grid on
view(45, 20)

clear data center row_data row











%% Aggregate Power

% Add all power
summed_power = sum(powers, 1);

% Normalized by No-Wave summed power
summed_power = summed_power / summed_power(1,1);

% Plot
clc; close all
ax = figure('Position', [200,200,300,500], 'color', 'white');
b = bar(["No Waves", "H = 1.0", "H = 1.25", "H = 1.5", "H = 2.0"], summed_power);

% Label value on top of chart
b(1).Labels = round(b(1).YData, 3);

ylim([0,1.1])
ylabel("Normalized Aggregate Farm Power")
% exportgraphics(ax, fullfile(figure_folder, 'Aggregate_Normalized_Power.png'), 'Resolution', 200)











