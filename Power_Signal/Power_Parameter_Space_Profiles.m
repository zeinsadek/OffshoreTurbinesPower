%% Average Power Plotted Across Parameter Space
% Zein Sadek
% Portland State University

clear; close all; clc;
%% Import Data

% Data locations
projet_path = "/Users/zeinsadek/Desktop/Experiments/Offshore/Power";
mat_path = fullfile(projet_path, "Data/Matfiles");

% Which arangment to process
farm_arrangement = "FBF_Inline";
steepness = "AK06";
waves = {"2", "3", "4", "5"};

% Find all folders for all spacings
spacing_folders = dir(fullfile(mat_path, farm_arrangement));
spacing_folders = spacing_folders(~ismember({spacing_folders.name},{'.','..','.DS_Store'}));
spacings = {spacing_folders.name};



%% Loop and save all data

for sx = 1:length(spacings)
    spacing = spacings{sx};
    split = strsplit(spacing, '_');
    streamwise_spacing = str2double(split{2}(3:end)) / 10;
    sxs(sx) = streamwise_spacing;
    disp(streamwise_spacing)


    %%% NO WAVES
    % Load mat-file
    no_wave_caze = "LM0_AK00.mat";
    path = fullfile(mat_path, farm_arrangement, spacing, no_wave_caze);
    data = load(path);
    data = data.output;

    % Average each turbine in time and then average together
    turbines = [2, 5, 8, 11];
    T_avgs = zeros(length(turbines), 1);
    for T = 1:length(turbines)
        T_avgs(T) = mean(data(turbines(T)).Power, 'omitnan');
    end
    T_avg = mean(T_avgs, 'omitnan');
    no_wave_powers.(spacing) = T_avg;
    clear T_avgs T_avg data

    %%% WITH WAVES
    % Loop through all mat-files
    for wv = 1:length(waves)
        wave = waves{wv};
        disp(wave);

        % Load mat-file
        caze = strcat("LM", num2str(wave), "_", steepness, ".mat");
        path = fullfile(mat_path, farm_arrangement, spacing, caze);
        data = load(path);
        data = data.output;

        % Average each turbine in time and then average together
        turbines = [2, 5, 8, 11];
        T_avgs = zeros(length(turbines), 1);
        for T = 1:length(turbines)
            T_avgs(T) = mean(data(turbines(T)).Power, 'omitnan');
        end
        T_avg = mean(T_avgs, 'omitnan');

        % Save to array for plotting surface
        wvs(wv) = str2double(wave);
        powers.(spacing).(strcat("W", wave)) = T_avg;

    end
end

% Add the extra two cases to 5D wavelength case
spacing = spacings{end};
harmonic_waves = {"25", "33"};

% Loop through all mat-files
for wv = 1:length(harmonic_waves)
    wave = harmonic_waves{wv};
    disp(wave);

    % Load mat-file
    caze = strcat("LM", num2str(wave), "_", steepness, ".mat");
    path = fullfile(mat_path, farm_arrangement, spacing, caze);
    data = load(path);
    data = data.output;

    % Average each turbine in time and then average together
    turbines = [2, 5, 8, 11];
    T_avgs = zeros(length(turbines), 1);
    for T = 1:length(turbines)
        T_avgs(T) = mean(data(turbines(T)).Power, 'omitnan');
    end
    T_avg = mean(T_avgs, 'omitnan');

    % Save to array for plotting surface
    wvs(wv) = str2double(wave);
    powers.(spacing).(strcat("W", wave)) = T_avg;

end

clc;

%% Plot Farm Average Power Vs Wavelength

colors = {"#42F2F7", "#FFED65", "#38369A", "#999AC6", "#191308"};
markerSize = 80;
lineWidth = 3;
fontSize = 16;

ax = figure();
hold on
for sx = 1:length(spacings) - 1
    spacing = spacings{sx};
    streamwise_spacing = sxs(sx);
    label = strcat("$S_x = ", num2str(streamwise_spacing), "D$");
    for wv = 1:length(waves)
        wave = waves{wv};
        scatter(str2double(wave), powers.(spacing).(strcat("W", wave)), ...
                markerSize, 'filled', 'MarkerEdgeColor', 'none', ...
                'MarkerFaceColor', colors{sx}, ...
                'HandleVisibility', 'off')
        xAxisTemp(wv) = str2double(wave);
        yAxisTemp(wv) = powers.(spacing).(strcat("W", wave));
    end
    plot(xAxisTemp, yAxisTemp, 'color', colors{sx}, 'linewidth', lineWidth, 'DisplayName', label)
    clear xAxisTemp yAxisTemp
end

clear xAxisTemp yAxisTemp

% Plot 5D wave seperate since this has extra cases
spacing = spacings{end};
for wv = 1:length(waves)
    wave = waves{wv};
    scatter(str2double(wave), powers.(spacing).(strcat("W", wave)), ...
            markerSize, 'filled', 'MarkerEdgeColor', 'none', ...
            'MarkerFaceColor', colors{5}, ...
            'HandleVisibility', 'off')
    xAxisTemp(wv) = str2double(wave);
    yAxisTemp(wv) = powers.(spacing).(strcat("W", wave));
end

% Plot 25 wave
scatter(2.5, powers.(spacing).("W25"), markerSize, ...
        'filled', 'MarkerEdgeColor', 'none', ...
        'MarkerFaceColor', colors{5}, ...
        'HandleVisibility', 'off')
xAxisTemp(wv + 1) = 2.5;
yAxisTemp(wv + 1) = powers.(spacing).("W25");

% Plot 33 wave
scatter(3.3, powers.(spacing).("W33"), markerSize, ...
        'filled', 'MarkerEdgeColor', 'none', ...
        'MarkerFaceColor', colors{5}, ...
        'HandleVisibility', 'off')
xAxisTemp(wv + 2) = 3.3;
yAxisTemp(wv + 2) = powers.(spacing).("W33");


[xAxisTemp_sorted, xAxisTemp_order] = sort(xAxisTemp);
yAxisTemp_sorted = yAxisTemp(:, xAxisTemp_order);

plot(xAxisTemp_sorted, yAxisTemp_sorted, 'color', colors{5}, 'linewidth', lineWidth, 'DisplayName', '$S_x = 5D$')
clear xAxisTemp yAxisTemp xAxisTemp_sorted yAxisTemp_sorted

hold off
legend('Interpreter', 'latex')
xlim([1.5, 5.5])
xticks([2,2.5,3,3.33,4,5])
xlabel('$\lambda [D]$', 'interpreter', 'latex', 'FontSize', fontSize)
ylabel('$\overline{P}$', 'interpreter', 'latex', 'FontSize', fontSize)
grid on
title(strcat(farm_arrangement, ": ", steepness), 'interpreter', 'none')



%% Plot Farm Average Power Vs Wavelength (normalized)

colors = {"#42F2F7", "#FFED65", "#38369A", "#999AC6", "#191308"};
markerSize = 80;
lineWidth = 3;
fontSize = 16;

ax = figure();
hold on
for sx = 1:length(spacings) - 1
    spacing = spacings{sx};
    streamwise_spacing = sxs(sx);
    label = strcat("$S_x = ", num2str(streamwise_spacing), "D$");
    for wv = 1:length(waves)
        wave = waves{wv};
        scatter(str2double(wave), powers.(spacing).(strcat("W", wave)) / no_wave_powers.(spacing), ...
                markerSize, 'filled', 'MarkerEdgeColor', 'none', ...
                'MarkerFaceColor', colors{sx}, ...
                'HandleVisibility', 'off')
        xAxisTemp(wv) = str2double(wave);
        yAxisTemp(wv) = powers.(spacing).(strcat("W", wave)) / no_wave_powers.(spacing);
    end
    plot(xAxisTemp, yAxisTemp, 'color', colors{sx}, 'linewidth', lineWidth, 'DisplayName', label)
    clear xAxisTemp yAxisTemp
end

clear xAxisTemp yAxisTemp

% Plot 5D wave seperate since this has extra cases
spacing = spacings{end};
for wv = 1:length(waves)
    wave = waves{wv};
    scatter(str2double(wave), powers.(spacing).(strcat("W", wave)) / no_wave_powers.(spacing), ...
            markerSize, 'filled', 'MarkerEdgeColor', 'none', ...
            'MarkerFaceColor', colors{5}, ...
            'HandleVisibility', 'off')
    xAxisTemp(wv) = str2double(wave);
    yAxisTemp(wv) = powers.(spacing).(strcat("W", wave)) / no_wave_powers.(spacing);
end

% Plot 25 wave
scatter(2.5, powers.(spacing).("W25") / no_wave_powers.(spacing), markerSize, ...
        'filled', 'MarkerEdgeColor', 'none', ...
        'MarkerFaceColor', colors{5}, ...
        'HandleVisibility', 'off')
xAxisTemp(wv + 1) = 2.5;
yAxisTemp(wv + 1) = powers.(spacing).("W25") / no_wave_powers.(spacing);

% Plot 33 wave
scatter(3.3, powers.(spacing).("W33") / no_wave_powers.(spacing), markerSize, ...
        'filled', 'MarkerEdgeColor', 'none', ...
        'MarkerFaceColor', colors{5}, ...
        'HandleVisibility', 'off')
xAxisTemp(wv + 2) = 3.3;
yAxisTemp(wv + 2) = powers.(spacing).("W33") / no_wave_powers.(spacing);


[xAxisTemp_sorted, xAxisTemp_order] = sort(xAxisTemp);
yAxisTemp_sorted = yAxisTemp(:, xAxisTemp_order);

plot(xAxisTemp_sorted, yAxisTemp_sorted, 'color', colors{5}, 'linewidth', lineWidth, 'DisplayName', '$S_x = 5D$')
clear xAxisTemp yAxisTemp xAxisTemp_sorted yAxisTemp_sorted

hold off
legend('Interpreter', 'latex', 'location', 'southeast')
xlim([1.5, 5.5])
xticks([2,2.5,3,3.33,4,5])
xlabel('$\lambda [D]$', 'interpreter', 'latex', 'FontSize', fontSize)
ylabel('$\overline{P} / \overline{P}_{no waves}$', 'interpreter', 'latex', 'FontSize', fontSize)
grid on
title(strcat(farm_arrangement, ": ", steepness), 'interpreter', 'none')
ylim([0.95, 1.05])