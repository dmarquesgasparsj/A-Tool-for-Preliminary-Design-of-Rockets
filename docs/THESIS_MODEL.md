# Original Thesis Model (2014)

This document summarizes the software architecture and numerical model described in the MSc thesis **A Tool for Preliminary Design of Rockets** (Diogo Marques Gaspar, Instituto Superior Técnico, July 2014).

It is intended as the reference specification for reconstructing the original MATLAB tool. Where the present code differs from this document, the distinction should be treated as either an incomplete reconstruction or a later maintenance decision.

## 1. Design objective

The tool was designed for the preliminary sizing and optimization of a multistage launcher for a specified:

- payload mass;
- target orbit altitude.

For each selected configuration and combination of design parameters, the program calculated launcher masses and dimensions, simulated the ascent trajectory, corrected the required `Delta-V`, and iterated until convergence.

The final configuration was selected to reduce **Gross Lift-Off Weight (GLOW)** and increase the **payload ratio**.

## 2. User-selected design variables

The thesis identifies the following main user inputs / design variables:

- number of stages (two to four);
- number of boosters;
- booster diameter;
- stage diameter;
- nozzle area ratio;
- propellant selection;
- stage thrust;
- booster thrust;
- `Delta-V` distribution between stages.

The Ariane 5 optimization study also varied booster burn time.

## 3. Mission `Delta-V`

The design budget was expressed as:

```text
Delta-V_design = Delta-V_orbit + Delta-V_gravity + Delta-V_drag
```

The circular-orbit velocity was obtained from the gravitational parameter and orbital radius.

Initial estimates of gravity and drag losses were used to start the mass-model iteration. The trajectory subsequently produced updated losses, which were fed back into the design loop.

The complete tool converged when the `Delta-V` used to size the launcher agreed with the `Delta-V` required by the simulated trajectory. The thesis reports a `Delta-V` convergence tolerance of **0.01%**.

## 4. Mass model

### 4.1 Stage sizing

For a given stage `Delta-V`, specific impulse and initial structural factor, the model used the Tsiolkovsky relation and the stage structural factor to estimate structural and propellant masses.

The design proceeded **from the upper stage downward**. For each stage, the payload was the mass of everything above that stage.

The thesis equations are:

```text
k_n = exp(Delta-V / (g Isp_n))

m_s,n = [epsilon_n (k_n - 1) / (1 - epsilon_n k_n)] m_pl

m_p,n = [(k_n - 1)(1 - epsilon_n) / (1 - k_n epsilon_n)] m_pl
```

where `epsilon_n` is the structural factor and `m_pl` is the payload carried by that stage.

### 4.2 Structural-factor iteration

An initial structural factor was selected from the launcher database created during the thesis.

The calculated stage was then compared with heuristic Mass Estimation Relationships (MERs). The resulting structural mass produced a new structural factor, and the process repeated until the structural factor converged.

The thesis reports a structural-factor convergence tolerance of **0.1%**.

### 4.3 MERs documented in the thesis

The original model used / discussed heuristic estimates for components including:

- thrust structure;
- solid rocket motor casing;
- engine mass;
- oxidizer tank;
- fuel tank;
- tank insulation;
- fairing;
- avionics;
- external stage structure.

Examples documented in the thesis include:

```text
M_thrust_structure = 2.55e-4 T
M_motor_casing     = 0.135 M_prop
M_LOX_tank         = 0.0107 M_LOX
M_LH2_tank         = 0.128 M_LH2
M_RP1_tank         = 0.0148 M_RP1
M_avionics         = 10 M0^0.361
```

The engine MER additionally depended on thrust and nozzle area ratio.

### 4.4 Geometry

Launcher dimensions were calculated in parallel with the mass model.

For each stage:

- propellant mass and density provided propellant volume;
- stage volume was estimated from tank volume;
- diameter was user-defined;
- length followed from volume and diameter;
- external structural mass was estimated from surface area, material density and wall thickness.

The fairing was included in the upper stage. Multiple nose-cone geometries were documented: Ogive, Power, Ellipse and Haack.

## 5. Boosters / parallel staging

The thesis explicitly supported boosters burning in parallel with the first stage.

A combined “zeroth stage” represented the period during which boosters and the first stage burned simultaneously. After booster burnout and jettison, the remaining first stage continued its burn.

Booster burn time was explored as a fraction of first-stage burn time.

## 6. Trajectory model

The ascent was divided into three principal phases.

### 6.1 Vertical ascent

The launcher lifted off vertically. For the thesis simulations, the gravity turn began at approximately **500 m**, although this value was identified as a possible design parameter.

A lift-off thrust-to-weight requirement of approximately `T/W > 1.2` was used.

### 6.2 Gravity turn

The atmospheric phase used a zero-lift / zero-angle-of-attack gravity turn.

The trajectory state included altitude, downrange, velocity, flight-path angle and mass. The equations were integrated using MATLAB `ode45`.

The thesis used a Mach-dependent drag coefficient and cross-sectional reference area.

### 6.3 Atmospheric transition

The end of the gravity-turn phase was determined with the **Knudsen number**.

The characteristic length was based on the radius of the last stage / nose-cone base. The transition to free flight occurred once the flow was considered sufficiently rarefied for aerodynamic effects to be neglected.

### 6.4 Free-flight optimization

Outside the atmosphere, the trajectory was optimized as a **minimum-time Two Point Boundary Value Problem (TPBVP)**.

The formulation contained:

- four state equations;
- four costate equations;
- Pontryagin Minimum Principle;
- a linear-tangent steering law;
- boundary conditions for circular-orbit altitude, horizontal velocity and zero vertical velocity.

The thesis describes a shooting-method formulation and also reports the use of MATLAB `bvp4c` for the boundary-value solution.

## 7. Aerodynamics

The drag force was:

```text
D = 0.5 rho Cd S_ref V^2
```

The thesis adopted a sixth-order polynomial approximation for `Cd` as a function of Mach number:

```text
Cd = -3e-6 M^6 + 0.0002 M^5 - 0.0046 M^4
     + 0.053 M^3 - 0.2806 M^2 + 0.6211 M + 0.0568
```

Skin-friction drag was neglected in the preliminary model.

## 8. Atmosphere and gravity

The thesis used:

- U.S. Standard Atmosphere 1976 below 86 km;
- U.S. Standard Atmosphere 1962 above 86 km, described up to 2000 km;
- a simplified gravity model varying with altitude;
- a flat, non-rotating Earth assumption in the original thesis formulation.

Some modern reconstruction code may intentionally use a spherical-Earth formulation. Such changes should be documented as later improvements rather than attributed to the 2014 model.

## 9. Coupled design loop

For a single configuration / parameter combination, the original algorithm can be summarized as:

```text
mission objective
      |
      v
initial Delta-V estimate
      |
      v
mass model + geometry
      |
      v
vertical ascent -> gravity turn -> optimized free flight
      |
      v
actual gravity/drag losses + last-stage propellant residual
      |
      v
updated Delta-V
      |
      +----> repeat mass model until convergence
```

This complete loop was repeated for all selected combinations of configuration and design parameters. The final solution was chosen according to minimum GLOW / maximum payload ratio.

## 10. Historical validation targets

### Vega

Mission:

- payload: 1,500 kg;
- circular orbit: 700 km.

Reported thesis result:

- GLOW deviation from reference launcher: **4.8%**.

### Proton K

Mission:

- payload: 19,360 kg;
- circular orbit: 200 km.

Reported thesis result:

- GLOW deviation: **6.2%**.

### Ariane 5 optimization study

Mission:

- payload: 19.3 t;
- circular orbit: 200 km.

The thesis reports **170 simulations** varying seven design parameters. The selected design reduced GLOW by approximately **84 t (11%)** relative to the Ariane 5 reference configuration used in the study.

## 11. Source

Diogo Marques Gaspar, *A Tool for Preliminary Design of Rockets*, MSc Thesis in Aerospace Engineering, Instituto Superior Técnico, July 2014. Supervisor: Prof. Paulo J. S. Gil.

<https://fenix.tecnico.ulisboa.pt/cursos/meaer/dissertacao/2353642467857>
