function out = estimate_launcher_cost(design,cfg)
%ESTIMATE_LAUNCHER_COST Transparent mass-based parametric CER framework.
%
% DESIGN may contain:
%   stages(i).ms_kg
%   GLOW_kg
% Optional:
%   stages(i).cost_complexity_factor (default 1)
%   stages(i).quantity (default 1)
%
% CFG follows cost_model_template(). Monetary estimates are only as valid
% as the supplied/calibrated CER coefficients. This function does not claim
% that the normalized defaults represent euros, dollars, or historical
% launcher prices.
%
% Production learning curve:
%   C_n = C_1 * n^b, b = log(slope)/log(2)

if nargin<2 || isempty(cfg), cfg=cost_model_template('normalized'); end
if ~isfield(design,'stages') || isempty(design.stages)
    error('estimate_launcher_cost:Stages','design.stages is required.');
end
if ~isfield(design,'GLOW_kg') || ~isfinite(design.GLOW_kg)
    error('estimate_launcher_cost:GLOW','design.GLOW_kg is required.');
end
stages=design.stages;
units=cfg.program.units;
launches=cfg.program.launches;
validateattributes(units,{'numeric'},{'scalar','integer','positive'});
validateattributes(launches,{'numeric'},{'scalar','integer','positive'});
slope=cfg.production.learning_curve_slope;
validateattributes(slope,{'numeric'},{'scalar','real','finite','>',0,'<=',1});
b=log(slope)/log(2);

blank=struct('name','','dry_mass_kg',0,'quantity',1,'complexity_factor',1, ...
    'development_cost',0,'first_unit_cost',0,'production_cost',0);
comp=repmat(blank,1,numel(stages));
dev=0; prod=0;
for i=1:numel(stages)
    if ~isfield(stages(i),'ms_kg') || ~isfinite(stages(i).ms_kg) || stages(i).ms_kg<=0
        error('estimate_launcher_cost:DryMass', ...
            'Stage %d requires positive ms_kg.',i);
    end
    if isfield(stages(i),'name'), name=stages(i).name;
    else, name=sprintf('Stage %d',i); end
    if isfield(stages(i),'cost_complexity_factor') && ...
            isfinite(stages(i).cost_complexity_factor)
        complexity=stages(i).cost_complexity_factor;
    else
        complexity=1;
    end
    if isfield(stages(i),'quantity') && isfinite(stages(i).quantity)
        qty=stages(i).quantity;
    else
        qty=1;
    end
    validateattributes(complexity,{'numeric'}, ...
        {'scalar','real','finite','positive'});
    validateattributes(qty,{'numeric'}, ...
        {'scalar','integer','positive'});

    m=stages(i).ms_kg;
    cdev=cfg.development.coefficient*m^cfg.development.mass_exponent*complexity;
    c1=cfg.production.coefficient*m^cfg.production.mass_exponent*complexity*qty;
    series=sum((1:units).^b);
    cprod=c1*series;
    comp(i)=struct('name',name,'dry_mass_kg',m,'quantity',qty, ...
        'complexity_factor',complexity,'development_cost',cdev, ...
        'first_unit_cost',c1,'production_cost',cprod);
    dev=dev+cdev;
    prod=prod+cprod;
end

ops_per_launch=cfg.operations.fixed_per_launch + ...
    cfg.operations.glow_coefficient*design.GLOW_kg^cfg.operations.glow_exponent;
ops=launches*ops_per_launch;
total=dev+prod+ops;

out.components=comp;
out.development_cost=dev;
out.production_cost=prod;
out.operations_cost=ops;
out.operations_cost_per_launch=ops_per_launch;
out.total_program_cost=total;
out.average_cost_per_launch=total/launches;
out.recurring_cost_per_launch=(prod/units)+ops_per_launch;
out.currency=cfg.currency;
out.base_year=cfg.base_year;
out.units=units;
out.launches=launches;
out.learning_curve_exponent=b;
out.configuration=cfg;
out.model_status=['2026 early-design parametric CER framework. Results ', ...
    'depend on user-supplied/calibrated coefficients.'];
end
