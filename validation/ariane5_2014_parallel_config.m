function cfg = ariane5_2014_parallel_config(mode)
%ARIANE5_2014_PARALLEL_CONFIG Ariane 5 benchmark for generalized boosters.
%
% mode='original' uses Table 6.8 and the centre of the Table 6.9 design
% variables. mode='reported_optimum' uses Table 6.10.
%
% The initial total Delta-V follows the surviving InputMenu heuristic:
% circular-orbit speed + 8% gravity loss + 0.8% drag loss = 1.088*Vorbit.
% Earth-rotation subtraction was commented out in the recovered source.
%
% Interpretation of Table 6.10 booster thrust:
% Table 6.8 reports ~14,000 kN for the booster pair. The +14% search limit
% is ~15,960 kN total, essentially 2*8,000 kN. Therefore the 8,000 kN
% optimum is represented here as PER BOOSTER. This is a documented 2026
% inference, not silently rewritten thesis data.

if nargin<1 || isempty(mode), mode='reported_optimum'; end
ref=ariane5_2014_optimization_reference();
env=earth_constants();

mission.payload_kg=ref.mission.payload_kg;
mission.orbit_altitude_km=ref.mission.orbit_altitude_m/1000;
v_orbit=sqrt(env.mu/(env.Re+ref.mission.orbit_altitude_m));
mission.delta_v_budget_m_s=1.088*v_orbit;
mission.g0=env.g0;
mission.launch_lat_deg=0;

switch lower(char(mode))
    case 'original'
        core_thrust=ref.original.core.thrust_N;
        upper_thrust=ref.original.upper.thrust_N;
        core_d=ref.original.core.diameter_m;
        upper_d=ref.original.upper.diameter_m;
        booster_d=ref.original.boosters.diameter_m;
        booster_each_thrust=ref.original.boosters.thrust_N/2;
        fractions=ref.search.delta_v_fraction_center;
        burn_fraction=ref.search.booster_burn_fraction.center;
        source='Ariane 5 Table 6.8 + Table 6.9 centre values';
    case {'reported_optimum','optimum'}
        core_thrust=ref.optimum.stage_thrust_N(1);
        upper_thrust=ref.optimum.stage_thrust_N(2);
        core_d=ref.optimum.core_diameter_m;
        upper_d=ref.optimum.core_diameter_m;
        booster_d=ref.optimum.booster_diameter_m;
        booster_each_thrust=ref.optimum.booster_thrust_N;
        fractions=ref.optimum.delta_v_fractions;
        burn_fraction=ref.optimum.booster_burn_fraction_of_core;
        source='Ariane 5 reported optimum, Table 6.10';
    otherwise
        error('ariane5_2014_parallel_config:Mode', ...
            'Unknown Ariane configuration mode: %s.',char(mode));
end

core=liquid_stage('EPC/core','LOX/H2',ref.original.core.Isp_s, ...
    core_thrust,ref.original.core.nozzle_area_ratio,core_d);
upper=liquid_stage('ESC-A/upper','LOX/H2',ref.original.upper.Isp_s, ...
    upper_thrust,ref.original.upper.nozzle_area_ratio,upper_d);
booster=solid_stage('EAP booster','HTPB/AP', ...
    ref.original.boosters.Isp_s,booster_each_thrust, ...
    ref.original.boosters.nozzle_area_ratio,booster_d);

cfg.name=['ARIANE5-2014-' upper(mode)];
cfg.mission=mission;
cfg.stages=[core upper];
cfg.boosters.count=2;
cfg.boosters.burn_fraction_of_core=burn_fraction;
cfg.boosters.stage=booster;
cfg.parallel_delta_v_fractions=fractions;
cfg.source=source;
cfg.provenance_note=[ ...
    '2026 generalized parallel-booster configuration derived from the ', ...
    '2014 thesis; booster 8000 kN interpreted per physical booster.'];
end

function s=liquid_stage(name,propellant,Isp,thrust,area_ratio,diameter)
s=base_stage(name,propellant,'liquid',Isp,thrust,area_ratio,diameter);
catalog=thesis_propellant_database();
idx=find(strcmpi({catalog.name},propellant),1);
s.mixture_ratio_OF=catalog(idx).mixture_ratio_OF;
s.rho_oxidizer_kg_m3=catalog(idx).rho_oxidizer_kg_m3;
s.rho_fuel_kg_m3=catalog(idx).rho_fuel_kg_m3;
end

function s=solid_stage(name,propellant,Isp,thrust,area_ratio,diameter)
s=base_stage(name,propellant,'solid',Isp,thrust,area_ratio,diameter);
s.mixture_ratio_OF=NaN;
s.rho_oxidizer_kg_m3=NaN;
s.rho_fuel_kg_m3=NaN;
end

function s=base_stage(name,propellant,type,Isp,thrust,area_ratio,diameter)
s=struct('name',name,'propellant_name',propellant, ...
    'propulsion_type',type,'Isp_s',Isp,'thrust_N',thrust, ...
    'nozzle_area_ratio',area_ratio,'diameter_m',diameter, ...
    'mixture_ratio_OF',NaN,'rho_oxidizer_kg_m3',NaN, ...
    'rho_fuel_kg_m3',NaN,'fairing_area_m2',NaN, ...
    'oxidizer_tank_area_m2',NaN,'fuel_tank_area_m2',NaN);
end
