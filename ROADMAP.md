# Roadmap — From the 2014 Thesis to the AI-Assisted 2026 Project

This roadmap separates three things that must not be conflated:

1. the scientific work documented in the 2014 MSc thesis;
2. unfinished thesis-era MATLAB development files recovered in 2026;
3. new implementation and extensions developed in 2026 with AI assistance.

## AI-assisted development statement

The 2026 reconstruction and extension is **AI-assisted**. ChatGPT is being used to help recover intent from the thesis and surviving source files, refactor MATLAB code, write tests, identify inconsistencies, document assumptions and implement new modules.

AI output is not treated as scientific evidence. Equations and historical claims must be traceable to the thesis or cited technical sources, and new modelling choices must be labelled as such and validated with regression tests or external reference cases.

## Immediate priority: integrated thesis architecture

The thesis couples the mass model and trajectory model by iterating the Delta-V estimate after computing drag and gravity losses. The modern repository now contains the first explicit version of that feedback loop.

Current state: **partially implemented**.

Implemented in the modern coupled path:

- generalized serial-stage MER mass sizing;
- stage masses passed directly to the trajectory propagator;
- drag and gravity loss integration;
- dynamic pressure calculation;
- iterative Delta-V update with a default 0.01% convergence criterion;
- explicit lift-off thrust-to-weight diagnostic;
- separation between “Delta-V loop converged” and “requested orbit reached”.

Still required before calling this a full reproduction of the thesis integrated model:

- resolve/document the Vega atmospheric transition discrepancy (reconstruction Kn=5 timing differs from the reported 97.1 s), then validate the staged TPBVP and Proton case;
- shape-specific nose-cone aerodynamics beyond the thesis-wide Cd(Mach) fit;
- interstage/fairing structural integration beyond the implemented cylindrical stage geometry and optional skin-mass model;
- historical end-to-end validation of the implemented booster trajectory coupling;
- exact treatment of propellant *shortfall* in the lost 2014 final implementation (the documented excess-residual Tsiolkovsky feedback is implemented);
- Vega, Proton K and Ariane 5 end-to-end validation.

## Original thesis Future Work

| 2014 proposal | 2026 status | Next implementation |
| --- | --- | --- |
| GUI for non-programmers | Partial | Keep menus, then add a richer MATLAB app only after the scientific API is stable. |
| Chamber pressure, exit pressure and nozzle geometry in mass/thrust models | **Implemented / experimental** | Pressure-aware isentropic nozzle sizing, ambient-pressure thrust and optional nozzle shell mass are implemented; validate against engine reference cases before making it the default. |
| More realistic engine mass model | Partial | Replace the current low-fidelity thrust-based MER with propulsion/pressure/performance-aware alternatives. |
| More realistic drag model for nose-cone configurations | Partial | Appendix A geometry and thesis-wide Cd(Mach) are implemented; add shape-specific analytical/CFD correlations as a new validated extension. |
| Trajectory constraints: max-q, heat flux, bending load, axial acceleration | **Implemented as evaluators** | Max-q, Sutton-Graves heat flux, preliminary bending and axial acceleration limits return pass/fail. Active throttle/guidance response to violations remains future work. |
| More booster options, grain geometry, nose cones and solid propellants | **Partial / advanced** | Generalized parallel booster sizing and trajectory coupling are implemented; next add grain-geometry submodels and broader solid-propellant models. |
| Air-launched and initially inclined launchers | **Implemented / experimental** | Generalized initial altitude, speed and flight-path angle are implemented while preserving the historical ground-launch default; next add full 3D heading/azimuth and carrier-release validation. |
| Cost model | **Implemented as transparent CER framework** | Development, production, operations and learning-curve terms are implemented. Normalized defaults are dimensionless; monetary estimates require a calibrated external CER dataset. |
| GEO transfers, interplanetary trajectories and long coast phases | **Implemented / preliminary** | Hohmann GEO, patched-conic interplanetary estimates and 3D long-coast propagation are implemented; next add Lambert/ephemeris targeting and capture manoeuvres. |
| Thrust misalignment, non-spherical Earth gravity, Moon/Sun perturbations | **Partial / implemented through J2** | Deterministic thrust misalignment and optional Earth J2 are implemented; Moon/Sun third-body gravity and stochastic pointing-error Monte Carlo remain future work. |
| Rewrite in C/C++ for speed | Deferred / conditional | Profile MATLAB first. Use vectorization, parallel execution or selective MEX/C++ only for measured bottlenecks. |

## Why C/C++ is no longer an automatic priority

In 2014, rewriting the whole program in C or C++ was a reasonable route to shorter simulation times. In the modern project it should be a performance decision, not a goal by itself.

The preferred sequence is:

1. make the MATLAB scientific model correct and reproducible;
2. profile representative optimization runs;
3. improve algorithms and vectorization;
4. parallelize independent design evaluations where useful;
5. move only genuinely expensive kernels to C/C++/MEX if profiling shows a clear benefit.

A full rewrite would make scientific comparison with the thesis harder and increase maintenance cost without guaranteeing that the real bottleneck is solved.

## Suggested milestones

### v0.4 — Integrated thesis core
The three-phase architecture, documented interstage coasts, final-stage residual-propellant Delta-V feedback and generalized parallel-booster sizing are implemented. Vega reproduces max-q altitude but still disagrees on Kn-transition timing/last-stage reserve; the literal Proton Table 6.2 thrust gives T/W < 1, while the recovered development dynamics reach Kn=5 but the staged TPBVP still exposes a singular-Jacobian case. These discrepancies are validation targets, not values to tune away.

### v0.5 — Aerodynamics, propulsion and constraints
Pressure-aware nozzle geometry/thrust and max-q, heat-flux, bending and axial-acceleration evaluators are implemented. Remaining work is validation, shape-specific drag beyond the thesis-wide Cd(Mach), and active guidance/throttle constraint handling.

### v0.6 — Configuration generalization
The generic "zeroth-stage" parallel-booster mass/performance model, trajectory coupling and a toolbox-free discrete optimizer are implemented. Inclined/air-launch initial conditions are also implemented. Remaining work: grain-geometry submodels, full 3D launch heading/azimuth and broader validation.

### v0.7 — Mission and economic extensions
Inclined/air-launch initial conditions, transparent CER cost modelling, GEO Hohmann transfer, interplanetary Hohmann/patched-conic analysis and long-coast 3D propagation are implemented. Remaining work: ephemeris/Lambert targeting, arrival/capture manoeuvres and calibrated monetary CER datasets.

### v0.8 — Higher-fidelity dynamics
Deterministic thrust misalignment and Earth J2 are implemented. Remaining work: 3D ascent heading/azimuth, stochastic pointing errors and, where mission duration justifies it, lunar/solar third-body effects.

### v1.0 — Validated open design tool
Documented end-to-end validation, reproducible examples, stable API/GUI and performance profiling. Selective native-code acceleration only if benchmarks justify it.
