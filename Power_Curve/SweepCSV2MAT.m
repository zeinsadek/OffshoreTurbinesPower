%%% Power curve from CSV
% Zein Sadek
% Portland State University

clear; close all; clc;

%% Import data

% Data locations
projet_path = "/Users/zeinsadek/Desktop/Experiments/Offshore/Power";
raw_path = fullfile(projet_path, "Data/Raw");
mat_path = fullfile(projet_path, "Data/Matfiles");

% Case
farm_arrangement = "FBF_Inline";
farm_spacing = "WT60_SX30_AG0";

% Find all folders for all sweeps
sweeps_path = fullfile(raw_path, farm_arrangement, farm_spacing, "Sweeps");
sweeps_folders = dir(sweeps_path);
sweeps_folders = sweeps_folders(~ismember({sweeps_folders.name},{'.','..','.DS_Store'}));
rows = {sweeps_folders.name};

% Save location
save_path = fullfile(mat_path, farm_arrangement, farm_spacing, "Sweeps");
if ~exist(save_path, 'dir')
    mkdir(save_path);
end

%% Loop through the different sweeps

% Constants
start = 1;
stop  = 29;
inc   = 1;
PPR   = 1000;
resistors = start:inc:stop;
D = 0.15;

% Loop
for r = 1:length(rows)
    row = rows{r};
    data_path = fullfile(sweeps_path, row);

    % Get actual CSV name
    data_folder = dir(data_path);
    data_folder = data_folder(~ismember({data_folder.name},{'.','..','.DS_Store'}));
    CSVs = {data_folder.name};
    CSV = CSVs{contains(CSVs, "1000")};

    % Find input parameters from file name
    path = fullfile(sweeps_path, row, CSV);
    data = readmatrix(path);
    data = data(1:(PPR * (stop - start + 1)),:);
    
    % Compute power
    t    = data(:,1);
    R    = data(:,2);
    BV   = data(:,3);
    SV   = data(:,4);
    I    = data(:,5); 
    V    = BV + SV;
    P    = V .* I;
    
    % Tip Speed
    delta_t = gradient(t) * 1E-6;
    TS      = (D/2) ./ delta_t;
    
    % Averages per Resistor
    P_avg  = zeros(1, length(resistors));
    TS_avg = zeros(1, length(resistors));
    
    for i = 1:length(resistors)
        resistor = resistors(i);
        x = find(R == resistor);
        x = x(1:PPR);
        P_avg(i)  = mean(P(x), 'all', 'omitnan');
        TS_avg(i) = mean(TS(x), 'all', 'omitnan');
    end
    
    % [peak, peak_ind] = max(P_avg, [], 'all');
    
    output(r).TS = TS;
    output(r).R = R;
    output(r).P = P;
    output(r).P_avg = P_avg;
    output(r).TS_avg = TS_avg;

end



%% Plot
colors          = jet(length(resistors));
marker_size     = 75;
bkg_marker_size = 20;
marker_trans    = 0.1;
line_trans      = 0.5;
linewidth       = 2;

ax = figure('Position', [500, 500, 500, 400]);
sgtitle(strcat(farm_arrangement, ": ", farm_spacing), 'Interpreter', 'none')

% Power vs Tip Speed
hold on
for r = 1:4
    for i = 1:length(resistors)
        resistor = resistors(i);
        x = find(R == resistor);
        x = x(1:PPR);
        scatter(output(r).TS(x), output(r).P(x), bkg_marker_size, 'MarkerFaceColor', colors(i,:), 'MarkerFaceAlpha', marker_trans, 'MarkerEdgeColor', 'none')
    end
    plt = plot(output(r).TS_avg, output(r).P_avg, 'k', 'LineWidth', linewidth);
    plt.Color(:, 4) = line_trans;
    for i = 1:length(resistors)
        scatter(output(r).TS_avg(i), output(r).P_avg(i), marker_size, 'MarkerFaceColor', colors(i,:), 'MarkerEdgeColor', 'k')
    end
end
hold off
xlabel('Tip Speed [m/s]')
ylabel('Power [mW]');
grid on
xlim([0, 3])
ylim([0, 180])


% Save Figure
figure_name = strcat(farm_arrangement, "_", farm_spacing, "_PowerCurve.png");
exportgraphics(ax, fullfile(save_path ,figure_name), 'Resolution', 300)

% Save to mat file
matfile_name = strcat(farm_arrangement, "_", farm_spacing, "_PowerCurve.mat");
save(fullfile(save_path, matfile_name), 'output')

















