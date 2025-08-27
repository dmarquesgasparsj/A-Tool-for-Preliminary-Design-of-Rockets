
# MATLAB Toolkit — Preliminary Rocket Design (Multi-Stage + Gravity Turn)

**Language:** English  
**Purpose:** Estimate masses, dimensions and payload ratio for multi-stage rockets, including a 2D gravity turn simulation and simple iteration between **trajectory** and **configuration**.

> ⚠️ **Important note:** These models are preliminary/simplified and rely on approximations (exponential atmosphere, constant drag per stage, simplified pitch control, sequential stage burns without side boosters). They are useful for initial trade-offs and sensitivity studies, **not** for flight verification.

## How to use
1. Open `main.m` in MATLAB/Octave.
2. Choose the configuration in `main.m` (e.g., `demo_config` or create one in `configs/`).
3. Run `main.m`. The script will:
   - Show a small GUI asking for the desired payload mass and target orbit altitude.
   - Load the launcher configuration and mission parameters.
   - Optimize (by default) the basic trajectory (pitch timing and kick).
   - Search, by bisection, for the **maximum payload** that still reaches the target orbit.
   - Report the payload ratio (= m_payload / m0) and provide altitude/velocity plots.

## Folders
- `configs/` — parameter files for each launcher (e.g., `demo_config.m`).  
  Create variants (e.g., `vega_config.m`, `protonkdm3_config.m`, `ariane5_config.m`) by editing Isp, thrust, structural masses, propellant masses, `CdA`, etc.
- `util/` — helper functions.

## Main limitations
- Simplified ISA (exponential, fixed scale height).
- Drag modeled via constant `CdA` per stage.
- Thrust direction: vertical until `t_pitch`; short pitch-kick window; then gravity turn with thrust aligned with velocity.
- No modeling of side boosters/asymmetric attachments.
- Optimization *without* toolboxes (uses grid search and `fminsearch` when applicable).

## Expected results
- Estimate of lift-off mass, payload ratio and time histories (altitude, velocity, angle).
- Basis to compare configurations (by editing files in `configs/`) and perform parameter what-if analyses.

---
This toolkit stems from the author's Master's thesis available at: <https://fenix.tecnico.ulisboa.pt/cursos/meaer/dissertacao/2353642467857>.
