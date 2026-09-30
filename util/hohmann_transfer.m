function tr = hohmann_transfer(mu_m3_s2,r1_m,r2_m)
%HOHMANN_TRANSFER Minimum-energy two-impulse transfer between circular orbits.
%
% Returns signed tangential impulses (positive prograde, negative retrograde),
% absolute Delta-V magnitudes and half-ellipse coast time.

validateattributes(mu_m3_s2,{'numeric'}, ...
    {'scalar','real','finite','positive'});
validateattributes(r1_m,{'numeric'}, ...
    {'scalar','real','finite','positive'});
validateattributes(r2_m,{'numeric'}, ...
    {'scalar','real','finite','positive'});
if abs(r2_m-r1_m)<eps(max(r1_m,r2_m))
    tr=struct('r1_m',r1_m,'r2_m',r2_m,'semi_major_axis_m',r1_m, ...
        'v_circular_1_m_s',sqrt(mu_m3_s2/r1_m), ...
        'v_circular_2_m_s',sqrt(mu_m3_s2/r2_m), ...
        'v_transfer_1_m_s',sqrt(mu_m3_s2/r1_m), ...
        'v_transfer_2_m_s',sqrt(mu_m3_s2/r2_m), ...
        'delta_v1_m_s',0,'delta_v2_m_s',0,'total_delta_v_m_s',0, ...
        'time_of_flight_s',0,'mu_m3_s2',mu_m3_s2);
    return;
end
a=(r1_m+r2_m)/2;
vc1=sqrt(mu_m3_s2/r1_m);
vc2=sqrt(mu_m3_s2/r2_m);
vt1=sqrt(mu_m3_s2*(2/r1_m-1/a));
vt2=sqrt(mu_m3_s2*(2/r2_m-1/a));
dv1=vt1-vc1;
dv2=vc2-vt2;
tof=pi*sqrt(a^3/mu_m3_s2);

tr.r1_m=r1_m;
tr.r2_m=r2_m;
tr.semi_major_axis_m=a;
tr.v_circular_1_m_s=vc1;
tr.v_circular_2_m_s=vc2;
tr.v_transfer_1_m_s=vt1;
tr.v_transfer_2_m_s=vt2;
tr.delta_v1_m_s=dv1;
tr.delta_v2_m_s=dv2;
tr.total_delta_v_m_s=abs(dv1)+abs(dv2);
tr.time_of_flight_s=tof;
tr.mu_m3_s2=mu_m3_s2;
tr.model_status='Two-impulse coplanar Hohmann transfer.';
end
