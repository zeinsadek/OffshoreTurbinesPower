%%% CSV2MAT
% Convert power CSV to Matfile

clear; close all; clc;
%% Import Data

remote_path    = "/Users/zeinsadek/Library/CloudStorage/GoogleDrive-sadek@pdx.edu/Other computers/Pinhole/Power";
project        = "WT60_SX50_AG0";
main_path      = fullfile(remote_path, project);
matfile_folder = fullfile(remote_path, project, "Matfiles");
figure_folder  = fullfile(remote_path, project, "Figures");

% Recording
caze          = "WT60_WV";
points        = 12000;
turbines      = 1:12;

if ~exist(matfile_folder, "dir")
    mkdir(matfile_folder);
end
if ~exist(figure_folder, "dir")
    mkdir(figure_folder);
end


for T = 1:length(turbines)

    fprintf("Turbine: %2.0f\n", T)

    filename = strcat('T', num2str(T), '_', caze, '_P_', num2str(points), '.csv');
    path     = fullfile(main_path, caze, filename);
    data     = readmatrix(path);

    % delete data before first trigger
    triggers = find(data(:,6) == 1);
    data     = data(triggers(1):end, :);
    
    % Compute Power
    t    = data(:,1) * 1E-6;
    t    = t - t(1);
    R    = data(:,2);
    BV   = data(:,3);
    SV   = data(:,4);
    I    = data(:,5); 
    trig = data(:,6);

    % Power
    V    = BV + SV;
    P    = V .* I;

    % Output
    output(T).t     = t;
    output(T).trig  = trig;
    output(T).P     = P;
end

% Save to mat file
save(fullfile(matfile_folder, caze + '.mat'), 'output')

















