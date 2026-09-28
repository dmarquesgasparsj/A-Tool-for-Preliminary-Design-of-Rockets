function cfg = vega_2014_trajectory_config()
%VEGA_2014_TRAJECTORY_CONFIG Isolated Vega trajectory validation fixture.
%
% Uses Table 6.1 values from the MSc thesis rather than the recovered
% development-script constants. This fixture exists to validate trajectory
% reconstruction independently from the modern mass model.
%
% Reported thesis trajectory landmarks:
%   gravity turn starts:     500 m
%   Kn=5/free-flight start:  97.1 s
%   total flight time:       357.4 s
%   maximum q:               around 9 km altitude
%
% The historical validation used 3 s coast times between stages. The
% atmospheric transition is reported before first-stage burnout, so coast
% handling does not affect the 97.1 s regression target.

ref=vega_2014_reference();

cfg.name='VEGA-2014-THESIS-TRAJECTORY';
cfg.payload_kg=ref.mission.payload_kg;
cfg.target_altitude_m=ref.mission.orbit_altitude_m;
cfg.reference_GLOW_kg=ref.reference_GLOW_kg;
cfg.gravity_turn_altitude_m=500;
cfg.gravity_turn_seed_gamma_rad=deg2rad(89.5);
cfg.knudsen_threshold=5;
cfg.knudsen_characteristic_length_m=ref.stages(end).diameter_m/2;
cfg.coast_time_s=[3 3 3];
cfg.reported=ref.reported;

template=struct('name','','mp_kg',0,'ms_kg',0,'Isp_s',0, ...
    'thrust_N',0,'burn_time_s',0,'diameter_m',0, ...
    'reference_area_m2',0,'drag_model','thesis_mach_polynomial');
stages=repmat(template,1,numel(ref.stages));
for i=1:numel(ref.stages)
    src=ref.stages(i);
    stages(i).name=src.name;
    stages(i).mp_kg=src.mp_kg;
    stages(i).ms_kg=src.ms_kg;
    stages(i).Isp_s=src.Isp_s;
    stages(i).thrust_N=src.thrust_N;
    stages(i).burn_time_s=src.burn_time_s;
    stages(i).diameter_m=src.diameter_m;
    stages(i).reference_area_m2=pi*src.diameter_m^2/4;
end
cfg.stages=stages;
cfg.source=['Gaspar MSc thesis (2014), Chapter 6 Table 6.1 and ', ...
    'reported Vega trajectory validation landmarks.'];
end
