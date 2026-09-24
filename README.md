# A Tool for Preliminary Design of Rockets

MATLAB software originally developed in **2014** as part of my MSc thesis in Aerospace Engineering at **Instituto Superior Técnico (IST), University of Lisbon**, under the supervision of **Prof. Paulo J. S. Gil**.

The original work developed a preliminary launch-vehicle design tool coupling a **mass model** with an **ascent trajectory model**. For a prescribed payload and target orbit, the program explored launcher configurations and design parameters with the objective of reducing **Gross Lift-Off Weight (GLOW)** and increasing the **payload ratio**.

> **Original research and software:** 2014  
> **Public GitHub reconstruction:** 2025  
> **Maintenance, testing and restoration:** 2026–present

The scientific model, equations, design logic and historical validation cases described here originate from the 2014 thesis. The present GitHub repository is a public reconstruction and ongoing improvement of that work. Some thesis-era MATLAB **development prototypes** have since been recovered; they are not assumed to be the final source. Original research, source recovery and later modelling/software improvements are documented separately.

## Original 2014 model

The thesis tool was organised around two coupled parts:

1. **Mass model**
   - two to four serial stages;
   - optional parallel boosters;
   - Tsiolkovsky-based stage sizing from assigned `Delta-V`;
   - structural-factor iteration;
   - Mass Estimation Relationships (MERs);
   - propellant selection and density data;
   - stage diameter, tank volume and launcher dimensions;
   - fairing sizing and structural-mass estimates.

2. **Trajectory model**
   - vertical ascent;
   - atmospheric gravity turn;
   - transition to exo-atmospheric flight using the Knudsen number;
   - optimized free-flight phase formulated as a Two Point Boundary Value Problem (TPBVP);
   - `ode45` / Runge-Kutta integration and indirect optimal-control formulation;
   - computation of drag and gravity losses;
   - iteration back to the mass model until the design `Delta-V` and trajectory `Delta-V` converged.

For every combination of launcher configuration and design parameters, the complete mass-model/trajectory loop was evaluated. The final design was selected by minimum GLOW / maximum payload ratio.

## Historical validation

The original thesis validated the model against two real launch vehicles and then used it for an optimization study:

| Case | Mission | Thesis result |
| --- | --- | --- |
| **Vega** | 1,500 kg to 700 km circular orbit | GLOW deviation: **4.8%** |
| **Proton K** | 19,360 kg to 200 km circular orbit | GLOW deviation: **6.2%** |
| **Ariane 5 study** | 19.3 t to 200 km | optimized configuration reduced GLOW by about **84 t (11%)** |

The Ariane 5 study varied seven design parameters, including core diameter, thrust, `Delta-V` distribution, number of boosters, booster thrust, booster diameter and booster burn time.

## Repository status

The repository combines research from the 2014 thesis, recovered **unfinished development files**, and a new generalized implementation. The old files provide scientific provenance and regression inputs, not design restrictions. The modern mass model accepts any number of **serial** stages and has a menu-independent programmatic API.

### Recovered / modernized core

- staged 2D trajectory propagation;
- U.S. Standard Atmosphere implementation for the lower atmosphere;
- stage mass accounting and separation events;
- launcher configuration validation;
- bounded trajectory-parameter search;
- adaptive payload bracketing and bisection;
- MATLAB regression tests.

### Original thesis components still being restored

- final end-to-end validation of the modern structural-factor / MER loop against complete thesis launchers;
- propellant database and stage-volume model;
- fairing and launcher geometry model;
- boosters and parallel staging;
- Mach-dependent drag coefficient from the thesis;
- Knudsen-number transition criterion;
- optimized TPBVP free-flight phase;
- coupled `Delta-V` convergence between mass model and trajectory;
- complete Vega, Proton K and Ariane 5 cases.

See [`docs/THESIS_MODEL.md`](docs/THESIS_MODEL.md) for the 2014 architecture and [`docs/RECONSTRUCTION.md`](docs/RECONSTRUCTION.md) for the distinction between recovered thesis functionality and later maintenance.

## Running the current code

For the **new generalized mass model**, open MATLAB in the repository root and run:

```matlab
main
```

Choose *Generalized launcher sizing*. Its dynamic menus let you configure an arbitrary number of serial stages and select existing or custom propellants. You can also bypass the menus entirely:

```matlab
cfg = general_launcher_preset('illustrative_two_stage');
result = run_thesis_sizing(cfg);
```

For custom missions, use `make_launcher_config(mission, stages)` and `run_thesis_sizing(mission, stages)`. See [Generalized design](docs/GENERALIZED_DESIGN.md) for the complete API and physical assumptions. This is preliminary **mass sizing**: target orbit altitude is metadata until the trajectory and mass models are coupled.

The earlier simplified trajectory demonstration remains accessible from the second `main` menu option or programmatically:

```matlab
[result, history] = run_design(1000, 200);
```

where those inputs are payload mass in kilograms and target orbit altitude in kilometres.

## Tests

Run the current regression tests from MATLAB with:

```matlab
results = runtests('tests');
table(results)
```

As the original model is restored, the historical Vega, Proton K and Ariane 5 results will become end-to-end regression tests.

## Repository layout

```text
configs/      launcher configurations
util/         numerical and physical-model functions
tests/        MATLAB regression tests
docs/         thesis-model and reconstruction documentation
main.m        interactive entry point
run_design.m  programmatic entry point
```

The structure will evolve as the mass model, aerodynamics and validation cases are improved and integrated. Large file moves are intentionally postponed until the scientific model is stable, so that the reconstruction remains easy to review against the thesis.

## Project history

- **July 2014 — MSc thesis:** *A Tool for Preliminary Design of Rockets*, Instituto Superior Técnico. The MATLAB tool, mass model, trajectory model, validation studies and Ariane 5 optimization were developed as part of the thesis.
- **2025 — Public GitHub reconstruction:** the project was placed on GitHub and source reconstruction began after the original working code was no longer available.
- **2026 — Restoration and maintenance:** the implementation is being compared systematically with the thesis, missing scientific components are being restored, and regression tests and modern repository tooling are being added.

The Git history records when the public reconstruction was written; it is **not intended to rewrite the chronology of the original 2014 research**.

## Thesis

**Diogo Marques Gaspar**, *A Tool for Preliminary Design of Rockets*, MSc Thesis in Aerospace Engineering, Instituto Superior Técnico, July 2014. Supervisor: Prof. Paulo J. S. Gil.

Thesis record: <https://fenix.tecnico.ulisboa.pt/cursos/meaer/dissertacao/2353642467857>

## License

Released under the [MIT License](LICENSE). The licence applies to the source code in this repository. Academic use should also cite the 2014 thesis above.
