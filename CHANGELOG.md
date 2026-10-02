# Changelog

This file distinguishes the **original 2014 research and MATLAB tool** from the later public reconstruction and maintenance of the repository.

The Git commit dates reflect when the public reconstruction was created or modified. They do not replace the historical date of the underlying MSc work.

## Original research — 2014

Developed for the MSc thesis *A Tool for Preliminary Design of Rockets* at Instituto Superior Técnico.

Scientific and engineering functionality documented in the thesis included:

- preliminary sizing of multistage launch vehicles;
- two to four serial stages;
- optional parallel boosters;
- stage sizing from assigned `Delta-V` using the Tsiolkovsky equation;
- structural-factor iteration with Mass Estimation Relationships (MERs);
- propellant selection and density data;
- launcher mass and dimension estimation;
- fairing sizing;
- vertical ascent and atmospheric gravity turn;
- Mach-dependent drag coefficient;
- U.S. Standard Atmosphere models;
- Knudsen-number criterion for the atmospheric/exo-atmospheric transition;
- optimized free-flight phase using an indirect TPBVP formulation;
- iterative coupling of trajectory losses and the mass model;
- validation with Vega and Proton K;
- Ariane 5 design-parameter optimization.

Historical thesis results included:

- Vega GLOW deviation: 4.8%;
- Proton K GLOW deviation: 6.2%;
- Ariane 5 optimization: approximately 84 t / 11% GLOW reduction relative to the reference configuration used in the study.

## Public reconstruction — 2025

- Created the public GitHub repository.
- Reintroduced a simplified MATLAB/Octave staged-ascent model.
- Added basic configuration files and trajectory utilities.
- Established a starting point from which the thesis model could be recovered.

## Restoration and maintenance — 2026

### Numerical core

- Fixed the trajectory grid search so that it spans the requested bounds.
- Confined local trajectory refinement to physical parameter bounds.
- Replaced the fixed payload search ceiling with adaptive bracketing and bisection.
- Improved orbit-attainment evaluation across the simulated trajectory.
- Added launcher-configuration validation and normalized structural-mass handling.
- Added stage event/history data to support later mass-model/trajectory coupling.

### Testing and documentation

- Added initial MATLAB regression tests.
- Rewrote the README to distinguish the original 2014 scientific work from the public reconstruction.
- Added explicit documentation of the thesis architecture and reconstruction policy.
- Added an open-source licence.

### 2026 completion status

The repository now contains implementations for the structural-factor / MER mass model, propellant and geometry data, serial and parallel staging, thesis `Cd(Mach)`, Knudsen transition, staged TPBVP free flight, coupled `Delta-V` feedback, Future-Work propulsion/aerodynamic/constraint extensions, air/inclined launch, cost studies and preliminary GEO/interplanetary analysis.

The remaining open work is primarily **validation and provenance closure**: reproducing Vega, Proton K and Ariane 5 end-to-end results where surviving 2014 evidence permits it, quantifying uncertainty, and calibrating modern empirical extensions against external datasets.
