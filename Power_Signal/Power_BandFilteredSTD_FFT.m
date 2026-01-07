%% Looking at band-limited RMS/STD of power (CORRECTED VERSION)
% Zein Sadek
% 
% Key changes from original:
% 1. Uses FFT-based band-limited RMS (no filter roll-off losses)
% 2. Bands are defined to be perfectly contiguous: [0, 0.5*fw], [0.5*fw, 1.5*fw], [1.5*fw, Fs/2]
% 3. Includes verification that sum of squared band RMS equals total variance

clear; close all; clc;
addpath("/Users/zeinsadek/Documents/MATLAB/MatlabFunctions")
addpath("/Users/zeinsadek/Documents/MATLAB/colormaps")
addpath('/Users/zeinsadek/Documents/MATLAB/colormaps/slanCM')


offshore_path = "/Users/zeinsadek/Desktop/Experiments/Offshore";
power_path = fullfile(offshore_path, "Power/Data/Matfiles");

turbine_type = 'FBF';
farm_arrangement = "Staggered";
turbines = 1:12;

% Name depending on farm type
if strcmp(turbine_type, 'FWF')
    fancy_name = 'Floating Wind Farm';
elseif strcmp(turbine_type, 'FBF')
    fancy_name = 'Fixed-Bottom Farm';
end

% Load all spacings
farm_spacings = [5, 4.5, 4, 3.5, 3];
wave_steepnesses = [0.06, 0.09, 0.12];
wavelengths = [5, 4, 3, 2];

% Generate list of waves
waves = {};
c = 1;
for w = 1:length(wavelengths)
    wavelength = wavelengths(w);
    for st = 1:length(wave_steepnesses)
        wave_steepness = wave_steepnesses(st);
        steep = compose('%02d', round(100 * wave_steepness));
        waves{c} = ['LM', num2str(wavelength), '_AK', steep{1}];
        c = c + 1;
    end
end

clear w wavelength st wave_steepness steep c


% Load powers
for s = 1:length(farm_spacings)
    farm_spacing = ['SX', num2str(farm_spacings(s) * 10)];
    caze = strcat("WT60_", farm_spacing, "_AG0");
    fprintf('%s\n', caze)

    for w = 1:length(waves)
        wave = waves{w};

        power_file = fullfile(power_path, strcat(turbine_type, "_", farm_arrangement), caze, strcat(wave, ".mat"));
        tmp = load(power_file);
        power.(farm_spacing).(wave) = tmp.output;
    end
end

clear w wave tmp power_file farm_spacing caze

% Remove nans from signals
clc;
for s = 1:length(farm_spacings)
    farm_spacing = ['SX', num2str(farm_spacings(s) * 10)];
    caze = strcat("WT60_", farm_spacing, "_AG0");
    fprintf('%s\n', caze)

    for w = 1:length(waves)
        wave = waves{w};

        for t = 1:length(turbines)
            % turbine = turbines(t);
            power.(farm_spacing).(wave)(t).Power = fillmissing(power.(farm_spacing).(wave)(t).Power, 'spline');
        end
    end
end

clear w wave tmp power_file farm_spacing caze


forcing_frequencies.("LM5")  = 1.4273;
forcing_frequencies.("LM4")  = 1.6075;
forcing_frequencies.("LM33") = 1.7651;
forcing_frequencies.("LM3")  = 1.8617;
forcing_frequencies.("LM25") = 2.0402;
forcing_frequencies.("LM2")  = 2.2813;



%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COMPUTE STD OF EACH POWER STIGNAL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc;
for s = 1:length(farm_spacings)
    farm_spacing = ['SX', num2str(farm_spacings(s) * 10)];
    caze = strcat("WT60_", farm_spacing, "_AG0");
    fprintf('%s\n', caze)

    % Loop through waves
    for w = 1:length(waves)
        wave = waves{w};

        % Loop through turbines
        for t = 1:length(turbines)
            % Compute standard deviation
            deviations.(farm_spacing)(t).(wave) = std(power.(farm_spacing).(wave)(t).Power, 0, 'all', 'omitnan');

            if isnan(deviations.(farm_spacing)(t).(wave))
                fprintf('%s: %s Turbine %2.0f\n', caze, wave, t)
            end
        end
    end
end


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COMPUTE MEAN OF EACH POWER STIGNAL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc;
for s = 1:length(farm_spacings)
    farm_spacing = ['SX', num2str(farm_spacings(s) * 10)];
    caze = strcat("WT60_", farm_spacing, "_AG0");
    fprintf('%s\n', caze)

    % Loop through waves
    for w = 1:length(waves)
        wave = waves{w};

        % Loop through turbines
        for t = 1:length(turbines)
            % Compute standard deviation
            averages.(farm_spacing)(t).(wave) = mean(power.(farm_spacing).(wave)(t).Power, 'all', 'omitnan');

            if isnan(deviations.(farm_spacing)(t).(wave))
                fprintf('%s: %s Turbine %2.0f\n', caze, wave, t)
            end
        end
    end
end



%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COMPUTE BAND-LIMITED RMS OF EACH DOF (FFT METHOD)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% KEY CHANGES:
% 1. Using FFT-based method for sharp frequency cutoffs
% 2. Bands are perfectly contiguous: [0, 0.5*fw], [0.5*fw, 1.5*fw], [1.5*fw, Fs/2]
% 3. This ensures sum of squared RMS values = total variance

Fs = 30;

clc;
fprintf('Computing band-limited RMS using FFT method...\n\n');

for s = 1:length(farm_spacings)
    farm_spacing = ['SX', num2str(farm_spacings(s) * 10)];
    caze = strcat("WT60_", farm_spacing, "_AG0");
    fprintf('%s\n', caze)


    % Loop through waves
    for w = 1:length(waves)
        % Get wave and wave frequency
        wave = waves{w};
        split_wave = split(wave, '_');
        wavelength_name = split_wave{1};

        if ~strcmp(wavelength_name, 'LM0')
            fw = forcing_frequencies.(wavelength_name);

            % Define contiguous bands spanning [0, Fs/2]
            % No gaps, no overlaps
            bands.LF   = [0,       0.5*fw];     % DC to half wave frequency
            bands.Wave = [0.5*fw,  1.5*fw];     % Wave frequency band
            bands.HF   = [1.5*fw,  Fs/2];       % High frequency to Nyquist
    

            % Loop through turbines
            for t = 1:length(turbines)
                % Signal
                q = power.(farm_spacing).(wave)(t).Power;

                % Compute low frequency portion (includes DC)
                rLF = bandlimited_rms_fft(q, Fs, bands.LF(1), bands.LF(2), 'constant');
                
                % Compute wave frequency portion
                rWave = bandlimited_rms_fft(q, Fs, bands.Wave(1), bands.Wave(2), 'constant');

                % Compute high frequency portion (up to Nyquist)
                rHF = bandlimited_rms_fft(q, Fs, bands.HF(1), bands.HF(2), 'constant');

                % Save
                bandfilteredDeviations.(farm_spacing).(wave)(t).LF = rLF;
                bandfilteredDeviations.(farm_spacing).(wave)(t).WF = rWave;
                bandfilteredDeviations.(farm_spacing).(wave)(t).HF = rHF;

            end

        end
    end
end

fprintf('\nDone!\n');


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% VERIFY: Sum of squared bands should equal total variance
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc;
fprintf('=== VERIFICATION: Parseval''s Theorem Check ===\n\n');

spacing = 'SX50';
wave = 'LM4_AK09';
turbine = 10;

full = deviations.(spacing)(turbine).(wave);
LF = bandfilteredDeviations.(spacing).(wave)(turbine).LF;
WF = bandfilteredDeviations.(spacing).(wave)(turbine).WF;
HF = bandfilteredDeviations.(spacing).(wave)(turbine).HF;

% Sum of squares of partitioned signals
ss = LF^2 + WF^2 + HF^2;
total_squared = full^2;

fprintf('Case: %s, %s, Turbine %d\n', spacing, wave, turbine);
fprintf('--------------------------------------------\n');
fprintf('Band RMS values:\n');
fprintf('  LF:   %.6f\n', LF);
fprintf('  Wave: %.6f\n', WF);
fprintf('  HF:   %.6f\n', HF);
fprintf('\nFull signal STD: %.6f\n', full);
fprintf('\nSum of squared bands:  %.6f\n', ss);
fprintf('Squared full STD:      %.6f\n', total_squared);
fprintf('\nRatio (should be ~1.0): %.6f\n', ss / total_squared);


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CHECK ALL CASES - Find worst closure errors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc;
fprintf('=== Checking closure errors for all cases ===\n\n');

ratios = [];
worst_cases = struct('ratio', [], 'spacing', {}, 'wave', {}, 'turbine', []);

for s = 1:length(farm_spacings)
    farm_spacing = ['SX', num2str(farm_spacings(s) * 10)];

    for w = 1:length(waves)
        wave = waves{w};
        split_wave = split(wave, '_');
        wavelength_name = split_wave{1};

        if ~strcmp(wavelength_name, 'LM0') && isfield(bandfilteredDeviations.(farm_spacing), wave)

            for t = 1:length(turbines)
                full = deviations.(farm_spacing)(t).(wave);
                LF = bandfilteredDeviations.(farm_spacing).(wave)(t).LF;
                WF = bandfilteredDeviations.(farm_spacing).(wave)(t).WF;
                HF = bandfilteredDeviations.(farm_spacing).(wave)(t).HF;
                ss = LF^2 + WF^2 + HF^2;

                ratio = ss / full^2;
                ratios = [ratios; ratio];

                if isnan(ratio)
                    fprintf('%s, %s, %1.0f\n', farm_spacing, wave, turbine)
                    fprintf('%1.3f, %1.3f, %1.3f, %1.3f\n', full, LF, WF, HF)
                    fprintf('%1.3f, %1.3f\n', ss, ratio)
                end
                
                % Track worst cases
                if abs(ratio - 1) > 0.01  % More than 1% error
                    idx = length(worst_cases) + 1;
                    worst_cases(idx).ratio = ratio;
                    worst_cases(idx).spacing = farm_spacing;
                    worst_cases(idx).wave = wave;
                    worst_cases(idx).turbine = t;
                    worst_cases(idx).DOF = DOF;
                end
            end

        end
    end
end

fprintf('Closure ratio statistics:\n');
fprintf('  Min:    %.6f\n', min(ratios));
fprintf('  Max:    %.6f\n', max(ratios));
fprintf('  Mean:   %.6f\n', mean(ratios, 'omitnan'));
fprintf('  Median: %.6f\n', median(ratios, 'omitnan'));
fprintf('  Std:    %.6f\n', std(ratios, 'omitnan'));

fprintf('\nCases with >1%% error: %d out of %d\n', length(worst_cases), length(ratios));

if ~isempty(worst_cases)
    fprintf('\nWorst cases:\n');
    [~, sortIdx] = sort(abs([worst_cases.ratio] - 1), 'descend');
    for i = 1:min(5, length(sortIdx))
        wc = worst_cases(sortIdx(i));
        fprintf('  %s, %s, T%d, %s: ratio = %.4f\n', ...
            wc.spacing, wc.wave, wc.turbine, wc.DOF, wc.ratio);
    end
end



%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PLOTTING STD OF POWER SIGAL AGAINST HARMONIC RATIO
% FOR A SIGLE TURBINE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Plotting here the variance associated with the wave-frequency normalized
% by the total variance
% Represents the percentage of the energy contained in this band, and varys
% from 0 to 1

% clc;
% wavelengths = [5,4,3,2];
% wave_steepnesses = [0.06, 0.09, 0.12];
% turbine = 11;
% 
% steepness_alpha = [0.3, 0.6, 1];
% sz = 100;
% spacing_shapes = {'o', 'diamond', '^', 'v', 'square'};
% wave_colors = {'#EC4E20', '#FF9505', '#4C4B63', '#ABA8B2'};
% 
% clc; close all
% figure('color','white')
% sgtitle(sprintf('%s %s: Row %1.0f Power STD', farm_arrangement, fancy_name, ceil(turbine / 3)), 'Interpreter', 'latex')
% 
% hold on
% for st = 1:length(wave_steepnesses)
%     wave_steepness = wave_steepnesses(st);
%     steep = compose('%02d', round(100 * wave_steepness));
%     disp(steep{1})
% 
%     for s = 1:length(farm_spacings)
%         farm_spacing = ['SX', num2str(farm_spacings(s) * 10)];
%         caze = strcat("WT60_", farm_spacing, "_AG0");
%         fprintf('%s\n', caze)
% 
%         for w = 1:length(wavelengths)
%             wave = ['LM', num2str(wavelengths(w)), '_AK', steep{1}];
%             harmonic_ratio = farm_spacings(s) / wavelengths(w);
% 
%             % total_variance = deviations.(farm_spacing)(turbine).(wave);
%             % wave_band_variance = bandfilteredDeviations.(farm_spacing).(wave)(turbine).(freq)^2;
%             % % wave_band_variance = bandfilteredDeviations.(farm_spacing).(wave)(turbine).(freq)^2;
%             % % wave_score = wave_band_variance ./ total_variance;
% 
%             scatter(harmonic_ratio, deviations.(farm_spacing)(turbine).(wave), sz, spacing_shapes{s}, 'filled', ...
%                     'MarkerFaceColor', wave_colors{w}, 'MarkerFaceAlpha', steepness_alpha(st), ...
%                     'HandleVisibility', 'off')
%         end
%     end
% end
% 
% 
% 
% %%% Legend
% % Legend for color
% for w = 1:length(wavelengths)
%     plot(nan, nan, 'Color', wave_colors{w}, 'linewidth', 3, ...
%         'Displayname', sprintf('$\\lambda = %1.0fD$', wavelengths(w)), 'HandleVisibility', 'on')
% end
% 
% % White space
% plot(nan, nan, 'color', 'white', 'HandleVisibility', 'on', 'displayname', '')
% plot(nan, nan, 'color', 'white', 'HandleVisibility', 'on', 'displayname', '')
% 
% % Legend for marker shape
% for s = 1:length(farm_spacings)
%     scatter(nan, nan, sz, spacing_shapes{s}, 'black', 'filled', 'HandleVisibility', 'on', ...
%             'DisplayName', sprintf('$S_x = %1.1fD', farm_spacings(s)))
% end
% 
% % White space
% plot(nan, nan, 'color', 'white', 'HandleVisibility', 'on', 'displayname', '')
% plot(nan, nan, 'color', 'white', 'HandleVisibility', 'on', 'displayname', '')
% 
% % Legend for marker alpha
% for st = 1:length(wave_steepnesses)
%     scatter(nan, nan, sz, 'o', 'black', 'filled', 'HandleVisibility', 'on', ...
%             'markerfacealpha', steepness_alpha(st), ...
%             'Displayname', sprintf('$ak = %1.2f$', wave_steepnesses(st)))
% end
% 
% legend('interpreter', 'latex', 'box', 'off', 'location', 'eastoutside');
% hold off
% 
% xlabel('$S_x / \lambda$', 'Interpreter','latex')
% ylabel('$\\sigma$ [mW]', 'interpreter', 'latex')
% xlim([0.5, 2.6])
% ylim([0, 30])





%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PLOTTING STD OF POWER SIGAL AGAINST HARMONIC RATIO
% LOOPED FOR ALL CENTER TURBINES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Plotting here the variance associated with the wave-frequency normalized
% by the total variance
% Represents the percentage of the energy contained in this band, and varys
% from 0 to 1

% clc;
% wavelengths = [5,4,3,2];
% wave_steepnesses = [0.06, 0.09, 0.12];
% centers = [2, 5, 8 ,11];
% 
% steepness_alpha = [0.3, 0.6, 1];
% sz = 100;
% spacing_shapes = {'o', 'diamond', '^', 'v', 'square'};
% 
% 
% % Colors per row
% row_colors.Row1 = slanCM(12, length(wavelengths));
% row_colors.Row2 = slanCM(16, length(wavelengths));
% row_colors.Row3 = slanCM(24, length(wavelengths));
% row_colors.Row4 = slanCM(20, length(wavelengths));
% 
% % Loop
% clc; close all
% figure('color','white')
% sgtitle(sprintf('%s %s: All Rows Power STD', farm_arrangement, fancy_name), 'Interpreter', 'latex')
% 
% hold on
% for c = 1:length(centers)
%     turbine = centers(c);
%     row_tag = sprintf('Row%1.0f', ceil(turbine/3));
%     colors = row_colors.(row_tag);
% 
%     for st = 1:length(wave_steepnesses)
%         wave_steepness = wave_steepnesses(st);
%         steep = compose('%02d', round(100 * wave_steepness));
%         disp(steep{1})
% 
%         for s = 1:length(farm_spacings)
%             farm_spacing = ['SX', num2str(farm_spacings(s) * 10)];
%             caze = strcat("WT60_", farm_spacing, "_AG0");
%             fprintf('%s\n', caze)
% 
%             for w = 1:length(wavelengths)
%                 wave = ['LM', num2str(wavelengths(w)), '_AK', steep{1}];
%                 harmonic_ratio = farm_spacings(s) / wavelengths(w);
% 
%                 scatter(harmonic_ratio, deviations.(farm_spacing)(turbine).(wave), sz, spacing_shapes{s}, 'filled', ...
%                         'MarkerFaceColor', colors(w, :), 'MarkerFaceAlpha', steepness_alpha(st), ...
%                         'HandleVisibility', 'off')
%             end
%         end
%     end
% 
% 
% 
%     %%% Legend
%     % Legend for color
%     for w = 1:length(wavelengths)
%         plot(nan, nan, 'Color', colors(w,:), 'linewidth', 3, ...
%             'Displayname', sprintf('$%s: \\lambda = %1.0fD$', row_tag, wavelengths(w)), 'HandleVisibility', 'on')
%     end
% 
%     % White space
%     plot(nan, nan, 'color', 'white', 'HandleVisibility', 'on', 'displayname', '')
%     plot(nan, nan, 'color', 'white', 'HandleVisibility', 'on', 'displayname', '')
% 
% end
% 
% 
% % Legend for marker shape
% for s = 1:length(farm_spacings)
%     scatter(nan, nan, sz, spacing_shapes{s}, 'black', 'filled', 'HandleVisibility', 'on', ...
%             'DisplayName', sprintf('$S_x = %1.1fD', farm_spacings(s)))
% end
% 
% % White space
% plot(nan, nan, 'color', 'white', 'HandleVisibility', 'on', 'displayname', '')
% plot(nan, nan, 'color', 'white', 'HandleVisibility', 'on', 'displayname', '')
% 
% % Legend for marker alpha
% for st = 1:length(wave_steepnesses)
%     scatter(nan, nan, sz, 'o', 'black', 'filled', 'HandleVisibility', 'on', ...
%             'markerfacealpha', steepness_alpha(st), ...
%             'Displayname', sprintf('$ak = %1.2f$', wave_steepnesses(st)))
% end
% 
% legend('interpreter', 'latex', 'box', 'off', 'location', 'eastoutside');
% hold off
% 
% xlabel('$S_x / \lambda$', 'Interpreter','latex')
% ylabel('$\sigma$ [mW]', 'interpreter', 'latex')
% xlim([0.5, 2.6])
% ylim([0, 30])






%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PLOTTING STD OF POWER SIGAL AGAINST HARMONIC RATIO
% LOOPED FOR ALL CENTER TURBINES
% PLOTTED IN A TILED LAYOUT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Plotting here the variance associated with the wave-frequency normalized
% by the total variance
% Represents the percentage of the energy contained in this band, and varys
% from 0 to 1

clc;
wavelengths = [5,4,3,2];
wave_steepnesses = [0.06, 0.09, 0.12];
centers = [2, 5, 8 ,11];

steepness_alpha = [0.3, 0.6, 1];
sz = 100;
spacing_shapes = {'o', 'diamond', '^', 'v', 'square'};


% Colors per row
row_colors.Row1 = flipud(slanCM(31, 2 * length(wavelengths)));
row_colors.Row2 = flipud(slanCM(48, 2 * length(wavelengths)));
row_colors.Row3 = flipud(slanCM(34, 2 * length(wavelengths)));
row_colors.Row4 = flipud(slanCM(35, 2 * length(wavelengths)));

% Loop
clc; close all
figure('color','white')
t = tiledlayout(1, length(centers));
sgtitle(sprintf('%s %s: All Rows Power STD', farm_arrangement, fancy_name), 'Interpreter', 'latex')


for c = 1:length(centers)
    turbine = centers(c);
    row_tag = sprintf('Row%1.0f', ceil(turbine/3));
    colors = row_colors.(row_tag);

    h(c) = nexttile;
    hold on
    title(row_tag)
    for st = 1:length(wave_steepnesses)
        wave_steepness = wave_steepnesses(st);
        steep = compose('%02d', round(100 * wave_steepness));
        disp(steep{1})
        
        for s = 1:length(farm_spacings)
            farm_spacing = ['SX', num2str(farm_spacings(s) * 10)];
            caze = strcat("WT60_", farm_spacing, "_AG0");
            fprintf('%s\n', caze)
        
            for w = 1:length(wavelengths)
                wave = ['LM', num2str(wavelengths(w)), '_AK', steep{1}];
                harmonic_ratio = farm_spacings(s) / wavelengths(w);
    
                scatter(harmonic_ratio, deviations.(farm_spacing)(turbine).(wave), sz, spacing_shapes{s}, 'filled', ...
                        'MarkerFaceColor', colors(w, :), 'MarkerFaceAlpha', steepness_alpha(st), ...
                        'HandleVisibility', 'off')
            end
        end
    end
    
    
    
    %%% Legend
    % Legend for color
    for w = 1:length(wavelengths)
        plot(nan, nan, 'Color', colors(w,:), 'linewidth', 3, ...
            'Displayname', sprintf('$\\lambda = %1.0fD$', wavelengths(w)), 'HandleVisibility', 'on')
    end

    hold off
    legend('location', 'northeast', 'interpreter', 'latex', 'box', 'off', 'fontsize', 6)
    xlabel('$S_x / \lambda$', 'Interpreter','latex')
    ylabel('$\sigma$ [mW]', 'interpreter', 'latex')
    xlim([0.5, 2.6])
    ylim([0, 30])

    
    % % White space
    % plot(nan, nan, 'color', 'white', 'HandleVisibility', 'on', 'displayname', '')
    % plot(nan, nan, 'color', 'white', 'HandleVisibility', 'on', 'displayname', '')
    
end


% % Legend for marker shape
% for s = 1:length(farm_spacings)
%     scatter(nan, nan, sz, spacing_shapes{s}, 'black', 'filled', 'HandleVisibility', 'on', ...
%             'DisplayName', sprintf('$S_x = %1.1fD', farm_spacings(s)))
% end
% 
% % White space
% plot(nan, nan, 'color', 'white', 'HandleVisibility', 'on', 'displayname', '')
% plot(nan, nan, 'color', 'white', 'HandleVisibility', 'on', 'displayname', '')
% 
% % Legend for marker alpha
% for st = 1:length(wave_steepnesses)
%     scatter(nan, nan, sz, 'o', 'black', 'filled', 'HandleVisibility', 'on', ...
%             'markerfacealpha', steepness_alpha(st), ...
%             'Displayname', sprintf('$ak = %1.2f$', wave_steepnesses(st)))
% end
% 
% legend('interpreter', 'latex', 'box', 'off', 'location', 'eastoutside');
% hold off










%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PLOTTING AGAINST HARMONIC RATIO: ALL STEEPNESSES
% LOOPED OVER ALL THREE COMPONENTS
% FOR A SINGLE ROW
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Plotting here the variance associated with the wave-frequency normalized
% by the total variance
% Represents the percentage of the energy contained in this band, and varys
% from 0 to 1

clc;
wavelengths = [5,4,3,2];
wave_steepnesses = [0.06, 0.09, 0.12];
turbine = 8;
freqs = {'LF', 'WF', 'HF'};

steepness_alpha = [0.3, 0.6, 1];
sz = 100;
spacing_shapes = {'o', 'diamond', '^', 'v', 'square'};
wave_colors = {'#EC4E20', '#FF9505', '#4C4B63', '#ABA8B2'};

row_tag = sprintf('Row%1.0f', ceil(turbine/3));
colors = row_colors.(row_tag);

clc; close all
figure('color','white')
tiledlayout(1, length(freqs))
sgtitle(sprintf('%s %s: Row %1.0f Power, Partitioned RMS', farm_arrangement, fancy_name, ceil(turbine / 3)), 'Interpreter', 'latex')

for f = 1:length(freqs)
    disp(f)
    freq = freqs{f};

    % Titles based on frequency
    if strcmp(freq, 'LF')
        freq_name = 'Low Frequency';
    elseif strcmp(freq, 'WF')
        freq_name = 'Wave Frequency';
    elseif strcmp(freq, 'HF')
        freq_name = 'High Frequency';
    end
  
    % Plotting
    clc; clear tmp
    % title(sprintf('%s: $\\sigma_{%s}$ %s', name, symb, units), 'interpreter', 'latex', 'fontsize', 14)
    h(f) = nexttile;
    title(freq_name)
    hold on 
    for st = 1:length(wave_steepnesses)
        wave_steepness = wave_steepnesses(st);
        steep = compose('%02d', round(100 * wave_steepness));
        disp(steep{1})
        
        for s = 1:length(farm_spacings)
            farm_spacing = ['SX', num2str(farm_spacings(s) * 10)];
            caze = strcat("WT60_", farm_spacing, "_AG0");
            fprintf('%s\n', caze)
        
            for w = 1:length(wavelengths)
                wave = ['LM', num2str(wavelengths(w)), '_AK', steep{1}];
                harmonic_ratio = farm_spacings(s) / wavelengths(w);
    
                total_variance = deviations.(farm_spacing)(turbine).(wave)^2;
                wave_band_variance = bandfilteredDeviations.(farm_spacing).(wave)(turbine).(freq)^2;
                % wave_band_variance = bandfilteredDeviations.(farm_spacing).(wave)(turbine).(freq)^2;
                wave_score = wave_band_variance ./ total_variance;
    
                scatter(harmonic_ratio, wave_score, sz, spacing_shapes{s}, 'filled', ...
                        'MarkerFaceColor', colors(w,:), 'MarkerFaceAlpha', steepness_alpha(st), ...
                        'HandleVisibility', 'off')
            end
        end
    end
    
    
    if f == 3
        %%% Legend
        % Legend for color
        for w = 1:length(wavelengths)
            plot(nan, nan, 'Color', colors(w,:), 'linewidth', 3, ...
                'Displayname', sprintf('$\\lambda = %1.0fD$', wavelengths(w)), 'HandleVisibility', 'on')
        end
        
        % White space
        plot(nan, nan, 'color', 'white', 'HandleVisibility', 'on', 'displayname', '')
        plot(nan, nan, 'color', 'white', 'HandleVisibility', 'on', 'displayname', '')
        
        % Legend for marker shape
        for s = 1:length(farm_spacings)
            scatter(nan, nan, sz, spacing_shapes{s}, 'black', 'filled', 'HandleVisibility', 'on', ...
                    'DisplayName', sprintf('$S_x = %1.1fD', farm_spacings(s)))
        end
        
        % White space
        plot(nan, nan, 'color', 'white', 'HandleVisibility', 'on', 'displayname', '')
        plot(nan, nan, 'color', 'white', 'HandleVisibility', 'on', 'displayname', '')
        
        % Legend for marker alpha
        for st = 1:length(wave_steepnesses)
            scatter(nan, nan, sz, 'o', 'black', 'filled', 'HandleVisibility', 'on', ...
                    'markerfacealpha', steepness_alpha(st), ...
                    'Displayname', sprintf('$ak = %1.2f$', wave_steepnesses(st)))
        end
        
        legend('interpreter', 'latex', 'box', 'off', 'location', 'eastoutside');
    end
    hold off
    
    xlabel('$S_x / \lambda$', 'Interpreter','latex')
    ylabel(sprintf('$\\sigma_{%s}^2 / \\sigma^2$', freq), 'interpreter', 'latex')
    xlim([0.5, 2.6])
    ylim([0, 1])
end

linkaxes(h, 'xy')






%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PLOTTING AGAINST HARMONIC RATIO: ALL STEEPNESSES
% LOOPED OVER ALL THREE COMPONENTS
% LOOPED FOR ALL CENTER TURBINES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Plotting here the variance associated with the wave-frequency normalized
% by the total variance
% Represents the percentage of the energy contained in this band, and varys
% from 0 to 1

clc;
wavelengths = [5,4,3,2];
wave_steepnesses = [0.06, 0.09, 0.12];
turbine = 8;
freqs = {'LF', 'WF', 'HF'};

steepness_alpha = [0.3, 0.6, 1];
sz = 100;
spacing_shapes = {'o', 'diamond', '^', 'v', 'square'};
wave_colors = {'#EC4E20', '#FF9505', '#4C4B63', '#ABA8B2'};


centers = [2,5,8,11];


clc; close all
figure('color','white')
tiledlayout(length(centers), length(freqs))
sgtitle(sprintf('%s %s: Power, Partitioned RMS', farm_arrangement, fancy_name), 'Interpreter', 'latex')


for c = 1:length(centers)
    turbine = centers(c);
    row_tag = sprintf('Row%1.0f', ceil(turbine/3));
    colors = row_colors.(row_tag);



    for f = 1:length(freqs)
        disp(f)
        freq = freqs{f};
    
        % Titles based on frequency
        if strcmp(freq, 'LF')
            freq_name = 'Low Frequency';
        elseif strcmp(freq, 'WF')
            freq_name = 'Wave Frequency';
        elseif strcmp(freq, 'HF')
            freq_name = 'High Frequency';
        end
      
        % Plotting
        clc; clear tmp
        % title(sprintf('%s: $\\sigma_{%s}$ %s', name, symb, units), 'interpreter', 'latex', 'fontsize', 14)
        h(f) = nexttile;
        title(sprintf('Row %1.0f: %s', c, freq_name))
        hold on 
        for st = 1:length(wave_steepnesses)
            wave_steepness = wave_steepnesses(st);
            steep = compose('%02d', round(100 * wave_steepness));
            disp(steep{1})
            
            for s = 1:length(farm_spacings)
                farm_spacing = ['SX', num2str(farm_spacings(s) * 10)];
                caze = strcat("WT60_", farm_spacing, "_AG0");
                fprintf('%s\n', caze)
            
                for w = 1:length(wavelengths)
                    wave = ['LM', num2str(wavelengths(w)), '_AK', steep{1}];
                    harmonic_ratio = farm_spacings(s) / wavelengths(w);
        
                    total_variance = deviations.(farm_spacing)(turbine).(wave)^2;
                    wave_band_variance = bandfilteredDeviations.(farm_spacing).(wave)(turbine).(freq)^2;
                    % wave_band_variance = bandfilteredDeviations.(farm_spacing).(wave)(turbine).(freq)^2;
                    wave_score = wave_band_variance ./ total_variance;
        
                    scatter(harmonic_ratio, wave_score, sz, spacing_shapes{s}, 'filled', ...
                            'MarkerFaceColor', colors(w,:), 'MarkerFaceAlpha', steepness_alpha(st), ...
                            'HandleVisibility', 'off')
                end
            end
        end
        
        
        %%% LEGEND
        % if f == 3
        %     %%% Legend
        %     % Legend for color
        %     for w = 1:length(wavelengths)
        %         plot(nan, nan, 'Color', colors(w,:), 'linewidth', 3, ...
        %             'Displayname', sprintf('$\\lambda = %1.0fD$', wavelengths(w)), 'HandleVisibility', 'on')
        %     end
        % 
        %     % White space
        %     plot(nan, nan, 'color', 'white', 'HandleVisibility', 'on', 'displayname', '')
        %     plot(nan, nan, 'color', 'white', 'HandleVisibility', 'on', 'displayname', '')
        % 
        %     % Legend for marker shape
        %     for s = 1:length(farm_spacings)
        %         scatter(nan, nan, sz, spacing_shapes{s}, 'black', 'filled', 'HandleVisibility', 'on', ...
        %                 'DisplayName', sprintf('$S_x = %1.1fD', farm_spacings(s)))
        %     end
        % 
        %     % White space
        %     plot(nan, nan, 'color', 'white', 'HandleVisibility', 'on', 'displayname', '')
        %     plot(nan, nan, 'color', 'white', 'HandleVisibility', 'on', 'displayname', '')
        % 
        %     % Legend for marker alpha
        %     for st = 1:length(wave_steepnesses)
        %         scatter(nan, nan, sz, 'o', 'black', 'filled', 'HandleVisibility', 'on', ...
        %                 'markerfacealpha', steepness_alpha(st), ...
        %                 'Displayname', sprintf('$ak = %1.2f$', wave_steepnesses(st)))
        %     end
        % 
        %     legend('interpreter', 'latex', 'box', 'off', 'location', 'eastoutside');
        % end
        hold off
        
        xlabel('$S_x / \lambda$', 'Interpreter','latex')
        ylabel(sprintf('$\\sigma_{%s}^2 / \\sigma^2$', freq), 'interpreter', 'latex')
        xlim([0.5, 2.6])
        ylim([0, 1])
    end
end

linkaxes(h, 'xy')














%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FFT-BASED BAND-LIMITED RMS FUNCTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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


