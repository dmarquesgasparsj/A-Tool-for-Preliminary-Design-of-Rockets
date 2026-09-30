# Mission, Economic and Higher-Fidelity Extensions (2026)

This document separates the 2014 thesis Future Work from the implementation added in 2026.

The 2014 thesis explicitly proposed air-launched rockets, GEO transfers, interplanetary trajectories with long coast phases, and a cost model. Inclined launch initial conditions, thrust misalignment and J2 are implemented here as additional modern extensions.

## Inclined and air launch

The historical default remains:

- launch altitude = 0 m;
- vehicle-relative speed = 0 m/s;
- flight-path angle = 90 deg;
- Earth rotation included;
- vertical -> pitch kick -> gravity turn guidance.

Modern missions can provide:

- `initial_altitude_m`;
- `initial_speed_m_s`;
- `initial_flight_path_angle_deg` or `_rad`;
- optional `initial_angle_hold_s`.

The initial speed is defined relative to the rotating Earth/atmosphere. Local eastward Earth-rotation velocity is added separately when enabled.

Files:

- `util/launch_initial_conditions.m`
- `util/launch_guidance.m`
- `util/simulate_gravity_turn.m`
- `util/propagate_to_knudsen_transition.m`

## GEO transfers

`geo_transfer_analysis()` uses a circular parking orbit and a two-impulse Hohmann transfer to GEO. GEO radius is derived from Earth rotation and gravitational parameter. A change in orbital inclination can either be combined with the apogee circularization burn or treated separately.

Reference:
NASA NTRS, *Hohmann Transfer: Concentric Orbits*:
https://ntrs.nasa.gov/api/citations/19890009139/downloads/19890009139.pdf

## Interplanetary preliminary analysis

`interplanetary_transfer_analysis()` uses:

1. a coplanar circular heliocentric Hohmann transfer;
2. Earth-relative hyperbolic excess velocity `v_inf`;
3. characteristic energy `C3 = v_inf^2`;
4. patched-conic injection from a circular Earth parking orbit.

It is a preliminary mission-sizing model, not an ephemeris-based Lambert solver. Planet eccentricity, launch windows, finite burns, target capture and gravity assists are outside the current scope.

NASA describes Hohmann transfers as a baseline way to reason about interplanetary trajectories:
https://science.nasa.gov/learn/basics-of-space-flight/chapter4-1/

## Long coast phases and J2

`propagate_orbit_3d()` integrates a Cartesian Earth-centred inertial coast using central gravity and optional J2. This is intentionally separate from the local-Cartesian thesis TPBVP, whose constant-gravity assumptions are not suitable for multi-hour or multi-day orbital coasts.

The Earth J2 term is the first non-spherical gravity correction used by the new propagator.

References:

- NASA Earth Fact Sheet:
  https://nssdc.gsfc.nasa.gov/planetary/factsheet/earthfact.html
- NASA/JPL SPICE documentation for Earth zonal harmonics:
  https://naif.jpl.nasa.gov/pub/naif/toolkit_docs/MATLAB/mice/cspice_evsgp4.html

## Thrust misalignment

`apply_thrust_misalignment()` rotates the commanded thrust direction without changing Isp, mass flow or nominal thrust magnitude. The current implementation supports:

- deterministic in-plane bias for the 2D ascent equations;
- arbitrary-axis Rodrigues rotation for 3D vectors.

A stochastic pointing-error study can be built by drawing a time/history of angles externally and reusing the same rotation primitive.

## Cost model

The thesis proposed a cost model but did not define a complete cost-estimating relationship. The 2026 implementation therefore does **not** invent a historical 2014 cost equation.

`estimate_launcher_cost()` provides a transparent parametric framework with separate:

- development cost;
- production cost;
- operations cost;
- learning-curve behavior;
- stage dry mass, quantity and complexity drivers.

`cost_model_template('normalized')` deliberately returns a **dimensionless cost index**. To obtain EUR/USD estimates, the user must replace the coefficients with a documented and calibrated CER dataset.

This is consistent with NASA guidance that early parametric cost estimates use explicit cost drivers and calibrated cost-estimating relationships (CERs):

- NASA Cost Estimating Handbook:
  https://www.nasa.gov/ocfo/ppc-corner/nasa-cost-estimating-handbook-ceh/
- NASA Project Cost Estimating Capability:
  https://www.nasa.gov/ocfo/ppc-corner/pcec-project-cost-estimating-capability/

## Interactive access

Run:

```matlab
main
```

and choose **Mission / advanced extensions**.

The menu offers:

- inclined / air-launch ascent example;
- GEO transfer analysis;
- interplanetary Hohmann / C3 analysis;
- long coast with optional J2;
- normalized launcher cost trade.

All numerical functions remain independently callable without the GUI.
