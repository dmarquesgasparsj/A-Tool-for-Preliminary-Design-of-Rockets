function result = run_mission_extensions()
%RUN_MISSION_EXTENSIONS Interactive front-end for modern mission analysis.
%
% Numerical APIs remain independent of this menu:
%   launch_initial_conditions / simulate_gravity_turn
%   geo_transfer_analysis
%   interplanetary_transfer_analysis
%   propagate_orbit_3d
%   estimate_launcher_cost

root=fileparts(mfilename('fullpath'));
addpath(root);
addpath(fullfile(root,'configs'));
addpath(fullfile(root,'util'));

choice=menu('Mission and advanced extensions', ...
    'Inclined / air-launch ascent example', ...
    'GEO transfer analysis', ...
    'Interplanetary Hohmann / C3 analysis', ...
    'Long coast propagation with optional J2', ...
    'Normalized launcher cost trade', ...
    'Cancel');
result=[];
if choice==0 || choice==6, return; end

switch choice
    case 1
        cfg=general_launcher_preset('illustrative_two_stage');
        mass=thesis_iterative_mass_model(cfg);
        tcfg=trajectory_config_from_mass_result(cfg,mass);
        a=inputdlg({'Initial altitude [km]', ...
            'Vehicle-relative speed [m/s]', ...
            'Initial flight-path angle above horizontal [deg]', ...
            'Hold initial thrust direction [s]'}, ...
            'Inclined / air launch',1,{'12','250','10','3'});
        if isempty(a), return; end
        mission.target_alt=cfg.mission.orbit_altitude_km*1000;
        mission.launch_lat=deg2rad(cfg.mission.launch_lat_deg);
        mission.initial_altitude_m=1000*str2double(a{1});
        mission.initial_speed_m_s=str2double(a{2});
        mission.initial_flight_path_angle_deg=str2double(a{3});
        traj_params=struct('initial_angle_hold_s',str2double(a{4}));
        result=simulate_gravity_turn(tcfg,mission,traj_params, ...
            cfg.mission.payload_kg);
        fprintf('\n=== Inclined / air-launch ascent ===\n');
        fprintf('Mode: %s\n',result.initial_conditions.mode);
        fprintf('Initial altitude %.1f km, speed %.1f m/s, gamma %.2f deg\n', ...
            result.initial_conditions.altitude_m/1000, ...
            result.initial_conditions.relative_speed_m_s, ...
            result.initial_conditions.flight_path_angle_deg);
        fprintf('Final altitude %.1f km | speed %.1f m/s | max-q %.1f kPa\n', ...
            result.h(end)/1000,result.v(end), ...
            result.max_dynamic_pressure_Pa/1000);

    case 2
        a=inputdlg({'Parking-orbit altitude [km]', ...
            'Initial inclination [deg]','Final GEO inclination [deg]', ...
            'Optional Isp [s] (NaN = skip propellant fraction)'}, ...
            'GEO transfer',1,{'200','0','0','450'});
        if isempty(a), return; end
        opts.initial_inclination_deg=str2double(a{2});
        opts.final_inclination_deg=str2double(a{3});
        isp=str2double(a{4});
        if isfinite(isp), opts.Isp_s=isp; end
        result=geo_transfer_analysis(1000*str2double(a{1}),opts);
        fprintf('\n=== GEO transfer ===\n');
        fprintf('GEO altitude: %.1f km\n',result.geo_altitude_m/1000);
        fprintf('Delta-V departure: %.1f m/s\n',result.delta_v_departure_m_s);
        fprintf('Delta-V apogee: %.1f m/s\n',result.delta_v_apogee_m_s);
        fprintf('Total Delta-V: %.1f m/s\n',result.total_delta_v_m_s);
        fprintf('Transfer coast: %.2f h\n',result.transfer_time_h);
        if isfinite(result.propellant_fraction)
            fprintf('Ideal propellant fraction at selected Isp: %.2f%%\n', ...
                100*result.propellant_fraction);
        end

    case 3
        a=inputdlg({'Target heliocentric orbit radius [AU]', ...
            'Earth parking-orbit altitude [km]'}, ...
            'Interplanetary Hohmann / patched conic',1,{'1.523679','200'});
        if isempty(a), return; end
        result=interplanetary_transfer_analysis( ...
            str2double(a{1}),1000*str2double(a{2}));
        fprintf('\n=== Interplanetary transfer ===\n');
        fprintf('Departure v_inf: %.3f km/s\n',result.departure_v_inf_m_s/1000);
        fprintf('C3: %.3f km^2/s^2\n',result.C3_km2_s2);
        fprintf('Earth injection Delta-V: %.1f m/s\n', ...
            result.earth_injection_delta_v_m_s);
        fprintf('Hohmann coast: %.1f days\n',result.transfer_time_days);
        fprintf('Arrival v_inf: %.3f km/s\n',result.arrival_v_inf_m_s/1000);

    case 4
        a=inputdlg({'Circular-orbit altitude [km]', ...
            'Inclination [deg]','Coast duration [h]','Include J2? 1=yes, 0=no'}, ...
            'Long coast / J2',1,{'700','63.4','24','1'});
        if isempty(a), return; end
        env=earth_constants();
        r0=env.Re+1000*str2double(a{1});
        inc=deg2rad(str2double(a{2}));
        v0=sqrt(env.mu/r0);
        initial=struct('r_eci_m',[r0;0;0], ...
            'v_eci_m_s',[0;v0*cos(inc);v0*sin(inc)]);
        opts=struct('include_J2',logical(str2double(a{4})));
        result=propagate_orbit_3d(initial,3600*str2double(a{3}),opts);
        fprintf('\n=== Long coast ===\n');
        fprintf('J2 enabled: %d | duration %.2f h\n', ...
            result.include_J2,result.duration_s/3600);
        fprintf('Final altitude: %.2f km | speed %.2f km/s\n', ...
            result.altitude_m(end)/1000,result.speed_m_s(end)/1000);
        fprintf('Two-body specific-energy spread: %.3g J/kg\n', ...
            max(result.specific_energy_J_kg)-min(result.specific_energy_J_kg));

    case 5
        cfg=general_launcher_preset('illustrative_two_stage');
        mass=thesis_iterative_mass_model(cfg);
        a=inputdlg({'Number of produced launcher units', ...
            'Number of launches','Learning-curve slope (e.g. 0.90)'}, ...
            'Normalized cost trade',1,{'4','4','0.90'});
        if isempty(a), return; end
        ccfg=cost_model_template();
        ccfg.program.units=str2double(a{1});
        ccfg.program.launches=str2double(a{2});
        ccfg.production.learning_curve_slope=str2double(a{3});
        design.GLOW_kg=mass.GLOW_kg;
        design.stages=mass.stages;
        result=estimate_launcher_cost(design,ccfg);
        fprintf('\n=== Normalized cost trade ===\n');
        fprintf(['These are dimensionless cost indices, not EUR/USD. ', ...
            'Supply calibrated CER coefficients for monetary estimates.\n']);
        fprintf('Development index: %.3f\n',result.development_cost);
        fprintf('Production index: %.3f\n',result.production_cost);
        fprintf('Operations index: %.3f\n',result.operations_cost);
        fprintf('Total program index: %.3f\n',result.total_program_cost);
end
end
