%% Looking at mean of power
% Zein Sadek


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


% Load powers w/ waves
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

% Load powers w/out waves
for s = 1:length(farm_spacings)
    farm_spacing = ['SX', num2str(farm_spacings(s) * 10)];
    caze = strcat("WT60_", farm_spacing, "_AG0");
    fprintf('%s\n', caze)

    wave = 'LM0_AK00';
    power_file = fullfile(power_path, strcat(turbine_type, "_", farm_arrangement), caze, strcat(wave, ".mat"));
    tmp = load(power_file);
    power.(farm_spacing).(wave) = tmp.output;

end
clear w wave tmp power_file farm_spacing caze


% Remove nans from signals
clc;
for s = 1:length(farm_spacings)
    farm_spacing = ['SX', num2str(farm_spacings(s) * 10)];
    caze = strcat("WT60_", farm_spacing, "_AG0");
    fprintf('%s\n', caze)

    waves = fields(power.(farm_spacing));
    for w = 1:length(waves)
        wave = waves{w};
        disp(wave)

        for t = 1:length(turbines)
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
% PLOTTING MEAN OF POWER SIGAL AGAINST HARMONIC RATIO
% FOR A SIGLE TURBINE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Plotting here the variance associated with the wave-frequency normalized
% by the total variance
% Represents the percentage of the energy contained in this band, and varys
% from 0 to 1

% clc;
% wavelengths = [5,4,3,2];
% wave_steepnesses = [0.06, 0.09, 0.12];
% turbine = 5;
% 
% steepness_alpha = [0.3, 0.6, 1];
% sz = 100;
% spacing_shapes = {'o', 'diamond', '^', 'v', 'square'};
% wave_colors = {'#EC4E20', '#FF9505', '#4C4B63', '#ABA8B2'};
% 
% clc; close all
% figure('color','white')
% sgtitle(sprintf('%s %s: Row %1.0f Power Mean', farm_arrangement, fancy_name, ceil(turbine / 3)), 'Interpreter', 'latex')
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
%             scatter(harmonic_ratio, averages.(farm_spacing)(turbine).(wave), sz, spacing_shapes{s}, 'filled', ...
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
% ylabel('$\overline{P}$ [mW]', 'interpreter', 'latex')
% xlim([0.5, 2.6])
% ylim([0, 180])




%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PLOTTING MEAN OF POWER SIGAL AGAINST HARMONIC RATIO
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
% 
% steepness_alpha = [0.3, 0.6, 1];
% sz = 100;
% spacing_shapes = {'o', 'diamond', '^', 'v', 'square'};
% 
% 
% % Colors per row
% row_colors.Row1 = flipud(slanCM(7, 2 * length(wavelengths)));
% row_colors.Row2 = flipud(slanCM(8, 2 * length(wavelengths)));
% row_colors.Row3 = flipud(slanCM(9, 2 * length(wavelengths)));
% row_colors.Row4 = flipud(slanCM(10, 2 * length(wavelengths)));
% 
% % Loop
% clc; close all
% figure('color','white')
% sgtitle(sprintf('%s %s: All Rows Power Mean', farm_arrangement, fancy_name, ceil(turbine / 3)), 'Interpreter', 'latex')
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
%                 scatter(harmonic_ratio, averages.(farm_spacing)(turbine).(wave), sz, spacing_shapes{s}, 'filled', ...
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
% ylabel('$\overline{P}$ [mW]', 'interpreter', 'latex')
% xlim([0.5, 2.6])
% % ylim([0, 30])




%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PLOTTING MEAN OF POWER SIGAL AGAINST HARMONIC RATIO
% LOOPED FOR ALL CENTER TURBINES
% PLOTTED AS A TILEDLAYOUT
% NON-NORMALIZED
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc;
wavelengths = [5,4,3,2];
wave_steepnesses = [0.06, 0.09, 0.12];
centers = [2, 5, 8 ,11];

steepness_alpha = [0.3, 0.6, 1];
sz = 50;
spacing_shapes = {'o', 'diamond', '^', 'v', 'square'};


% Colors per row
row_colors.Row1 = flipud(slanCM(31, 2 * length(wavelengths)));
row_colors.Row2 = flipud(slanCM(48, 2 * length(wavelengths)));
row_colors.Row3 = flipud(slanCM(34, 2 * length(wavelengths)));
row_colors.Row4 = flipud(slanCM(35, 2 * length(wavelengths)));

% Loop
clear t
clc; close all
figure('color','white')
t = tiledlayout(1, length(centers));

hold on
for c = 1:length(centers)
    turbine = centers(c);
    row_tag = sprintf('Row%1.0f', ceil(turbine/3));
    colors = row_colors.(row_tag);

    h(c) = nexttile;
    title(row_tag)
    hold on
    for st = 1:length(wave_steepnesses)
        wave_steepness = wave_steepnesses(st);
        steep = compose('%02d', round(100 * wave_steepness));
        disp(steep{1})
        

        for w = 1:length(wavelengths)
            wave = ['LM', num2str(wavelengths(w)), '_AK', steep{1}];

            for s = 1:length(farm_spacings)
                farm_spacing = ['SX', num2str(farm_spacings(s) * 10)];
                caze = strcat("WT60_", farm_spacing, "_AG0");
                fprintf('%s\n', caze)
        
                harmonic_ratio = farm_spacings(s) / wavelengths(w);
                data = averages.(farm_spacing)(turbine).(wave);

                tmpX(s) = harmonic_ratio;
                tmpY(s) = data;

                scatter(harmonic_ratio, data, sz, spacing_shapes{s}, 'filled', ...
                        'MarkerFaceColor', colors(w, :), 'MarkerFaceAlpha', steepness_alpha(st), ...
                        'HandleVisibility', 'off')
            end

            % Linear fit
            % p(1) = slope
            % p(2) = interept
            p = polyfit(tmpX, tmpY, 1);
            % plot(tmpX, polyval(p, tmpX), 'linewidth', 1, ...
            %      'linestyle', '--', 'color', colors(w,:), 'HandleVisibility', 'off')

            % Saveclo
            row_index = (ceil(turbine / 3));
            slopes.(wave)(row_index).slope = p(1);

        end
    end


    % Legend for color ~ wavelength
    for w = 1:length(wavelengths)
        plot(nan, nan, 'Color', colors(w,:), 'linewidth', 3, ...
            'Displayname', sprintf('$\\lambda = %1.0fD$', wavelengths(w)), 'HandleVisibility', 'on')
    end

    legend('location', 'best', 'interpreter', 'latex', 'box', 'off', 'fontsize', 6)
    ylabel('$\overline{P}$ [mW]', 'interpreter', 'latex')
    xlabel('$S_x / \lambda$', 'interpreter', 'latex')
    xlim([0.5, 2.6])
    hold off    
end

linkaxes(h, 'xy')
ylim([0, 250])
sgtitle(sprintf('%s %s: All Rows Power Mean', farm_arrangement, fancy_name), 'Interpreter', 'latex')


% % Legend for marker shape
% for s = 1:length(farm_spacings)
%     scatter(nan, nan, sz, spacing_shapes{s}, 'black', 'filled', 'HandleVisibility', 'on', ...
%             'DisplayName', sprintf('$S_x = %1.1fD', farm_spacings(s)))
% end
% % White space
% plot(nan, nan, 'color', 'white', 'HandleVisibility', 'on', 'displayname', '')
% plot(nan, nan, 'color', 'white', 'HandleVisibility', 'on', 'displayname', '')
% % Legend for marker alpha
% for st = 1:length(wave_steepnesses)
%     scatter(nan, nan, sz, 'o', 'black', 'filled', 'HandleVisibility', 'on', ...
%             'markerfacealpha', steepness_alpha(st), ...
%             'Displayname', sprintf('$ak = %1.2f$', wave_steepnesses(st)))
% end
% 
% legend('interpreter', 'latex', 'box', 'off', 'location', 'eastoutside');



%%
% Plot the slopes as a function of lambda per row
% figure('color', 'white')
% tiledlayout(1, length(centers))
% 
% for c = 1:length(centers)
%     colors = row_colors.(sprintf('Row%1.0f',c));
%     h(c) = nexttile;
%     hold on
%     title(sprintf('Row %1.0f', c))
%     for w = 1:length(wavelengths)
%         for st = 1:length(wave_steepnesses)
%             wave_steepness = wave_steepnesses(st);
%             steep = compose('%02d', round(100 * wave_steepness));
%             wave = ['LM', num2str(wavelengths(w)), '_AK', steep{1}];
% 
%             scatter(wavelengths(w), slopes.(wave)(c).slope, sz, colors(w,:), 'filled')
%         end
%     end
%     hold off
%     xlim([1.5, 5.5])
% end
% linkaxes(h, 'xy')





%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PLOTTING MEAN OF POWER SIGAL AGAINST HARMONIC RATIO
% LOOPED FOR ALL CENTER TURBINES
% PLOTTED AS A TILEDLAYOUT
% NORMALIZED BY POWER UNDER NO-WAVES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% clc;
% wavelengths = [5,4,3,2];
% wave_steepnesses = [0.06, 0.09, 0.12];
% centers = [2, 5, 8 ,11];
% 
% steepness_alpha = [0.3, 0.6, 1];
% sz = 50;
% spacing_shapes = {'o', 'diamond', '^', 'v', 'square'};
% 
% 
% % Colors per row
% row_colors.Row1 = flipud(slanCM(31, 2 * length(wavelengths)));
% row_colors.Row2 = flipud(slanCM(48, 2 * length(wavelengths)));
% row_colors.Row3 = flipud(slanCM(34, 2 * length(wavelengths)));
% row_colors.Row4 = flipud(slanCM(35, 2 * length(wavelengths)));
% 
% % Loop
% clear t
% clc; close all
% figure('color','white')
% t = tiledlayout(1, length(centers));
% 
% hold on
% for c = 1:length(centers)
%     turbine = centers(c);
%     row_tag = sprintf('Row%1.0f', ceil(turbine/3));
%     colors = row_colors.(row_tag);
% 
%     h(c) = nexttile;
%     title(row_tag)
%     hold on
%     for st = 1:length(wave_steepnesses)
%         wave_steepness = wave_steepnesses(st);
%         steep = compose('%02d', round(100 * wave_steepness));
%         disp(steep{1})
% 
% 
%         for w = 1:length(wavelengths)
%             wave = ['LM', num2str(wavelengths(w)), '_AK', steep{1}];
% 
%             for s = 1:length(farm_spacings)
%                 farm_spacing = ['SX', num2str(farm_spacings(s) * 10)];
%                 caze = strcat("WT60_", farm_spacing, "_AG0");
%                 fprintf('%s\n', caze)
% 
%                 harmonic_ratio = farm_spacings(s) / wavelengths(w);
%                 mean_power = averages.(farm_spacing)(turbine).(wave);
%                 no_wave_power = averages.(farm_spacing)(turbine).LM0_AK00;
% 
%                 power_percentage = mean_power / no_wave_power;
%                 power_gain_loss = power_percentage - 1;
% 
%                 tmpX(s) = harmonic_ratio;
%                 tmpY(s) = power_percentage;
% 
%                 scatter(harmonic_ratio, power_percentage, sz, spacing_shapes{s}, 'filled', ...
%                         'MarkerFaceColor', colors(w, :), 'MarkerFaceAlpha', steepness_alpha(st), ...
%                         'HandleVisibility', 'off')
%             end
% 
%             % Linear fit
%             % p(1) = slope
%             % p(2) = interept
%             p = polyfit(tmpX, tmpY, 1);
%             % plot(tmpX, polyval(p, tmpX), 'linewidth', 1, ...
%             %      'linestyle', '--', 'color', colors(w,:), 'HandleVisibility', 'off')
% 
%             % Saveclo
%             row_index = (ceil(turbine / 3));
%             slopes.(wave)(row_index).slope = p(1);
% 
%         end
%     end
% 
% 
%     % Legend for color ~ wavelength
%     for w = 1:length(wavelengths)
%         plot(nan, nan, 'Color', colors(w,:), 'linewidth', 3, ...
%             'Displayname', sprintf('$\\lambda = %1.0fD$', wavelengths(w)), 'HandleVisibility', 'on')
%     end
% 
%     legend('location', 'best', 'interpreter', 'latex', 'box', 'off', 'fontsize', 6)
%     ylabel('$\overline{P} / \overline{P}_{No Wave}$', 'interpreter', 'latex')
%     xlabel('$S_x / \lambda$', 'interpreter', 'latex')
%     xlim([0.5, 2.6])
%     hold off    
% end
% 
% linkaxes(h, 'xy')
% ylim([0, 1.2])
% sgtitle(sprintf('%s %s: All Rows Power Mean', farm_arrangement, fancy_name), 'Interpreter', 'latex')


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PLOTTING MEAN OF POWER SIGAL AGAINST HARMONIC RATIO
% LOOPED FOR ALL CENTER TURBINES
% PLOTTED AS A TILEDLAYOUT
% NORMALIZED BY POWER UNDER NO-WAVES
% HIGHLIGHTING THE GAINS/LOSS FROM THE NO-WAVE
% (P / P_{NO WAVE} - 1
% POSITIVE IS A GAIN, NEGATIVE IS A LOSS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc;
wavelengths = [5,4,3,2];
wave_steepnesses = [0.06, 0.09, 0.12];
centers = [2, 5, 8 ,11];

steepness_alpha = [0.3, 0.6, 1];
sz = 50;
spacing_shapes = {'o', 'diamond', '^', 'v', 'square'};


% Colors per row
row_colors.Row1 = flipud(slanCM(31, 2 * length(wavelengths)));
row_colors.Row2 = flipud(slanCM(48, 2 * length(wavelengths)));
row_colors.Row3 = flipud(slanCM(34, 2 * length(wavelengths)));
row_colors.Row4 = flipud(slanCM(35, 2 * length(wavelengths)));

% Loop
clear t
clc; close all
figure('color','white')
t = tiledlayout(1, length(centers));

hold on
for c = 1:length(centers)
    turbine = centers(c);
    row_tag = sprintf('Row%1.0f', ceil(turbine/3));
    colors = row_colors.(row_tag);

    h(c) = nexttile;
    title(row_tag)
    hold on
    for st = 1:length(wave_steepnesses)
        wave_steepness = wave_steepnesses(st);
        steep = compose('%02d', round(100 * wave_steepness));
        disp(steep{1})
        

        for w = 1:length(wavelengths)
            wave = ['LM', num2str(wavelengths(w)), '_AK', steep{1}];

            for s = 1:length(farm_spacings)
                farm_spacing = ['SX', num2str(farm_spacings(s) * 10)];
                caze = strcat("WT60_", farm_spacing, "_AG0");
                fprintf('%s\n', caze)
        
                harmonic_ratio = farm_spacings(s) / wavelengths(w);
                mean_power = averages.(farm_spacing)(turbine).(wave);
                no_wave_power = averages.(farm_spacing)(turbine).LM0_AK00;

                power_percentage = mean_power / no_wave_power;
                power_gain_loss = power_percentage - 1;

                scatter(harmonic_ratio, power_gain_loss, sz, spacing_shapes{s}, 'filled', ...
                        'MarkerFaceColor', colors(w, :), 'MarkerFaceAlpha', steepness_alpha(st), ...
                        'HandleVisibility', 'off')
            end
        end
    end


    % Legend for color ~ wavelength
    for w = 1:length(wavelengths)
        plot(nan, nan, 'Color', colors(w,:), 'linewidth', 3, ...
            'Displayname', sprintf('$\\lambda = %1.0fD$', wavelengths(w)), 'HandleVisibility', 'on')
    end

    yline(0, 'HandleVisibility', 'off', 'linestyle', '--')
    legend('location', 'best', 'interpreter', 'latex', 'box', 'off', 'fontsize', 6)
    ylabel('$\left( \overline{P} / \overline{P}_{No Wave} \right) - 1$', 'interpreter', 'latex')
    xlabel('$S_x / \lambda$', 'interpreter', 'latex')
    xlim([0.5, 2.6])
    ylim([-0.15, 0.15])
    % yticks(-0.5:0.25:0.5)
    hold off    
end

linkaxes(h, 'xy')
sgtitle(sprintf('%s %s: Relative power gains/losses', farm_arrangement, fancy_name), 'Interpreter', 'latex')

