# Future Work Extensions Implemented in 2026

This document records the implementation of four items proposed in the 2014 thesis Future Work. It deliberately distinguishes thesis-derived equations from new 2026 modelling choices.

## 1. Stage geometry and exterior skin mass

**Source:** 2014 thesis, Chapter 5, Eq. (5.4) and Table 5.2.

The restored geometry rule is:

- propellant/tank volume is calculated from propellant mass and density;
- stage envelope volume is `1.10 * V_propellant`;
- a cylindrical envelope is calculated from the user-defined diameter;
- exterior skin mass is `rho_alloy * S * thickness`.

Historical defaults are preserved exactly as printed in the thesis:

- alloy density: 2700 kg/m^3;
- skin thickness: 0.033 m.

The thesis explicitly states that a reliable radius-to-wall-thickness heuristic was not available. Therefore skin mass is **opt-in** in the modern MER (`include_skin_mass=true`) and the 33 mm value is not presented as a modern structural recommendation.

Implementation: `util/thesis_stage_geometry_skin.m`.

## 2. Chamber pressure, exit pressure and nozzle areas

**Motivation:** 2014 thesis Future Work.

This is a **new 2026 extension**, not recovered 2014 source. `pressure_aware_nozzle.m` implements standard choked/isentropic rocket-nozzle relations:

- throat area from `c* = Pc * At / mdot`;
- supersonic exit Mach from `Ae/At`;
- exit pressure from the isentropic pressure relation;
- thrust coefficient and thrust including the ambient-pressure correction;
- throat/exit radii and a conical nozzle length;
- optional shell mass from material density and wall thickness.

NASA Glenn's rocket-nozzle equations are used as an external reference:
https://www1.grc.nasa.gov/beginners-guide-to-aeronautics/thrust-equations-summary/
https://www1.grc.nasa.gov/beginners-guide-to-aeronautics/rocket-thrust-equation/

When explicitly configured, atmospheric thrust changes with ambient pressure. Free-flight schedules use the corresponding vacuum thrust.

For liquid/hybrid stages, nozzle shell mass is not added by default because the existing engine MER already contains a nozzle-area-ratio term; this avoids hidden double counting.

## 3. Trajectory constraints

**Motivation:** 2014 thesis Future Work explicitly proposed maximum dynamic pressure, heat flux, bending load and axial acceleration.

Implementation: `util/evaluate_trajectory_constraints.m`.

The evaluator reports histories, peaks, limit margins and an overall pass/fail result for:

- dynamic pressure;
- stagnation-point convective heat flux;
- preliminary bending moment;
- axial structural acceleration.

Dynamic pressure is already part of the reconstructed ascent model.

Heat flux is a **2026 extension** using the Sutton-Graves correlation for Earth:

`qdot = k * sqrt(rho / Rnose) * V^3`

with `k = 1.7415e-4` in SI units by default.

NASA aerothermodynamics course reference:
https://tfaws.nasa.gov/TFAWS12/Proceedings/Aerothermodynamics%20Course.pdf

Bending uses a deliberately simple preliminary normal-force relation:

`N = q * Aref * Cn_alpha * |alpha|`

and `M = N * lever_arm`. Angle of attack and lever arm are explicit inputs rather than hidden assumptions.

Axial load is reported as `(T-D)/(m*g0)`. This is a structural specific-force diagnostic, not the inertial flight-path acceleration.

Current constraints are evaluators: they reject/flag a configuration but do not yet command throttle or alter guidance automatically.

## 4. Parallel-booster trajectory coupling

The thesis represents boosters and the core burning together as a **zeroth stage**. The 2026 generalized implementation turns the mass result into an equivalent flight sequence:

1. virtual zeroth stage = all booster propellant + core propellant burned during overlap;
2. at booster burnout, only booster dry mass is jettisoned;
3. the core continues with its remaining propellant;
4. serial upper stages follow normally.

This representation closes mass exactly and lets the existing reconstructed trajectory chain operate without a separate Ariane-specific solver:

`vertical ascent -> gravity turn -> Kn = 5 -> staged TPBVP -> target orbit`

The virtual phase's aerodynamic reference area currently defaults to the sum of core and booster frontal areas. This is an explicit preliminary assumption and can be replaced by a more detailed clustered-body aerodynamic model later.

Implementations:

- `util/parallel_booster_trajectory_config.m`
- `util/simulate_parallel_booster_trajectory.m`

## Validation status

These features are **implemented**, but implementation and validation are distinct milestones.

- geometry/skin: equation regression-tested; historical 33 mm input remains a modelling caveat;
- pressure nozzle: equation and sea-level/vacuum behaviour regression-tested; engine-specific validation remains;
- constraints: histories and pass/fail logic regression-tested; active guidance/throttle response remains;
- booster trajectory: mass closure and atmospheric coupling regression-tested; Ariane 5 historical end-to-end agreement remains a validation target.

No coefficient is tuned merely to reproduce a historical result.
