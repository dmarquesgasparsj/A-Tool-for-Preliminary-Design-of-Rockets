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

`main()` offers the new generalized menu alongside the existing simplified trajectory demonstration. The existing `main(payload_kg, orbit_altitude_km)` and `run_design()` APIs remain available for compatibility; **they are not yet using the modern iterative mass model**.

The interactive menu is optional. The entire mass calculation can be run from a script or test without windows, global variables or hard-coded filenames.

## Stage count and propellants

The mathematical model accepts any **positive integer number of serial stages**. Practical feasibility is constrained by the mass-ratio equations and the selected MER assumptions, not by branches like `propellant_2`, `propellant_3` and `propellant_4`.

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

For liquid and hybrid stages, a separate nozzle mass is not added by default because the engine MER already depends on nozzle area ratio. Fairing and insulation are added when areas are supplied. The tank and casing coefficients are low-fidelity parametric estimates, especially for custom fuels. The separate nozzle rule and hybrid casing rule are modern choices requiring validation.

## What this does *not* yet calculate

This is a **generalized serial-stage preliminary mass model**, not yet a complete launcher optimizer. It currently does not calculate:

- parallel boosters or overlapping burns;
- closed-loop coupled flight trajectory, aerodynamic/gravity losses, or actual orbit insertion;
- stage skin thickness, interstage structure and full geometry;
- engine throttle, multi-burn profiles, propellant residuals, or uncertainty margins;
- an optimum Delta-V allocation (the user supplies the allocation).

The menu asks for orbit altitude and optional diameter because the mission configuration will be reused by the future full model. Until mass and trajectory are coupled, **orbit altitude is informational** and Delta-V is explicitly prescribed. A converged mass calculation is not evidence that an orbit is achievable.

## Validation and provenance

- The recovered MATLAB files are development evidence, not a final reference implementation.
- The Vega preset reproduces *inputs* from the recovered four-stage development file, not a certified outcome.
- The original thesis's Vega and Proton results are independent targets for future integrated regression tests.
- Unit and physics-invariant tests run under GitHub Actions on every pull request.
- Keep legacy behaviour, thesis scientific intent and genuinely new modelling choices separately documented.
