function g = thesis_stage_geometry_skin(stage,mp_kg,opts)
%THESIS_STAGE_GEOMETRY_SKIN Stage volume, cylindrical envelope and skin mass.
%
% Reconstructs the geometry rule described in Chapter 5 of the 2014 thesis:
%   V_stage = 1.10 * V_propellant
%   M_skin  = rho_alloy * S * thickness
%
% Thesis Table 5.2 gives rho_alloy = 2.7 g/cm^3 (2700 kg/m^3) and
% thickness = 33 mm. Those values are preserved as defaults even though
% the thesis itself notes that no reliable radius/wall-thickness heuristic
% was available. They should therefore be treated as historical inputs,
% not as a modern structural design recommendation.
%
% Required STAGE:
%   diameter_m, propulsion_type
%
% Density inputs:
%   liquid/hybrid: mixture_ratio_OF, rho_oxidizer_kg_m3,
%                  rho_fuel_kg_m3
%   solid:         propellant_bulk_density_kg_m3, or
%                  rho_oxidizer_kg_m3 as a thesis-table fallback
%
% opts:
%   volume_margin          default 1.10
%   alloy_density_kg_m3    default 2700
%   skin_thickness_m       default 0.033
%   surface_model          'closed_cylinder' (default) or 'lateral_only'

if nargin<3 || isempty(opts), opts=struct(); end
if ~isfield(opts,'volume_margin'), opts.volume_margin=1.10; end
if ~isfield(opts,'alloy_density_kg_m3'), opts.alloy_density_kg_m3=2700; end
if ~isfield(opts,'skin_thickness_m'), opts.skin_thickness_m=0.033; end
if ~isfield(opts,'surface_model'), opts.surface_model='closed_cylinder'; end

if ~isfield(stage,'diameter_m')
    error('thesis_stage_geometry_skin:MissingDiameter', ...
        'stage.diameter_m is required.');
end
if ~isfield(stage,'propulsion_type')
    error('thesis_stage_geometry_skin:MissingPropulsion', ...
        'stage.propulsion_type is required.');
end
validateattributes(mp_kg,{'numeric'}, ...
    {'scalar','real','finite','positive'});
validateattributes(stage.diameter_m,{'numeric'}, ...
    {'scalar','real','finite','positive'});
validateattributes(opts.volume_margin,{'numeric'}, ...
    {'scalar','real','finite','>=',1});
validateattributes(opts.alloy_density_kg_m3,{'numeric'}, ...
    {'scalar','real','finite','positive'});
validateattributes(opts.skin_thickness_m,{'numeric'}, ...
    {'scalar','real','finite','positive'});

ptype=lower(char(stage.propulsion_type));
Vox=0; Vfuel=0; Vprop=0;
switch ptype
    case {'liquid','hybrid'}
        req={'mixture_ratio_OF','rho_oxidizer_kg_m3','rho_fuel_kg_m3'};
        for i=1:numel(req)
            if ~isfield(stage,req{i}) || ~isfinite(stage.(req{i})) || ...
                    stage.(req{i})<=0
                error('thesis_stage_geometry_skin:MissingDensity', ...
                    '%s stage requires positive %s.',ptype,req{i});
            end
        end
        OF=stage.mixture_ratio_OF;
        mox=OF*mp_kg/(OF+1);
        mfuel=mp_kg/(OF+1);
        Vox=mox/stage.rho_oxidizer_kg_m3;
        Vfuel=mfuel/stage.rho_fuel_kg_m3;
        Vprop=Vox+Vfuel;
    case 'solid'
        rho=NaN;
        if isfield(stage,'propellant_bulk_density_kg_m3') && ...
                isfinite(stage.propellant_bulk_density_kg_m3) && ...
                stage.propellant_bulk_density_kg_m3>0
            rho=stage.propellant_bulk_density_kg_m3;
        elseif isfield(stage,'rho_oxidizer_kg_m3') && ...
                isfinite(stage.rho_oxidizer_kg_m3) && ...
                stage.rho_oxidizer_kg_m3>0
            % Appendix B stores the single solid density in this column.
            rho=stage.rho_oxidizer_kg_m3;
        end
        if ~isfinite(rho)
            error('thesis_stage_geometry_skin:MissingDensity', ...
                'Solid stage requires propellant_bulk_density_kg_m3.');
        end
        Vprop=mp_kg/rho;
    otherwise
        error('thesis_stage_geometry_skin:InvalidPropulsion', ...
            'Unknown propulsion type: %s.',ptype);
end

Vstage=opts.volume_margin*Vprop;
d=stage.diameter_m;
r=d/2;
Across=pi*r^2;
L=Vstage/Across;
Slateral=2*pi*r*L;
Sendcaps=2*pi*r^2;
switch lower(char(opts.surface_model))
    case 'closed_cylinder'
        S=Slateral+Sendcaps;
    case 'lateral_only'
        S=Slateral;
    otherwise
        error('thesis_stage_geometry_skin:SurfaceModel', ...
            'Unknown surface_model: %s.',char(opts.surface_model));
end
skin=opts.alloy_density_kg_m3*S*opts.skin_thickness_m;

g.propellant_volume_m3=Vprop;
g.oxidizer_volume_m3=Vox;
g.fuel_volume_m3=Vfuel;
g.stage_internal_volume_m3=Vstage;
g.diameter_m=d;
g.cylinder_length_m=L;
g.length_to_diameter=L/d;
g.cross_section_area_m2=Across;
g.lateral_area_m2=Slateral;
g.endcap_area_m2=Sendcaps;
g.skin_area_m2=S;
g.skin_mass_kg=skin;
g.volume_margin=opts.volume_margin;
g.alloy_density_kg_m3=opts.alloy_density_kg_m3;
g.skin_thickness_m=opts.skin_thickness_m;
g.surface_model=char(opts.surface_model);
g.source='Gaspar MSc thesis (2014), Chapter 5 Eq. 5.4 and Table 5.2';
g.warning=['The 33 mm default is transcribed from Table 5.2; the thesis ', ...
    'states that no reliable radius-to-wall-thickness heuristic was found.'];
end
