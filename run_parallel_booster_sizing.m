function [result,cfg] = run_parallel_booster_sizing(cfg,opts)
%RUN_PARALLEL_BOOSTER_SIZING User-facing generalized booster sizing.
%
% Interactive:
%   result = run_parallel_booster_sizing();
%
% Programmatic:
%   result = run_parallel_booster_sizing(cfg);
%
% The sizing API is always available. Interactive users can additionally
% run the experimental booster atmosphere -> Kn=5 -> TPBVP trajectory and
% Future-Work constraint diagnostics from the same menu path.

root=fileparts(mfilename('fullpath'));
addpath(root);
addpath(fullfile(root,'configs'));
addpath(fullfile(root,'util'));
addpath(fullfile(root,'validation'));

if nargin<2 || isempty(opts), opts=struct(); end
interactive=(nargin<1 || isempty(cfg));
if interactive
    cfg=parallel_booster_menu();
    if isempty(cfg)
        result=[];
        return;
    end
end
if ~isfield(opts,'show_plots'), opts.show_plots=false; end
if ~isfield(opts,'run_trajectory')
    if interactive
        tchoice=menu('Parallel booster analysis', ...
            'Sizing only', ...
            'Sizing + trajectory and constraint diagnostics');
        opts.run_trajectory=(tchoice==2);
    else
        opts.run_trajectory=false;
    end
end
if ~isfield(opts,'trajectory_opts'), opts.trajectory_opts=struct(); end

solver_opts=opts;
strip={'show_plots','run_trajectory','trajectory_opts'};
for kk=1:numel(strip)
    if isfield(solver_opts,strip{kk})
        solver_opts=rmfield(solver_opts,strip{kk});
    end
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
if opts.run_trajectory
    tr=simulate_parallel_booster_trajectory(cfg,result,opts.trajectory_opts);
    result.trajectory=tr;
    fprintf('\n--- Booster trajectory / constraints ---\n');
    fprintf('Kn=5 transition detected: %s\n',logical_text(tr.transition_detected));
    fprintf('Max-q: %.2f kPa | peak heat flux: %.2f kW/m^2\n', ...
        tr.constraints.max_q_Pa/1000, ...
        tr.constraints.max_heat_flux_W_m2/1000);
    fprintf('Max axial structural acceleration: %.3f g\n', ...
        tr.constraints.max_axial_accel_g);
    if isfinite(tr.constraints.max_bending_moment_Nm)
        fprintf('Max preliminary bending moment: %.3f MN m\n', ...
            tr.constraints.max_bending_moment_Nm/1e6);
    else
        fprintf(['Bending moment: not evaluated (provide angle of attack ', ...
            'and bending lever arm).\n']);
    end
    fprintf('Configured trajectory constraints pass: %s\n', ...
        logical_text(tr.constraints_pass));
    fprintf('Orbit/TPBVP status: %s\n',tr.status);
else
    fprintf(['NOTE: choose the trajectory option to propagate the booster ', ...
        'configuration through gravity turn, Kn=5 and TPBVP.\n']);
end

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
    if opts.run_trajectory && isfield(result,'trajectory')
        figure('Name','Parallel booster atmospheric trajectory');
        plot(result.trajectory.atmospheric.t, ...
            result.trajectory.atmospheric.h/1000);
        xlabel('Time [s]');
        ylabel('Altitude [km]');
        title('Parallel-booster atmospheric ascent');
        grid on;
    end
end
end

function s=logical_text(v)
if v, s='yes'; else, s='no'; end
end
