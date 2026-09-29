function out = thesis_propellant_residual_delta_v(stage,payload_above_kg,residual_propellant_kg,g0)
%THESIS_PROPELLANT_RESIDUAL_DELTA_V Convert last-stage residual mass to Delta-V.
%
% Positive residual_propellant_kg means propellant remains at orbital
% insertion. For the nominal last stage:
%
%   M0 = payload_above + ms + mp
%   Mf = payload_above + ms
%
% the unused ideal Delta-V is
%   ve*ln((Mf + residual)/Mf).
%
% Therefore the design Delta-V correction is negative.
%
% Negative residual denotes a propellant shortfall. The returned positive
% correction estimates the additional ideal Delta-V that the *additional
% initial propellant mass* would provide:
%   ve*ln((M0 + missing)/M0).
% This branch is a 2026 explicit approximation because the surviving source
% does not specify the exact missing-propellant implementation.
%
% STAGE requires Isp_s, ms_kg and mp_kg.

if nargin<4 || isempty(g0), g0=9.80665; end
req={'Isp_s','ms_kg','mp_kg'};
for i=1:numel(req)
    if ~isfield(stage,req{i})
        error('thesis_propellant_residual_delta_v:StageField', ...
            'stage.%s is required.',req{i});
    end
end
validateattributes(payload_above_kg,{'numeric'}, ...
    {'scalar','real','finite','nonnegative'});
validateattributes(residual_propellant_kg,{'numeric'}, ...
    {'scalar','real','finite'});
validateattributes(g0,{'numeric'},{'scalar','real','finite','positive'});

ve=stage.Isp_s*g0;
dry_payload=payload_above_kg+stage.ms_kg;
M0=dry_payload+stage.mp_kg;
if dry_payload<=0 || M0<=0
    error('thesis_propellant_residual_delta_v:Mass','Invalid stage masses.');
end

if residual_propellant_kg>=0
    if residual_propellant_kg>stage.mp_kg*(1+1e-9)
        error('thesis_propellant_residual_delta_v:ResidualTooLarge', ...
            'Residual cannot exceed nominal stage propellant mass.');
    end
    unused=ve*log((dry_payload+residual_propellant_kg)/dry_payload);
    correction=-unused;
    mode='excess';
    approximation=false;
else
    missing=-residual_propellant_kg;
    extra=ve*log((M0+missing)/M0);
    correction=extra;
    unused=-extra;
    mode='shortfall';
    approximation=true;
end

out.mode=mode;
out.residual_propellant_kg=residual_propellant_kg;
out.delta_v_correction_m_s=correction;
out.unused_delta_v_m_s=unused;
out.approximation=approximation;
out.exhaust_velocity_m_s=ve;
out.nominal_initial_mass_kg=M0;
out.nominal_dry_plus_payload_kg=dry_payload;
end
