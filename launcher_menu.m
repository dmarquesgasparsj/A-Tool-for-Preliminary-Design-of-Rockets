function cfg = launcher_menu()
%LAUNCHER_MENU Interactive front-end; all calculations remain GUI-free.
%
% Mission and stage menus are generated from the propellant catalog. The
% number of stages is chosen by the user: no propellant_2/_3/_4 branches.
% Return [] when the user cancels.

root=fileparts(mfilename('fullpath'));
addpath(fullfile(root,'configs'));
addpath(fullfile(root,'util'));

choice=menu('Preliminary Rocket Design','Build a custom launcher', ...
    'Illustrative two-stage example','Cancel');
if choice==0 || choice==3
    cfg=[];
    return;
end
if choice==2
    mission=struct('payload_kg',1000,'orbit_altitude_km',200, ...
        'delta_v_budget_m_s',8500);
    specs(1)=struct('name','LOX/RP1 first stage', ...
        'propellant_name','LOX/RP1','delta_v_fraction',0.55, ...
        'thrust_N',2.5e6,'nozzle_area_ratio',25, ...
        'Isp_s',295,'epsilon0',0.08);
    specs(2)=struct('name','LOX/H2 upper stage', ...
        'propellant_name','LOX/H2','delta_v_fraction',0.45, ...
        'thrust_N',300e3,'nozzle_area_ratio',80, ...
        'Isp_s',440,'epsilon0',0.10);
    cfg=make_launcher_config(mission,specs);
    return;
end

mission_answer=inputdlg( ...
    {'Payload [kg]','Target circular orbit altitude [km]', ...
     'Initial mission Delta-V budget [m/s]','Number of serial stages'}, ...
    'Mission and launcher',1,{'1000','200','9000','2'});
if isempty(mission_answer), cfg=[]; return; end
mission.payload_kg=str2double(mission_answer{1});
mission.orbit_altitude_km=str2double(mission_answer{2});
mission.delta_v_budget_m_s=str2double(mission_answer{3});
N=str2double(mission_answer{4});
validateattributes(N,{'numeric'},{'scalar','real','finite','integer','positive'});
catalog=thesis_propellant_database();
labels=[{catalog.name}, {'Custom propellant'}];

% A common field schema makes a nonempty MATLAB struct array possible.
empty=struct('name','','propellant_name','', ...
    'delta_v_fraction',0,'thrust_N',0, ...
    'nozzle_area_ratio',0,'Isp_s',0,'epsilon0',0.10, ...
    'propulsion_type','','mixture_ratio_OF',NaN,'diameter_m',NaN);
specs=repmat(empty,1,N);

for i=1:N
    pidx=menu(sprintf('Stage %d of %d: propellant',i,N),labels{:});
    if pidx==0, cfg=[]; return; end
    if pidx<=numel(catalog)
        p=catalog(pidx);
        prop_name=p.name;
        Isp=p.Isp_s;
        OF=p.mixture_ratio_OF;
        type='';
    else
        prop_name='custom';
        Isp=300;
        OF=2.5;
        type_index=menu('Propulsion for this custom stage', ...
            'Liquid','Solid','Hybrid','Cancel');
        if type_index==0 || type_index==4, cfg=[]; return; end
        types={'liquid','solid','hybrid'};
        type=types{type_index};
        if strcmp(type,'solid'), OF=NaN; end
    end
    default_name=sprintf('Stage %d',i);
    if i==N, default_name='Upper stage'; end
    defaults={default_name,num2str(100/N,'%.10g'), ...
        num2str(1000/(2^(i-1)),'%.10g'),num2str(Isp), ...
        '30','0.10',num2str(OF),'3'};
    answer=inputdlg( ...
        {'Stage name','Fraction of total Delta-V [%]', ...
         'Stage thrust [kN]','Effective Isp for this stage [s]', ...
         'Nozzle area ratio','Initial structural factor epsilon', ...
         'Oxidizer/Fuel ratio (NaN for solids)', ...
         'Diameter [m] (future geometry input)'}, ...
        sprintf('Stage %d of %d',i,N),1,defaults);
    if isempty(answer), cfg=[]; return; end
    specs(i).name=answer{1};
    specs(i).propellant_name=prop_name;
    specs(i).delta_v_fraction=str2double(answer{2})/100;
    specs(i).thrust_N=1000*str2double(answer{3});
    specs(i).nozzle_area_ratio=str2double(answer{5});
    specs(i).Isp_s=str2double(answer{4});
    specs(i).epsilon0=str2double(answer{6});
    specs(i).propulsion_type=type;
    specs(i).mixture_ratio_OF=str2double(answer{7});
    specs(i).diameter_m=str2double(answer{8});
end
cfg=make_launcher_config(mission,specs);
end
