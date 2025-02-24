%%% CSV2MAT
% Convert power CSV to Matfile

clear; close all; clc;
%% Import Data


% Data locations
projet_path = "/Users/zeinsadek/Desktop/Experiments/Offshore/Power";
raw_path = fullfile(projet_path, "Data/Raw");
mat_path = fullfile(projet_path, "Data/Matfiles");

% Which arangment to process and where to save
farm_arrangement = "FBF_Inline";
farm_arrangement_save = fullfile(mat_path, farm_arrangement);
if ~exist(farm_arrangement_save, 'dir')
    mkdir(farm_arrangement_save)
end

% Find all folders for all spacings
spacing_folders = dir(fullfile(raw_path, farm_arrangement));
spacing_folders = spacing_folders(~ismember({spacing_folders.name},{'.','..','.DS_Store'}));
spacings = {spacing_folders.name};

% Loop thorugh all spacings folders
for sx = 1:length(spacings)
    spacing = spacings{sx};
    disp(spacing);
    spacing_save = fullfile(mat_path, farm_arrangement, spacing);
    if ~exist(spacing_save, 'dir')
        mkdir(spacing_save)
    end
    
    waves_folders = dir(fullfile(raw_path, farm_arrangement, spacing));
    waves_folders = waves_folders(~ismember({waves_folders.name},{'.','..','.DS_Store','Sweeps'}));
    waves = {waves_folders.name};

    % Loop through all wave folders
    for wv = 1:length(waves)
        wave = waves{wv};
        disp(wave);
        data_path = fullfile(raw_path, farm_arrangement, spacing, wave);
        
        output = readPower(wave, data_path);
        save(fullfile(spacing_save, strcat(wave, '.mat')), 'output')
        clear output
        clc;
    end
    
end


% CSV Reading Function
function output = readPower(wave, input_path)

    % For Processing
    points = 12000;
    turbines = 1:12;

    % Loop through turbines
    for T = 1:length(turbines)

        fprintf("Turbine: %2.0f\n", T)
    
        filename = strcat('T', num2str(T), '_', wave, '_P', num2str(points), '.csv');
        path     = fullfile(input_path, filename);

        % Check if file is empty
        file = dir(path);
        if file.bytes < 75E3
            fprintf("File Was Empty :( \n")
            output(T).Time    = nan;
            output(T).Trigger = nan;
            output(T).Power   = nan;
        else

            data     = readmatrix(path);
        
            % Delete data before first trigger
            triggers = find(data(:,6) == 1);
            data     = data(triggers(1):end, :);
            
            % Compute Power
            time = data(:,1) * 1E-6;
            time = time - time(1);
            R    = data(:,2);
            BV   = data(:,3);
            SV   = data(:,4);
            I    = data(:,5); 
            trigger = data(:,6);
        
            % Power
            V    = BV + SV;
            P    = V .* I;
        
            % Output
            output(T).Time    = time;
            output(T).Trigger = trigger;
            output(T).Power   = P;
        end
    end
end





%%
main_path     = "/Users/zeinsadek/Desktop/Experiments/Offshore/Power/Data/Raw/FWF_Inline/WT60_SX30_AG0";
caze          = "LM0_AK00";
points        = 12000;
turbines      = 1:12;

save_path     = "/Users/zeinsadek/Desktop/Experiments/Offshore/Power/Data/Matfiles/FWF_Inline";


for T = 1:length(turbines)

    fprintf("Turbine: %2.0f\n", T)

    filename = strcat('T', num2str(T), '_', caze, '_P', num2str(points), '.csv');
    path     = fullfile(main_path, caze, filename);
    data     = readmatrix(path);

    % Delete data before first trigger
    triggers = find(data(:,6) == 1);
    data     = data(triggers(1):end, :);
    
    % Compute Power
    time = data(:,1) * 1E-6;
    time = time - time(1);
    R    = data(:,2);
    BV   = data(:,3);
    SV   = data(:,4);
    I    = data(:,5); 
    trigger = data(:,6);

    % Power
    V    = BV + SV;
    P    = V .* I;

    % Output
    output(T).Time    = time;
    output(T).Trigger = trigger;
    output(T).Power   = P;
end

% Save to mat file
save(fullfile(save_path, caze + '.mat'), 'output')
fprintf("\n%s Done Saveing\n", caze)
















