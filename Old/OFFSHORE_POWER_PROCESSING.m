clc;
clear;
close all;
addpath('C:\Users\oferc\OneDrive\Documents\MATLAB\Functions');

path        = 'C:/Users/oferc/OneDrive/Documents/1_Projects/14_Downwind_Whisker_Turbines/Power_Data/Power_Results/';
save_path   = 'C:/Users/oferc/OneDrive/Documents/1_Projects/14_Downwind_Whisker_Turbines/Power_Data/';
save_name   = 'POWER_RESULTS_ALL';
sub_path    = dir(path);
sub_path    = {sub_path([sub_path.isdir]).name};
sub_path    = sub_path(3:end);

km          = 11.4;         % Motor Torque Constant [mNm/A]
kt          = 0.00073;      % Friction Torque       [mNm/s]

res_length  = 1000;         % resistor data length  [%]
enc_stp     = 400;          % enc steps             [num]
tol         = 1;            % outlier tolerance     [%]
U_inf       = 3;            % velocity              [m/s]
lookup      = [0.33 0.5 0.66 0.78 1 2 3.6 4.7 6.2 8.2 9.1 11 13 16 18 20.2 22 24 27 30 33 36 39 47 56 66];

fprintf("<DW1_POWER_Calculation_Rev002> in Progress...\n")

for i = 1:length(sub_path)
    % Print Progress.
    progressbarText(i/length(sub_path));

    % Parse Data & Save
    data_name   = string(sub_path(i));
    output      = downwindDataParse(path, string(sub_path(i)), res_length, enc_stp, tol, U_inf, lookup);

    % Calculate Performance Curve from Motor Torque & Motor Specs
    TSR         = output.Ts_mean/output.U_inf;                % Tip Speed Ratio       [%]
    Tm          = km * output.A_mean + kt.*output.omega_mean.';   % Torque from Current   [mNm]
    Pt          = Tm./1000.*output.omega_mean.';           % Power from Torque     [Nm]
    Cp_trq      = Pt/output.Pu;                        % Power Coefficient     [%]

    power(i).name               = save_name;
    power(i).TSR                = TSR;
    power(i).Cp                 = Cp_trq;
    power(i).U_inf              = output.U_inf;
    power(i).Pu                 = output.Pu;
    power(i).V                  = output.V;
    power(i).V_mean             = output.V_mean;
    power(i).A                  = output.A;
    power(i).A_mean             = output.A_mean;
    power(i).Pv                 = output.Pv;
    power(i).Pv_mean            = output.Pv_mean;
    power(i).omega              = output.omega;
    power(i).omega_mean         = output.omega_mean;
    power(i).Ts_mean            = output.Ts_mean;
    power(i).direction          = data_name{1}(1:2);
    power(i).lambda             = data_name{1}(6:7);
    power(i).coning             = data_name{1}(11:12);

end

% Save All Data to Single .mat File
fprintf("\nSAVING DATA...")
save(strcat(save_path, save_name, '.mat'), 'power')
clc;
fprintf("<DW1_POWER_Calculation_Rev002> \nCOMPLETE!\n")
