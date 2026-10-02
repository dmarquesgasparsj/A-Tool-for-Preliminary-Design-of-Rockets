function out = estimate_engine_mass(stage,model)
%ESTIMATE_ENGINE_MASS Configurable preliminary liquid/hybrid engine mass.
%
% Two policies are supported:
%   thesis_2014        Reproduce the thesis/recovered MER.
%   reference_powerlaw Scale a calibrated reference engine using thrust,
%                      chamber pressure, nozzle area ratio and O/F ratio.
%
% The reference-power-law form is intentionally calibration-driven:
%
% m = mref (T/Tref)^aT (Pc/Pcref)^aPc (AR/ARref)^aAR (OF/OFref)^aOF
%
% No universal exponents are hidden in this function. They must be supplied
% by the caller from an identified engine dataset. This implements the 2014
% Future Work requirement that engine mass depend on more than thrust while
% keeping empirical assumptions visible and replaceable.

if nargin < 2 || isempty(model)
    if isfield(stage,'engine_mass_model') && isstruct(stage.engine_mass_model)
        model=stage.engine_mass_model;
    else
        model=struct('mode','thesis_2014');
    end
end
if ~isfield(model,'mode'), model.mode='thesis_2014'; end
mode=lower(char(model.mode));

req={'thrust_N','nozzle_area_ratio'};
for i=1:numel(req)
    if ~isfield(stage,req{i}) || ~isfinite(stage.(req{i})) || stage.(req{i})<=0
        error('estimate_engine_mass:MissingStageField', ...
            'stage.%s must be positive.',req{i});
    end
end
T=stage.thrust_N;
AR=stage.nozzle_area_ratio;

switch mode
    case {'thesis_2014','legacy_mer'}
        m=7.81e-4*T + 3.37e-5*T*sqrt(AR) + 59;
        out.mass_kg=m;
        out.mode='thesis_2014';
        out.source=['Gaspar MSc thesis (2014) / recovered MER: thrust ', ...
            'and nozzle-area-ratio based engine estimate.'];
        out.calibrated=false;

    case {'reference_powerlaw','calibrated_powerlaw'}
        names={'reference_mass_kg','reference_thrust_N', ...
            'reference_chamber_pressure_Pa','reference_area_ratio', ...
            'exponents'};
        for i=1:numel(names)
            if ~isfield(model,names{i}) || isempty(model.(names{i}))
                error('estimate_engine_mass:MissingCalibration', ...
                    'reference_powerlaw requires model.%s.',names{i});
            end
        end
        validateattributes(model.reference_mass_kg,{'numeric'}, ...
            {'scalar','real','finite','positive'});
        validateattributes(model.reference_thrust_N,{'numeric'}, ...
            {'scalar','real','finite','positive'});
        validateattributes(model.reference_chamber_pressure_Pa,{'numeric'}, ...
            {'scalar','real','finite','positive'});
        validateattributes(model.reference_area_ratio,{'numeric'}, ...
            {'scalar','real','finite','positive'});
        ex=model.exponents(:).';
        if numel(ex)~=4 || any(~isfinite(ex))
            error('estimate_engine_mass:Exponents', ...
                'model.exponents must be [aT aPc aAR aOF].');
        end

        Pc=current_chamber_pressure(stage);
        [OF,OFref]=current_and_reference_of(stage,model,ex(4));
        ratios=[T/model.reference_thrust_N, ...
            Pc/model.reference_chamber_pressure_Pa, ...
            AR/model.reference_area_ratio, OF/OFref];
        m=model.reference_mass_kg*prod(ratios.^ex);
        out.mass_kg=m;
        out.mode='reference_powerlaw';
        out.reference_mass_kg=model.reference_mass_kg;
        out.ratios=ratios;
        out.exponents=ex;
        out.chamber_pressure_Pa=Pc;
        out.mixture_ratio_OF=OF;
        out.calibrated=true;
        if isfield(model,'calibration_source')
            out.source=char(model.calibration_source);
        else
            out.source=['User-calibrated reference-engine power law. ', ...
                'Calibration source not supplied.'];
        end

    otherwise
        error('estimate_engine_mass:UnknownMode', ...
            'Unknown engine mass mode: %s',mode);
end
end

function Pc=current_chamber_pressure(stage)
Pc=NaN;
if isfield(stage,'chamber_pressure_Pa') && isfinite(stage.chamber_pressure_Pa)
    Pc=stage.chamber_pressure_Pa;
elseif isfield(stage,'pressure_nozzle') && isstruct(stage.pressure_nozzle) && ...
        isfield(stage.pressure_nozzle,'chamber_pressure_Pa') && ...
        isfinite(stage.pressure_nozzle.chamber_pressure_Pa)
    Pc=stage.pressure_nozzle.chamber_pressure_Pa;
end
if ~isfinite(Pc) || Pc<=0
    error('estimate_engine_mass:ChamberPressure', ...
        'reference_powerlaw requires a positive chamber pressure.');
end
end

function [OF,OFref]=current_and_reference_of(stage,model,aOF)
if abs(aOF)<eps
    OF=1; OFref=1;
    return;
end
if ~isfield(stage,'mixture_ratio_OF') || ...
        ~isfinite(stage.mixture_ratio_OF) || stage.mixture_ratio_OF<=0
    error('estimate_engine_mass:MixtureRatio', ...
        'A positive stage.mixture_ratio_OF is required when aOF ~= 0.');
end
if ~isfield(model,'reference_mixture_ratio_OF') || ...
        ~isfinite(model.reference_mixture_ratio_OF) || ...
        model.reference_mixture_ratio_OF<=0
    error('estimate_engine_mass:ReferenceMixtureRatio', ...
        'model.reference_mixture_ratio_OF is required when aOF ~= 0.');
end
OF=stage.mixture_ratio_OF;
OFref=model.reference_mixture_ratio_OF;
end
