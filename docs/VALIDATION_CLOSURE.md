# Validation Closure — v0.9

This document closes the historical validation phase of the public reconstruction of **A Tool for Preliminary Design of Rockets**.

## What “closure” means

Validation closure does **not** mean forcing the 2026 reconstruction to reproduce every number printed in the 2014 thesis. The final 2014 MATLAB source has not been recovered, the surviving files are unfinished development versions, and some surviving values conflict with the dissertation.

A historical target is therefore closed when it is placed in one of these reproducible categories:

- **verified** — a thesis table/equation can be reproduced from the published values;
- **reconstructed** — the public 2026 code reproduces the requested physical/numerical diagnostic;
- **not reproduced** — the public reconstruction runs but does not reproduce the historical value;
- **provenance gap** — surviving thesis/source evidence is insufficient or internally inconsistent, so no unique implementation can be justified.

No coefficient, Knudsen threshold, thrust convention, payload convention or optimization path is selected simply because it gives a closer historical answer.

Run the complete executable report with:

```matlab
addpath('validation','util','configs')
report = run_validation_closure(struct('print_summary',true));
```

## Vega

### Thesis-internal mass validation

Chapter 6 Table 6.4 reports a Vega first-section reference mass of **132,530 kg** and a simulated value of **126,085 kg**. Applying thesis Eq. (6.1) gives approximately **4.86%**, consistent with the printed **4.8%** after table rounding.

The stage propellant/structural deviations and the Table 6.5 length/volume deviations are stored as machine-readable validation fixtures and re-evaluated in CI. Most reproduce Eq. (6.1) to the printed rounding, but two structural cells do not. Stage 3: 833 kg vs 906.2 kg gives about 8.79%, while Table 6.4 prints 8.1%. Stage 4: 418 kg vs 175.6 kg gives about 57.99%, while the table prints 57.6%. The repository preserves both as published arithmetic/transcription anomalies rather than changing source values.

There is one explicit Table 6.4 convention ambiguity in the final AVUM `m0` cell. The printed component masses imply **692.2 kg** before payload; adding the 1,500 kg payload gives **2,192.2 kg**. The printed **11.8%** deviation is consistent with the no-payload convention. Both values are preserved and the ambiguous cell is excluded from the automatic table-rounding assertion.

**Classification: verified source transcription, with two structural arithmetic/transcription anomalies and one documented Stage-4 `m0` convention ambiguity.**

### Atmospheric trajectory

The thesis reports:

- gravity-turn start: **500 m**;
- gravity-turn/free-flight transition: **97.1 s**;
- transition criterion: **Kn = 5**;
- total flight time: **357.4 s**;
- maximum dynamic pressure around **9 km** altitude.

With literal Table 6.1 stage inputs and the thesis-stated last-stage-radius Knudsen convention, the reconstruction gives a Kn=5 transition of approximately **143.84 s at 128.8 km**. The lower-atmosphere max-q location is approximately **9.81 km**, which is close to the thesis qualitative landmark even though the Knudsen switch time is not.

The recovered Vega gravity-turn development file uses different masses, **2,440 kN** first-stage thrust rather than Table 6.1's **2,092 kN**, and a **1.9 m** aerodynamic diameter. Those inputs move the transition substantially but still do not reproduce 97.1 s under the thesis Kn=5/radius rule.

**Classification: not reproduced + provenance gap.**

### Three-phase trajectory

The current staged TPBVP can complete the Vega solve, but the last recorded CI baseline gives roughly:

- total time: **310.584 s** vs 357.4 s;
- last-stage propellant remaining: **98.45%** vs the thesis trajectory-validation value of 34%;
- circular-orbit acceptance: **false**.

This is deliberately retained as a failed historical reproduction rather than tuned away.

**Classification: not reproduced.**

## Proton K / DM-3

### Thesis-internal mass validation

Chapter 6 Table 6.6 reports:

- reference first-section mass: **668,577 kg**;
- simulated first-section mass: **626,563 kg**;
- printed deviation: **6.3%** in the table and **6.2%** in the prose.

Eq. (6.1) gives approximately **6.28%**, explaining both rounded presentations. The stage mass and Table 6.7 geometry deviations are reproduced by the executable validation fixture.

**Classification: verified.**

### Literal trajectory contradiction

The thesis states that the DM-3 is not fired and is carried as additional payload. If the Table 6.2 first-stage thrust (**3,492 kN**) is combined literally with that vehicle/payload convention, the current fixture computes lift-off **T/W ≈ 0.504**. Such a vehicle cannot lift off.

The recovered development test instead uses:

- first-stage thrust **6 × 1,470 kN = 8,820 kN**;
- different Isp values;
- second-stage burn time 210 s instead of the printed 327 s;
- a 4.1 m aerodynamic diameter;
- an initial-mass convention that does not include the stated 19,360 kg mission payload.

Under the recovered-development convention, the vehicle lifts off and the reconstructed Kn=5 event occurs at approximately **198.05 s**, not the thesis **153 s**.

**Classification: provenance gap + not reproduced.**

### Three-phase trajectory

For the recovered-development Proton interpretation, the staged `bvp4c` TPBVP currently terminates with a singular collocation Jacobian rather than a validated orbit solution.

This is reported as a numerical reconstruction outcome. It is not converted into a pass by changing historical inputs.

**Classification: not reproduced.**

## Ariane 5 optimization

Ariane 5 is different from Vega/Proton: Chapter 6 explicitly presents it as an **optimization study**, not a validation requiring the optimized launcher to reproduce the original Ariane.

The thesis reports:

- original vehicle mass: **764,140 kg**;
- optimized vehicle mass: **680,076.5 kg**;
- reduction: **84,063.5 kg**, approximately **11%**;
- optimum core diameter: **3.9 m**;
- stage thrust values: **1,700 kN** and **58.5 kN**;
- Delta-V division: **25% / 49% / 26%**;
- two boosters;
- booster thrust printed as **8,000 kN**;
- booster diameter: **2.625 m**;
- booster burn fraction: **25%**;
- total flight time: **462.8 s**;
- end of gravity turn: **111.5 s**, **120.4 km**, gamma **58.9 deg**.

Tables 6.11 and 6.12 are machine-readable. Table 6.11 mass deviations and Table 6.12 volume deviations reproduce Eq. (6.1) within printed rounding. Two Table 6.12 length cells do not: using the printed reference/simulated lengths gives about 78.49% for Stage 1 and 57.75% for Stage 2, while the table prints 44% and 36.6%, respectively. These are preserved as published table anomalies.

### Unrecoverable optimization path

Table 6.9 states that **23 Delta-V division points** contributed to a total of **170 simulations**, but the thesis does not specify the exact 23-point sequence. The public repository therefore preserves:

```matlab
delta_v_sequence = []
```

rather than inventing a path that happens to include the reported optimum.

The interpretation of the reported 8,000 kN booster thrust is also preserved as an explicit 2026 inference: the generalized fixture treats it as per physical booster, because the original ~14,000 kN figure appears to describe the pair and the stated +14% search range is compatible with roughly 2 × 8,000 kN.

**Classification: verified thesis optimum + provenance gap for exact search history.**

### 2026 generalized mass benchmark

Running the same two named Ariane configurations through the generalized 2026 parallel-booster sizing model gives approximately:

- original-point GLOW: **720,187 kg**;
- reported-optimum-point GLOW: **502,891 kg**;
- reduction between those two 2026 model points: **30.17%**.

This is **not** evidence that the 2014 optimization should have achieved a 30% reduction. The modern component aggregation, booster interpretation and Delta-V treatment differ from the lost final 2014 implementation, and the exact historical 23-point Delta-V sequence is unavailable. These numbers are retained as a modern-model comparison baseline only.

### Reconstructed booster trajectory

The generalized booster model closes mass accounting and reaches the Knudsen transition. The recent CI baseline reports max-q around **136.6 kPa** and preliminary heat flux around **77.8 kW/m²**. Its staged free-flight TPBVP currently fails with a singular Jacobian, so the public code does not claim to reproduce the 462.8 s historical optimized trajectory.

**Classification: implemented benchmark, historical trajectory not reproduced.**

## Closure decision

The Chapter 6 validation campaign is considered **closed with documented provenance gaps**.

That status is stronger and more reproducible than declaring success from manually selected parameters:

| Case | Thesis tables | Atmospheric reconstruction | Full trajectory | Provenance |
| --- | --- | --- | --- | --- |
| Vega | Verified with published table anomaly | Not reproduced | Not reproduced | Conflicting recovered development inputs |
| Proton K | Verified | Literal inputs cannot lift off; recovered inputs differ | Not reproduced | Table/source thrust, Isp, mass conventions conflict |
| Ariane 5 | Verified with Table 6.12 length anomalies | Booster path implemented | Not reproduced end-to-end | Exact 23-point Delta-V path unavailable |

These outcomes are regression-tested. If future source files are recovered, they can change a provenance classification only by supplying new evidence.

## What remains after v0.9

Remaining work is no longer “finish the 2014 program.” It is one of two categories:

1. **new historical evidence** — e.g. recovering `RocketDynEq.m` or the lost final optimization driver;
2. **modern model validation** — calibrating the 2026 engine, aerodynamic, solid-grain, cost and mission extensions against independent engineering datasets.

Neither category blocks the historical validation closure recorded here.
