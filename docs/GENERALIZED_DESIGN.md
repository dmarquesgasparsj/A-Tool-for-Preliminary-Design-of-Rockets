# Generalized Launcher Design: Modern Implementation

The files recovered from the original thesis project are **development prototypes**, not the final production code. Their mathematical ideas, data and validation experiments are useful evidence. Bugs, hard-coded launcher values and duplicated interfaces are not requirements for the modern implementation.

## Separate configuration, calculations and interface

The modern serial-stage mass-sizing path is:

```text
main.m -> launcher_menu.m -> make_launcher_config.m
                             |
run_thesis_sizing(mission,stages) -> thesis_iterative_mass_model.m
                                    |
                                    +-- thesis_stage_mass.m
                                    +-- modern_stage_mer.m
                                        |
                                        +-- thesis_mer_components.m
```

`main()` now offers the unified graphical app plus dedicated integrated, mass-only, booster, mission-extension and compatibility paths. The existing `main(payload_kg, orbit_altitude_km)` and `run_design()` APIs remain available.

The interactive menu is optional. The entire mass calculation can be run from a script or test without windows, global variables or hard-coded filenames.

## Stage count and propellants

The serial model accepts any **positive integer number of stages**. In addition, the modern 2026 implementation now supports a generalized booster-assisted first/core stage: an arbitrary positive booster count burns in parallel with the core (the thesis "zeroth stage"), the empty boosters are jettisoned, and the core then continues alone. Practical feasibility is constrained by the mass-ratio equations and MER assumptions, not by separate 2/3/4-stage functions.

Every stage can set:

- effective specific impulse, thrust, nozzle area ratio;
- its own fraction of the available Delta-V;
- solid, liquid or hybrid propulsion;
- a listed or custom propellant;
- mixture ratio and densities (where applicable);
- an optional fairing area and tank insulation areas;
- initial structural factor for the non-iterative historic model.

The catalog is the 2014 source table. The modern selection layer corrects the historical LOX/RP1 **propulsion-type label** to liquid without altering the historical table file. For the catalog's nominal Isp values, supply a stage-specific `Isp_s` or an explicit `isp_efficiency`; the nominal value must not be assumed to equal an actual engine's delivered impulse.

## Pure programmatic example

```matlab
mission = struct('payload_kg', 1000, ...
    'orbit_altitude_km', 200, ...
    'delta_v_budget_m_s', 8500);

stages(1) = struct('name','Core', ...
    'propellant_name','LOX/RP1', ...
    'delta_v_fraction',0.55, ...
    'thrust_N',2.5e6, ...
    'nozzle_area_ratio',25, ...
    'Isp_s',295);

stages(2) = struct('name','Upper stage', ...
    'propellant_name','LOX/H2', ...
    'delta_v_fraction',0.45, ...
    'thrust_N',300e3, ...
    'nozzle_area_ratio',80, ...
    'Isp_s',440);

result = run_thesis_sizing(mission, stages);
```

To use the menus instead, run `main`, select **Generalized launcher sizing**, then **Custom launcher**. The menu asks how many stages to create and repeats the same stage editor for each stage. Vega's **recovered development inputs**, explicitly not a modern validation result, are also available as a preset.

A custom propellant can be supplied with `propellant_name='custom'`, `propulsion_type`, `Isp_s` and a positive `mixture_ratio_OF` for liquid or hybrid propulsion. This is an input pathway, not a claim that its physical behaviour has been validated.

## Structural-factor solution

The 2014 development prototype searched a coarse grid of candidate structural factors. The new solver uses bracketed bisection over the physically admissible range `0 <= epsilon < 1/k`, where `k=exp(DeltaV/(g0*Isp))`, and solves:

```text
mass_structural_Tsiolkovsky(epsilon)
    = mass_structural_MER(epsilon)
```

It stops when the **relative structural-mass discrepancy** is at most 0.1% by default. The solver returns each stage's epsilon, propellant and dry masses, MER components, Delta-V and convergence history. If a stage has no bracketed solution, the solver returns an explicit error rather than silently accepting an unphysical design.

The **new MER aggregation is a modelling policy**, not a claim that an unfinished 2014 prototype had already implemented it:

| Propulsion | Component policy |
| --- | --- |
| Solid | Casing + avionics + thrust structure + separate nozzle |
| Liquid | Oxidizer and fuel tanks + avionics + thrust structure + engine |
| Hybrid | Oxidizer tank + assumed fuel casing + avionics + thrust structure + engine |

For liquid and hybrid stages, a separate nozzle mass is not added by default because the engine MER already depends on nozzle area ratio. Fairing/insulation are supported, and the 2026 extension adds explicit fairing, interstage, payload-adapter and wiring geometry when configured. Per-stage reserve propellant and explicit dry-mass margins are also supported. The tank/casing coefficients remain low-fidelity parametric estimates, especially for custom fuels.

## Parallel boosters and the thesis "zeroth stage"

The new booster path is deliberately separate from the lost final 2014 implementation. `parallel_booster_performance()` performs direct mass accounting for the simultaneous booster+core burn, booster jettison and subsequent core-only burn. `size_parallel_booster_core()` solves the core structural factor against the modern MER model and sizes each physical solid booster independently before multiplying by the booster count. This avoids applying nonlinear nozzle/avionics relations to an aggregate pair as though it were one motor.

`size_parallel_booster_launcher()` combines that lower system with arbitrary serial upper stages. Its Delta-V vector is explicit:

```text
[booster-parallel phase, core-only phase, upper stage 1, ...]
```

The allocated booster-phase Delta-V is a **target**; the actual value is predicted from count, thrust, Isp and burn fraction. The discrete `optimize_parallel_booster_launcher()` searches user-supplied grids and selects minimum GLOW only among candidates that satisfy the Delta-V match and lift-off T/W criteria.

The Ariane 5 Chapter 6 benchmark is mapped through `ariane5_2014_parallel_config()`. The reported 8000 kN optimum is treated as thrust **per booster** because two such boosters give 16,000 kN, consistent with the +14% upper end of the approximately 14,000 kN pair-total reference. This is a documented reconstruction inference, not a silent alteration of Table 6.10.

## Integrated mass / trajectory feedback

`run_integrated_design()` couples the generalized mass model to the current 2D gravity-turn propagator. Each iteration resizes the launcher, propagates the ascent, integrates drag and gravity losses, and updates the total Delta-V budget. The default Delta-V convergence tolerance is 0.01%, matching the value stated in the thesis.

The generalized Delta-V feedback path and the historical three-phase reconstruction are deliberately separate. The latter propagates to the exact **Kn = 5** event and hands the live state, active stage and remaining propellant to the staged TPBVP solver. Historical Vega/Proton disagreements are treated as validation/provenance findings rather than missing software. Results continue to report Delta-V convergence and orbit attainment separately.

The trajectory adapter retains the thesis Eq. (3.49) Mach-dependent `Cd` as the historical default. Explicit constant `Cd*A` remains supported. A 2026 `shape_specific` option now uses Appendix-A nose profiles with a modified-Newtonian high-Mach pressure-drag model blended with the thesis law.

## What this does *not* yet calculate

This is a **preliminary-design** tool. Implemented capabilities are intentionally separated from higher-fidelity analyses that remain outside scope. It does not claim:

- full trajectory coupling for parallel boosters/overlapping burns (mass/performance sizing is implemented);
- historical closure of the Kn=5 -> staged TPBVP trajectory against Vega and Proton K;
- flight-certified structural sizing, engine restart/multi-burn sequencing and full probabilistic uncertainty propagation;
- automatic continuous Delta-V allocation (the discrete booster optimizer can search user-supplied allocations, but does not invent the missing historical 23-point Ariane sequence).

The menu asks for orbit altitude and optional diameter because the mission configuration will be reused by the future full model. Until mass and trajectory are coupled, **orbit altitude is informational** and Delta-V is explicitly prescribed. A converged mass calculation is not evidence that an orbit is achievable.

## Validation and provenance

- The recovered MATLAB files are development evidence, not a final reference implementation.
- The Vega preset reproduces *inputs* from the recovered four-stage development file, not a certified outcome.
- The original thesis's Vega and Proton results are independent targets for future integrated regression tests.
- Unit and physics-invariant tests run under GitHub Actions on every pull request.
- Keep legacy behaviour, thesis scientific intent and genuinely new modelling choices separately documented.


See [`../ROADMAP.md`](../ROADMAP.md) for the implementation sequence based on the thesis Future Work and for the AI-assisted development policy.
