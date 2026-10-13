%% Power spectra: FWF + FBF, Inline + Staggered
% Zein Sadek
%
% Loads all four farm configurations into:
%   power.FWF.Inline.(spacing).(wave)
%   power.FWF.Staggered.(spacing).(wave)
%   power.FBF.Inline.(spacing).(wave)
%   power.FBF.Staggered.(spacing).(wave)
%
% and computes spectra into the same hierarchy:
%   spectra.(farm_type).(arrangement).(spacing)(record).(wave)
%
% IMPORTANT FOR STAGGERED FARMS:
% The physical turbine positions 6 and 12 are absent. The ten stored turbine
% records are therefore mapped to physical turbine IDs:
%   [1 2 3 4 5 7 8 9 10 11]
% Each spectrum also stores .turbine_id so this mapping is retained.

clear; close all; clc;
addpath("/Users/zeinsadek/Documents/MATLAB/MatlabFunctions")
addpath("/Users/zeinsadek/Documents/MATLAB/colormaps")
addpath('/Users/zeinsadek/Documents/MATLAB/colormaps/slanCM')


offshore_path = "/Users/zeinsadek/Desktop/Experiments/Offshore";
power_path = fullfile(offshore_path, "Power/Data/Matfiles");

% -------------------------------------------------------------------------
% FARM SETTINGS
% -------------------------------------------------------------------------
farm_types = {'FWF', 'FBF'};
farm_arrangements = {'Inline', 'Staggered'};

fancy_names.FWF = 'Floating Wind Farm';
fancy_names.FBF = 'Fixed-Bottom Farm';

% Physical turbine IDs present in each layout
% Inline:    3,3,3,3 turbines per row -> 12 total
% Staggered: 3,2,3,2 turbines per row -> positions 6 and 12 removed
physical_turbines.Inline = 1:12;
physical_turbines.Staggered = [1:5, 7:11];

farm_spacings = [5, 4.5, 4, 3.5, 3];
wave_steepnesses = [0.06, 0.09, 0.12];
wavelengths = [5, 4, 3, 2];

% Generate list of forced-wave cases
waves = {};
c = 1;
for w = 1:length(wavelengths)
    wavelength = wavelengths(w);
    for st = 1:length(wave_steepnesses)
        wave_steepness = wave_steepnesses(st);
        steep = compose('%02d', round(100 * wave_steepness));
        waves{c} = ['LM', num2str(wavelength), '_AK', steep{1}]; %#ok<SAGROW>
        c = c + 1;
    end
end
clear w wavelength st wave_steepness steep c


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LOAD POWER DATA: FWF/FBF x INLINE/STAGGERED
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc;
fprintf('Loading power data...\n')

for ft = 1:length(farm_types)
    farm_type = farm_types{ft};

    for a = 1:length(farm_arrangements)
        arrangement = farm_arrangements{a};
        fprintf('\n%s - %s\n', fancy_names.(farm_type), arrangement)

        for s = 1:length(farm_spacings)
            farm_spacing = ['SX', num2str(farm_spacings(s) * 10)];
            caze = strcat("WT60_", farm_spacing, "_AG0");
            fprintf('  %s\n', caze)

            % Forced-wave cases
            for w = 1:length(waves)
                wave = waves{w};

                power_file = fullfile(power_path, ...
                    strcat(farm_type, "_", arrangement), ...
                    caze, strcat(wave, ".mat"));

                if ~isfile(power_file)
                    warning('Missing file: %s', power_file)
                    continue
                end

                tmp = load(power_file);
                power.(farm_type).(arrangement).(farm_spacing).(wave) = tmp.output;
            end

            % No-wave case
            wave = 'LM0_AK00';
            power_file = fullfile(power_path, ...
                strcat(farm_type, "_", arrangement), ...
                caze, strcat(wave, ".mat"));

            if ~isfile(power_file)
                warning('Missing file: %s', power_file)
            else
                tmp = load(power_file);
                power.(farm_type).(arrangement).(farm_spacing).(wave) = tmp.output;
            end
        end
    end
end

clear ft farm_type a arrangement s w wave tmp power_file farm_spacing caze


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FILL MISSING VALUES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc;
fprintf('Filling missing values...\n')

for ft = 1:length(farm_types)
    farm_type = farm_types{ft};

    for a = 1:length(farm_arrangements)
        arrangement = farm_arrangements{a};
        fprintf('\n%s - %s\n', fancy_names.(farm_type), arrangement)

        if ~isfield(power, farm_type) || ~isfield(power.(farm_type), arrangement)
            continue
        end

        for s = 1:length(farm_spacings)
            farm_spacing = ['SX', num2str(farm_spacings(s) * 10)];

            if ~isfield(power.(farm_type).(arrangement), farm_spacing)
                continue
            end

            cases = fields(power.(farm_type).(arrangement).(farm_spacing));

            for w = 1:length(cases)
                wave = cases{w};
                fprintf('  %s  %s\n', farm_spacing, wave)

                n_records = numel(power.(farm_type).(arrangement).(farm_spacing).(wave));
                expected_records = numel(physical_turbines.(arrangement));

                if n_records ~= expected_records
                    warning(['%s %s %s %s contains %d turbine records; ' ...
                             '%d were expected for the %s layout.'], ...
                        farm_type, arrangement, farm_spacing, wave, ...
                        n_records, expected_records, arrangement)
                end

                for t = 1:n_records
                    power.(farm_type).(arrangement).(farm_spacing).(wave)(t).Power = ...
                        fillmissing(power.(farm_type).(arrangement).(farm_spacing).(wave)(t).Power, 'spline');
                end
            end
        end
    end
end

clear ft farm_type a arrangement s farm_spacing cases w wave n_records expected_records t


%% Wave forcing frequencies
forcing_frequencies.("LM5")  = 1.4273;
forcing_frequencies.("LM4")  = 1.6075;
forcing_frequencies.("LM33") = 1.7651;
forcing_frequencies.("LM3")  = 1.8617;
forcing_frequencies.("LM25") = 2.0402;
forcing_frequencies.("LM2")  = 2.2813;


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COMPUTE POWER SPECTRA: FWF/FBF x INLINE/STAGGERED
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% PSD settings
% window_length = 2048;
% overlap = window_length/2;          % 50% overlap
% nfft = window_length;
% min_valid_fraction = 0.5;

window_length = 8192;
overlap = round(0.75 * window_length);
nfft = 16384;
min_valid_fraction = 0.5;


clc;
fprintf('Computing power spectra...\n')

for ft = 1:length(farm_types)
    farm_type = farm_types{ft};

    for a = 1:length(farm_arrangements)
        arrangement = farm_arrangements{a};
        fprintf('\n%s - %s\n', fancy_names.(farm_type), arrangement)

        if ~isfield(power, farm_type) || ~isfield(power.(farm_type), arrangement)
            continue
        end

        turbine_ids = physical_turbines.(arrangement);

        for s = 1:length(farm_spacings)
            farm_spacing = ['SX', num2str(farm_spacings(s) * 10)];

            if ~isfield(power.(farm_type).(arrangement), farm_spacing)
                continue
            end

            fprintf('  %s\n', farm_spacing)
            waves_list = fields(power.(farm_type).(arrangement).(farm_spacing));

            for w = 1:length(waves_list)
                wave = waves_list{w};
                n_records = numel(power.(farm_type).(arrangement).(farm_spacing).(wave));

                for t = 1:n_records
                    turbine_data = power.(farm_type).(arrangement).(farm_spacing).(wave)(t);
                    power_signal = turbine_data.Power(:);

                    % Map the array record to its physical turbine number.
                    % If an unexpected extra record exists, retain NaN rather than
                    % assigning a misleading physical turbine ID.
                    if t <= numel(turbine_ids)
                        turbine_id = turbine_ids(t);
                    else
                        turbine_id = NaN;
                    end

                    time_signal = turbine_data.Time(:);
                    dt = mean(diff(time_signal), 'omitnan');
                    Fs = 1/dt;

                    nan_fraction = sum(isnan(power_signal)) / length(power_signal);

                    % Always save identity/QC information
                    spectra.(farm_type).(arrangement).(farm_spacing)(t).(wave).turbine_id = turbine_id;
                    spectra.(farm_type).(arrangement).(farm_spacing)(t).(wave).record_index = t;

                    if nan_fraction > (1 - min_valid_fraction)
                        fprintf('    Skipping %s T%d (%.1f%% NaN)\n', ...
                            wave, turbine_id, nan_fraction * 100);
                        spectra.(farm_type).(arrangement).(farm_spacing)(t).(wave).Pxx = NaN;
                        spectra.(farm_type).(arrangement).(farm_spacing)(t).(wave).f = NaN;
                        spectra.(farm_type).(arrangement).(farm_spacing)(t).(wave).valid = false;
                        continue
                    end

                    % Remove mean
                    power_signal = power_signal - mean(power_signal, 'omitnan');

                    valid_data = power_signal(~isnan(power_signal));
                    if length(valid_data) < window_length
                        fprintf('    Skipping %s T%d (only %d valid points)\n', ...
                            wave, turbine_id, length(valid_data));
                        spectra.(farm_type).(arrangement).(farm_spacing)(t).(wave).Pxx = NaN;
                        spectra.(farm_type).(arrangement).(farm_spacing)(t).(wave).f = NaN;
                        spectra.(farm_type).(arrangement).(farm_spacing)(t).(wave).valid = false;
                        continue
                    end

                    % Welch PSD
                    [Pxx, f] = pwelch(power_signal, ...
                        hamming(window_length), overlap, nfft, Fs);

                    % Store output
                    spectra.(farm_type).(arrangement).(farm_spacing)(t).(wave).Pxx = Pxx;
                    spectra.(farm_type).(arrangement).(farm_spacing)(t).(wave).f = f;
                    spectra.(farm_type).(arrangement).(farm_spacing)(t).(wave).Fs = Fs;
                    spectra.(farm_type).(arrangement).(farm_spacing)(t).(wave).dt = dt;
                    spectra.(farm_type).(arrangement).(farm_spacing)(t).(wave).window_length = window_length;
                    spectra.(farm_type).(arrangement).(farm_spacing)(t).(wave).overlap = overlap;
                    spectra.(farm_type).(arrangement).(farm_spacing)(t).(wave).valid = true;
                    spectra.(farm_type).(arrangement).(farm_spacing)(t).(wave).nan_fraction = nan_fraction;

                    % Low-frequency RMS, 0--0.5 Hz
                    [rms_low, ~] = bandlimited_rms_fft(power_signal, Fs, 0, 0.5, 'none');
                    spectra.(farm_type).(arrangement).(farm_spacing)(t).(wave).rms_low = rms_low;

                    % Wave-frequency RMS, +/-10% around forcing frequency
                    if contains(wave, 'LM') && ~strcmp(wave, 'LM0_AK00')
                        wave_prefix = extractBefore(wave, '_');

                        if isfield(forcing_frequencies, wave_prefix)
                            f_wave = forcing_frequencies.(wave_prefix);
                            [rms_wave, ~] = bandlimited_rms_fft(power_signal, Fs, ...
                                0.9*f_wave, 1.1*f_wave, 'none');

                            spectra.(farm_type).(arrangement).(farm_spacing)(t).(wave).rms_wave = rms_wave;
                            spectra.(farm_type).(arrangement).(farm_spacing)(t).(wave).f_wave = f_wave;
                        end
                    end
                end
            end
        end
    end
end

fprintf('\nPower spectra computation complete.\n')

clear ft farm_type a arrangement turbine_ids s farm_spacing waves_list w wave
clear n_records t turbine_data power_signal turbine_id time_signal dt Fs nan_fraction
clear valid_data Pxx f rms_low rms_wave wave_prefix f_wave


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EXAMPLE: COMPARE ALL FOUR FARM CONFIGURATIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

farm_spacing = 'SX50';
physical_turbine = 5;
wave = 'LM4_AK12';

clc; close all
figure('Color', 'white', 'Position', [100, 100, 800, 600])
hold on

for ft = 1:length(farm_types)
    farm_type = farm_types{ft};

    for a = 1:length(farm_arrangements)
        arrangement = farm_arrangements{a};

        % Find the storage-record index corresponding to this physical turbine
        turbine_ids = physical_turbines.(arrangement);
        t = find(turbine_ids == physical_turbine, 1);

        if isempty(t) || ...
           ~isfield(spectra, farm_type) || ...
           ~isfield(spectra.(farm_type), arrangement) || ...
           ~isfield(spectra.(farm_type).(arrangement), farm_spacing) || ...
           length(spectra.(farm_type).(arrangement).(farm_spacing)) < t || ...
           ~isfield(spectra.(farm_type).(arrangement).(farm_spacing)(t), wave) || ...
           ~spectra.(farm_type).(arrangement).(farm_spacing)(t).(wave).valid
            fprintf('Skipping %s %s in comparison plot - invalid/missing data\n', ...
                farm_type, arrangement)
            continue
        end

        spec = spectra.(farm_type).(arrangement).(farm_spacing)(t).(wave);
        loglog(spec.f, spec.Pxx, 'LineWidth', 2, ...
            'DisplayName', sprintf('%s - %s', farm_type, arrangement))
    end
end

grid on
xlabel('Frequency [Hz]')
ylabel('PSD [Power^2/Hz]')
title(sprintf('Physical turbine %d - %s - %s', physical_turbine, farm_spacing, wave))
legend('Location', 'best')

% Wave frequency and harmonics
wave_prefix = extractBefore(wave, '_');
if isfield(forcing_frequencies, wave_prefix)
    f_wave = forcing_frequencies.(wave_prefix);
    xline(f_wave * (1:5), '--', 'HandleVisibility', 'off', 'linewidth', 1, 'layer', 'bottom')
    xline(f_wave * (0.5:1:5.5), '-', 'HandleVisibility', 'off', 'linewidth', 1, 'layer', 'bottom')
end

xscale('log')
yscale('log')
xlim([1E-1, 1E1])





%% Testing differnt plot types


% farm_spacing = 'SX50';
% physical_turbine = 5;
% 
% labelFontSize = 10;
% tickFontSize = 8;
% 
% wavelength_colors = {}
% 
% c = 1;
% clc; close all
% 
% fig = figure('Color', 'white', 'Position', [100, 100, 800, 600]);
% 
% til = tiledlayout(fig, 1, 4, ...
%     'TileSpacing', 'compact', ...
%     'Padding', 'compact');
% 
% h = gobjects(0);
% 
% 
% for ft = 1:length(farm_types)
%     farm_type = farm_types{ft};
% 
%     for a = 1:length(farm_arrangements)
%         arrangement = farm_arrangements{a};
% 
%         % Find storage-record index corresponding to physical turbine
%         turbine_ids = physical_turbines.(arrangement);
%         t = find(turbine_ids == physical_turbine, 1);
% 
%         % Check that this farm / arrangement / spacing / turbine exists
%         if isempty(t) || ...
%            ~isfield(spectra, farm_type) || ...
%            ~isfield(spectra.(farm_type), arrangement) || ...
%            ~isfield(spectra.(farm_type).(arrangement), farm_spacing) || ...
%            length(spectra.(farm_type).(arrangement).(farm_spacing)) < t
% 
%             fprintf('Skipping %s %s - invalid/missing turbine data\n', ...
%                 farm_type, arrangement)
%             continue
%         end
% 
% 
%         % Create tile
%         h(c) = nexttile(til);
% 
%         set(h(c), ...
%             'FontSize', tickFontSize, ...
%             'TickLabelInterpreter', 'latex');
%         hold(h(c), 'on')
% 
% 
%         % Plot waves
%         for w = 1:length(waves)
%             wave = waves{w};
%             turbine_data = ...
%                 spectra.(farm_type).(arrangement).(farm_spacing)(t);
% 
%             wave_prefix = extractBefore(wave, '_');
%             wave_suffix = extractAfter(wave, '_');
%             f_wave = forcing_frequencies.(wave_prefix);
% 
%             % Check this particular wave
%             if ~isfield(turbine_data, wave) || ...
%                ~turbine_data.(wave).valid
% 
%                 fprintf('Skipping %s %s %s - invalid/missing wave\n', ...
%                     farm_type, arrangement, wave)
%                 continue
%             end
% 
%             spec = turbine_data.(wave);
%             P = plot(h(c), spec.f / f_wave, spec.Pxx, 'LineWidth', 1);
%             % P.Color(4) = 0.25;
%         end
% 
%         xline([1,2,3], 'color', 'black', 'linewidth', 1, 'layer', 'bottom')
%         xline([0.5, 1.5, 2.5], 'color', 'black', 'linewidth', 1, 'linestyle', '--', 'layer', 'bottom')
% 
%         hold(h(c), 'off')
%         title(h(c), sprintf('%s - %s', farm_type, arrangement), ...
%             'Interpreter', 'none')
%         set(h(c), ...
%             'XScale', 'log', ...
%             'YScale', 'log')
% 
%         xlim(h(c), [1E-1, 1E1])
%         c = c + 1;
%     end
% end
% 
% 
% % Link only axes that actually got created
% if ~isempty(h)
%     linkaxes(h, 'xy')
% end
% 
% % Shared labels
% xlabel(til, '$f \mathbin{/} f_{\mathrm{wave}}$', ...
%     'Interpreter', 'latex', ...
%     'FontSize', labelFontSize)
% 
% ylabel(til, 'PSD [Power$^2$/Hz]', ...
%     'Interpreter', 'latex', ...
%     'FontSize', labelFontSize)



%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ROW-AVERAGED POWER SPECTRA
%
% Computes the average PSD of all turbines within each physical farm row.
%
% Inline rows:
%   Row 1 = turbines 1  2  3
%   Row 2 = turbines 4  5  6
%   Row 3 = turbines 7  8  9
%   Row 4 = turbines 10 11 12
%
% Staggered rows:
%   Row 1 = turbines 1  2  3
%   Row 2 = turbines 4  5
%   Row 3 = turbines 7  8  9
%   Row 4 = turbines 10 11
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Physical turbine IDs belonging to each farm row
row_turbines.Inline = { ...
    [1 2 3], ...
    [4 5 6], ...
    [7 8 9], ...
    [10 11 12]};

row_turbines.Staggered = { ...
    [1 2 3], ...
    [4 5], ...
    [7 8 9], ...
    [10 11]};


clc
fprintf('Computing row-averaged power spectra...\n')


for ft = 1:length(farm_types)

    farm_type = farm_types{ft};

    for a = 1:length(farm_arrangements)

        arrangement = farm_arrangements{a};

        if ~isfield(spectra, farm_type) || ...
           ~isfield(spectra.(farm_type), arrangement)
            continue
        end

        % Physical turbine ID associated with each stored record
        turbine_ids = physical_turbines.(arrangement);


        for s = 1:length(farm_spacings)

            farm_spacing = ['SX', num2str(farm_spacings(s) * 10)];

            if ~isfield(spectra.(farm_type).(arrangement), farm_spacing)
                continue
            end


            % Use cases appearing in the original power structure
            if ~isfield(power, farm_type) || ...
               ~isfield(power.(farm_type), arrangement) || ...
               ~isfield(power.(farm_type).(arrangement), farm_spacing)
                continue
            end

            cases = fields(power.(farm_type).(arrangement).(farm_spacing));


            for r = 1:4

                % Physical turbine IDs in this row
                row_ids = row_turbines.(arrangement){r};

                % Corresponding storage indices
                row_record_indices = find(ismember(turbine_ids, row_ids));


                for w = 1:length(cases)

                    wave = cases{w};

                    Pxx_stack = [];
                    f_common = [];
                    turbines_used = [];


                    for ii = 1:length(row_record_indices)

                        t = row_record_indices(ii);

                        % Make sure record exists
                        if length(spectra.(farm_type).(arrangement).(farm_spacing)) < t
                            continue
                        end

                        turbine_spec = ...
                            spectra.(farm_type).(arrangement).(farm_spacing)(t);


                        % Make sure this wave exists and is valid
                        if ~isfield(turbine_spec, wave) || ...
                           ~turbine_spec.(wave).valid
                            continue
                        end

                        spec = turbine_spec.(wave);

                        f_tmp = spec.f(:);
                        P_tmp = spec.Pxx(:);


                        % First valid turbine defines common frequency vector
                        if isempty(f_common)

                            f_common = f_tmp;
                            P_interp = P_tmp;

                        else

                            % Usually all frequency vectors will already be
                            % identical. This interpolation is just a safeguard.
                            if length(f_tmp) == length(f_common) && ...
                               max(abs(f_tmp - f_common)) < 1e-10

                                P_interp = P_tmp;

                            else

                                P_interp = interp1( ...
                                    f_tmp, P_tmp, f_common, ...
                                    'linear', NaN);

                            end
                        end


                        Pxx_stack(:,end+1) = P_interp; %#ok<SAGROW>
                        turbines_used(end+1) = turbine_ids(t); %#ok<SAGROW>

                    end


                    % -----------------------------------------------------
                    % Average spectra across turbines in this row
                    % -----------------------------------------------------
                    if ~isempty(Pxx_stack)

                        row_spectra.(farm_type).(arrangement). ...
                            (farm_spacing)(r).(wave).f = f_common;

                        row_spectra.(farm_type).(arrangement). ...
                            (farm_spacing)(r).(wave).Pxx = ...
                            mean(Pxx_stack, 2, 'omitnan');

                        row_spectra.(farm_type).(arrangement). ...
                            (farm_spacing)(r).(wave).n_turbines = ...
                            size(Pxx_stack,2);

                        row_spectra.(farm_type).(arrangement). ...
                            (farm_spacing)(r).(wave).turbine_ids = ...
                            turbines_used;

                        row_spectra.(farm_type).(arrangement). ...
                            (farm_spacing)(r).(wave).valid = true;

                    else

                        row_spectra.(farm_type).(arrangement). ...
                            (farm_spacing)(r).(wave).f = NaN;

                        row_spectra.(farm_type).(arrangement). ...
                            (farm_spacing)(r).(wave).Pxx = NaN;

                        row_spectra.(farm_type).(arrangement). ...
                            (farm_spacing)(r).(wave).n_turbines = 0;

                        row_spectra.(farm_type).(arrangement). ...
                            (farm_spacing)(r).(wave).turbine_ids = [];

                        row_spectra.(farm_type).(arrangement). ...
                            (farm_spacing)(r).(wave).valid = false;

                    end
                end
            end
        end
    end
end


fprintf('Row-averaged power spectra complete.\n')


clear ft farm_type a arrangement turbine_ids s farm_spacing cases
clear r row_ids row_record_indices w wave ii t turbine_spec spec
clear f_tmp P_tmp f_common P_interp Pxx_stack turbines_used



%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MEAN ROW-AVERAGED SPECTRA ACROSS ALL WAVE CASES
%
% For each:
%   farm type
%   arrangement
%   spacing
%   physical farm row
%
% interpolate each wave-case PSD onto a common normalized
% frequency axis f/f_wave, then average across wave cases.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Common normalized frequency axis
% Covers the same range used in the plots
f_norm_common = logspace(-1, 1, 500)';


fprintf('Computing mean spectra across wave cases...\n')


for ft = 1:length(farm_types)

    farm_type = farm_types{ft};


    for a = 1:length(farm_arrangements)

        arrangement = farm_arrangements{a};


        if ~isfield(row_spectra, farm_type) || ...
           ~isfield(row_spectra.(farm_type), arrangement)
            continue
        end


        for s = 1:length(farm_spacings)

            farm_spacing = ['SX', num2str(farm_spacings(s) * 10)];


            if ~isfield(row_spectra.(farm_type).(arrangement), farm_spacing)
                continue
            end


            for r = 1:4

                wave_PSDs = [];
                waves_used = {};


                for w = 1:length(waves)

                    wave = waves{w};


                    % Make sure this row/wave exists
                    if length(row_spectra.(farm_type).(arrangement).(farm_spacing)) < r
                        continue
                    end

                    row_data = ...
                        row_spectra.(farm_type).(arrangement). ...
                        (farm_spacing)(r);


                    if ~isfield(row_data, wave) || ...
                       ~row_data.(wave).valid
                        continue
                    end


                    % ---------------------------------------------
                    % Get forcing frequency
                    % ---------------------------------------------
                    wave_prefix = extractBefore(wave, '_');

                    if ~isfield(forcing_frequencies, wave_prefix)
                        continue
                    end

                    f_wave = forcing_frequencies.(wave_prefix);


                    % ---------------------------------------------
                    % Normalize frequency by forcing frequency
                    % ---------------------------------------------
                    f = row_data.(wave).f(:);
                    Pxx = row_data.(wave).Pxx(:);

                    f_norm = f / f_wave;


                    % ---------------------------------------------
                    % Interpolate onto common normalized frequency
                    % axis
                    % ---------------------------------------------
                    P_interp = interp1( ...
                        f_norm, ...
                        Pxx, ...
                        f_norm_common, ...
                        'linear', ...
                        NaN);


                    wave_PSDs(:,end+1) = P_interp; %#ok<SAGROW>
                    waves_used{end+1} = wave; %#ok<SAGROW>

                end


                % ---------------------------------------------
                % Average across wave cases
                % ---------------------------------------------
                if ~isempty(wave_PSDs)

                    mean_row_spectra.(farm_type).(arrangement). ...
                        (farm_spacing)(r).f_norm = ...
                        f_norm_common;

                    mean_row_spectra.(farm_type).(arrangement). ...
                        (farm_spacing)(r).Pxx = ...
                        mean(wave_PSDs, 2, 'omitnan');

                    mean_row_spectra.(farm_type).(arrangement). ...
                        (farm_spacing)(r).n_waves = ...
                        size(wave_PSDs,2);

                    mean_row_spectra.(farm_type).(arrangement). ...
                        (farm_spacing)(r).waves_used = ...
                        waves_used;

                    mean_row_spectra.(farm_type).(arrangement). ...
                        (farm_spacing)(r).valid = true;

                else

                    mean_row_spectra.(farm_type).(arrangement). ...
                        (farm_spacing)(r).f_norm = NaN;

                    mean_row_spectra.(farm_type).(arrangement). ...
                        (farm_spacing)(r).Pxx = NaN;

                    mean_row_spectra.(farm_type).(arrangement). ...
                        (farm_spacing)(r).n_waves = 0;

                    mean_row_spectra.(farm_type).(arrangement). ...
                        (farm_spacing)(r).waves_used = {};

                    mean_row_spectra.(farm_type).(arrangement). ...
                        (farm_spacing)(r).valid = false;

                end

            end
        end
    end
end


fprintf('Mean spectra across wave cases complete.\n')


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PLOT ROW-AVERAGED POWER SPECTRA
%
%       Row 1     Row 2     Row 3     Row 4
%
% FBF     x         x         x         x
%
% FWF     x         x         x         x
%
% Solid  = Inline
% Dashed = Staggered
% Color  = wave case
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Choose farm spacing to plot
farm_spacing = 'SX50';


labelFontSize = 10;
tickFontSize = 8;
line_width = 0.5 ;


% Plot order requested:
% top    = fixed-bottom
% bottom = floating
plot_farm_types = {'FBF', 'FWF'};

% Arrangement represented by line style
arrangement_linestyle.Inline = '-';
arrangement_linestyle.Staggered = '--';

mean_arrangement_linestyle.Inline = '-';
mean_arrangement_linestyle.Staggered = ':';

% One color per wave case
% wave_colors = turbo(length(waves));
wave_colors = slanCM('haline', length(waves));


%%% Vibrant sunset
steepness_colors.Inline.('AK06') = '#9d4edd';
steepness_colors.Inline.('AK09') = '#5a189a';
steepness_colors.Inline.('AK12') = '#240046';

steepness_colors.Staggered.('AK06') = '#ff9e00';
steepness_colors.Staggered.('AK09') = '#ff8500';
steepness_colors.Staggered.('AK12') = '#ff6d00';

spectra_alpha = 0.4;


clc
close all

fig = figure( ...
    'Color', 'white', ...
    'units', 'centimeters', ...
    'Position', [10 10 16 5]);

til = tiledlayout(fig, 2, 4, ...
    'TileSpacing', 'tight', ...
    'Padding', 'tight');


ax = gobjects(2,4);


for ft = 1:2

    farm_type = plot_farm_types{ft};


    for r = 1:4

        % Explicit tile index guarantees:
        %
        % 1 2 3 4 = FBF
        % 5 6 7 8 = FWF
        tile_number = (ft - 1)*4 + r;

        ax(ft,r) = nexttile(til, tile_number);

        hold(ax(ft,r), 'on')

        set(ax(ft,r), ...
            'FontSize', tickFontSize, ...
            'TickLabelInterpreter', 'latex', ...
            'XScale', 'log', ...
            'YScale', 'log', ...
            'Box', 'on')

        if tile_number < 5
            xticklabels({})
        end

        if ~ismember(tile_number, [1, 5])
            yticklabels({})
        end


        % -------------------------------------------------------------
        % Plot Inline + Staggered
        % -------------------------------------------------------------
        for a = 1:length(farm_arrangements)

            arrangement = farm_arrangements{a};
            line_style = arrangement_linestyle.(arrangement);


            if ~isfield(row_spectra, farm_type) || ...
               ~isfield(row_spectra.(farm_type), arrangement) || ...
               ~isfield(row_spectra.(farm_type).(arrangement), farm_spacing) || ...
               length(row_spectra.(farm_type).(arrangement).(farm_spacing)) < r
                continue
            end


            % ---------------------------------------------------------
            % Plot every forced-wave case
            % ---------------------------------------------------------
            for w = 1:length(waves)

                wave = waves{w};

                row_data = ...
                    row_spectra.(farm_type).(arrangement). ...
                    (farm_spacing)(r);


                if ~isfield(row_data, wave) || ...
                   ~row_data.(wave).valid
                    continue
                end


                % Forcing frequency for this wave
                wave_prefix = extractBefore(wave, '_');

                if ~isfield(forcing_frequencies, wave_prefix)
                    continue
                end

                f_wave = forcing_frequencies.(wave_prefix);


                spec = row_data.(wave);


                color = steepness_colors.(arrangement).(extractAfter(wave, '_'));
                P = plot(ax(ft,r), ...
                    spec.f / f_wave, ...
                    spec.Pxx, ...
                    'Color', color, ...
                    'LineStyle', line_style, ...
                    'LineWidth', line_width, ...
                    'HandleVisibility', 'off');
                P.Color(4) = spectra_alpha;

            end

            % ---------------------------------------------------------
            % Plot mean spectrum across all wave cases
            % ---------------------------------------------------------
            if isfield(mean_row_spectra, farm_type) && ...
               isfield(mean_row_spectra.(farm_type), arrangement) && ...
               isfield(mean_row_spectra.(farm_type).(arrangement), farm_spacing) && ...
               length(mean_row_spectra.(farm_type).(arrangement).(farm_spacing)) >= r
            
                mean_spec = ...
                    mean_row_spectra.(farm_type).(arrangement). ...
                    (farm_spacing)(r);
            
                if mean_spec.valid
            
                    P = plot(ax(ft,r), ...
                        mean_spec.f_norm, ...
                        mean_spec.Pxx, ...
                        'Color', 'black', ...
                        'LineStyle', mean_arrangement_linestyle.(arrangement), ...
                        'LineWidth', 1.5, ...
                        'HandleVisibility', 'off');
                    uistack(P, 'top')
            
                end
            end

        end


        % -------------------------------------------------------------
        % Wave frequency + harmonics
        % -------------------------------------------------------------
        lines_lw = 0.75;

        if ft == 1
            % xline(ax(ft,r), [1,2,4,8], ...
            %     '-', ...
            %     {'1', '2', '4', '8'}, ...
            %     'Fontsize', 7, ...
            %     'interpreter', 'latex', ...
            %     'LabelOrientation', 'horizontal', ...
            %     'LabelVerticalAlignment', 'top', ...
            %     'LabelHorizontalAlignment', 'center', ...
            %     'Color', 'black', ...
            %     'LineWidth', lines_lw, ...
            %     'HandleVisibility', 'off', ...
            %     'Layer', 'bottom');
            % 
            % xline(ax(ft,r), [0.5], ...
            %     '--', ...
            %     {'0.5'}, ...
            %     'Fontsize', 7, ...
            %     'interpreter', 'latex', ...
            %     'LabelOrientation', 'horizontal', ...
            %     'LabelVerticalAlignment', 'top', ...
            %     'LabelHorizontalAlignment', 'center', ...
            %     'Color', 'black', ...
            %     'LineWidth', lines_lw, ...
            %     'HandleVisibility', 'off', ...
            %     'Layer', 'bottom');


            a = ax(ft,r);
        
            % Settings
            xValues   = [0.5, 1, 2, 4, 8];
            labels    = {'0.5', '1', '2', '4', '8'};
            styles    = {'--', '-', '-', '-', '-'};
        
            yLabel = 15.0;   % Bottom of labels (adjust to your limits)
            gap    = 0.4;  % Distance below labels to line endpoints
        
            yl = ylim(a);
            yLineEnd = yLabel - gap;
        
            for k = 1:numel(xValues)
                % Vertical segment
                h = line(a, [xValues(k), xValues(k)], ...
                    [yl(1), yLineEnd], ...
                    'LineStyle', styles{k}, ...
                    'Color', 'black', ...
                    'LineWidth', lines_lw, ...
                    'HandleVisibility', 'off');
        
                uistack(h, 'bottom');
        
                % Separate label
                text(a, xValues(k), yLabel, labels{k}, ...
                    'FontSize', 7, ...
                    'Interpreter', 'latex', ...
                    'HorizontalAlignment', 'center', ...
                    'VerticalAlignment', 'bottom', ...
                    'Color', 'black', ...
                    'HandleVisibility', 'off');
            end
        

        else
            xline(ax(ft,r), [1,2,4,8], ...
                '-', ...
                'Color', 'black', ...
                'LineWidth', lines_lw, ...
                'HandleVisibility', 'off', ...
                'Layer', 'bottom');

            xline(ax(ft,r), [0.5], ...
                '--', ...
                'Color', 'black', ...
                'LineWidth', lines_lw, ...
                'HandleVisibility', 'off', ...
                'Layer', 'bottom');
        end




        % Column titles
        if ft == 1
            title(ax(ft,r), ...
                sprintf('Row %d', r), ...
                'Interpreter', 'latex', ...
                'FontSize', labelFontSize);
        end


        hold(ax(ft,r), 'off')

    end
end



% Row labels
ylabel(til, ...
    'PSD [mW$^2 \mathbin{/}$ Hz]', ...
    'Interpreter', 'latex', ...
    'FontSize', labelFontSize);

xlabel(til, ...
    '$f \mathbin{/} f_{\mathrm{wave}}$', ...
    'Interpreter', 'latex', ...
    'FontSize', labelFontSize);







% =====================
% Dummy legend entries for steepness colors
% =====================
ax_leg = nexttile(1);
hold(ax_leg, 'on')

steepness_legend_values = [0.06, 0.09, 0.12];

for ly = 1:2
    farm_arrangement = farm_arrangements{ly};
    keys = fields(steepness_colors.(farm_arrangement));
    for st = 1:length(keys)
        steepness = keys{st};
        label = sprintf('%s: $ak_{%1.2f}$', farm_arrangement(1), steepness_legend_values(st));
        color = steepness_colors.(farm_arrangement).(steepness);
        plot(ax_leg, nan, nan, ...
            'color', color, 'DisplayName', label, ...
            'linewidth', 2)
    end
    plot(ax_leg, nan, nan, 'Color', 'black', ...
                        'LineStyle', mean_arrangement_linestyle.(farm_arrangement), ...
                        'LineWidth', 2, 'Displayname', sprintf('%s: $\\overline{\\mathrm{PSD}}$', farm_arrangement(1)));
    if ly == 1
        plot(ax_leg, nan, nan, 'Color', 'white', 'DisplayName', ' ')
    end
end

hold(ax_leg, 'off')
leg = legend(ax_leg, 'box', 'off', 'interpreter', 'latex', 'location', 'eastoutside');
leg.Layout.Tile = 'east';
leg.IconColumnWidth = 10;

% Link all axes
linkaxes(ax(:), 'xy')
ylim([1E-3, 200])
xlim([1E-1, 11])


addPanelLabelsFixed(fig, [ax(1,1), ax(2,1)], {'a', 'b'}, 'FontSize', 10, 'OffsetPts', [-3,-52])


% Save figure
% figure_folder = '/Users/zeinsadek/Desktop/Experiments/Offshore/Publishing/PowerMotion/Power/Results';
% filename = 'Offshore_PowerMotion_PowerSpectra.pdf';
% pause(3)
% exportgraphics(fig, fullfile(figure_folder, filename), 'resolution', 600)
% close all




%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EXAMPLES: ACCESSING RESULTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Inline turbine 3 (record 3 = physical turbine 3):
%   spectra.FWF.Inline.SX50(3).LM5_AK06.Pxx
%   spectra.FBF.Inline.SX50(3).LM5_AK06.Pxx
%
% Staggered physical turbine 7 is RECORD 6 because turbine 6 is absent:
%   spectra.FWF.Staggered.SX50(6).LM5_AK06.Pxx
%   spectra.FWF.Staggered.SX50(6).LM5_AK06.turbine_id   % returns 7
%
% Corresponding raw power data:
%   power.FWF.Inline.SX50.LM5_AK06(3).Power
%   power.FBF.Staggered.SX50.LM5_AK06(6).Power
%
% Mapping used for staggered data:
%   record index:  1  2  3  4  5  6  7  8  9  10
%   turbine ID:    1  2  3  4  5  7  8  9 10  11
%


function hAnn = addPanelLabelsFixed(fig, ax, labels, varargin)
% Places (a),(b),... just outside top-left with FIXED physical offsets.
%
% fig    : figure handle (e.g., totalFigure)
% ax     : array of axes handles
% labels : {'a','b',...} or ["a","b",...]
%
% Name-value:
% 'OffsetPts' : [dx dy] in points (default [-10 6])  (left, up)
% 'FontSize'  : default 12
% 'FontName'  : default 'Times New Roman'

p = inputParser;
addParameter(p,'OffsetPts',[-10 6]);
addParameter(p,'FontSize',12);
addParameter(p,'FontName','Times New Roman');
parse(p,varargin{:});

labels = string(labels);
offPts = p.Results.OffsetPts;

ppi = get(0,'ScreenPixelsPerInch');
offPx = offPts/72 * ppi;   % points -> pixels

hAnn = gobjects(numel(ax),1);

for k = 1:numel(ax)
    if ~isgraphics(ax(k),'axes'), continue; end

    % Axes outer position in figure pixels
    op = getpixelposition(ax(k), true);  % [x y w h] in pixels relative to figure

    % Anchor point: outside top-left of axes
    x = op(1) + offPx(1);
    y = op(2) + op(4) + offPx(2);

    % TeX gives roman parentheses + italic letter
    str = sprintf('(\\it%s\\rm)', labels(k));

    hAnn(k) = annotation(fig,'textbox', ...
        'Units','pixels', ...
        'Position',[x y 40 20], ...   % small box; big enough for "(a)"
        'String',str, ...
        'Interpreter','tex', ...
        'FontName',p.Results.FontName, ...
        'FontSize',p.Results.FontSize, ...
        'LineStyle','none', ...
        'HorizontalAlignment','left', ...
        'VerticalAlignment','bottom');
    end
end


function [rmsBand, psdInfo] = bandlimited_rms_fft(q, Fs, f1, f2, detrendMode)
% bandlimited_rms_fft  Compute RMS of q in the frequency band [f1,f2] using FFT
%
% This function uses Parseval's theorem to compute band-limited RMS with
% sharp frequency cutoffs (no filter roll-off losses). This ensures that
% the sum of squared RMS values across contiguous bands equals the total
% variance of the signal.
%
% Inputs:
%   q           [Nx1] signal
%   Fs          sampling frequency [Hz]
%   f1          lower band edge [Hz] (use 0 for DC)
%   f2          upper band edge [Hz] (must be <= Fs/2)
%   detrendMode 'constant' (mean removal), 'linear', or 'none'
%
% Outputs:
%   rmsBand     RMS of signal content in [f1, f2]
%   psdInfo     struct with diagnostic info (optional)

    arguments
        q (:,1) double
        Fs (1,1) double {mustBePositive}
        f1 (1,1) double {mustBeNonnegative}
        f2 (1,1) double {mustBePositive}
        detrendMode (1,:) char = 'constant'
    end

    % Input validation
    if f2 > Fs/2
        error('f2 must be <= Fs/2. Got f2=%.3f, Fs/2=%.3f', f2, Fs/2);
    end
    if f1 >= f2
        error('f1 must be < f2. Got f1=%.3f, f2=%.3f', f1, f2);
    end

    N = length(q);
    
    % Detrend signal
    switch detrendMode
        case 'constant'
            q0 = q - mean(q, 'omitnan');
        case 'linear'
            q0 = detrend(q, 'linear');
        case 'none'
            q0 = q;
        otherwise
            q0 = q - mean(q, 'omitnan');
    end

    % Compute FFT
    Q = fft(q0);
    
    % Frequency vector
    df = Fs / N;                    % Frequency resolution
    f = (0:N-1)' * df;              % Two-sided frequency vector
    
    % One-sided frequency vector for indexing
    if mod(N, 2) == 0
        nUnique = N/2 + 1;          % DC to Nyquist (inclusive)
    else
        nUnique = (N+1)/2;          % DC to just below Nyquist
    end
    f_onesided = f(1:nUnique);
    
    % Find frequency bins within the band [f1, f2)
    % Use >= f1 and < f2 for lower bands, include f2 if at Nyquist
    if abs(f2 - Fs/2) < df/2
        idx_band = (f_onesided >= f1) & (f_onesided <= f2);
    else
        idx_band = (f_onesided >= f1) & (f_onesided < f2);
    end
    
    % Get the magnitude squared of FFT coefficients in the band
    Q_onesided = Q(1:nUnique);
    magSq = abs(Q_onesided(idx_band)).^2;
    
    % Determine scaling for each bin
    idx_numbers = find(idx_band);
    
    power = 0;
    for i = 1:length(idx_numbers)
        k = idx_numbers(i);
        if k == 1
            % DC component (appears once)
            power = power + magSq(i);
        elseif mod(N, 2) == 0 && k == nUnique
            % Nyquist component for even N (appears once)
            power = power + magSq(i);
        else
            % All other components (appear twice: positive and negative freq)
            power = power + 2 * magSq(i);
        end
    end
    
    % Parseval's theorem: sum(|x|^2) = (1/N) * sum(|X|^2)
    variance_band = power / N^2;
    rmsBand = sqrt(variance_band);
    
    % Optional diagnostic output
    if nargout > 1
        Pxx = abs(Q_onesided).^2 / (N^2 * df);
        Pxx(2:end-1) = 2 * Pxx(2:end-1);
        if mod(N, 2) ~= 0
            Pxx(end) = 2 * Pxx(end);
        end
        
        psdInfo.f = f_onesided;
        psdInfo.Pxx = Pxx;
        psdInfo.idx = idx_band;
        psdInfo.df = df;
        psdInfo.N = N;
    end
end


