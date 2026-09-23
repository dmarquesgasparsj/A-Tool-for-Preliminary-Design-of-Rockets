# Recovered Thesis-Era MATLAB Source

In September 2026, a set of MATLAB files from the original thesis project was recovered. These files materially improve the fidelity of the public reconstruction because they expose implementation decisions that were only partially described in the dissertation.

## Recovered source groups

### Main design flow

- `InputMenu.m`
- `mass_model_n_2.m`
- `mass_model_n_2_it.m`
- `mass_model_n_3.m`
- `mass_model_n_3_it.m`
- `mass_model_n_4.m`
- `mass_model_n_4_it.m`

These files confirm the original mission-to-design sequence:

1. read payload and target altitude;
2. compute circular-orbit velocity;
3. start with estimated drag and gravity losses;
4. select stage propellants;
5. run the stage mass model;
6. run the gravity-turn trajectory;
7. update the Delta-V loss estimate and repeat.

### Propellant menus

- `propellant_2.m`
- `propellant_3.m`
- `propellant_4.m`

The recovered files contain the selectable propellant combinations, mixture ratios and stage-dependent Isp efficiency factors used by the thesis-era implementation.

### Trajectory and validation scripts

Recovered files include generic and vehicle-specific gravity-turn scripts for Vega and Proton. They expose the masses, thrust levels, burn times, stage-change delays and gravity-turn start altitude used during development and validation.

### Optimal-ascent files

- `ascent_odes_tf.m`
- `ascent_bcs_tf.m`

These files contain state/costate differential equations and final-boundary conditions for the free-flight optimal-ascent problem.

### Atmosphere source

A recovered `atmosphere.m` file implements the extended atmosphere, Mach, Reynolds and Knudsen-number calculations up to 2000 km.

The recovered atmosphere file carries an explicit third-party copyright notice (Ashish Tewari, 2006). For that reason, the public repository should not silently relicense that exact historical file under the repository MIT licence. The reconstruction can reproduce the documented physical model independently while preserving attribution and provenance.

## Structural-mass logic recovered from source

The source resolves an ambiguity that remained after reading the thesis alone.

For each candidate structural factor, the legacy program:

1. computes structural and propellant mass using the Tsiolkovsky/epsilon equations;
2. computes a heuristic structural mass from component MERs;
3. compares the two structural masses;
4. accepts epsilon when the ratio is approximately within 10 percent;
5. scans epsilon from 0.05 to 0.17 in steps of 0.01.

For the recovered four-stage implementation, the heuristic structural mass includes:

- fuel tank mass;
- oxidizer tank mass;
- avionics;
- thrust structure;
- nozzle;
- engine.

The source also reveals several implementation-specific assumptions and inconsistencies. These are preserved in explicitly named `legacy` recovery functions and should not be silently treated as improved physics.

## Vega values recovered from source

The four-stage source contains the following hard-coded development case:

- payload: 1500 kg;
- Delta-V estimate: 9200 m/s;
- Isp: 280 / 289 / 294 / 317 s;
- thrust: 2092 / 959 / 230 / 2.2 kN;
- initial Delta-V distribution: 20 / 25 / 40 / 15 percent;
- nozzle area ratios: 20 / 30 / 60 / 100.

These values are now stored separately as `validation/vega_2014_legacy_inputs.m`.

## Reconstruction rule

Where recovered source and the thesis differ in detail, both should be retained:

- **legacy recovery**: reproduce what the original MATLAB source actually did;
- **thesis model**: reproduce the scientific method described in the dissertation;
- **modern model**: later corrections or improvements, explicitly labelled as such.

This three-layer distinction lets the repository preserve historical fidelity without perpetuating accidental bugs or undocumented approximations as if they were intended scientific assumptions.
