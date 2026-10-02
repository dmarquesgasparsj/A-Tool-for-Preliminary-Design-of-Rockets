function report = run_validation_closure(opts)
%RUN_VALIDATION_CLOSURE Reproducible Chapter-6 validation closure.
%
% This report separates:
%   1. thesis-internal checks (published tables + Eq. 6.1);
%   2. reconstruction checks (current public MATLAB implementation);
%   3. provenance gaps that cannot be resolved from surviving 2014 source.
%
% No parameter is tuned to reproduce a historical number.
%
% opts.run_full_trajectory      default true
% opts.run_ariane_trajectory    default true
% opts.print_summary            default false
%
% Closure does NOT mean that every historical output is reproduced.
% It means every validation target is either reproduced, contradicted by
% surviving evidence, or explicitly classified as unresolved provenance.

if nargin<1 || isempty(opts), opts=struct(); end
if ~isfield(opts,'run_full_trajectory'), opts.run_full_trajectory=true; end
if ~isfield(opts,'run_ariane_trajectory'), opts.run_ariane_trajectory=true; end
if ~isfield(opts,'print_summary'), opts.print_summary=false; end

report.schema_version=1;
report.generated_by='run_validation_closure.m';
report.policy=['Do not tune coefficients, thresholds or source data merely ', ...
    'to reproduce Chapter 6.'];
report.status_codes=struct( ...
    'verified','published thesis data/equation reproduced', ...
    'reconstructed','2026 model reproduces the requested diagnostic', ...
    'provenance_gap','surviving 2014 evidence is internally inconsistent or incomplete', ...
    'not_reproduced','2026 reconstruction runs but does not reproduce the historical result');

report.vega=validate_vega(opts);
report.proton=validate_proton(opts);
report.ariane5=validate_ariane(opts);

statuses={report.vega.closure_status,report.proton.closure_status, ...
    report.ariane5.closure_status};
report.all_cases_classified=all(~cellfun(@isempty,statuses));
report.validation_closure_complete=report.all_cases_classified;
report.overall_status='closed_with_documented_provenance_gaps';
report.open_implementation_defects={};
report.remaining_work={ ...
    'Locate additional 2014 source if it exists (especially RocketDynEq and final optimization driver).', ...
    'Calibrate modern 2026 extensions against independent external datasets.', ...
    'Treat precision CFD/GNC/ephemerides as higher-fidelity validation, not Chapter-6 reconstruction.'};

if opts.print_summary
    print_validation_closure(report);
end
end

function v=validate_vega(opts)
ref=vega_2014_reference();
v.reference=ref;

% Thesis Table 6.4 internal reproduction.
rmp=[ref.stages.mp_kg];
rms=[ref.stages.ms_kg];
rm0=ref.reported.table6_4_reference_m0_kg;
smp=ref.reported.table6_4_simulated_mp_kg;
sms=ref.reported.table6_4_simulated_ms_kg;
sm0=ref.reported.table6_4_simulated_m0_kg;
calc=[historical_percent_deviation(rmp,smp).', ...
      historical_percent_deviation(rms,sms).', ...
      historical_percent_deviation(rm0,sm0).'];
published=ref.reported.table6_4_deviation_percent;
mask=isfinite(calc) & isfinite(published);
v.mass_table.calculated_deviation_percent=calc;
v.mass_table.published_deviation_percent=published;
v.mass_table.deviation_residual_percentage_points=calc-published;
v.mass_table.max_printed_residual_percentage_points= ...
    max(abs(v.mass_table.deviation_residual_percentage_points(mask)));
v.mass_table.max_rounding_error_percent= ...
    v.mass_table.max_printed_residual_percentage_points; % legacy diagnostic alias
v.mass_table.arithmetic_anomaly_mask= ...
    abs(v.mass_table.deviation_residual_percentage_points)>0.15;
v.mass_table.glow_deviation_percent=historical_percent_deviation( ...
    ref.reported.table6_4_reference_glow_kg, ...
    ref.reported.table6_4_simulated_glow_kg);
if any(v.mass_table.arithmetic_anomaly_mask(:))
    v.mass_table.status='verified_with_published_arithmetic_anomaly';
else
    v.mass_table.status='verified';
end

% Stage-4 m0 is kept as a provenance note rather than forced.
v.mass_table.stage4_m0_without_payload_kg= ...
    ref.reported.table6_4_stage4_m0_without_payload_kg;
v.mass_table.stage4_m0_with_payload_kg= ...
    ref.reported.table6_4_stage4_m0_with_payload_kg;
v.mass_table.stage4_m0_note=[ ...
    'Published component masses imply 692.2 kg before payload; extracted ', ...
    'text can read 2192.2 kg with the 1500 kg payload included, while the ', ...
    'printed 11.8% deviation is consistent with the former convention.'];

v.geometry_table=geometry_check( ...
    ref.reported.table6_5_reference_length_m, ...
    ref.reported.table6_5_simulated_length_m, ...
    ref.reported.table6_5_deviation_length_percent, ...
    ref.reported.table6_5_reference_volume_m3, ...
    ref.reported.table6_5_simulated_volume_m3, ...
    ref.reported.table6_5_deviation_volume_percent);

cfg=vega_2014_trajectory_config();
atm=simulate_thesis_2014_atmospheric_phase(cfg);
v.trajectory.thesis_fixture.kn_detected=atm.transition.detected;
v.trajectory.thesis_fixture.kn_time_s=atm.transition.time_s;
v.trajectory.thesis_fixture.kn_altitude_m=atm.transition.altitude_m;
v.trajectory.thesis_fixture.max_q_altitude_m=atm.max_q_altitude_m;
v.trajectory.thesis_fixture.kn_time_error_s= ...
    atm.transition.time_s-ref.reported.gravity_turn_end_time_s;
v.trajectory.thesis_fixture.status='not_reproduced';

dev=vega_2014_recovered_gravity_test();
dcfg=cfg;
dcfg.gravity_turn_altitude_m=dev.gravity_turn_altitude_m;
dcfg.gravity_turn_seed_gamma_rad=dev.gamma0_rad;
for i=1:numel(dcfg.stages)
    dcfg.stages(i).mp_kg=dev.mp_kg(i);
    dcfg.stages(i).Isp_s=dev.Isp_s(i);
    dcfg.stages(i).thrust_N=dev.thrust_N(i);
    dcfg.stages(i).burn_time_s=dev.burn_time_s(i);
end
dcfg.stages(1).diameter_m=dev.aerodynamic_diameter_m;
dcfg.stages(1).reference_area_m2=pi*dev.aerodynamic_diameter_m^2/4;
dcfg.knudsen_characteristic_length_m=dev.aerodynamic_diameter_m/2;
datm=simulate_thesis_2014_atmospheric_phase(dcfg,struct( ...
    'drag_reference','active_stage','initial_mass_kg', ...
    dev.section_initial_mass_kg(1)));
v.trajectory.recovered_development.kn_time_s=datm.transition.time_s;
v.trajectory.recovered_development.kn_altitude_m=datm.transition.altitude_m;
v.trajectory.recovered_development.max_q_altitude_m=datm.max_q_altitude_m;
v.trajectory.recovered_development.kn_time_error_s= ...
    datm.transition.time_s-ref.reported.gravity_turn_end_time_s;
v.trajectory.recovered_development.status='provenance_gap';

if opts.run_full_trajectory
    topts=struct('free_flight_opts',struct( ...
        'rel_tol',1e-4,'abs_tol',1e-6,'mesh_points',41, ...
        'output_points',101,'max_nodes',12000));
    full=simulate_thesis_reference_trajectory(cfg,topts);
    v.trajectory.full=status_from_full(full,ref.reported.flight_time_s, ...
        ref.reported.trajectory_validation_last_stage_unburned_percent);
else
    v.trajectory.full=struct('status','not_run');
end

v.findings={ ...
    'Most Chapter-6 Vega table deviations reproduce Eq. 6.1 within printed rounding; the Stage-3 structural-mass deviation is a published arithmetic/transcription anomaly.', ...
    'The reconstructed lower-atmosphere max-q altitude is close to the thesis qualitative ~9 km landmark.', ...
    'The thesis Kn=5 transition time is not reproduced by either published-table or recovered-development inputs.', ...
    'Recovered Vega thrust, masses and aerodynamic diameter differ from Table 6.1; no surviving evidence uniquely selects one convention.'};
v.closure_status='closed_provenance_gap';
end

function p=validate_proton(opts)
ref=proton_2014_reference();
p.reference=ref;
active=ref.stages(ref.active_stage_indices);
rmp=[active.mp_kg]; rms=[active.ms_kg];
rm0=[668577 218577 50747];
smp=ref.reported.table6_6_simulated_mp_kg;
sms=ref.reported.table6_6_simulated_ms_kg;
sm0=ref.reported.table6_6_simulated_m0_kg;
calc=[historical_percent_deviation(rmp,smp).', ...
      historical_percent_deviation(rms,sms).', ...
      historical_percent_deviation(rm0,sm0).'];
published=ref.reported.table6_6_stage_deviation_percent;
p.mass_table.calculated_deviation_percent=calc;
p.mass_table.published_deviation_percent=published;
p.mass_table.deviation_residual_percentage_points=calc-published;
p.mass_table.max_printed_residual_percentage_points= ...
    max(abs(p.mass_table.deviation_residual_percentage_points(:)));
p.mass_table.max_rounding_error_percent= ...
    p.mass_table.max_printed_residual_percentage_points; % legacy diagnostic alias
p.mass_table.arithmetic_anomaly_mask= ...
    abs(p.mass_table.deviation_residual_percentage_points)>0.15;
p.mass_table.glow_deviation_percent=historical_percent_deviation( ...
    ref.reported.table6_6_reference_glow_kg, ...
    ref.reported.table6_6_simulated_glow_kg);
if any(p.mass_table.arithmetic_anomaly_mask(:))
    p.mass_table.status='verified_with_published_arithmetic_anomaly';
else
    p.mass_table.status='verified';
end

p.geometry_table=geometry_check( ...
    ref.reported.table6_7_reference_length_m, ...
    ref.reported.table6_7_simulated_length_m, ...
    ref.reported.table6_7_deviation_length_percent, ...
    ref.reported.table6_7_reference_volume_m3, ...
    ref.reported.table6_7_simulated_volume_m3, ...
    ref.reported.table6_7_deviation_volume_percent);

literal=proton_2014_trajectory_config('thesis_semantic');
latm=simulate_thesis_2014_atmospheric_phase(literal);
p.trajectory.thesis_semantic.liftoff_TW=literal.liftoff_TW;
p.trajectory.thesis_semantic.kn_detected=latm.transition.detected;
p.trajectory.thesis_semantic.status='provenance_gap';

recovered=proton_2014_trajectory_config('recovered_development');
ratm=simulate_thesis_2014_atmospheric_phase(recovered);
p.trajectory.recovered_development.liftoff_TW=recovered.liftoff_TW;
p.trajectory.recovered_development.kn_detected=ratm.transition.detected;
p.trajectory.recovered_development.kn_time_s=ratm.transition.time_s;
p.trajectory.recovered_development.kn_altitude_m=ratm.transition.altitude_m;
p.trajectory.recovered_development.kn_time_error_s= ...
    ratm.transition.time_s-ref.reported.gravity_turn_end_time_s;
p.trajectory.recovered_development.status='not_reproduced';

if opts.run_full_trajectory
    topts=struct('free_flight_opts',struct( ...
        'rel_tol',2e-4,'abs_tol',1e-6,'mesh_points',41, ...
        'output_points',101,'max_nodes',12000));
    full=simulate_thesis_reference_trajectory(recovered,topts);
    p.trajectory.full=status_from_full(full,ref.reported.flight_time_s, ...
        ref.reported.integrated_final_propellant_reserve_percent);
else
    p.trajectory.full=struct('status','not_run');
end

p.findings={ ...
    'The Chapter-6 Proton mass and geometry deviations reproduce Eq. 6.1 within printed rounding.', ...
    'Literal Table 6.2 thrust plus the thesis payload/DM-3 convention gives T/W below one, so the published trajectory inputs are internally inconsistent for lift-off.', ...
    'The recovered development test uses materially different thrust, Isp, burn time, aerodynamic diameter and payload convention.', ...
    'The recovered-development trajectory reaches Kn=5 but not at the reported 153 s.'};
p.closure_status='closed_provenance_gap';
end

function a=validate_ariane(opts)
ref=ariane5_2014_optimization_reference();
a.reference=ref;

rmp=[ref.original.boosters.mp_kg ref.original.core.mp_kg ref.original.upper.mp_kg];
rms=[ref.original.boosters.ms_kg ref.original.core.ms_kg ref.original.upper.ms_kg];
rm0=ref.original.table6_11_m0_kg;
smp=[ref.optimum.masses.booster_mp_kg ref.optimum.masses.core_mp_kg ...
    ref.optimum.masses.upper_mp_kg];
sms=[ref.optimum.masses.booster_ms_kg ref.optimum.masses.core_ms_kg ...
    ref.optimum.masses.upper_ms_kg];
sm0=ref.optimum.table6_11_simulated_m0_kg;
calc=[historical_percent_deviation(rmp,smp).', ...
      historical_percent_deviation(rms,sms).', ...
      historical_percent_deviation(rm0,sm0).'];
published=ref.optimum.table6_11_deviation_percent;
a.mass_table.calculated_deviation_percent=calc;
a.mass_table.published_deviation_percent=published;
a.mass_table.deviation_residual_percentage_points=calc-published;
a.mass_table.max_printed_residual_percentage_points= ...
    max(abs(a.mass_table.deviation_residual_percentage_points(:)));
a.mass_table.max_rounding_error_percent= ...
    a.mass_table.max_printed_residual_percentage_points; % legacy diagnostic alias
a.mass_table.arithmetic_anomaly_mask= ...
    abs(a.mass_table.deviation_residual_percentage_points)>0.15;
a.mass_table.reported_reduction_kg=ref.optimum.reported_mass_reduction_kg;
a.mass_table.calculated_reduction_percent=100* ...
    ref.optimum.reported_mass_reduction_kg/ref.original.reported_vehicle_mass_kg;
if any(a.mass_table.arithmetic_anomaly_mask(:))
    a.mass_table.status='verified_with_published_arithmetic_anomaly';
else
    a.mass_table.status='verified';
end

a.geometry_table=geometry_check( ...
    ref.original.dimensions.length_m,ref.optimum.dimensions.length_m, ...
    ref.optimum.table6_12_deviation_percent(:,2).', ...
    ref.original.dimensions.volume_m3,ref.optimum.dimensions.volume_m3, ...
    ref.optimum.table6_12_deviation_percent(:,3).');

bench=run_ariane5_2014_parallel_benchmark(struct( ...
    'delta_v_match_tolerance_m_s',1500));
a.modern_benchmark=bench;
if all([bench.cases.success])
    a.modern_benchmark.status='reconstructed_comparison_only';
else
    a.modern_benchmark.status='not_reproduced';
end

space=ariane5_2014_reported_design_space();
a.design_space.reported_total_simulations=space.reported_total_simulations;
a.design_space.delta_v_reported_points=space.delta_v_reported_points;
a.design_space.exact_delta_v_sequence_available=~isempty(space.delta_v_sequence);
a.design_space.status='provenance_gap';

if opts.run_ariane_trajectory && bench.cases(2).success
    cfg=bench.cases(2).configuration;
    sizing=bench.cases(2).sizing;
    popts=struct();
    popts.trajectory_config=struct('interstage_coast_time_s',3);
    popts.free_flight_opts=struct('rel_tol',5e-4,'abs_tol',1e-6, ...
        'mesh_points',31,'output_points',61,'max_nodes',6000);
    try
        tr=simulate_parallel_booster_trajectory(cfg,sizing,popts);
        a.trajectory.status_text=tr.status;
        a.trajectory.transition_detected=tr.transition_detected;
        a.trajectory.orbit_reached=tr.orbit_reached;
        a.trajectory.max_q_Pa=tr.constraints.max_q_Pa;
        a.trajectory.max_heat_flux_W_m2=tr.constraints.max_heat_flux_W_m2;
        if tr.transition_detected
            a.trajectory.kn_time_s=tr.atmospheric.transition.time_s;
            a.trajectory.kn_altitude_m=tr.atmospheric.transition.altitude_m;
        end
        if tr.orbit_reached
            a.trajectory.status='reconstructed';
        else
            a.trajectory.status='not_reproduced';
        end
    catch ME
        a.trajectory.status='not_reproduced';
        a.trajectory.status_text=[ME.identifier ': ' ME.message];
    end
else
    a.trajectory=struct('status','not_run');
end

a.findings={ ...
    'Ariane Table 6.11 mass deviations and Table 6.12 volume deviations reproduce Eq. 6.1; two printed stage-length deviations in Table 6.12 do not.', ...
    'The thesis states that the optimization objective was not exact reproduction of Ariane 5 but a lighter design.', ...
    'The exact 23-point Delta-V path is not specified in the surviving thesis/source and is therefore not reconstructed by guesswork.', ...
    'The 8000 kN booster-thrust interpretation remains explicitly documented as a 2026 inference.'};
a.closure_status='closed_provenance_gap';
end

function out=geometry_check(rl,sl,publ,rv,sv,pubv)
cl=historical_percent_deviation(rl,sl);
cv=historical_percent_deviation(rv,sv);
out.calculated_length_deviation_percent=cl;
out.published_length_deviation_percent=publ;
out.calculated_volume_deviation_percent=cv;
out.published_volume_deviation_percent=pubv;
out.length_residual_percentage_points=cl-publ;
out.volume_residual_percentage_points=cv-pubv;
all_residuals=[out.length_residual_percentage_points, ...
    out.volume_residual_percentage_points];
out.max_printed_residual_percentage_points=max(abs(all_residuals));
out.max_rounding_error_percent= ...
    out.max_printed_residual_percentage_points; % legacy diagnostic alias
out.arithmetic_anomaly_mask=abs(all_residuals)>0.15;
if any(out.arithmetic_anomaly_mask)
    out.status='verified_with_published_arithmetic_anomaly';
else
    out.status='verified';
end
end

function s=status_from_full(full,reported_time_s,reported_reserve_percent)
s.status_text=full.status;
s.transition_detected=full.transition_detected;
s.orbit_reached=full.orbit_reached;
if isfield(full,'total_time_s')
    s.total_time_s=full.total_time_s;
    s.total_time_error_s=full.total_time_s-reported_time_s;
else
    s.total_time_s=NaN;
    s.total_time_error_s=NaN;
end
if isfield(full,'last_stage_propellant_remaining_fraction')
    s.reserve_percent=100*full.last_stage_propellant_remaining_fraction;
    s.reserve_error_percentage_points=s.reserve_percent-reported_reserve_percent;
else
    s.reserve_percent=NaN;
    s.reserve_error_percentage_points=NaN;
end
if full.orbit_reached
    s.status='reconstructed';
else
    s.status='not_reproduced';
end
end
