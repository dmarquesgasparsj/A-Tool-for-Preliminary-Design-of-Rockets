function cfg = make_launcher_config(mission, stage_specs)
%MAKE_LAUNCHER_CONFIG Construct a launcher independently of any GUI.
%
% mission.payload_kg          required, positive
% mission.delta_v_budget_m_s  required, positive (trajectory coupling pending)
% mission.orbit_altitude_km   optional, informational until orbit coupling
%
% stage_specs is an array of user-defined stages, ordered bottom to top.
% Every stage needs:
%   name, delta_v_fraction, propellant_name, thrust_N, nozzle_area_ratio
% A named propellant is taken from thesis_propellant_database(). To use
% an entirely new propellant, set propellant_name = 'custom', Isp_s,
% propulsion_type ('solid'/'liquid'/'hybrid'), and mixture_ratio_OF for
% liquids/hybrids. Catalog Isp values are nominal: supply Isp_s to override
% them, or isp_efficiency to scale them for the chosen stage.
%
% epsilon0 is optional, default 0.10. The modern iterative solver finds
% its own structural factor; epsilon0 is used by thesis_mass_model().
%
% Neither stage count nor propellant selection is tied to a menu.

if ~isstruct(mission) || ~isscalar(mission) || ...
        ~isfield(mission,'payload_kg') || ...
        ~isfield(mission,'delta_v_budget_m_s')
    error('make_launcher_config:InvalidMission', ...
        'Mission requires payload_kg and delta_v_budget_m_s.');
end
validateattributes(mission.payload_kg, {'numeric'}, ...
    {'scalar','real','finite','positive'});
validateattributes(mission.delta_v_budget_m_s, {'numeric'}, ...
    {'scalar','real','finite','positive'});
if ~isfield(mission,'orbit_altitude_km')
    mission.orbit_altitude_km = NaN;
else
    validateattributes(mission.orbit_altitude_km, {'numeric'}, ...
        {'scalar','real','finite','nonnegative'});
end
if ~isfield(mission,'g0'), mission.g0 = 9.80665; end
validateattributes(mission.g0, {'numeric'}, ...
    {'scalar','real','finite','positive'});

if ~isstruct(stage_specs) || isempty(stage_specs)
    error('make_launcher_config:InvalidStages', ...
        'Provide a nonempty array of stage specifications.');
end

catalog = thesis_propellant_database();
N = numel(stage_specs);
empty = struct('name','','propellant_name','', ...
    'propulsion_type','','Isp_s',0,'delta_v_fraction',0, ...
    'epsilon0',0.10,'thrust_N',0,'nozzle_area_ratio',0, ...
    'mixture_ratio_OF',NaN,'rho_oxidizer_kg_m3',NaN, ...
    'rho_fuel_kg_m3',NaN,'diameter_m',NaN, ...
    'fairing_area_m2',NaN,'oxidizer_tank_area_m2',NaN, ...
    'fuel_tank_area_m2',NaN);
stages = repmat(empty,1,N);

for i = 1:N
    s = stage_specs(i);
    required = {'name','propellant_name','delta_v_fraction', ...
        'thrust_N','nozzle_area_ratio'};
    for j = 1:numel(required)
        if ~isfield(s,required{j}) || isempty(s.(required{j}))
            error('make_launcher_config:MissingStageField', ...
                'Stage %d requires %s.',i,required{j});
        end
    end

    name = char(s.name);
    p_name = char(s.propellant_name);
    if isempty(strtrim(name)) || isempty(strtrim(p_name))
        error('make_launcher_config:EmptyName','Stage and fuel names cannot be empty.');
    end

    idx = find(strcmpi({catalog.name},p_name),1);
    if isempty(idx) && ~strcmpi(p_name,'custom')
        error('make_launcher_config:UnknownPropellant', ...
            'Unknown propellant %s. Select custom for new propellants.',p_name);
    end

    if ~isempty(idx)
        p = catalog(idx);
        type = lower(p.type_as_written_in_thesis);
        % The 2014 source calls LOX/RP1 "Hybrid"; both constituents are
        % liquids. Correct its type in the modern design layer only.
        if strcmpi(p.name,'LOX/RP1'), type = 'liquid'; end
        Isp = p.Isp_s;
        OF = p.mixture_ratio_OF;
        rho_ox = p.rho_oxidizer_kg_m3;
        rho_fuel = p.rho_fuel_kg_m3;
    else
        type = '';
        Isp = NaN;
        OF = NaN;
        rho_ox = NaN;
        rho_fuel = NaN;
    end

    if isfield(s,'propulsion_type') && ~isempty(s.propulsion_type)
        type = lower(char(s.propulsion_type));
    end
    if ~ismember(type,{'solid','liquid','hybrid'})
        error('make_launcher_config:InvalidPropulsion', ...
            'Stage %d must specify solid, liquid or hybrid propulsion.',i);
    end
    if isfield(s,'mixture_ratio_OF') && ~isempty(s.mixture_ratio_OF)
        OF = s.mixture_ratio_OF;
    end
    if isfield(s,'rho_oxidizer_kg_m3') && ~isempty(s.rho_oxidizer_kg_m3)
        rho_ox = s.rho_oxidizer_kg_m3;
    end
    if isfield(s,'rho_fuel_kg_m3') && ~isempty(s.rho_fuel_kg_m3)
        rho_fuel = s.rho_fuel_kg_m3;
    end
    if isfield(s,'isp_efficiency') && ~isempty(s.isp_efficiency)
        validateattributes(s.isp_efficiency,{'numeric'}, ...
            {'scalar','real','finite','positive','<=',1});
        Isp = Isp * s.isp_efficiency;
    end
    if isfield(s,'Isp_s') && ~isempty(s.Isp_s)
        Isp = s.Isp_s;
    end
    validateattributes(Isp,{'numeric'}, ...
        {'scalar','real','finite','positive'});
    if ~strcmp(type,'solid')
        validateattributes(OF,{'numeric'}, ...
            {'scalar','real','finite','positive'});
    end
    validateattributes(s.delta_v_fraction,{'numeric'}, ...
        {'scalar','real','finite','positive','<',1});
    validateattributes(s.thrust_N,{'numeric'}, ...
        {'scalar','real','finite','positive'});
    validateattributes(s.nozzle_area_ratio,{'numeric'}, ...
        {'scalar','real','finite','positive'});

    stages(i).name = name;
    stages(i).propellant_name = p_name;
    stages(i).propulsion_type = type;
    stages(i).Isp_s = Isp;
    stages(i).delta_v_fraction = s.delta_v_fraction;
    stages(i).thrust_N = s.thrust_N;
    stages(i).nozzle_area_ratio = s.nozzle_area_ratio;
    stages(i).mixture_ratio_OF = OF;
    stages(i).rho_oxidizer_kg_m3 = rho_ox;
    stages(i).rho_fuel_kg_m3 = rho_fuel;

    if isfield(s,'epsilon0') && ~isempty(s.epsilon0)
        validateattributes(s.epsilon0,{'numeric'}, ...
            {'scalar','real','finite','>',0,'<',1});
        stages(i).epsilon0 = s.epsilon0;
    end
    optional = {'diameter_m','fairing_area_m2', ...
        'oxidizer_tank_area_m2','fuel_tank_area_m2'};
    for j = 1:numel(optional)
        key = optional{j};
        if isfield(s,key) && ~isempty(s.(key))
            validateattributes(s.(key),{'numeric'}, ...
                {'scalar','real','finite','positive'});
            stages(i).(key) = s.(key);
        end
    end
end

fractions = [stages.delta_v_fraction];
if abs(sum(fractions)-1) > 1e-8
    error('make_launcher_config:DeltaVFractions', ...
        'Delta-V fractions must sum to 1 (received %.12g).',sum(fractions));
end

cfg.mission = mission;
cfg.stages = stages;
cfg.source = 'User-defined modern launcher configuration';
cfg.model_status = 'Serial stage sizing; parallel boosters not yet coupled';
end
