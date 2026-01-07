%%% Power curve from CSV
% Zein Sadek
% Portland State University

clear; close all; clc;

%% Import data

% Data locations
projet_path = "/Users/zeinsadek/Desktop/Experiments/Offshore/Power";
raw_path = fullfile(projet_path, "Data/Raw");
mat_path = fullfile(projet_path, "Data/Matfiles");
keywords = {'ROW', 'START', 'INC', 'STOP', 'PPR'};

% Case
farm_arrangement = "FWT";
farm_spacing = "";


% Find all folders for all sweeps
sweeps_path = fullfile(raw_path, farm_arrangement, farm_spacing, "Sweeps");
sweeps_folders = dir(sweeps_path);
sweeps_folders = sweeps_folders(~ismember({sweeps_folders.name},{'.','..','.DS_Store','Figures','Matfiles'}));
rows = {sweeps_folders.name};

% Or manually say which files to read if multiple resistors were used
if strcmp(farm_arrangement, "FWF_Inline") 
    if strcmp(farm_spacing, "WT60_SX50_AG0")
        rows = {'ROW1_R20', 'ROW2_R50', 'ROW3_R62', 'ROW4_R62'};
    elseif strcmp(farm_spacing, "WT60_SX30_AG0")
        rows = {'ROW1_R20', 'ROW2_R68', 'ROW3_R62', 'ROW4_R62'};
    end
elseif strcmp(farm_arrangement, "FWF_Staggered")
    if strcmp(farm_spacing, "WT60_SX50_AG0")
        rows = {'ROW1_R20', 'ROW2_R25', 'ROW3_R50', 'ROW4_R62'};
    end
end

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
clc;
for r = 1:length(rows)
    row = rows{r};
    fprintf('%s\n', row)
    data_path = fullfile(sweeps_path, row);

    % Get actual CSV name
    data_folder = dir(data_path);
    data_folder = data_folder(~ismember({data_folder.name},{'.','..','.DS_Store','Figures','Matfiles'}));
    CSVs = {data_folder.name};
    CSV = CSVs{contains(CSVs, "1000")};

    % Get start/end resistors from CSV name
    char_name = CSV(1:end-4);
    for i = 1:numel(keywords)
        key = keywords{i};
    
        % Match: KEY_<number>
        expr = [key '_([0-9]+)'];
    
        token = regexp(char_name, expr, 'tokens', 'once');
    
        if ~isempty(token)
            values.(key) = str2double(token{1});
            fprintf('%s: %g\n', key, values.(key))
        else
            warning('Keyword %s not found', key)
        end
    end

    char_name = char_name(1:end-1);
    % row   = values.('ROW');
    start = values.('START');
    stop  = values.('STOP');
    inc   = values.('INC');
    PPR   = values.('PPR');
    resistors = start:inc:stop;
    % pause(1)
    fprintf('\n\n')

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
    omega   = (2 * pi) ./ delta_t;
    TS      = (D/2) .* omega;
    % TS      = (D/2) ./ delta_t;
    
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
    
    % Save
    output(r).file = row;
    output(r).time = t * 1E-6;
    output(r).TS = TS;
    output(r).R = R;
    output(r).P = P;
    output(r).P_avg = P_avg;
    output(r).TS_avg = TS_avg;

    % Find optimal resistor
    [peak, peak_ind] = max(P_avg, [], 'all');
    output(r).optimal = resistors(peak_ind);

end





%% Plot + save

colors.R1 = spring(29);
colors.R2 = summer(29);
colors.R3 = autumn(29);
colors.R4 = winter(29);

marker_size     = 75;
bkg_marker_size = 20;
marker_trans    = 0.1;
line_trans      = 0.5;
linewidth       = 2;

ax = figure('Position', [500, 500, 500, 400], 'color', 'white');
sgtitle(strcat(farm_arrangement, ": ", farm_spacing), 'Interpreter', 'none')

% Power vs Tip Speed
hold on
for r = 1:length(rows)
    R = output(r).R;
    unique_resistors = unique(R);
    color = colors.(['R', num2str(r)]);
    for i = 1:length(unique_resistors)
        resistor = unique_resistors(i);
        x = find(R == resistor);
        x = x(1:PPR);
        scatter(output(r).TS(x), output(r).P(x), bkg_marker_size, ...
                'MarkerFaceColor', color(resistor,:), 'MarkerFaceAlpha', marker_trans, ...
                'MarkerEdgeColor', 'none', 'HandleVisibility', 'off')
    end
    plt = plot(output(r).TS_avg, output(r).P_avg, 'k', 'LineWidth', linewidth, ...
               'HandleVisibility', 'off');
    plt.Color(:, 4) = line_trans;
    for i = 1:length(unique_resistors)
        resistor = unique_resistors(i);
        scatter(output(r).TS_avg(i), output(r).P_avg(i), marker_size, ...
                'MarkerFaceColor', color(resistor,:), 'MarkerEdgeColor', 'k', 'HandleVisibility', 'off')
    end

    % For legend
    c = color(1, :);
    scatter(nan, nan, marker_size, 'MarkerFaceColor', c, 'MarkerEdgeColor', 'k', 'Displayname', sprintf('Row %1.0f', r))

end
hold off
xlabel('Tip Speed = $R \omega$ [m/s]', 'interpreter', 'latex')
ylabel('Power [mW]', 'interpreter', 'latex');
grid on
xlim([0, 20])
ylim([0, 275])
legend('Orientation', 'vertical', 'Location', 'northwest', ...
       'box', 'off', 'fontsize', 10, 'interpreter', 'latex')



% Save Figure
figure_name = strcat(farm_arrangement, "_", farm_spacing, "_PowerCurve.png");
exportgraphics(ax, fullfile(save_path ,figure_name), 'Resolution', 300)
close all

% Save to mat file
matfile_name = strcat(farm_arrangement, "_", farm_spacing, "_PowerCurve.mat");
save(fullfile(save_path, matfile_name), 'output')

















