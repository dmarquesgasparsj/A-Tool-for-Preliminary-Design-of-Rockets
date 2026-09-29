function cfg = proton_2014_trajectory_config(mode)
%PROTON_2014_TRAJECTORY_CONFIG Proton historical trajectory fixtures.
%
% mode='thesis_semantic' (default):
%   literal Chapter 6 Table 6.2 active-stage values, with DM-3 inactive
%   and carried above stage 3 together with the stated 19,360 kg payload.
%   NOTE: the printed 3,492 kN first-stage thrust gives T/W < 1 for this
%   mass, so this literal interpretation cannot lift off.
%
% mode='recovered_development':
%   surviving gravity_turn_teste_Proton.m dynamics: same stage propellant
%   and dry masses, but recovered Isp, thrust, burn times, global 4.1 m
%   aerodynamic diameter, and the recovered initial-mass convention in
%   which DM-3 wet mass is carried but the stated mission payload is absent.
%
% The discrepancy is preserved as provenance rather than silently resolved.

if nargin<1 || isempty(mode), mode='thesis_semantic'; end
ref=proton_2014_reference();
active=ref.stages(ref.active_stage_indices);

cfg.name='PROTON-K-2014-THESIS-TRAJECTORY';
cfg.target_altitude_m=ref.mission.orbit_altitude_m;
cfg.gravity_turn_altitude_m=500;
cfg.gravity_turn_seed_gamma_rad=deg2rad(89.5);
cfg.knudsen_threshold=5;
cfg.coast_time_s=ref.reported.coast_time_s;
cfg.reported=ref.reported;

switch lower(char(mode))
    case 'thesis_semantic'
        cfg.payload_kg=ref.semantic_passive_payload_kg;
        cfg.source_note=['Literal thesis Table 6.2/prose interpretation. ', ...
            'Its printed first-stage thrust does not satisfy lift-off T/W.'];
        cfg.source='Gaspar MSc thesis (2014), Chapter 6 Table 6.2';

    case {'recovered_development','recovered_development_mass'}
        dev=proton_2014_recovered_gravity_test();
        cfg.payload_kg=ref.passive_dm3_wet_mass_kg;
        cfg.coast_time_s=dev.coast_time_s(1:2);
        for i=1:3
            active(i).Isp_s=dev.Isp_s(i);
            active(i).thrust_N=dev.thrust_N(i);
            active(i).burn_time_s=dev.burn_time_s(i);
            active(i).diameter_m=dev.aerodynamic_diameter_m;
        end
        cfg.gravity_turn_altitude_m=dev.gravity_turn_altitude_m;
        cfg.gravity_turn_seed_gamma_rad=dev.gamma0_rad;
        cfg.source_note=['Recovered development dynamics and initial-mass ', ...
            'convention; stated 19,360 kg mission payload omitted.'];
        cfg.source=dev.source;

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
cfg.knudsen_characteristic_length_m=stages(end).diameter_m/2;
cfg.initial_mass_kg=cfg.payload_kg+sum([stages.mp_kg])+sum([stages.ms_kg]);
cfg.liftoff_TW=stages(1).thrust_N/(cfg.initial_mass_kg*9.81);
end
