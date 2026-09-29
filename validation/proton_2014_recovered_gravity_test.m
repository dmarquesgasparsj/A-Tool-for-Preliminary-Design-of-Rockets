function ref = proton_2014_recovered_gravity_test()
%PROTON_2014_RECOVERED_GRAVITY_TEST Surviving development-test constants.
%
% These are not substituted for Table 6.2 values. They exist to diagnose
% implementation differences, exactly as for the Vega recovered fixture.

ref.name='Recovered Proton gravity-turn development test';
ref.N=3;
ref.mp_kg=[419410 156113 46562 15200];
ref.Isp_s=[285 327 327 353];
ref.section_initial_mass_kg=[686927 236927 69097 18350];
ref.aerodynamic_diameter_m=4.1;
ref.gravity_turn_altitude_m=500;
ref.burn_time_s=[120 210 230 600];
ref.coast_time_s=[1 1 5];
ref.thrust_N=[6*1470000 4*582000 582000 87000];
ref.gamma0_rad=deg2rad(89.5);
ref.source='Recovered thesis-era gravity_turn_teste_Proton.m development file';
ref.note=['Development test only: N=3 but four stage arrays are present; ', ...
    'Isp, thrust, burn times and initial-mass convention differ from Table 6.2.'];
end
