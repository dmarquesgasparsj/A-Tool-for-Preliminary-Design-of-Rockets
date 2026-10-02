# Future Work Extensions Implemented in 2026

This document records the implementation of the propulsion, aerodynamics, trajectory-constraint and booster items proposed in the 2014 thesis Future Work. It deliberately distinguishes thesis-derived equations from new 2026 modelling choices.

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

Constraint histories remain independently evaluable. In addition, the modern ascent path can use `constraint_aware_throttle.m` to reduce thrust near configured q/heating/bending/axial limits. This is transparent preliminary control logic, not flight-certified GNC.

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

These features are **implemented**, but historical reconstruction and modern engineering validation are distinct questions.

- geometry/skin: equation regression-tested; historical 33 mm input remains a modelling caveat;
- pressure nozzle: equation and sea-level/vacuum behaviour regression-tested; engine-specific external calibration remains a modern validation task;
- constraints: histories, pass/fail logic and preliminary active throttle response are regression-tested;
- booster trajectory: mass closure and atmospheric coupling are regression-tested; the Ariane Chapter 6 end-to-end disagreement is now classified in [VALIDATION_CLOSURE.md](VALIDATION_CLOSURE.md), rather than left as an open historical target.

No coefficient is tuned merely to reproduce a historical result.


## 5. Calibrated multi-parameter engine mass

Implementation: `util/estimate_engine_mass.m`.

The recovered thesis MER remains available unchanged. A new reference-engine power-law option can scale engine mass with thrust, chamber pressure, nozzle area ratio and mixture ratio. The model intentionally contains **no hidden universal exponents**: reference values and exponents must be supplied from an identified calibration dataset.

This closes the software capability requested by the thesis Future Work without presenting an arbitrary correlation as a physical law.

## 6. Shape-specific nose-cone drag

Implementations:

- `util/thesis_nose_cone_geometry.m`
- `util/nose_cone_drag_coefficient.m`
- `util/aerodynamic_drag.m`

The Appendix-A ogive, power, ellipse and Haack profiles now feed a modified-Newtonian forebody pressure model at high Mach number. Because modified Newtonian theory is a hypersonic approximation, the implementation smoothly blends from the thesis-wide `Cd(Mach)` fit between configurable Mach limits. Viscous, base and clustered-body interference drag remain explicit higher-fidelity additions rather than hidden corrections.

The historical thesis drag law is preserved as a separate option for regression.

## 7. Solid-propellant grain geometry

Implementation: `util/solid_grain_ballistics.m`.

The generalized solid-motor extension supports:

- inhibited cylindrical-core grains;
- BATES grains;
- end-burning grains;
- arbitrary density and Saint-Robert burn-law coefficients;
- quasi-steady chamber-pressure solution from burn area and throat area;
- optional pressure-aware nozzle thrust history.

This is a conceptual internal-ballistics model. Combustion instability, erosive burning, cracks, ignition transients and structural grain stress are outside its fidelity.

## 8. Active constraint response

Implementation: `util/constraint_aware_throttle.m`, integrated by `equations_of_motion.m` and `simulate_gravity_turn.m`.

When stage limits are configured, the modern ascent model can respond during integration rather than only flag violations after the flight. Axial acceleration produces an instantaneous thrust ceiling; q, heat-flux and preliminary bending limits produce soft-limit throttle commands. Stage burnout is detected from remaining propellant mass, so reduced throttle correctly lengthens burn duration.

This control law is intended for preliminary design sensitivity studies, not operational guidance certification.


## 9. Fairing, interstage, adapter and wiring components

Implementation: `util/estimate_secondary_structure.m`.

The fairing can use the original thesis Eq. (4.16) from its Appendix-A surface geometry. For interstages, the thesis explicitly states that the Akin model had no dedicated MER and that interstage mass could be included in the lower-stage structural mass. The 2026 extension therefore does **not** invent a historical coefficient: interstage and payload-adapter mass use explicit frustum geometry plus user-supplied areal density or material density/thickness. Wiring likewise requires an explicit linear-density calibration.

This structure is compatible with a future external component database while keeping empirical data separate from equations.

## 10. Per-stage propellant reserve and dry-mass margins

Implementations:

- `util/stage_mass_with_reserve.m`
- `util/thesis_iterative_mass_model.m`
- `util/modern_stage_mer.m`

The reserve model solves the rocket equation analytically with a defined fraction of stage propellant remaining at burnout, rather than simply multiplying the final mass after sizing. A zero reserve reduces exactly to the historical thesis stage equation. The trajectory adapters convert reserve propellant into non-burned carried mass, so the mass closes consistently through burnout and separation.

An optional dry-mass margin is applied transparently to the sum of modeled dry components. Both margins default to zero and must be explicitly configured.
