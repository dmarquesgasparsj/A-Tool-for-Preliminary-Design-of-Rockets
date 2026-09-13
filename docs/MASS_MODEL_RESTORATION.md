# 2014 Mass Model Restoration

This document records the first source-faithful restoration pass of the mass model described in the 2014 MSc thesis *A Tool for Preliminary Design of Rockets*.

## Restored directly from the thesis

The following behaviour is explicitly documented and is now implemented without reinterpretation:

1. The launcher is sized from the **upper stage downward**.
2. The payload of each stage is the mass of everything above that stage.
3. For each stage:

```text
k_n = exp(Delta-V_n / (g Isp_n))

m_s,n = epsilon_n (k_n - 1) / (1 - epsilon_n k_n) * m_pl

m_p,n = (k_n - 1)(1 - epsilon_n) / (1 - k_n epsilon_n) * m_pl
```

4. The stage Delta-V values are assigned from a user-defined Delta-V distribution.
5. Initial structural factors can be taken from the historical database in Table 4.2.
6. The component-level Mass Estimation Relationships stated in section 4.4 are restored as individual equations.
7. The historical propellant properties from Appendix B are available as data.

## MER equations restored

The component equations currently exposed include:

```text
M_thrust_structure = 2.55e-4 T
M_motor_casing     = 0.135 M_prop
M_engine           = 7.81e-4 T + 3.37e-5 T sqrt(A_r) + 59
M_LOX_tank         = 0.0107 M_LOX
M_LH2_tank         = 0.128 M_LH2
M_RP1_tank         = 0.0148 M_RP1
M_avionics         = 10 M0^0.361
M_fairing          = 4.95 A_fairing^1.15
```

The LOX and LH2 insulation equations are also represented when tank surface areas are supplied.

## Deliberately not guessed yet

The thesis states that the heuristic structural mass generates a new structural factor and that the process iterates to a tolerance of 0.1%. However, the written thesis does not completely specify the original source-code rule for deciding which component MERs were included in each propulsion/stage case and how every component was aggregated.

For this reason, the current restoration does **not** silently sum all component estimates and present that as the original algorithm.

The next reconstruction step is to recover this aggregation policy from additional evidence if possible, or to implement an explicitly labelled reconstruction policy that can be tested against the Vega and Proton results.

## Historical validation target: Vega

The repository now includes the thesis reference data for Vega:

- payload: 1,500 kg;
- circular orbit: 700 km;
- four stages: P80, Zefiro 23, Zefiro 9, AVUM;
- reported GLOW deviation of the complete thesis tool: 4.8%;
- reported final-stage unburned propellant in the trajectory validation: 34%.

These values are regression targets. The repository should only claim reproduction of the thesis result when the restored model produces it within a stated tolerance.

## Files

- `util/thesis_stage_mass.m` — equations 5.1-5.3.
- `util/thesis_mass_model.m` — upper-to-lower multistage stacking.
- `util/thesis_mer_components.m` — component MER equations.
- `configs/thesis_structural_factor_database.m` — Table 4.2.
- `configs/thesis_propellant_database.m` — Appendix B / Table B.1.
- `validation/vega_2014_reference.m` — historical Vega reference case.
- `tests/test_thesis_mass_model.m` — regression/invariant tests.

## Modern maintenance

Automated MATLAB testing through GitHub Actions is a 2026 maintenance addition. It is not part of the historical scientific model.
