function ref = vega_2014_reference()
%VEGA_2014_REFERENCE Historical Vega validation data from the MSc thesis.
%
% Mission and launcher values reproduce Table 6.1 and the validation
% objective described in Chapter 6. These are reference data, not a claim
% that the current reconstruction already reproduces the 4.8% GLOW result.

ref.mission.payload_kg = 1500;
ref.mission.orbit_altitude_m = 700e3;
ref.reported.GLOW_deviation_percent = 4.8;
ref.reported.trajectory_validation_last_stage_unburned_percent = 34;
ref.reported.last_stage_propellant_unburned_percent = 34; % legacy field name
ref.reported.flight_time_s = 357.4;
ref.reported.gravity_turn_end_time_s = 97.1;
ref.reported.table6_4_first_stage_m0_kg = 132530;
ref.reported.max_q_altitude_approx_m = 9000;
ref.reported.coast_time_s = [3 3 3];
ref.reported.table6_4_reference_glow_kg = 132530;
ref.reported.table6_4_simulated_glow_kg = 126085;
ref.reported.table6_4_simulated_mp_kg = [83211.3 22918 8566.2 516.6];
ref.reported.table6_4_simulated_ms_kg = [8595 2396.1 906.2 175.6];
% The OCR/text extraction around the final m0 cell is internally ambiguous:
% printed component masses sum to 692.2 kg before payload, while extracted
% text can read 2192.2 kg with payload included. The published 11.8%%
% deviation is consistent with 692.2 vs 785, so both interpretations are
% preserved instead of silently choosing one.
ref.reported.table6_4_simulated_m0_kg = [126085 34248.9 11663.8 NaN];
ref.reported.table6_4_stage4_m0_without_payload_kg = 692.2;
ref.reported.table6_4_stage4_m0_with_payload_kg = 2192.2;
ref.reported.table6_4_deviation_percent = [ ...
    5.83 15.6 4.8; 4.1 29.8 6.8; 15.3 8.1 6.1; 40.7 57.6 11.8];

ref.reported.table6_5_reference_diameter_m = [3 1.9 1.9 2.2];
ref.reported.table6_5_reference_length_m = [11.2 8.39 4.12 2.0];
ref.reported.table6_5_reference_volume_m3 = [79.1 23.8 11.7 7.6];
ref.reported.table6_5_simulated_diameter_m = [3 1.9 1.9 2.2];
ref.reported.table6_5_simulated_length_m = [10.6 8.0 3.7 1.5];
ref.reported.table6_5_simulated_volume_m3 = [74.9 22.7 10.5 6.7];
ref.reported.table6_5_deviation_length_percent = [5.4 4.6 10.2 25];
ref.reported.table6_5_deviation_volume_percent = [5.3 4.6 10.3 11.8];

names = {'P80','Zefiro 23','Zefiro 9','AVUM'};
mp = [88365, 23906, 10115, 367];
ms = [7431, 1845, 833, 418];
propellant = {'HTPB-Al/AP','HTPB/AP','HTPB/AP','Hydrazine/NTO'};
Isp = [280, 289, 294, 317];
thrust_kN = [2092, 959, 230, 2.2];
burn_s = [105, 71, 116, 620];
diameter_m = [3.0, 1.9, 1.9, 2.6];
area_ratio = [16, 25, 60.8, 110];

stages = repmat(struct('name','','mp_kg',0,'ms_kg',0,'propellant','', ...
    'Isp_s',0,'thrust_N',0,'burn_time_s',0,'diameter_m',0, ...
    'nozzle_area_ratio',0), 1, 4);

for i = 1:4
    stages(i).name = names{i};
    stages(i).mp_kg = mp(i);
    stages(i).ms_kg = ms(i);
    stages(i).propellant = propellant{i};
    stages(i).Isp_s = Isp(i);
    stages(i).thrust_N = thrust_kN(i) * 1e3;
    stages(i).burn_time_s = burn_s(i);
    stages(i).diameter_m = diameter_m(i);
    stages(i).nozzle_area_ratio = area_ratio(i);
end

ref.stages = stages;
ref.reference_GLOW_kg = ref.mission.payload_kg + sum(mp) + sum(ms);
ref.source = 'Gaspar MSc thesis (2014), Chapter 6 / Table 6.1';
end
