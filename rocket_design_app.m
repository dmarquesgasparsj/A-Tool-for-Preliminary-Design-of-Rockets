function app = rocket_design_app()
%ROCKET_DESIGN_APP Unified GUI for non-programmer launcher studies.
%
% This programmatic MATLAB UI completes the GUI item proposed in the 2014
% Future Work without making the numerical model depend on the interface.
% Scientific workflows remain callable directly through run_* functions.
%
% The app edits a generalized serial launcher, runs mass-only or integrated
% mass/trajectory design, and links to booster and mission-extension tools.
% The latest result is also exported as rocket_design_result in the base
% workspace for inspection and reproducibility.

root=fileparts(mfilename('fullpath'));
addpath(root);
addpath(fullfile(root,'configs'));
addpath(fullfile(root,'util'));

catalog=thesis_propellant_database();
prop_names=[{catalog.name},{'custom'}];

fig=uifigure('Name','A Tool for Preliminary Design of Rockets', ...
    'Position',[100 100 1180 720]);
g=uigridlayout(fig,[8 4]);
g.RowHeight={32,32,32,32,'1x',38,38,28};
g.ColumnWidth={180,'1x',180,'1x'};

titleLabel=uilabel(g,'Text','Preliminary Rocket Design — 2026 generalized tool', ...
    'FontWeight','bold','FontSize',16);
titleLabel.Layout.Row=1; titleLabel.Layout.Column=[1 4];

uilabel(g,'Text','Payload [kg]').Layout.Row=2;
payload=uieditfield(g,'numeric','Value',1000,'Limits',[eps Inf]);
payload.Layout.Row=2; payload.Layout.Column=2;
uilabel(g,'Text','Orbit altitude [km]').Layout.Row=2; 
g.Children(1).Layout.Column=3;
orbit=uieditfield(g,'numeric','Value',200,'Limits',[0 Inf]);
orbit.Layout.Row=2; orbit.Layout.Column=4;

lab=uilabel(g,'Text','Initial Delta-V budget [m/s]');
lab.Layout.Row=3; lab.Layout.Column=1;
dv=uieditfield(g,'numeric','Value',9000,'Limits',[eps Inf]);
dv.Layout.Row=3; dv.Layout.Column=2;
lab=uilabel(g,'Text','Serial stages');
lab.Layout.Row=3; lab.Layout.Column=3;
nstage=uispinner(g,'Limits',[1 12],'Step',1,'Value',2);
nstage.Layout.Row=3; nstage.Layout.Column=4;

hint=uilabel(g,'Text',[ ...
    'Stage 1 is the first/core serial stage. Delta-V fractions must total 100%. ', ...
    'Use custom + Type/O-F for unlisted propellants.']);
hint.Layout.Row=4; hint.Layout.Column=[1 4];

tbl=uitable(g);
tbl.Layout.Row=5; tbl.Layout.Column=[1 4];
tbl.ColumnName={'Name','Propellant','Type','Isp [s]','DV [%]', ...
    'Thrust [kN]','Area ratio','Diameter [m]','O/F'};
tbl.ColumnEditable=true(1,9);
tbl.ColumnFormat={'char',prop_names,{'liquid','solid','hybrid'}, ...
    'numeric','numeric','numeric','numeric','numeric','numeric'};
tbl.Data=default_rows(2);

runMass=uibutton(g,'Text','Run mass sizing', ...
    'ButtonPushedFcn',@(~,~)run_serial(false));
runMass.Layout.Row=6; runMass.Layout.Column=1;
runIntegrated=uibutton(g,'Text','Run integrated design', ...
    'ButtonPushedFcn',@(~,~)run_serial(true));
runIntegrated.Layout.Row=6; runIntegrated.Layout.Column=2;
boost=uibutton(g,'Text','Boosters / Ariane 5', ...
    'ButtonPushedFcn',@(~,~)run_parallel_booster_sizing());
boost.Layout.Row=6; boost.Layout.Column=3;
missionBtn=uibutton(g,'Text','Mission extensions', ...
    'ButtonPushedFcn',@(~,~)run_mission_extensions());
missionBtn.Layout.Row=6; missionBtn.Layout.Column=4;

preset=uibutton(g,'Text','Load illustrative two-stage preset', ...
    'ButtonPushedFcn',@(~,~)load_demo());
preset.Layout.Row=7; preset.Layout.Column=[1 2];
legacy=uibutton(g,'Text','Load Vega development inputs', ...
    'ButtonPushedFcn',@(~,~)load_vega());
legacy.Layout.Row=7; legacy.Layout.Column=[3 4];

status=uilabel(g,'Text','Ready.','FontAngle','italic');
status.Layout.Row=8; status.Layout.Column=[1 4];

nstage.ValueChangedFcn=@(~,~)resize_rows();

app.figure=fig;
app.table=tbl;
app.payload=payload;
app.orbit=orbit;
app.delta_v=dv;
app.stage_count=nstage;
app.status=status;

    function rows=default_rows(N)
        rows=cell(N,9);
        for ii=1:N
            rows(ii,:)={sprintf('Stage %d',ii),'LOX/RP1','liquid', ...
                300,100/N,1000/2^(ii-1),25,2.5,2.27};
        end
        if N>=1
            rows(end,:)={sprintf('Stage %d',N),'LOX/H2','liquid', ...
                440,100/N,250,80,2.5,3.8};
        end
    end

    function resize_rows()
        N=round(nstage.Value);
        old=tbl.Data;
        rows=default_rows(N);
        keep=min(size(old,1),N);
        if keep>0, rows(1:keep,:)=old(1:keep,:); end
        total=sum(cell2mat(rows(:,5)));
        if total<=0
            for ii=1:N, rows{ii,5}=100/N; end
        end
        tbl.Data=rows;
        status.Text=sprintf('%d-stage serial configuration.',N);
    end

    function [mission,specs]=build_inputs()
        rows=tbl.Data;
        N=size(rows,1);
        mission=struct('payload_kg',payload.Value, ...
            'orbit_altitude_km',orbit.Value, ...
            'delta_v_budget_m_s',dv.Value);
        specs=repmat(struct('name','','propellant_name','', ...
            'propulsion_type','','Isp_s',0,'delta_v_fraction',0, ...
            'thrust_N',0,'nozzle_area_ratio',0,'diameter_m',0, ...
            'mixture_ratio_OF',NaN),1,N);
        for ii=1:N
            specs(ii).name=char(rows{ii,1});
            specs(ii).propellant_name=char(rows{ii,2});
            if strcmpi(specs(ii).propellant_name,'custom')
                specs(ii).propulsion_type=char(rows{ii,3});
            end
            specs(ii).Isp_s=rows{ii,4};
            specs(ii).delta_v_fraction=rows{ii,5}/100;
            specs(ii).thrust_N=1000*rows{ii,6};
            specs(ii).nozzle_area_ratio=rows{ii,7};
            specs(ii).diameter_m=rows{ii,8};
            if isfinite(rows{ii,9})
                specs(ii).mixture_ratio_OF=rows{ii,9};
            end
        end
    end

    function run_serial(integrated)
        try
            [m,s]=build_inputs();
            status.Text='Running...';
            drawnow;
            if integrated
                res=run_integrated_design(m,s,struct('show_plots',true));
            else
                res=run_thesis_sizing(m,s,struct('show_plots',true));
            end
            assignin('base','rocket_design_result',res);
            status.Text=sprintf('Completed. GLOW %.1f kg. Result -> rocket_design_result', ...
                res.mass_or_glow_placeholder);
        catch ME
            % Resolve GLOW without requiring both result APIs to match.
            if exist('res','var')
                if isfield(res,'mass') && isfield(res.mass,'GLOW_kg')
                    glow=res.mass.GLOW_kg;
                elseif isfield(res,'GLOW_kg')
                    glow=res.GLOW_kg;
                else
                    glow=NaN;
                end
                if isfinite(glow)
                    status.Text=sprintf('Completed. GLOW %.1f kg. Result -> rocket_design_result',glow);
                    return;
                end
            end
            status.Text=['Error: ' ME.message];
            uialert(fig,ME.message,'Design error');
        end
    end

    function load_demo()
        cfg=general_launcher_preset('illustrative_two_stage');
        load_cfg(cfg);
    end

    function load_vega()
        cfg=general_launcher_preset('vega_prototype');
        load_cfg(cfg);
    end

    function load_cfg(cfg)
        payload.Value=cfg.mission.payload_kg;
        orbit.Value=cfg.mission.orbit_altitude_km;
        dv.Value=cfg.mission.delta_v_budget_m_s;
        N=numel(cfg.stages);
        nstage.Value=N;
        rows=cell(N,9);
        for ii=1:N
            s=cfg.stages(ii);
            OF=s.mixture_ratio_OF;
            if ~isfinite(OF), OF=NaN; end
            d=s.diameter_m; if ~isfinite(d), d=2; end
            rows(ii,:)={s.name,s.propellant_name,s.propulsion_type, ...
                s.Isp_s,100*s.delta_v_fraction,s.thrust_N/1000, ...
                s.nozzle_area_ratio,d,OF};
        end
        tbl.Data=rows;
        status.Text=['Loaded: ' cfg.source];
    end
end
