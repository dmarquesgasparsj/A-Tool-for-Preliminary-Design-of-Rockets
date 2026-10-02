function ref = ariane5_2014_optimization_reference()
%ARIANE5_2014_OPTIMIZATION_REFERENCE Chapter 6 optimization benchmark.
%
% This fixture records the values reported in Tables 6.8-6.12. It is a
% benchmark target, not yet a claim that the modern model reproduces the
% booster optimization.

ref.mission.payload_kg=19300;
ref.mission.orbit_altitude_m=200e3;

ref.original.boosters.mp_kg=480000;
ref.original.boosters.ms_kg=80000;
ref.original.boosters.propellant='HTPB-Al/AP';
ref.original.boosters.Isp_s=274.5;
ref.original.boosters.thrust_N=14000e3;
ref.original.boosters.burn_time_s=129;
ref.original.boosters.diameter_m=3.0;
ref.original.boosters.nozzle_area_ratio=30;

ref.original.core.mp_kg=170000;
ref.original.core.ms_kg=14700;
ref.original.core.propellant='LOX/H2';
ref.original.core.Isp_s=432;
ref.original.core.thrust_N=1390e3;
ref.original.core.burn_time_s=537;
ref.original.core.diameter_m=5.4;
ref.original.core.nozzle_area_ratio=57;

ref.original.upper.mp_kg=14900;
ref.original.upper.ms_kg=4540;
ref.original.upper.propellant='LOX/H2';
ref.original.upper.Isp_s=446;
ref.original.upper.thrust_N=67e3;
ref.original.upper.burn_time_s=972;
ref.original.upper.diameter_m=5.4;
ref.original.upper.nozzle_area_ratio=88;

% Table 6.9: preserve ranges exactly as reported. The thesis states that
% 23 Delta-V-division points were used but does not specify enough detail
% to reconstruct their exact sequence, so no sequence is invented here.
ref.search.core_diameter=struct('center_m',5.4,'plusminus_fraction',0.36,'points',11);
ref.search.stage_thrust=struct('plusminus_fraction',0.25,'points',5);
ref.search.delta_v_fraction_center=[0.20 0.50 0.30];
ref.search.delta_v_plusminus_absolute=0.05;
ref.search.delta_v_reported_points=23;
ref.search.booster_count_values=[0 2];
ref.search.booster_thrust=struct('plusminus_fraction',0.14,'points',3);
ref.search.booster_diameter=struct('center_m',3.05,'plusminus_fraction',0.25,'points',5);
ref.search.booster_burn_fraction=struct('center',0.30,'plusminus_absolute',0.10,'points',5);
ref.search.reported_total_simulations=170;

% Table 6.10 optimal configuration.
ref.optimum.core_diameter_m=3.9;
ref.optimum.stage_thrust_N=[1700 58.5]*1e3;
ref.optimum.delta_v_fractions=[0.25 0.49 0.26];
ref.optimum.number_of_boosters=2;
ref.optimum.booster_thrust_N=8000e3;
ref.optimum.booster_diameter_m=2.625;
ref.optimum.booster_burn_fraction_of_core=0.25;

% Table 6.11 simulated optimum masses. Booster values are preserved as the
% aggregate "Booster" column printed in the thesis.
ref.optimum.masses.booster_mp_kg=458189.4;
ref.optimum.masses.booster_ms_kg=77216;
ref.optimum.masses.core_mp_kg=123735;
ref.optimum.masses.core_ms_kg=14406;
ref.optimum.masses.upper_mp_kg=2217;
ref.optimum.masses.upper_ms_kg=4313;
ref.optimum.reported_vehicle_mass_kg=680076.5;
ref.original.reported_vehicle_mass_kg=764140;
ref.optimum.reported_mass_reduction_kg= ...
    ref.original.reported_vehicle_mass_kg-ref.optimum.reported_vehicle_mass_kg;
ref.optimum.reported_GLOW_reduction_percent=11;

ref.optimum.flight_time_s=462.8;
ref.optimum.gravity_turn_end_time_s=111.5;
ref.optimum.gravity_turn_end_altitude_m=120.4e3;
ref.optimum.gravity_turn_end_gamma_deg=58.9;
ref.optimum.table6_11_deviation_percent=[ ...
    4.5 3.5 11; 27.2 2 29.1; 85.1 5 66.4];

ref.original.dimensions.diameter_m=[3.05 5.4 5.4];
ref.original.dimensions.length_m=[31.6 30.5 4.71];
ref.original.dimensions.volume_m3=[230.75 698.16 107.81];
ref.optimum.dimensions.diameter_m=[2.62 3.9 3.9];
ref.optimum.dimensions.length_m=[36.99 54.44 7.43];
ref.optimum.dimensions.volume_m3=[199.37 638.16 88.73];
ref.optimum.table6_12_deviation_percent=[ ...
    14.1 17.1 13.6; 27.8 44 8.6; 27.8 36.6 17.7];
ref.optimum.coast_time_s=3;

ref.provenance_notes={ ...
    'Table 6.9 reports booster diameter centre 3.05 m, while Table 6.8 prints 3.0 m and the final 2.625 m is consistent with a 3.0 m five-point +/-25% grid.', ...
    'Table 6.8 booster thrust 14,000 kN appears to represent the booster pair, while Table 6.10 reports booster thrust 8,000 kN; per-booster/aggregate interpretation is not silently resolved.', ...
    'The exact 23-point Delta-V sequence is not specified in the thesis text.'};
ref.source='Gaspar MSc thesis (2014), Chapter 6, Tables 6.8-6.12';
end
