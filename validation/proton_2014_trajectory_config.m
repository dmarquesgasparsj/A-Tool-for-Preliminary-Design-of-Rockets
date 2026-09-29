function cfg = proton_2014_trajectory_config(mode)
%PROTON_2014_TRAJECTORY_CONFIG Proton historical trajectory fixture.
%
% mode='thesis_semantic' (default):
%   first three stages burn; DM-3 is passive and the stated 19,360 kg
%   mission payload is also carried.
%
% mode='recovered_development_mass':
%   reproduces the recovered gravity-turn test's initial-mass convention:
%   first three stage masses + DM-3 wet mass, omitting mission payload.
%
% Neither mode silently resolves the discrepancy between thesis prose and
% surviving development source.

if nargin<1 || isempty(mode), mode='thesis_semantic'; end
ref=proton_2014_reference();
active=ref.stages(ref.active_stage_indices);

cfg.name='PROTON-K-2014-THESIS-TRAJECTORY';
cfg.target_altitude_m=ref.mission.orbit_altitude_m;
cfg.gravity_turn_altitude_m=500;
cfg.gravity_turn_seed_gamma_rad=deg2rad(89.5);
cfg.knudsen_threshold=5;
cfg.knudsen_characteristic_length_m=active(end).diameter_m/2;
cfg.coast_time_s=ref.reported.coast_time_s;
cfg.reported=ref.reported;

switch lower(char(mode))
    case 'thesis_semantic'
        cfg.payload_kg=ref.semantic_passive_payload_kg;
        cfg.source_note=['Thesis prose interpretation: 19,360 kg payload ', ...
            'plus inactive DM-3 wet mass carried above stage 3.'];
    case 'recovered_development_mass'
        cfg.payload_kg=ref.passive_dm3_wet_mass_kg;
        cfg.source_note=['Recovered development initial-mass convention: ', ...
            'DM-3 wet mass carried, stated payload omitted.'];
    otherwise
        error('proton_2014_trajectory_config:Mode', ...
            'Unknown mode: %s.',char(mode));
end

template=struct('name','','mp_kg',0,'ms_kg',0,'Isp_s',0, ...
    'thrust_N',0,'burn_time_s',0,'diameter_m',0, ...
    'reference_area_m2',0,'drag_model','thesis_mach_polynomial');
stages=repmat(template,1,numel(active));
for i=1:numel(active)
    s=active(i);
    stages(i).name=s.name;
    stages(i).mp_kg=s.mp_kg;
    stages(i).ms_kg=s.ms_kg;
    stages(i).Isp_s=s.Isp_s;
    stages(i).thrust_N=s.thrust_N;
    stages(i).burn_time_s=s.burn_time_s;
    stages(i).diameter_m=s.diameter_m;
    stages(i).reference_area_m2=pi*s.diameter_m^2/4;
end
cfg.stages=stages;
cfg.source='Gaspar MSc thesis (2014), Chapter 6 Table 6.2';
end
