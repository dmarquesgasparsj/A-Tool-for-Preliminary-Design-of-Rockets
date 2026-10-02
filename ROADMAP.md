# Roadmap — From the 2014 Thesis to the AI-Assisted 2026 Project

This roadmap separates three layers:

1. scientific work documented in the 2014 MSc thesis;
2. unfinished thesis-era MATLAB development files recovered in 2026;
3. new implementation and extensions developed in 2026 with AI assistance.

## AI-assisted development statement

The 2026 reconstruction and extension is **AI-assisted**. ChatGPT is used to help recover intent from the thesis and surviving source files, refactor MATLAB code, implement new modules, write tests, identify inconsistencies and document assumptions.

AI output is **not** scientific evidence. Historical claims remain traceable to the thesis/recovered files; new equations and modelling choices are labelled as 2026 extensions and should be validated against technical references or external data before operational use.

## Current implementation state

The modern code paths required for the original thesis architecture and the explicitly listed Future Work are now implemented at **preliminary-design fidelity**.

That statement does **not** mean that every historical number has been reproduced or that every extension is flight-certified. Two separate questions are tracked:

- **implementation completeness:** whether the capability exists in code with tests;
- **validation completeness:** whether the capability reproduces historical/reference data within an agreed tolerance.

The remaining historical discrepancies are validation/provenance questions rather than missing software:

- Vega: reconstructed Kn=5 transition timing and last-stage reserve differ from the reported thesis values;
- Proton K: the literal Table 6.2 thrust convention gives lift-off T/W below 1, while recovered development values produce lift-off;
- staged TPBVP convergence remains sensitive for some Proton conditions;
- Ariane 5: the generalized booster model is implemented, but exact reproduction of the lost 2014 23-point Delta-V search path is not possible from surviving evidence;
- exact treatment of final-stage propellant shortfall in the lost final implementation is not recoverable from the available source.

These points must not be tuned away merely to reproduce a historical table.

## Original thesis Future Work

| 2014 proposal | 2026 implementation status | Current implementation |
| --- | --- | --- |
| GUI for non-programmers | **Implemented** | rocket_design_app.m provides a unified MATLAB GUI for mission/stage editing and access to integrated, booster and mission workflows. Menus and programmatic APIs remain available. |
| Chamber pressure, exit pressure and nozzle geometry in mass/thrust models | **Implemented** | pressure_aware_nozzle.m performs choked/isentropic nozzle sizing, exit pressure, ambient-pressure thrust and optional shell mass. |
| More realistic engine mass model | **Implemented as calibrated framework** | estimate_engine_mass.m supports the thesis MER and a reference-engine power-law model using thrust, chamber pressure, area ratio and O/F. Calibration coefficients are explicit rather than invented. |
| More realistic drag model for nose-cone configurations | **Implemented as analytical preliminary model** | Appendix-A profiles feed a modified-Newtonian hypersonic forebody-pressure model, smoothly blended with the thesis Cd(Mach) law. CFD/experimental validation remains a fidelity upgrade, not missing functionality. |
| Trajectory constraints: max-q, heat flux, bending load, axial acceleration | **Implemented with active response** | Evaluators return histories/margins/pass-fail; constraint_aware_throttle.m provides a transparent throttle response and the ascent integrator burns stages to propellant depletion under throttling. |
| More booster options, grain geometry, nose cones and solid propellants | **Implemented at conceptual fidelity** | Arbitrary parallel-booster count, trajectory coupling and discrete optimization are implemented. solid_grain_ballistics.m adds BATES, inhibited-core and end-burner grains with configurable Saint-Robert propellant law; shape-specific nose drag is shared with serial stages. |
| Air-launched and initially inclined launchers | **Implemented** | Generalized initial altitude, velocity and flight-path angle are supported, with Earth rotation handled consistently. Full 3D heading/azimuth is a higher-fidelity extension beyond the original 2D thesis model. |
| Cost model | **Implemented as transparent CER framework** | Development, production, operations and learning-curve terms are implemented. Monetary output requires a calibrated external CER dataset. |
| GEO transfers, interplanetary trajectories and long coast phases | **Implemented at preliminary astrodynamics fidelity** | GEO Hohmann, interplanetary Hohmann/patched-conic analysis and long-coast 3D propagation are available. Lambert/ephemeris targeting remains a higher-fidelity mission-design extension. |
| Thrust misalignment, non-spherical Earth gravity, Moon/Sun perturbations | **Implemented** | Deterministic thrust misalignment, stochastic pointing-error Monte Carlo, Earth J2, Sun/Moon third-body gravity and an external ephemeris interface are implemented. Built-in Sun/Moon positions are explicitly low-order sensitivity models. |
| Rewrite in C/C++ for speed | **Deferred by design** | MATLAB is retained for traceability. Profiling should identify bottlenecks before selective MEX/C++ acceleration; a full rewrite is no longer assumed to be beneficial. |

## Fidelity boundaries

“Implemented” in this roadmap means the requested preliminary-design capability exists, is exposed through a documented numerical API, and has regression/invariant tests. It does **not** mean:

- certified structural design;
- CFD-quality aerodynamics;
- combustion-instability or erosive-burning modelling;
- operational GNC;
- high-precision planetary ephemerides;
- calibrated monetary cost estimates.

Those are higher-fidelity engineering products requiring external datasets and specialist validation.

## Milestones

### v0.4 — Integrated thesis core
Generalized serial mass sizing, 2D ascent/loss feedback, historical Kn=5 atmospheric reconstruction, staged TPBVP, explicit coast phases and final-stage residual-propellant feedback are implemented. Historical Vega/Proton discrepancies are preserved as validation findings.

### v0.5 — Aerodynamics, propulsion and constraints
Pressure-aware nozzle performance, calibrated engine-mass framework, shape-specific analytical nose drag, max-q/heat/bending/axial evaluators and active throttle response are implemented.

### v0.6 — Configuration generalization
Generalized parallel boosters, discrete optimization, booster trajectory coupling and configurable solid-grain ballistics are implemented.

### v0.7 — Mission and economic extensions
Inclined/air launch, cost CER framework, GEO/interplanetary preliminary analysis and long-coast propagation are implemented.

### v0.8 — Higher-fidelity dynamics
Thrust misalignment, pointing-error Monte Carlo, Earth J2 and Sun/Moon third-body gravity are implemented, with an interface for external ephemerides.

### v0.9 — Validation closure
Focus exclusively on reproducible Vega, Proton K and Ariane 5 validation reports, uncertainty/sensitivity analysis, benchmark datasets and documentation consistency.

### v1.0 — Validated open design tool
Stable API/GUI, documented fidelity limits, reproducible reference cases and performance profiling. Selective native-code acceleration only if measured benchmarks justify it.
