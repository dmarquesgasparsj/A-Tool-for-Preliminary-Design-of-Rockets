function cfg = vega_2014_legacy_inputs()
%VEGA_2014_LEGACY_INPUTS Values recovered from mass_model_n_4.m (2014).
%
% These are not inferred from a modern Vega data sheet. They are the
% hard-coded values found in the recovered thesis-era MATLAB source.

cfg.name = 'Vega legacy thesis input';
cfg.source = 'Recovered 2014 mass_model_n_4.m';

cfg.payload_kg = 1500;
cfg.delta_v_estimation_m_s = 9200;

cfg.Isp_s = [280 289 294 317];
cfg.OF = [3 3 3 4];
cfg.thrust_N = [2092e3 959e3 230e3 2.2e3];
cfg.delta_v_fraction = [0.20 0.25 0.40 0.15];

% Nozzle area ratios hard-coded stage-by-stage in the recovered source.
cfg.nozzle_area_ratio = [20 30 60 100];

% Structural factor grid used by the legacy implementation.
cfg.epsilon_grid = 0.05:0.01:0.17;

% Historical validation target reported in the thesis.
cfg.reported_GLOW_error_percent = 4.8;
cfg.target_orbit_altitude_km = 700;
end
