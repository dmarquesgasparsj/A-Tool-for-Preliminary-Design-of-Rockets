function result = thesis_legacy_epsilon_scan(payload_above_kg, delta_v_m_s, ...
    Isp_s, thrust_N, OF, nozzle_area_ratio, avionics_reference)
%THESIS_LEGACY_EPSILON_SCAN Recover the 2014 structural-factor search.
%
% The original mass-model files scanned epsilon from 0.05 to 0.17 in steps
% of 0.01. For each epsilon they calculated the structural mass from the
% Tsiolkovsky-based stage equations and compared it with the heuristic
% structural mass assembled from the Akin MERs.
%
% This function returns every candidate rather than silently retaining only
% the last accepted epsilon, making the original search auditable.
%
% A candidate is marked accepted when the two structural masses agree within
% the original approximately +/-10 percent ratio gate.

if nargin < 7 || isempty(avionics_reference)
    avionics_reference = 'stage_wet';
end

g0 = 9.81;
eps_grid = 0.05:0.01:0.17;
n = numel(eps_grid);

template = struct('epsilon',0,'ms_tsiolkovsky_kg',0,'mp_kg',0, ...
    'stage_wet_kg',0,'ms_mer_kg',0,'ratio_mer_to_tsiolkovsky',0, ...
    'accepted',false,'mer',struct());
candidates = repmat(template, 1, n);

for i = 1:n
    epsilon = eps_grid(i);
    [ms, mp] = thesis_stage_mass(payload_above_kg, delta_v_m_s, ...
        Isp_s, epsilon, g0);
    stage_wet = payload_above_kg + ms + mp;

    switch lower(avionics_reference)
        case 'stage_wet'
            ref_mass = stage_wet;
        case 'stage_only'
            ref_mass = ms + mp;
        otherwise
            error('thesis_legacy_epsilon_scan:UnknownReference', ...
                'Unknown avionics reference rule: %s', avionics_reference);
    end

    mer = thesis_legacy_akin_mass(mp, ref_mass, thrust_N, OF, nozzle_area_ratio);
    ratio = mer.total_kg / ms;

    candidates(i).epsilon = epsilon;
    candidates(i).ms_tsiolkovsky_kg = ms;
    candidates(i).mp_kg = mp;
    candidates(i).stage_wet_kg = stage_wet;
    candidates(i).ms_mer_kg = mer.total_kg;
    candidates(i).ratio_mer_to_tsiolkovsky = ratio;
    candidates(i).accepted = (ratio <= 1.1) && (ratio > 0.9);
    candidates(i).mer = mer;
end

accepted = candidates([candidates.accepted]);

result.epsilon_grid = eps_grid;
result.candidates = candidates;
result.accepted = accepted;
result.has_match = ~isempty(accepted);

if result.has_match
    % The 2014 loops overwrote Msel each time a later epsilon also matched,
    % so the last accepted epsilon is the closest literal recovery of that
    % selection behaviour.
    result.legacy_selected = accepted(end);

    [~, idx] = min(abs([accepted.ratio_mer_to_tsiolkovsky] - 1));
    result.best_agreement = accepted(idx);
else
    result.legacy_selected = [];
    [~, idx] = min(abs([candidates.ratio_mer_to_tsiolkovsky] - 1));
    result.best_agreement = candidates(idx);
end
end
