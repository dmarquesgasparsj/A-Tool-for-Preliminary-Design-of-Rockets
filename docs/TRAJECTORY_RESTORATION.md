# Trajectory Restoration

This document tracks the reconstruction of the 2014 trajectory model and distinguishes historical equations from 2026 integration infrastructure.

## Restored thesis components

The repository now contains:

- the thesis sixth-order `Cd(Mach)` polynomial (Eq. 3.49);
- Appendix A nose-cone geometry functions for ogive, power, ellipse and Haack profiles;
- an independently implemented extended atmosphere/Knudsen model up to 2000 km;
- a historical vertical-ascent + gravity-turn propagator using the thesis equations;
- event termination at the thesis atmospheric/exo-atmospheric boundary, `Kn = 5`;
- the minimum-time free-flight TPBVP using the printed state/costate equations and `bvp4c`;
- a modern staged extension of the TPBVP for an arbitrary remaining serial-stage burn schedule;
- a bridge from the generalized mass model to the historical atmospheric and TPBVP trajectory.

## End-to-end reconstruction path

```text
thesis_iterative_mass_model
        |
        v
thesis_trajectory_config_from_mass_result
        |
        v
simulate_thesis_2014_atmospheric_phase
  vertical -> gravity turn -> Kn = 5
        |
        v
build_free_flight_schedule
        |
        v
thesis_staged_free_flight_tpbvp
        |
        v
circular-orbit target
```

The convenience function `simulate_thesis_2014_trajectory()` executes this chain.

## Provenance

The aerodynamic polynomial, gravity-turn equations, Knudsen boundary and TPBVP formulation are derived from the 2014 thesis. The recovered thesis-era files `ascent_odes_tf.m` and `ascent_bcs_tf.m` provide additional evidence about the numerical implementation.

The staged TPBVP scheduler and schema adapters are 2026 reconstruction infrastructure. They are not represented as original 2014 source.

The recovered extended-atmosphere MATLAB file contains an explicit third-party copyright notice. It is **not** copied into the MIT-licensed source tree. The public `thesis_extended_atmosphere.m` is an independent implementation informed by the thesis and cross-checked against recovered layer data.

## Historical validation closure

Historical validation is now closed as a **forensic reconstruction**, not as a claim of exact reproduction. The executable report is `validation/run_validation_closure.m`; the findings are documented in [VALIDATION_CLOSURE.md](VALIDATION_CLOSURE.md).

The remaining disagreements are classified rather than left as an undefined backlog:

- Vega Kn=5 timing and final-stage reserve are not reproduced;
- literal Proton Table 6.2 inputs cannot lift off, while recovered development inputs use a different thrust/Isp/mass convention;
- Proton and Ariane staged TPBVP cases can encounter singular collocation Jacobians;
- the exact Ariane 23-point Delta-V search sequence is absent from the surviving record;
- the six-state recovered `ascent_odes_tf.m` and the eight-state thesis PMP derivation remain distinct pieces of historical evidence.

Future work on these items requires new historical evidence or a deliberately new numerical method; neither should be presented as recovery of the lost final 2014 implementation.

## Current use

For the generalized 2026 mass model:

```matlab
cfg = general_launcher_preset('illustrative_two_stage');
mass = thesis_iterative_mass_model(cfg);
traj = simulate_thesis_2014_trajectory(cfg, mass);
```

A failed TPBVP solve is returned as an explicit trajectory status rather than being interpreted as a valid orbital solution.


## 2026 extensions now implemented

The historical trajectory reconstruction remains unchanged for regression. The modern trajectory path additionally supports:

- shape-specific Appendix-A nose drag using a modified-Newtonian hypersonic extension;
- max-q, heat-flux, bending and axial-acceleration evaluation;
- active preliminary constraint-aware throttling;
- pressure-aware thrust;
- inclined and air-launch initial conditions;
- deterministic and stochastic thrust-misalignment analysis.

These additions must not be interpreted as recovered 2014 behavior.
