# Reconstruction and Maintenance Policy

This repository contains a public reconstruction of software originally developed for the 2014 MSc thesis **A Tool for Preliminary Design of Rockets**.

The purpose of this document is to keep the historical record clear while allowing the codebase to be restored, tested and improved.


## Recovered original source

A set of thesis-era MATLAB files was recovered in September 2026. These files are now treated as the highest-fidelity evidence for implementation details that the dissertation did not fully specify. See [RECOVERED_SOURCE_2014.md](RECOVERED_SOURCE_2014.md).

The recovery changes the provenance hierarchy used by this project:

1. recovered 2014 source for literal implementation behaviour;
2. the 2014 thesis for scientific intent and architecture;
3. clearly labelled reconstruction choices where neither source is complete;
4. modern improvements only after the historical model is understood.

## What belongs to the 2014 thesis model

A feature is described as part of the **original thesis model** when it is explicitly documented in the 2014 thesis, even if its present source file had to be rewritten during the public reconstruction.

Examples include:

- multistage sizing;
- boosters and parallel staging;
- structural-factor iteration;
- Mass Estimation Relationships;
- launcher geometry and fairing sizing;
- Mach-dependent drag;
- vertical ascent and gravity turn;
- Knudsen-number atmospheric transition;
- TPBVP free-flight optimization;
- coupled mass-model / trajectory `Delta-V` convergence;
- Vega and Proton K validation;
- Ariane 5 optimization study.

When these components are reimplemented from the thesis, commit messages should preferably use language such as **restore**, **recover** or **reconstruct**, rather than implying that the scientific idea was first introduced in the current year.

## What counts as modern maintenance

Features that were not part of the thesis should be identified as later maintenance or improvements. Examples include:

- automated regression tests;
- GitHub Actions / CI;
- input validation and defensive programming;
- repository packaging and documentation;
- MATLAB-version compatibility fixes;
- Octave compatibility;
- refactoring for readability or maintainability;
- bug fixes to the reconstructed implementation;
- new physics or optimization methods not present in the thesis.

These changes should keep their real Git history and date.

## Git history

The public repository was created after the thesis and therefore its commit dates do not represent the date on which the original research was performed.

No attempt should be made to backdate commits or fabricate a 2014 Git history.

Instead, historical provenance is recorded through:

- the thesis citation;
- the README project timeline;
- this reconstruction document;
- the changelog;
- comments in restored scientific modules where appropriate.

## Commit-message convention

Suggested wording for reconstructed thesis functionality:

```text
Restore 2014 structural-factor mass model
Restore Vega validation configuration
Reconstruct thesis Cd(Mach) model
Recover booster parallel-staging logic
Restore TPBVP free-flight phase
```

Suggested wording for genuinely modern changes:

```text
Add MATLAB regression tests
Fix bounded trajectory search
Add GitHub Actions test workflow
Improve configuration validation
Refactor trajectory event logging
```

## Validation philosophy

The thesis results are treated as historical regression targets, not as values to be silently forced into the code.

The restored implementation should reproduce the same modelling assumptions first. Differences from the reported values should then be investigated and documented.

Historical reference targets include:

- Vega: 1,500 kg to 700 km; reported GLOW deviation 4.8%;
- Proton K: 19,360 kg to 200 km; reported GLOW deviation 6.2%;
- Ariane 5 study: 19.3 t to 200 km; reported optimized GLOW reduction about 84 t / 11%.

## Modern extensions

Once the thesis model is reproduced and validated, new capabilities can be developed on top of a clearly labelled modern branch or module. Possible examples are the same future-work directions already identified in the thesis: improved engine/nozzle modelling, trajectory constraints, aerodynamic improvements, cost modelling and additional missions.

The goal is therefore not to freeze the code in 2014, but to preserve a clear boundary between **what was developed in the thesis** and **what was added later**.
