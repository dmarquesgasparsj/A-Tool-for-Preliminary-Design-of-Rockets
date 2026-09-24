function [result,cfg] = run_thesis_sizing(mission,stage_specs,opts)
%RUN_THESIS_SIZING General launcher design with optional interactive menus.
%
% Interactive:
%    result = run_thesis_sizing();
%
% Programmatic / batch:
%    result = run_thesis_sizing(mission,stage_specs);
%
% Re-use an existing configuration:
%    result = run_thesis_sizing(cfg);
%
% This calls the modern serial-stage structural-MER solver rather than the
% current simplified run_design() trajectory demo. Orbit altitude is
% recorded, but mission Delta-V is currently an explicit input until the
% trajectory and mass models are coupled.

root=fileparts(mfilename('fullpath'));
addpath(fullfile(root,'configs'));
addpath(fullfile(root,'util'));
if nargin<3 || isempty(opts), opts=struct(); end
if nargin==0 || isempty(mission)
    cfg=launcher_menu();
    if isempty(cfg)
        result=[];
        return;
    end
    if ~isfield(opts,'show_plots'), opts.show_plots=true; end
elseif nargin<2 || isempty(stage_specs)
    cfg=mission;
else
    cfg=make_launcher_config(mission,stage_specs);
end
if ~isfield(opts,'show_plots'), opts.show_plots=false; end

solver_opts=opts;
if isfield(solver_opts,'show_plots')
    solver_opts=rmfield(solver_opts,'show_plots');
end
result=thesis_iterative_mass_model(cfg,solver_opts);
result.configuration=cfg;
fprintf('\n=== Preliminary launcher sizing (modern mass model) ===\n');
fprintf('Payload: %.2f kg | Delta-V budget: %.1f m/s\n', ...
    result.payload_kg,result.total_delta_v_ms);
if isfinite(cfg.mission.orbit_altitude_km)
    fprintf('Target altitude (not yet trajectory-verified): %.1f km\n', ...
        cfg.mission.orbit_altitude_km);
end
fprintf('Number of serial stages: %d\n',numel(result.stages));
fprintf('GLOW estimate: %.2f kg | Payload ratio: %.5f\n', ...
    result.GLOW_kg,result.payload_ratio);
for i=1:numel(result.stages)
    s=result.stages(i);
    fprintf(['Stage %d (%s; %s): DV %.1f m/s, epsilon %.5f, ', ...
        'Mp %.1f kg, Ms %.1f kg, MER error %.3f%%\n'], ...
        i,s.name,s.propulsion_type,s.delta_v_ms,s.epsilon, ...
        s.mp_kg,s.ms_kg,100*s.relative_structural_error);
end
fprintf(['NOTE: Mass-model estimate only. Booster staging and ', ...
    'orbit insertion have not been verified.\n']);

if opts.show_plots
    figure('Name','Preliminary launcher mass breakdown');
    masses=[[result.stages.mp_kg]',[result.stages.ms_kg]'];
    bar(masses,'stacked');
    xlabel('Stage (1 = first stage)');
    ylabel('Mass [kg]');
    legend('Propellant','Structure','Location','best');
    title('Preliminary serial-stage mass breakdown');
    grid on;
end
end
