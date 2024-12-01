%%% CSV2MAT
% Convert power CSV to Matfile

clear; close all; clc;
%% Import Data

clc;
main_path     = "/Volumes/Zein_PIV_3/Zein_APS_Tracking/Power/WT60_SX50_AG0";
caze          = "LM0_AK00";
points        = 12000;
turbines      = 1:12;

save_path     = "/Volumes/Zein_PIV_3/Power_Results/WT60_SX50_AG0/Power_Signal";
figure_folder = fullfile(save_path, "Figures");
mat_folder    = fullfile(save_path, "Matfiles");

if ~exist(figure_folder, "dir")
    mkdir(figure_folder);
end

if ~exist(mat_folder, "dir")
    mkdir(mat_folder);
end


for T = 1:length(turbines)

    fprintf("Turbine: %2.0f\n", T)

    filename = strcat('T', num2str(T), '_', caze, '_P', num2str(points), '.csv');
    path     = fullfile(main_path, caze, filename);
    data     = readmatrix(path);

    % delete data before first trigger
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
save(fullfile(mat_folder, caze + '.mat'), 'output')
fprintf("\n%s Done Saveing\n", caze)
















