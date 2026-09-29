function ref = proton_2014_reference()
%PROTON_2014_REFERENCE Historical Proton K/DM3 validation data.
%
% Values are transcribed from Chapter 6, Table 6.2 of the 2014 MSc thesis.
% The thesis explicitly states that the DM-3 fourth stage is not fired in
% this validation and is treated as extra payload for another insertion.
%
% Important provenance note: recovered development trajectory files use
% different first/second-stage thrust/burn-time values and an initial mass
% that includes the DM-3 wet mass but not the stated 19,360 kg mission
% payload. Those development values are kept in a separate fixture.

ref.mission.payload_kg=19360;
ref.mission.orbit_altitude_m=200e3;

ref.reported.GLOW_deviation_percent_text=6.2;
ref.reported.table6_6_deviation_percent=6.3;
ref.reported.gravity_turn_end_time_s=153;
ref.reported.flight_time_s=509.2;
ref.reported.trajectory_validation_last_stage_unburned_percent=38;
ref.reported.integrated_final_propellant_reserve_percent=5;
ref.reported.coast_time_s=[3 3];
ref.reported.free_flight_altitude_approx_m=120e3;
ref.reported.table6_6_reference_glow_kg=668577;
ref.reported.table6_6_simulated_glow_kg=626563;

names={'RD-253 x6','RD-0210 x4','RD-0212 + vernier','DM-3 / RD-0214'};
mp=[419410 156113 46562 15200];
ms=[30590 11717 4185 3150];
propellant={'UDMH/NTO','UDMH/NTO','UDMH/NTO','LOX/Kerosene'};
Isp=[316 289 327 353];
thrust_kN=[3492 2328 582 87];
burn_s=[120 327 230 600];
diameter_m=[7.4 4.1 4.1 4.0];
area_ratio=[25 40 55 80];

stages=repmat(struct('name','','mp_kg',0,'ms_kg',0,'propellant','', ...
    'Isp_s',0,'thrust_N',0,'burn_time_s',0,'diameter_m',0, ...
    'nozzle_area_ratio',0),1,4);
for i=1:4
    stages(i).name=names{i};
    stages(i).mp_kg=mp(i);
    stages(i).ms_kg=ms(i);
    stages(i).propellant=propellant{i};
    stages(i).Isp_s=Isp(i);
    stages(i).thrust_N=thrust_kN(i)*1e3;
    stages(i).burn_time_s=burn_s(i);
    stages(i).diameter_m=diameter_m(i);
    stages(i).nozzle_area_ratio=area_ratio(i);
end
ref.stages=stages;
ref.active_stage_indices=1:3;
ref.passive_dm3_wet_mass_kg=mp(4)+ms(4);
ref.semantic_passive_payload_kg=ref.mission.payload_kg+ref.passive_dm3_wet_mass_kg;
ref.table6_2_vehicle_mass_without_payload_kg=sum(mp)+sum(ms);
ref.source='Gaspar MSc thesis (2014), Chapter 6 / Table 6.2 and narrative';
end
