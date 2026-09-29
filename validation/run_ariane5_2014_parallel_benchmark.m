function report = run_ariane5_2014_parallel_benchmark(opts)
%RUN_ARIANE5_2014_PARALLEL_BENCHMARK Compare thesis Ariane cases to new model.
%
% Evaluates the Chapter 6 reference-centre configuration and the reported
% Table 6.10 optimum using the same generalized 2026 booster model. It does
% not tune coefficients to make either point match Table 6.11.
%
% The result is deliberately diagnostic: discrepancies identify modelling
% work still required (geometry/skin mass, exact historic booster MER,
% trajectory-loss feedback, and the lost 23-point Delta-V search path).

if nargin<1 || isempty(opts), opts=struct(); end
if ~isfield(opts,'delta_v_match_tolerance_m_s')
    opts.delta_v_match_tolerance_m_s=100;
end
ref=ariane5_2014_optimization_reference();

modes={'original','reported_optimum'};
for i=1:2
    cfg=ariane5_2014_parallel_config(modes{i});
    item.mode=modes{i};
    item.configuration=cfg;
    try
        s=size_parallel_booster_launcher(cfg,struct( ...
            'delta_v_match_tolerance_m_s', ...
                opts.delta_v_match_tolerance_m_s));
        item.success=true;
        item.sizing=s;
        item.error='';
    catch ME
        item.success=false;
        item.sizing=[];
        item.error=[ME.identifier ': ' ME.message];
    end
    cases(i)=item; %#ok<AGROW>
end

report.reference=ref;
report.cases=cases;
report.reported_original_vehicle_mass_kg= ...
    ref.original.reported_vehicle_mass_kg;
report.reported_optimum_vehicle_mass_kg= ...
    ref.optimum.reported_vehicle_mass_kg;
report.reported_reduction_kg=ref.optimum.reported_mass_reduction_kg;

if all([cases.success])
    modern_original=cases(1).sizing.GLOW_kg;
    modern_optimum=cases(2).sizing.GLOW_kg;
    report.modern_original_GLOW_kg=modern_original;
    report.modern_optimum_GLOW_kg=modern_optimum;
    report.modern_reduction_kg=modern_original-modern_optimum;
    report.modern_reduction_percent= ...
        100*(modern_original-modern_optimum)/modern_original;
else
    report.modern_original_GLOW_kg=NaN;
    report.modern_optimum_GLOW_kg=NaN;
    report.modern_reduction_kg=NaN;
    report.modern_reduction_percent=NaN;
end

report.status=[ ...
    'Ariane 5 benchmark scaffold active. Results are comparison data, ', ...
    'not a reproduction claim until booster/geometry/trajectory validation ', ...
    'matches Chapter 6 independently.'];
end
