function [result,cfg] = run_parallel_booster_sizing(cfg,opts)
%RUN_PARALLEL_BOOSTER_SIZING User-facing generalized booster sizing.
%
% Interactive:
%   result = run_parallel_booster_sizing();
%
% Programmatic:
%   result = run_parallel_booster_sizing(cfg);
%
% This is a mass/performance sizing path. It does not yet couple the
% parallel-booster phase into the full atmospheric/TPBVP trajectory.

root=fileparts(mfilename('fullpath'));
addpath(root);
addpath(fullfile(root,'configs'));
addpath(fullfile(root,'util'));
addpath(fullfile(root,'validation'));

if nargin<2 || isempty(opts), opts=struct(); end
if nargin<1 || isempty(cfg)
    cfg=parallel_booster_menu();
    if isempty(cfg)
        result=[];
        return;
    end
end
if ~isfield(opts,'show_plots'), opts.show_plots=false; end

solver_opts=opts;
if isfield(solver_opts,'show_plots')
    solver_opts=rmfield(solver_opts,'show_plots');
end
result=size_parallel_booster_launcher(cfg,solver_opts);
result.configuration=cfg;

fprintf('\n=== Parallel-booster preliminary sizing ===\n');
fprintf('Configuration: %s\n',cfg.name);
fprintf('Payload: %.1f kg | Target Delta-V: %.1f m/s\n', ...
    result.payload_kg,result.target_total_delta_v_m_s);
fprintf('Boosters: %d | burn fraction of core: %.1f%%\n', ...
    result.lower.booster_count, ...
    100*result.lower.performance.booster_burn_fraction_of_core);
fprintf('GLOW: %.1f kg | payload ratio: %.5f | lift-off T/W: %.3f\n', ...
    result.GLOW_kg,result.payload_ratio,result.liftoff_TW);
fprintf(['Booster phase Delta-V: target %.1f, actual %.1f, ', ...
    'error %+0.1f m/s\n'], ...
    result.target_booster_phase_delta_v_m_s, ...
    result.actual_booster_phase_delta_v_m_s, ...
    result.booster_phase_delta_v_error_m_s);
fprintf('Core-only Delta-V: %.1f m/s | upper stack Delta-V: %.1f m/s\n', ...
    result.target_core_only_delta_v_m_s,result.upper_delta_v_m_s);
fprintf('Mass-model feasibility: %s\n',logical_text(result.feasible));
if ~result.delta_v_match
    fprintf(['NOTE: booster thrust/burn fraction does not match the allocated ', ...
        'booster-phase Delta-V within the selected tolerance.\n']);
end
fprintf(['NOTE: trajectory losses and orbital insertion are not yet coupled ', ...
    'to this booster sizing path.\n']);

if opts.show_plots
    labels={'Boosters propellant','Boosters structure','Core propellant', ...
        'Core structure','Upper stack'};
    values=[result.lower.booster_total_propellant_kg, ...
        result.lower.booster_total_structural_kg, ...
        result.lower.core.mp_kg,result.lower.core.ms_kg, ...
        result.lower.upper_mass_kg];
    figure('Name','Parallel booster mass breakdown');
    bar(values);
    set(gca,'XTick',1:numel(labels),'XTickLabel',labels);
    xtickangle(25);
    ylabel('Mass [kg]');
    title('Parallel-booster preliminary mass breakdown');
    grid on;
end
end

function s=logical_text(v)
if v, s='yes'; else, s='no'; end
end
