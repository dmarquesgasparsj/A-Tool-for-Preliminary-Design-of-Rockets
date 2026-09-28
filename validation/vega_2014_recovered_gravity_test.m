function ref = vega_2014_recovered_gravity_test()
%VEGA_2014_RECOVERED_GRAVITY_TEST Inputs from gravity_turn_teste_vega.m.
%
% These are recovered DEVELOPMENT-test values, not the final thesis Table
% 6.1 reference. They are kept separately to diagnose why the surviving
% trajectory test and the dissertation narrative do not fully agree.

ref.name='Recovered Vega gravity-turn development test';
ref.N=4;
ref.mp_kg=[80000 24000 9500 370];
ref.Isp_s=[280 289 294 317];
ref.section_initial_mass_kg=[124457 37119 11219 719];
ref.aerodynamic_diameter_m=1.9;
ref.gravity_turn_altitude_m=500;
ref.burn_time_s=[106.8 71.7 109.6 620];
ref.coast_time_s=[1 1 5];
ref.thrust_N=[2440000 959000 230000 22000];
ref.gamma0_rad=deg2rad(89.5);
ref.source='Recovered thesis-era gravity_turn_teste_vega.m development file';
ref.note=['Development test only: values differ from Table 6.1, including ', ...
    'first-stage thrust and masses.'];
end
