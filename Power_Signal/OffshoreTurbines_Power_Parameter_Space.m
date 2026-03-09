%% Average Power Plotted Across Parameter Space
% Zein Sadek
% Portland State University

clear; close all; clc;
%% Import Data

% Data locations
projet_path = "/Users/zeinsadek/Desktop/Experiments/Offshore/Power";
mat_path = fullfile(projet_path, "Data/Matfiles");

% Which arangment to process
farm_arrangement = "FWF_Inline";
steepness = "AK06";
waves = {"2", "3", "4", "5"};

% Find all folders for all spacings
spacing_folders = dir(fullfile(mat_path, farm_arrangement));
spacing_folders = spacing_folders(~ismember({spacing_folders.name},{'.','..','.DS_Store'}));
spacings = {spacing_folders.name};

% Make empty power array (spacings~rows, wavelengths~columns)
powers = nan(length(spacings), length(waves));
no_wave_powers = nan(length(spacings), 1);

% Start figure
marker_size = 80;
ax = figure();
view(320,20)
daspect([1 1 0.1])
hold on


% Loop thorugh all spacings folders
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
    no_wave_powers(sx,1) = T_avg;
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
        powers(sx,wv) = T_avg;

        % Plot
        scatter3(streamwise_spacing, str2double(wave), T_avg / no_wave_powers(sx,1), marker_size, 'black', 'filled')
        clear T_avgs T_avg data
    end

    % % If condition to plot harmonic cases for Sx = 5.0D
    % if streamwise_spacing == 5
    %     harmonics = {"25", "33"};
    % 
    %     for h = 1:length(harmonics)
    %         % Load mat-file
    %         wave = harmonics{h};
    %         caze = strcat("LM", num2str(wave), "_", steepness, ".mat");
    %         path = fullfile(mat_path, farm_arrangement, spacing, caze);
    %         data = load(path);
    %         data = data.output;
    % 
    %         % Average each turbine in time and then average together
    %         turbines = [2, 5, 8, 11];
    %         T_avgs = zeros(length(turbines), 1);
    %         for T = 1:length(turbines)
    %             T_avgs(T) = mean(data(turbines(T)).Power, 'omitnan');
    %         end
    %         T_avg = mean(T_avgs, 'omitnan');
    % 
    %         if wave == 2.5
    %             idx = 3;
    %         elseif wave == 3.3
    %             idx = 5;
    %         end
    % 
    %     powers(sx,idx) = T_avg;
    % 
    %         % Plot
    %         scatter3(streamwise_spacing, str2double(wave) / 10, T_avg, marker_size, 'black', 'filled')
    %         clear T_avgs T_avg data
    %     end
    % end

end

[WV, SX] = meshgrid(wvs, sxs);
surf(SX, WV, powers ./ no_wave_powers)

clc;
hold off
xlabel('$S_x [D]$', 'Interpreter', 'latex')
ylabel('$\lambda [D]$', 'Interpreter', 'latex')
zlabel('$P_{avg} / P_{No Waves}$', 'Interpreter', 'latex')
xticks(sxs)
yticks(wvs)
zlim([0.8, 1.1])
grid on


