function cfg = general_launcher_preset(preset_name)
%GENERAL_LAUNCHER_PRESET Editable scenarios for the new generalized model.
%
% 'illustrative_two_stage' : hypothetical liquid launcher (not validated).
% 'vega_prototype'        : inputs from recovered mass_model_n_4.m.
%
% The Vega prototype is a source-data fixture, NOT a claim that the modern
% solver reproduces the thesis Vega result or reaches its target orbit.

if nargin<1 || isempty(preset_name), preset_name='illustrative_two_stage'; end
switch lower(char(preset_name))
    case {'illustrative_two_stage','demo'}
        mission=struct('payload_kg',1000, ...
            'orbit_altitude_km',200,'delta_v_budget_m_s',8500);
        specs(1)=struct('name','LOX/RP1 first stage', ...
            'propellant_name','LOX/RP1','delta_v_fraction',0.55, ...
            'thrust_N',2.5e6,'nozzle_area_ratio',25, ...
            'Isp_s',295,'epsilon0',0.08);
        specs(2)=struct('name','LOX/H2 upper stage', ...
            'propellant_name','LOX/H2','delta_v_fraction',0.45, ...
            'thrust_N',300e3,'nozzle_area_ratio',80, ...
            'Isp_s',440,'epsilon0',0.10);

    case {'vega_prototype','vega'}
        % Values as hard-coded in the recovered mass_model_n_4.m.
        mission=struct('payload_kg',1500, ...
            'orbit_altitude_km',700,'delta_v_budget_m_s',9200);
        template=struct('name','','propellant_name','', ...
            'propulsion_type','','delta_v_fraction',0, ...
            'thrust_N',0,'nozzle_area_ratio',0, ...
            'Isp_s',0,'epsilon0',0.10);
        specs=repmat(template,1,4);
        names={'P80','Zefiro 23','Zefiro 9','AVUM'};
        props={'custom','HTPB/AP','HTPB/AP','Nitrogen Tetroxide/Hydrazine'};
        isps=[280 289 294 317];
        thr=[2092 959 230 2.2]*1000;
        dvs=[.20 .25 .40 .15];
        ars=[20 30 60 100];
        for i=1:4
            specs(i).name=names{i};
            specs(i).propellant_name=props{i};
            specs(i).delta_v_fraction=dvs(i);
            specs(i).thrust_N=thr(i);
            specs(i).nozzle_area_ratio=ars(i);
            specs(i).Isp_s=isps(i);
        end
        specs(1).propulsion_type='solid';
        % Explicitly retain HTPB-Al/AP as an uncatalogued historical
        % propellant; the modern model treats it as a generic solid.
        cfg=make_launcher_config(mission,specs);
        cfg.stages(1).propellant_name='HTPB-Al/AP';
        cfg.source=['Recovered 2014 Vega development inputs; ', ...
            'not a verified reproduction of final launcher performance'];
        return;

    otherwise
        error('general_launcher_preset:UnknownPreset', ...
            'Unknown preset: %s.',char(preset_name));
end

cfg=make_launcher_config(mission,specs);
cfg.source='Illustrative modern launcher configuration; not a flight benchmark';
end
