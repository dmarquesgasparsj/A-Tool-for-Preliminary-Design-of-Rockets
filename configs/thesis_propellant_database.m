function prop = thesis_propellant_database()
%THESIS_PROPELLANT_DATABASE Appendix B / Table B.1 from the 2014 thesis.
%
% Fields:
%   name, Isp_s, mixture_ratio_OF, rho_oxidizer_kg_m3, rho_fuel_kg_m3,
%   type_as_written_in_thesis
%
% For solid propellants, the thesis table provides a single density value
% in the oxidizer-density column and no OF ratio; those entries are kept as
% documented rather than reinterpreted.

raw = {
    'LOX/H2',                    462, 3.80, 1142,   71, 'Liquid';
    'LOX/Hydrazine',             363, 1.20, 1142, 1010, 'Liquid';
    'LOX/RP1',                   347, 2.27, 1142,  810, 'Hybrid';
    'Nitrogen Tetroxide/RP1',    328, 3.51, 1440,  810, 'Liquid';
    'Nitrogen Tetroxide/HTPB',   297, 3.17, 1440, 1810, 'Hybrid';
    'LOX/HTPB',                  317, 2.04, 1142, 1810, 'Hybrid';
    'F2/H2',                     441, 4.26, 1509,   71, 'Liquid';
    'Nitrogen Tetroxide/MMH',    318, 1.00, 1440,  878, 'Liquid';
    'Nitrogen Tetroxide/UDMH',   313, 1.75, 1440,  789, 'Liquid';
    'Nitrogen Tetroxide/Hydrazine',309,2.21,1440,1010,'Liquid';
    'HTPB/AP',                   265, NaN, 1800,   NaN, 'Solid';
    'DB-HMX/AP',                 260, NaN, 1854,   NaN, 'Solid'
    };

prop = repmat(struct('name','','Isp_s',0,'mixture_ratio_OF',NaN, ...
    'rho_oxidizer_kg_m3',NaN,'rho_fuel_kg_m3',NaN, ...
    'type_as_written_in_thesis',''), 1, size(raw,1));

for i = 1:size(raw,1)
    prop(i).name = raw{i,1};
    prop(i).Isp_s = raw{i,2};
    prop(i).mixture_ratio_OF = raw{i,3};
    prop(i).rho_oxidizer_kg_m3 = raw{i,4};
    prop(i).rho_fuel_kg_m3 = raw{i,5};
    prop(i).type_as_written_in_thesis = raw{i,6};
end
end
