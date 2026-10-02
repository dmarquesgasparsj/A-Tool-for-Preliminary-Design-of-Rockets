function [ms_kg,mp_total_kg,k,detail] = stage_mass_with_reserve( ...
    payload_kg,delta_v_ms,Isp_s,epsilon,reserve_fraction,g0)
%STAGE_MASS_WITH_RESERVE Rocket-equation sizing with unburned propellant.
%
% RESERVE_FRACTION is the fraction of total stage propellant intentionally
% retained at burnout. For reserve_fraction=0 this reduces exactly to
% thesis_stage_mass().
%
% Structural factor keeps the thesis definition:
%   epsilon = ms / (ms + mp_total)
%
% With beta = epsilon + reserve*(1-epsilon):
%   k = exp(DeltaV/(g0*Isp))
%   x = ms + mp_total = (k-1)*payload / (1-k*beta)
%
% Burned propellant is (1-reserve)*mp_total and reserve remains in the
% burnout mass. This is a modern extension motivated by the thesis
% validation discussion that propellant margin was not applied uniformly.

if nargin<6 || isempty(g0), g0=9.80665; end
validateattributes(payload_kg,{'numeric'}, ...
    {'scalar','real','finite','nonnegative'});
validateattributes(delta_v_ms,{'numeric'}, ...
    {'scalar','real','finite','nonnegative'});
validateattributes(Isp_s,{'numeric'}, ...
    {'scalar','real','finite','positive'});
validateattributes(epsilon,{'numeric'}, ...
    {'scalar','real','finite','>=',0,'<',1});
validateattributes(reserve_fraction,{'numeric'}, ...
    {'scalar','real','finite','>=',0,'<',1});
validateattributes(g0,{'numeric'}, ...
    {'scalar','real','finite','positive'});

if reserve_fraction==0
    [ms_kg,mp_total_kg,k]=thesis_stage_mass( ...
        payload_kg,delta_v_ms,Isp_s,epsilon,g0);
else
    k=exp(delta_v_ms/(g0*Isp_s));
    beta=epsilon+reserve_fraction*(1-epsilon);
    den=1-k*beta;
    if den<=0
        error('stage_mass_with_reserve:InfeasibleStage', ...
            ['No finite stage exists: retained structural/reserve fraction ', ...
             'times the required mass ratio must be < 1.']);
    end
    x=(k-1)*payload_kg/den;
    ms_kg=epsilon*x;
    mp_total_kg=(1-epsilon)*x;
end

detail.reserve_fraction=reserve_fraction;
detail.reserve_propellant_kg=reserve_fraction*mp_total_kg;
detail.usable_propellant_kg=(1-reserve_fraction)*mp_total_kg;
detail.burnout_stage_mass_kg=ms_kg+detail.reserve_propellant_kg;
detail.initial_stage_mass_kg=ms_kg+mp_total_kg;
detail.structural_factor=epsilon;
detail.mass_ratio=k;
detail.source=['2026 explicit reserve extension of the thesis stage ', ...
    'rocket-equation sizing; reserve propellant remains at burnout.'];
end
