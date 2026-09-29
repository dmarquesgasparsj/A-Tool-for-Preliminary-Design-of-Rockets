function cfg = parallel_booster_menu()
%PARALLEL_BOOSTER_MENU Interactive generalized booster configuration.
%
% Presets:
%   - Ariane 5 reference-centre configuration
%   - Ariane 5 reported optimum from the 2014 thesis
% Or build a custom booster-assisted launcher with any positive booster
% count, one core stage and one or more serial upper stages.

root=fileparts(mfilename('fullpath'));
addpath(fullfile(root,'configs'));
addpath(fullfile(root,'util'));
addpath(fullfile(root,'validation'));

choice=menu('Parallel Booster Launcher', ...
    'Ariane 5 reference configuration', ...
    'Ariane 5 reported optimum (2014 thesis)', ...
    'Build a custom booster-assisted launcher', ...
    'Cancel');
if choice==0 || choice==4
    cfg=[];
    return;
elseif choice==1
    cfg=ariane5_2014_parallel_config('original');
    return;
elseif choice==2
    cfg=ariane5_2014_parallel_config('reported_optimum');
    return;
end

answers=inputdlg( ...
    {'Payload [kg]','Target orbit altitude [km]', ...
     'Initial total Delta-V budget [m/s]', ...
     'Number of serial stages (core + upper stages)', ...
     'Number of identical boosters', ...
     'Booster burn time as % of core burn time'}, ...
    'Parallel booster mission',1, ...
    {'19000','200','8500','2','2','25'});
if isempty(answers), cfg=[]; return; end

mission.payload_kg=str2double(answers{1});
mission.orbit_altitude_km=str2double(answers{2});
mission.delta_v_budget_m_s=str2double(answers{3});
mission.g0=9.80665;
mission.launch_lat_deg=0;
N=str2double(answers{4});
count=str2double(answers{5});
burn_fraction=str2double(answers{6})/100;
validateattributes(N,{'numeric'}, ...
    {'scalar','integer','>=',2,'finite'});
validateattributes(count,{'numeric'}, ...
    {'scalar','integer','positive','finite'});
validateattributes(burn_fraction,{'numeric'}, ...
    {'scalar','>',0,'<',1,'finite'});

% Delta-V segmentation: booster overlap + core-only + one value for each
% upper stage. This gives N+1 segments for N serial stages.
prompts=cell(1,N+1);
defaults=cell(1,N+1);
prompts{1}='Booster-parallel phase [% of total Delta-V]';
prompts{2}='Core-only phase [% of total Delta-V]';
defaults{1}='25';
defaults{2}=num2str(50/max(N-1,1),'%.8g');
remaining=75-str2double(defaults{2});
for i=3:N+1
    prompts{i}=sprintf('Upper stage %d [% of total Delta-V]',i-2);
    defaults{i}=num2str(remaining/(N-1),'%.8g');
end
dv_answer=inputdlg(prompts,'Delta-V allocation',1,defaults);
if isempty(dv_answer), cfg=[]; return; end
fractions=zeros(1,N+1);
for i=1:N+1, fractions(i)=str2double(dv_answer{i})/100; end
if any(~isfinite(fractions)) || any(fractions<=0) || ...
        abs(sum(fractions)-1)>1e-6
    errordlg(sprintf('Delta-V percentages must be positive and sum to 100%% (got %.4f%%).', ...
        100*sum(fractions)),'Invalid Delta-V allocation');
    cfg=[];
    return;
end

stages=repmat(empty_stage(),1,N);
for i=1:N
    if i==1, title_text='Core stage'; else
        title_text=sprintf('Upper stage %d',i-1);
    end
    s=prompt_stage(title_text,false);
    if isempty(s), cfg=[]; return; end
    stages(i)=s;
end

booster=prompt_stage('One physical booster',true);
if isempty(booster), cfg=[]; return; end
if ~strcmpi(booster.propulsion_type,'solid')
    errordlg('The current generalized booster MER requires solid boosters.', ...
        'Unsupported booster propulsion');
    cfg=[];
    return;
end

cfg.name='CUSTOM-PARALLEL-BOOSTER';
cfg.mission=mission;
cfg.stages=stages;
cfg.boosters.count=count;
cfg.boosters.burn_fraction_of_core=burn_fraction;
cfg.boosters.stage=booster;
cfg.parallel_delta_v_fractions=fractions;
cfg.source='User-defined generalized parallel-booster configuration';
cfg.provenance_note=[ ...
    'Modern 2026 configuration. Menus are a front end only; the numerical ', ...
    'model can be called programmatically with the same struct.'];
end

function s=prompt_stage(title_text,solid_only)
catalog=thesis_propellant_database();
if solid_only
    keep=strcmpi({catalog.type_as_written_in_thesis},'Solid');
    choices={catalog(keep).name};
    catalog_index=find(keep);
else
    choices={catalog.name};
    catalog_index=1:numel(catalog);
end
choices=[choices {'Custom propellant'}];
pick=menu([title_text ': propellant'],choices{:});
if pick==0
    s=[];
    return;
end

if pick<=numel(catalog_index)
    p=catalog(catalog_index(pick));
    prop_name=p.name;
    type=lower(p.type_as_written_in_thesis);
    if strcmpi(prop_name,'LOX/RP1'), type='liquid'; end
    Isp=p.Isp_s;
    OF=p.mixture_ratio_OF;
    rho_ox=p.rho_oxidizer_kg_m3;
    rho_fuel=p.rho_fuel_kg_m3;
else
    prop_name='custom';
    if solid_only
        type='solid';
    else
        ti=menu([title_text ': propulsion type'], ...
            'Liquid','Solid','Hybrid','Cancel');
        if ti==0 || ti==4, s=[]; return; end
        types={'liquid','solid','hybrid'};
        type=types{ti};
    end
    Isp=300;
    if strcmp(type,'solid'), OF=NaN; else, OF=2.5; end
    rho_ox=NaN; rho_fuel=NaN;
end

a=inputdlg( ...
    {'Name','Thrust [kN]','Effective Isp [s]', ...
     'Nozzle area ratio','Diameter [m]', ...
     'Oxidizer/Fuel ratio (NaN for solids)'}, ...
    title_text,1, ...
    {title_text,'1000',num2str(Isp),'30','3',num2str(OF)});
if isempty(a), s=[]; return; end

s=empty_stage();
s.name=a{1};
s.propellant_name=prop_name;
s.propulsion_type=type;
s.thrust_N=1000*str2double(a{2});
s.Isp_s=str2double(a{3});
s.nozzle_area_ratio=str2double(a{4});
s.diameter_m=str2double(a{5});
s.mixture_ratio_OF=str2double(a{6});
s.rho_oxidizer_kg_m3=rho_ox;
s.rho_fuel_kg_m3=rho_fuel;
validateattributes(s.thrust_N,{'numeric'}, ...
    {'scalar','positive','finite'});
validateattributes(s.Isp_s,{'numeric'}, ...
    {'scalar','positive','finite'});
validateattributes(s.nozzle_area_ratio,{'numeric'}, ...
    {'scalar','positive','finite'});
validateattributes(s.diameter_m,{'numeric'}, ...
    {'scalar','positive','finite'});
if ~strcmp(type,'solid')
    validateattributes(s.mixture_ratio_OF,{'numeric'}, ...
        {'scalar','positive','finite'});
end
end

function s=empty_stage()
s=struct('name','','propellant_name','', ...
    'propulsion_type','','Isp_s',NaN,'thrust_N',NaN, ...
    'nozzle_area_ratio',NaN,'diameter_m',NaN, ...
    'mixture_ratio_OF',NaN,'rho_oxidizer_kg_m3',NaN, ...
    'rho_fuel_kg_m3',NaN,'fairing_area_m2',NaN, ...
    'oxidizer_tank_area_m2',NaN,'fuel_tank_area_m2',NaN);
end
