function cfg = cost_model_template(mode)
%COST_MODEL_TEMPLATE Transparent early-design parametric cost configuration.
%
% mode='normalized' returns a dimensionless cost-index model. It is useful
% for design trades without pretending to produce real currency.
%
% For monetary estimates, copy this struct and replace the coefficients
% with a documented/calibrated CER dataset. The estimator intentionally
% keeps coefficients outside the physics model.

if nargin<1 || isempty(mode), mode='normalized'; end
switch lower(char(mode))
    case 'normalized'
        cfg.name='Normalized mass-based CER';
        cfg.currency='cost_index';
        cfg.base_year=NaN;
        cfg.development.coefficient=1.0;
        cfg.development.mass_exponent=0.65;
        cfg.production.coefficient=0.35;
        cfg.production.mass_exponent=0.70;
        cfg.production.learning_curve_slope=0.90;
        cfg.operations.fixed_per_launch=0.10;
        cfg.operations.glow_coefficient=0.02;
        cfg.operations.glow_exponent=0.50;
        cfg.program.units=1;
        cfg.program.launches=1;
    otherwise
        error('cost_model_template:Mode', ...
            'Unknown template mode. Use normalized and calibrate explicitly.');
end
cfg.source_note=['2026 transparent parametric framework. Coefficients are ', ...
    'illustrative dimensionless defaults, not historical NASA/industry costs.'];
end
