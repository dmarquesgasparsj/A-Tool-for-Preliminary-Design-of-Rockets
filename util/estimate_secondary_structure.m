function out = estimate_secondary_structure(stage,opts)
%ESTIMATE_SECONDARY_STRUCTURE Fairing, interstage/adapter and wiring mass.
%
% This closes the geometric/component gap without inventing a historical
% interstage MER. The 2014 thesis explicitly says the Akin model had no
% interstage MER and that interstage mass could be incorporated into the
% lower-stage structural mass. Accordingly, every non-fairing term here is
% opt-in and requires explicit geometry plus shell/areal-density inputs.
%
% STAGE optional fields:
%   fairing_model
%       .enabled
%       .shape, .length_m, .radius_m
%       .mode = 'thesis_mer' (default) or 'shell'
%       .geometry_options
%       shell mode: .areal_density_kg_m2 OR
%                   .material_density_kg_m3 + .thickness_m
%
%   interstage_model
%       .enabled, .length_m, .lower_radius_m, .upper_radius_m
%       .areal_density_kg_m2 OR .material_density_kg_m3 + .thickness_m
%
%   payload_adapter_model
%       same geometry/density fields as interstage_model
%
%   wiring_model
%       .enabled, .length_m, .linear_density_kg_m
%
% OUT.total_kg is suitable for addition to stage structural mass.

if nargin<2 || isempty(opts), opts=struct(); end
out=struct('fairing_kg',0,'fairing_area_m2',NaN, ...
    'interstage_kg',0,'interstage_area_m2',NaN, ...
    'payload_adapter_kg',0,'payload_adapter_area_m2',NaN, ...
    'wiring_kg',0,'total_kg',0,'details',struct());

if isfield(stage,'fairing_model') && isstruct(stage.fairing_model) && ...
        enabled(stage.fairing_model)
    f=stage.fairing_model;
    req={'shape','length_m','radius_m'};
    require_fields(f,req,'fairing_model');
    gopts=struct();
    if isfield(f,'geometry_options') && isstruct(f.geometry_options)
        gopts=f.geometry_options;
    end
    geom=thesis_nose_cone_geometry(f.shape,f.length_m,f.radius_m,gopts);
    A=geom.wetted_area_m2;
    mode='thesis_mer';
    if isfield(f,'mode') && ~isempty(f.mode), mode=lower(char(f.mode)); end
    switch mode
        case 'thesis_mer'
            mass=4.95*A^1.15;
            source='Gaspar MSc thesis (2014), Eq. 4.16';
        case 'shell'
            sigma=areal_density(f,'fairing_model');
            mass=sigma*A;
            source='2026 explicit shell geometry model';
        otherwise
            error('estimate_secondary_structure:FairingMode', ...
                'Unknown fairing mode: %s.',mode);
    end
    out.fairing_kg=mass;
    out.fairing_area_m2=A;
    out.details.fairing=struct('geometry',geom,'mode',mode,'source',source);
end

if isfield(stage,'interstage_model') && isstruct(stage.interstage_model) && ...
        enabled(stage.interstage_model)
    [mass,A,d]=frustum_shell(stage.interstage_model,'interstage_model');
    out.interstage_kg=mass;
    out.interstage_area_m2=A;
    out.details.interstage=d;
end

if isfield(stage,'payload_adapter_model') && ...
        isstruct(stage.payload_adapter_model) && ...
        enabled(stage.payload_adapter_model)
    [mass,A,d]=frustum_shell(stage.payload_adapter_model, ...
        'payload_adapter_model');
    out.payload_adapter_kg=mass;
    out.payload_adapter_area_m2=A;
    out.details.payload_adapter=d;
end

if isfield(stage,'wiring_model') && isstruct(stage.wiring_model) && ...
        enabled(stage.wiring_model)
    w=stage.wiring_model;
    require_fields(w,{'length_m','linear_density_kg_m'},'wiring_model');
    validateattributes(w.length_m,{'numeric'}, ...
        {'scalar','real','finite','nonnegative'});
    validateattributes(w.linear_density_kg_m,{'numeric'}, ...
        {'scalar','real','finite','nonnegative'});
    out.wiring_kg=w.length_m*w.linear_density_kg_m;
    out.details.wiring=struct('length_m',w.length_m, ...
        'linear_density_kg_m',w.linear_density_kg_m, ...
        'source','2026 explicit user-calibrated component model');
end

out.total_kg=out.fairing_kg+out.interstage_kg+ ...
    out.payload_adapter_kg+out.wiring_kg;
out.model_status=['Fairing can use thesis Eq. 4.16; interstage, adapter ', ...
    'and wiring use explicit user-supplied geometry/density because the ', ...
    '2014 thesis documents no interstage MER.'];
end

function tf=enabled(s)
tf=true;
if isfield(s,'enabled'), tf=logical(s.enabled); end
end

function require_fields(s,names,label)
for i=1:numel(names)
    if ~isfield(s,names{i}) || isempty(s.(names{i}))
        error('estimate_secondary_structure:MissingField', ...
            '%s requires %s.',label,names{i});
    end
end
end

function sigma=areal_density(s,label)
if isfield(s,'areal_density_kg_m2') && ...
        isfinite(s.areal_density_kg_m2) && s.areal_density_kg_m2>=0
    sigma=s.areal_density_kg_m2;
    return;
end
require_fields(s,{'material_density_kg_m3','thickness_m'},label);
validateattributes(s.material_density_kg_m3,{'numeric'}, ...
    {'scalar','real','finite','positive'});
validateattributes(s.thickness_m,{'numeric'}, ...
    {'scalar','real','finite','nonnegative'});
sigma=s.material_density_kg_m3*s.thickness_m;
end

function [mass,A,detail]=frustum_shell(s,label)
require_fields(s,{'length_m','lower_radius_m','upper_radius_m'},label);
validateattributes(s.length_m,{'numeric'}, ...
    {'scalar','real','finite','nonnegative'});
validateattributes(s.lower_radius_m,{'numeric'}, ...
    {'scalar','real','finite','nonnegative'});
validateattributes(s.upper_radius_m,{'numeric'}, ...
    {'scalar','real','finite','nonnegative'});
r1=s.lower_radius_m; r2=s.upper_radius_m; L=s.length_m;
slant=sqrt(L^2+(r1-r2)^2);
A=pi*(r1+r2)*slant;
sigma=areal_density(s,label);
mass=A*sigma;
detail=struct('length_m',L,'lower_radius_m',r1, ...
    'upper_radius_m',r2,'slant_m',slant,'lateral_area_m2',A, ...
    'areal_density_kg_m2',sigma, ...
    'source','2026 explicit frustum-shell model; no historical interstage MER');
end
