function ref = vega_2014_reference()
%VEGA_2014_REFERENCE Historical Vega validation data from the MSc thesis.
%
% Mission and launcher values reproduce Table 6.1 and the validation
% objective described in Chapter 6. These are reference data, not a claim
% that the current reconstruction already reproduces the 4.8% GLOW result.

ref.mission.payload_kg = 1500;
ref.mission.orbit_altitude_m = 700e3;
ref.reported.GLOW_deviation_percent = 4.8;
ref.reported.last_stage_propellant_unburned_percent = 34;
ref.reported.flight_time_s = 357.4;
ref.reported.gravity_turn_end_time_s = 97.1;

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
