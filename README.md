# MATLAB Toolkit — Preliminary Rocket Design

**Language:** English  
**Purpose:** Rebuild and modernize the preliminary launch-vehicle design tool developed in the author's Master's thesis, while keeping the code modular, testable and usable in MATLAB/Octave.

> ⚠️ **Current status:** the repository presently contains a simplified 2D staged-ascent model. It is being progressively extended toward the fuller thesis architecture (mass sizing ↔ trajectory iteration, configuration trades, boosters and validation cases).

## How to use
1. Open `main.m` in MATLAB/Octave.
2. Choose the configuration in `run_design.m` (currently `demo_config`).
3. Run `main.m` or call `run_design(payload_kg, orbit_alt_km)`.
4. The current implementation:
   - loads a staged launcher configuration;
   - validates stage data and normalizes structural masses;
   - searches the full trajectory-design domain for pitch timing, kick angle and kick duration;
   - refines that solution using bounded variables with `fminsearch`;
   - finds the maximum feasible payload using an adaptive upper bound plus bisection;
   - evaluates circular-orbit conditions across all trajectory samples at or above the target altitude;
   - reports payload ratio and trajectory histories.

## Repository structure
- `configs/` — launcher definitions.
- `util/` — atmosphere, equations of motion, guidance, configuration validation and optimization helpers.
- `tests/` — MATLAB regression tests.
- `main.m` — optional GUI entry point.
- `run_design.m` — programmatic design entry point.

## Current physical model
- 2D polar equations of motion with spherical-Earth gravity `mu/r^2`.
- Initial eastward velocity from Earth rotation and launch latitude.
- 1976 U.S. Standard Atmosphere layers to ~85 km, followed by an isothermal extrapolation.
- Constant thrust and specific impulse per stage.
- Constant `CdA` per stage.
- Sequential stage burns and stage-structure jettison.
- Guidance: vertical ascent → finite pitch kick → thrust aligned with velocity (gravity turn).

## Current limitations
The present code is **not yet the complete thesis tool**. In particular it does not yet include:
- the thesis mass-estimation loop and Mass Estimation Relationships (MERs);
- iterative vehicle geometry/dimensions;
- side boosters and parallel burns;
- Mach-dependent drag coefficients;
- the high-altitude/free-flight optimal-control phase;
- the coupled design ↔ trajectory ΔV convergence loop;
- the Vega, Proton K and Ariane 5 validation/optimization cases.

## Reconstruction roadmap
The intended sequence is:
1. **Numerical/core reliability** — configuration validation, bounded trajectory optimization, robust payload bracketing, orbit-condition metrics and regression tests. **In progress / first pass complete.**
2. **Mass model** — implement the thesis structural-factor/MER sizing loop and expose stage geometry and mass breakdowns.
3. **Vehicle architecture** — support arbitrary stages, boosters and parallel propulsion events.
4. **Aerodynamics** — add reference geometry and `Cd(Mach)` instead of constant `CdA`.
5. **Three-phase ascent** — recover vertical ascent, gravity turn and optimized free-flight phase.
6. **Coupled convergence** — iterate mass sizing and trajectory losses until the required ΔV converges.
7. **Historical validation** — reproduce the thesis cases for Vega, Proton K and Ariane 5 and track deviations as regression tests.

## Tests
From the repository root in MATLAB:

```matlab
results = runtests('tests');
table(results)
```

The test suite will grow with each recovered thesis component, with the historical launcher results eventually acting as end-to-end regression tests.

---
This toolkit stems from the author's Master's thesis available at: <https://fenix.tecnico.ulisboa.pt/cursos/meaer/dissertacao/2353642467857>.
