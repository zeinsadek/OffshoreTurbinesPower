%%% Power curve for same row accross different farm spacings
% Zein Sadek
% Portland State University

clear; close all; clc;

%% Import data

% Data locations
projet_path = "/Users/zeinsadek/Desktop/Experiments/Offshore/Power";
mat_path = fullfile(projet_path, "Data/Matfiles");

% Case
farm_arrangement = "FBF_Inline";
farm_spacings = {"WT60_SX30_AG0", ...
                 "WT60_SX35_AG0", ...
                 "WT60_SX40_AG0", ...
                 "WT60_SX45_AG0", ...
                 "WT60_SX50_AG0"};

% Loop through all spacings and save data to one structure
for sx = 1:length(farm_spacings)
    % Get farm spacing
    farm_spacing = farm_spacings{sx};

    % Load matfile
    matfile_name = strcat(farm_arrangement, "_", farm_spacing, "_PowerCurve.mat");
    path = fullfile(mat_path, farm_arrangement, farm_spacing, "Sweeps", matfile_name);
    tmp = load(path);

    % Store in structure
    data.(farm_spacing) = tmp.output;
end

clear tmp sx

%% Plot same row accross different spacings

markerSize = 80;
lineWidth = 3;
colors = {"#42F2F7", "#FFED65", "#38369A", "#999AC6", "#191308"};
spaces = {"3.0", "3.5", "4.0", "4.5", "5.0"};

ax = figure();
tiledlayout(1,4);

for r = 1:4
    nexttile()
    hold on
    for sx = 1:length(farm_spacings)
        farm_spacing = farm_spacings{sx};
        tmp = data.(farm_spacing);


        label = strcat("$S_x = ", spaces{sx}, "D$");
        plot(tmp(r).TS_avg, tmp(r).P_avg, 'color', colors{sx}, 'linewidth', lineWidth, 'HandleVisibility', 'off');
        scatter(tmp(r).TS_avg, tmp(r).P_avg, markerSize, 'filled', 'MarkerFaceColor', colors{sx}, 'MarkerEdgeColor', 'none', 'DisplayName', (label));
    end
    hold off
    title(strcat("Row: ", num2str(r)))
    xlabel('Tip Speed [m/s]')
    ylabel('Power [mW]')
end
leg = legend('Orientation', 'Horizontal');
leg.Layout.Tile = 'north';
leg.Interpreter = "latex";
leg.FontSize = 18;