%% Offshore wind farm power normalization study
% Loads all four farm types:
%   1) FBF Inline
%   2) FBF Staggered
%   3) FWF Inline
%   4) FWF Staggered
%
% Computes row-mean power, several normalizations, and a few single-scalar
% metrics so different presentation choices can be compared quickly.
%
% IMPORTANT:
% Update row_map.Staggered below if your staggered turbine numbering differs.
%
% Output:
%   results.(farm_key).(spacing_key).raw_row_power               [nRows x nCases]
%   results.(farm_key).(spacing_key).norm.matched_no_wave       [nRows x nCases]
%   results.(farm_key).(spacing_key).norm.same_case_row1        [nRows x nCases]
%   results.(farm_key).(spacing_key).norm.fixed_bottom_no_wave  [nRows x nCases]
%   results.(farm_key).(spacing_key).norm.floating_no_wave      [nRows x nCases]
%   results.(farm_key).(spacing_key).scalars.*                  struct of vectors
%
% Save file:
%   <mat_folder>/PowerNormalizationStudy_AKxx.mat

clear; close all; clc;

%% Paths
main_folder   = "/Users/zeinsadek/Desktop/Experiments/Offshore/Power";
figure_folder = fullfile(main_folder, "Figures"); %#ok<NASGU>
mat_folder    = fullfile(main_folder, "Data", "Matfiles");

%% User settings
farm_spacings    = [5, 4.5, 4, 3.5, 3];
waves_steepnesses = [0.06, 0.09, 0.12];
wavelengths      = [0, 5, 4, 3, 2];   % include no-wave as 0
wind_case        = 'WT60';
angle_case       = 'AG0';
save_results     = false;

% -------------------------------------------------------------------------
% EDIT THESE ROW MAPS IF NEEDED
% -------------------------------------------------------------------------
% Inline numbering follows your original code: rows centered at [2 5 8 11]
% with 3 turbines per row.
row_map.Inline = { [1 2 3], [4 5 6], [7 8 9], [10 11 12] };

% Staggered numbering is experiment-specific.
% Replace the row groupings below with your actual turbine IDs per row.
% Example placeholder for a 3-2-3-2 style numbering:
row_map.Staggered = { [1 2 3], [4 5], [6 7 8], [9 10] };
%
% If your staggered cases still use four row groups but different turbine IDs,
% just edit the cell array above. NaNs are handled automatically.
% -------------------------------------------------------------------------

%% Case definitions
farm_types   = {'FBF','FWF'};
arrangements = {'Inline','Staggered'};

all_results = struct();
all_summary_tables = cell(numel(waves_steepnesses),1);

for iAK = 1:numel(waves_steepnesses)
    current_ak = waves_steepnesses(iAK);

    wave_cases   = cell(1, numel(wavelengths));
    legend_names = cell(1, numel(wavelengths));
    s = compose('%02d', round(100 * current_ak));
    for i = 1:numel(wavelengths)
        wavelength = wavelengths(i);
        if wavelength == 0
            wave_cases{i}   = 'LM0_AK00';
            legend_names{i} = 'No Waves';
        else
            wave_cases{i}   = ['LM', num2str(wavelength), '_AK', s{1}];
            legend_names{i} = ['$\lambda = ', num2str(wavelength), 'D$']; %#ok<NASGU>
        end
    end
    clear i s wavelength

%%% Build baseline denominators first
% Each denominator is the first-row no-wave mean power for a chosen baseline.
% These are stored by arrangement and spacing.

baselines = struct();

for a = 1:numel(arrangements)
    arrangement = arrangements{a};
    arrangement_key = matlab.lang.makeValidName(arrangement);

    for sp = 1:numel(farm_spacings)
        spacing_val = farm_spacings(sp);
        spacing_key = spacing_to_key(spacing_val);

        % Fixed-bottom no-wave, matched arrangement + spacing
        baselines.FBF.(arrangement_key).(spacing_key) = get_first_row_nowave(...
            mat_folder, wind_case, angle_case, 'FBF', arrangement, spacing_val, row_map);

        % Floating no-wave, matched arrangement + spacing
        baselines.FWF.(arrangement_key).(spacing_key) = get_first_row_nowave(...
            mat_folder, wind_case, angle_case, 'FWF', arrangement, spacing_val, row_map);
    end
end

%%% Main load loop
results = struct();

for t = 1:numel(farm_types)
    turbine_type = farm_types{t};

    for a = 1:numel(arrangements)
        arrangement = arrangements{a};
        arrangement_key = matlab.lang.makeValidName(arrangement);
        farm_key = [turbine_type, '_', arrangement_key];

        fprintf('\n=== %s %s ===\n', turbine_type, arrangement)

        for sp = 1:numel(farm_spacings)
            spacing_val = farm_spacings(sp);
            spacing_key = spacing_to_key(spacing_val);
            fprintf('  %s\n', spacing_key)

            nRows  = numel(row_map.(arrangement));
            nCases = numel(wave_cases);

            raw_row_power = nan(nRows, nCases);

            % Baselines for this farm configuration
            denom_matched = get_baseline_from_type(...
                baselines, turbine_type, arrangement_key, spacing_key);
            denom_fbf     = baselines.FBF.(arrangement_key).(spacing_key);
            denom_fwf     = baselines.FWF.(arrangement_key).(spacing_key);

            for w = 1:nCases
                case_name = wave_cases{w};
                fprintf('    %s\n', case_name)

                data = load_case_data(mat_folder, wind_case, angle_case, ...
                    turbine_type, arrangement, spacing_val, case_name);

                % Row means
                for r = 1:nRows
                    idx = row_map.(arrangement){r};
                    idx = idx(idx <= numel(data));
                    row_vals = nan(size(idx));
                    for ii = 1:numel(idx)
                        row_vals(ii) = mean(data(idx(ii)).Power(:), 'omitnan');
                    end
                    raw_row_power(r, w) = mean(row_vals, 'omitnan');
                end
            end

            % Normalizations
            norm_struct = struct();
            norm_struct.matched_no_wave      = raw_row_power ./ denom_matched;
            norm_struct.same_case_row1       = raw_row_power ./ raw_row_power(1, :);
            norm_struct.fixed_bottom_no_wave = raw_row_power ./ denom_fbf;
            norm_struct.floating_no_wave     = raw_row_power ./ denom_fwf;

            % Single-scalar metrics for each normalization choice
            scalars = struct();
            scalars.raw                    = compute_scalar_metrics(raw_row_power);
            scalars.matched_no_wave        = compute_scalar_metrics(norm_struct.matched_no_wave);
            scalars.same_case_row1         = compute_scalar_metrics(norm_struct.same_case_row1);
            scalars.fixed_bottom_no_wave   = compute_scalar_metrics(norm_struct.fixed_bottom_no_wave);
            scalars.floating_no_wave       = compute_scalar_metrics(norm_struct.floating_no_wave);

            % Save meta info too
            results.(farm_key).meta.turbine_type = turbine_type;
            results.(farm_key).meta.arrangement  = arrangement;
            results.(farm_key).meta.wave_cases   = wave_cases;
            results.(farm_key).meta.wavelengths  = wavelengths;
            results.(farm_key).meta.ak           = current_ak;
            results.(farm_key).meta.row_map      = row_map.(arrangement);

            metric_table = build_metric_table(scalars, wave_cases, wavelengths, current_ak);
            explicit_scalars = make_explicit_scalar_struct(scalars, wave_cases);
            explicit_norm = make_explicit_norm_struct(norm_struct, wave_cases);

            results.(farm_key).(spacing_key).raw_row_power = raw_row_power;
            results.(farm_key).(spacing_key).norm          = norm_struct;
            results.(farm_key).(spacing_key).norm_by_case  = explicit_norm;
            results.(farm_key).(spacing_key).scalars       = scalars;
            results.(farm_key).(spacing_key).scalars_by_case = explicit_scalars;
            results.(farm_key).(spacing_key).metric_table  = metric_table;
            results.(farm_key).(spacing_key).denoms.matched_no_wave      = denom_matched;
            results.(farm_key).(spacing_key).denoms.fixed_bottom_no_wave = denom_fbf;
            results.(farm_key).(spacing_key).denoms.floating_no_wave     = denom_fwf;
        end
    end
end

%% Optional: build one summary table for this steepness
summary_table = build_summary_table(results, farm_spacings, wave_cases, wavelengths, current_ak);
all_summary_tables{iAK} = summary_table;

ak_key = sprintf('AK%02d', round(100 * current_ak));
all_results.(ak_key).results = results;
all_results.(ak_key).summary_table = summary_table;
all_results.(ak_key).baselines = baselines;
all_results.(ak_key).wave_cases = wave_cases;
all_results.(ak_key).wavelengths = wavelengths;
all_results.(ak_key).ak = current_ak;

%% Save per-steepness
if save_results
    save_name = fullfile(mat_folder, ['PowerNormalizationStudy_', ak_key, '.mat']);
    ak_value = current_ak; %#ok<NASGU>
    save(save_name, 'results', 'summary_table', 'baselines', 'farm_spacings', ...
        'wave_cases', 'wavelengths', 'ak_value', 'row_map');
    fprintf('\nSaved: %s\n', save_name)
end

end % end steepness loop

%% Combine all summary tables
summary_table_all = vertcat(all_summary_tables{:});

%% Save combined file
if save_results
    save_name_all = fullfile(mat_folder, 'PowerNormalizationStudy_AllAK.mat');
    save(save_name_all, 'all_results', 'summary_table_all', 'farm_spacings', ...
        'waves_steepnesses', 'wavelengths', 'row_map');
    fprintf('\nSaved: %s\n', save_name_all)
end

%% Quick examples for playing with the outputs

% Example:
% results.FBF_Inline.SX50.scalars_by_case.matched_no_wave.farm_power_index.LM5_AK12
% results.FBF_Inline.SX50.scalars_by_case.same_case_row1.end_row_retention.LM3_AK09
% results.FBF_Inline.SX50.norm_by_case.matched_no_wave.LM4_AK06

% Example 1:
%   Compare farm power index for all farm types at SX50

spacing_key = 'SX50';
farm_keys = fieldnames(results);
figure('color','white'); hold on
for i = 1:numel(farm_keys)
    y = results.(farm_keys{i}).(spacing_key).scalars.matched_no_wave.farm_power_index;
    plot(1:numel(y), y, '-o', 'DisplayName', strrep(farm_keys{i}, '_', ' '), 'LineWidth', 1.5)
end
xticks(1:numel(wave_cases)); xticklabels(wave_cases); xtickangle(30)
ylabel('Farm power index (matched no-wave)'); legend('Location','best'); box off

% Example 2:
%   Sort full summary table by lowest farm power index
%
% summary_table_all = sortrows(summary_table_all, 'farm_power_index_matched_no_wave');
% disp(summary_table_all(1:20,:))

%% ------------------------------------------------------------------------
function spacing_key = spacing_to_key(spacing_val)
spacing_key = ['SX', num2str(spacing_val * 10)];
spacing_key = strrep(spacing_key, '.', 'p');
end

function first_row_nowave = get_first_row_nowave(mat_folder, wind_case, angle_case, ...
    turbine_type, arrangement, spacing_val, row_map)

spacing_folder = [wind_case, '_', ['SX', num2str(spacing_val * 10)], '_', angle_case];
base_folder = fullfile(mat_folder, [turbine_type, '_', arrangement], spacing_folder);
file_path = fullfile(base_folder, 'LM0_AK00.mat');

if ~isfile(file_path)
    error('Missing file: %s', file_path)
end

tmp = load(file_path);
data = tmp.output;
idx = row_map.(arrangement){1};
idx = idx(idx <= numel(data));
vals = arrayfun(@(k) mean(data(k).Power(:), 'omitnan'), idx);
first_row_nowave = mean(vals, 'omitnan');
end

function denom = get_baseline_from_type(baselines, turbine_type, arrangement_key, spacing_key)
switch turbine_type
    case 'FBF'
        denom = baselines.FBF.(arrangement_key).(spacing_key);
    case 'FWF'
        denom = baselines.FWF.(arrangement_key).(spacing_key);
    otherwise
        error('Unknown turbine type: %s', turbine_type)
end
end

function data = load_case_data(mat_folder, wind_case, angle_case, ...
    turbine_type, arrangement, spacing_val, case_name)
spacing_folder = [wind_case, '_', ['SX', num2str(spacing_val * 10)], '_', angle_case];
base_folder = fullfile(mat_folder, [turbine_type, '_', arrangement], spacing_folder);
file_path = fullfile(base_folder, [case_name, '.mat']);

if ~isfile(file_path)
    warning('Missing file: %s', file_path)
    data = struct('Power', nan);
    return
end

tmp = load(file_path);
data = tmp.output;
end

function metrics = compute_scalar_metrics(M)
% M is [nRows x nCases]

metrics = struct();

% Mean over all rows: main scalar for overall farm performance
metrics.farm_power_index = mean(M, 1, 'omitnan');

% Mean over downstream rows only (rows 2:end)
if size(M,1) >= 2
    metrics.downstream_mean = mean(M(2:end,:), 1, 'omitnan');
else
    metrics.downstream_mean = nan(1, size(M,2));
end

% End-of-farm retention
metrics.end_row_retention = M(end,:);

% Wake-loss index relative to row 1 within the provided normalization
% If M is same_case_row1-normalized, this directly measures decay through farm.
metrics.wake_loss_index = 1 - mean(M, 1, 'omitnan');

% Deep-farm penalty: last row relative to first row in this matrix
metrics.deep_farm_penalty = 1 - (M(end,:) ./ M(1,:));

% Simple linear slope vs row number
nRows = size(M,1);
x = (1:nRows)';
metrics.row_slope = nan(1, size(M,2));
for j = 1:size(M,2)
    y = M(:,j);
    good = isfinite(x) & isfinite(y);
    if nnz(good) >= 2
        p = polyfit(x(good), y(good), 1);
        metrics.row_slope(j) = p(1);
    end
end
end

function out = make_explicit_scalar_struct(scalars, wave_cases)
metric_groups = fieldnames(scalars);
out = struct();

for iGroup = 1:numel(metric_groups)
    group_name = metric_groups{iGroup};
    metric_names = fieldnames(scalars.(group_name));
    for iMetric = 1:numel(metric_names)
        metric_name = metric_names{iMetric};
        values = scalars.(group_name).(metric_name);
        for iCase = 1:numel(wave_cases)
            case_field = matlab.lang.makeValidName(wave_cases{iCase});
            out.(group_name).(metric_name).(case_field) = values(iCase);
        end
    end
end
end

function out = make_explicit_norm_struct(norm_struct, wave_cases)
norm_groups = fieldnames(norm_struct);
out = struct();

for iGroup = 1:numel(norm_groups)
    group_name = norm_groups{iGroup};
    values = norm_struct.(group_name);
    for iCase = 1:numel(wave_cases)
        case_field = matlab.lang.makeValidName(wave_cases{iCase});
        out.(group_name).(case_field) = values(:, iCase);
    end
end
end

function T = build_metric_table(scalars, wave_cases, wavelengths, ak_value)
nCases = numel(wave_cases);
T = table( ...
    wave_cases(:), ...
    wavelengths(:), ...
    repmat(ak_value, nCases, 1), ...
    scalars.raw.farm_power_index(:), ...
    scalars.matched_no_wave.farm_power_index(:), ...
    scalars.same_case_row1.farm_power_index(:), ...
    scalars.fixed_bottom_no_wave.farm_power_index(:), ...
    scalars.floating_no_wave.farm_power_index(:), ...
    scalars.matched_no_wave.end_row_retention(:), ...
    scalars.same_case_row1.end_row_retention(:), ...
    scalars.same_case_row1.wake_loss_index(:), ...
    scalars.same_case_row1.row_slope(:), ...
    'VariableNames', { ...
    'wave_case', ...
    'lambda_over_D', ...
    'ak', ...
    'farm_power_index_raw', ...
    'farm_power_index_matched_no_wave', ...
    'farm_power_index_same_case_row1', ...
    'farm_power_index_fixed_bottom_no_wave', ...
    'farm_power_index_floating_no_wave', ...
    'end_row_retention_matched_no_wave', ...
    'end_row_retention_same_case_row1', ...
    'wake_loss_index_same_case_row1', ...
    'row_slope_same_case_row1'});
end

function T = build_summary_table(results, farm_spacings, wave_cases, wavelengths, ak_value)
rows = {};

farm_keys = fieldnames(results);
for i = 1:numel(farm_keys)
    farm_key = farm_keys{i};
    meta = results.(farm_key).meta;

    for sp = 1:numel(farm_spacings)
        spacing_key = spacing_to_key(farm_spacings(sp));
        block = results.(farm_key).(spacing_key);

        for w = 1:numel(wave_cases)
            rows(end+1, :) = { ...
                meta.turbine_type, ...
                meta.arrangement, ...
                farm_spacings(sp), ...
                wave_cases{w}, ...
                wavelengths(w), ...
                ak_value, ...
                block.scalars.raw.farm_power_index(w), ...
                block.scalars.matched_no_wave.farm_power_index(w), ...
                block.scalars.same_case_row1.farm_power_index(w), ...
                block.scalars.fixed_bottom_no_wave.farm_power_index(w), ...
                block.scalars.floating_no_wave.farm_power_index(w), ...
                block.scalars.matched_no_wave.end_row_retention(w), ...
                block.scalars.same_case_row1.end_row_retention(w), ...
                block.scalars.same_case_row1.wake_loss_index(w), ...
                block.scalars.same_case_row1.row_slope(w) ...
                };
        end
    end
end

T = cell2table(rows, 'VariableNames', { ...
    'turbine_type', ...
    'arrangement', ...
    'spacing_D', ...
    'wave_case', ...
    'lambda_over_D', ...
    'ak', ...
    'farm_power_index_raw', ...
    'farm_power_index_matched_no_wave', ...
    'farm_power_index_same_case_row1', ...
    'farm_power_index_fixed_bottom_no_wave', ...
    'farm_power_index_floating_no_wave', ...
    'end_row_retention_matched_no_wave', ...
    'end_row_retention_same_case_row1', ...
    'wake_loss_index_same_case_row1', ...
    'row_slope_same_case_row1'});
end
