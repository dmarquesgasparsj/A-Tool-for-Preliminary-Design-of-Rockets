function atm = thesis_extended_atmosphere(h, v, characteristic_length_m)
%THESIS_EXTENDED_ATMOSPHERE Independent reconstruction of thesis atmosphere.
%
% Uses the 2014 thesis layer structure: U.S. Standard Atmosphere behaviour
% below 86 km and the extended 1962-style temperature/molecular-weight
% layers described by the recovered thesis-era atmosphere source up to
% 2000 km. This is a clean reimplementation, not a copy of the recovered
% third-party MATLAB file.
%
% Inputs:
%   h [m] altitude, scalar/vector, 0 <= h <= 2e6
%   v [m/s] optional speed (default zero)
%   characteristic_length_m optional length for Re/Kn (default NaN)
%
% Output fields:
%   rho_kg_m3, pressure_Pa, temperature_K, speed_of_sound_m_s,
%   dynamic_viscosity_Pa_s, molar_mass_g_mol, mean_free_path_m,
%   mach, reynolds, knudsen, flow_regime

if nargin<2 || isempty(v), v=zeros(size(h)); end
if nargin<3 || isempty(characteristic_length_m)
    characteristic_length_m=NaN;
end
validateattributes(h,{'numeric'},{'real','finite','nonnegative','<=',2e6});
validateattributes(v,{'numeric'},{'real','finite','nonnegative'});
if ~isscalar(v) && ~isequal(size(v),size(h))
    error('thesis_extended_atmosphere:SizeMismatch', ...
        'v must be scalar or have the same size as h.');
end
if isscalar(v), v=repmat(v,size(h)); end
if ~(isscalar(characteristic_length_m) && ...
        (isnan(characteristic_length_m) || ...
         (isfinite(characteristic_length_m) && characteristic_length_m>0)))
    error('thesis_extended_atmosphere:CharacteristicLength', ...
        'Characteristic length must be positive or NaN.');
end

R=287.0;
g0=9.806;
earth_radius=6378.14e3;
gravity_gradient=2/earth_radius;
gamma=1.405;
sutherland_C=110.4;
sutherland_beta=1.458e-6;
molar0=28.964;
avogadro=6.0220978e23;
molecular_diameter=3.65e-10;

z=1e3*[0,11.0191,20.0631,32.1619,47.3501,51.4125, ...
    71.8020,86,100,110,120,150,160,170,190,230,300,400,500,600,700,2000];
temp=[288.15,216.65,216.65,228.65,270.65,270.65,214.65,186.946, ...
    210.65,260.65,360.65,960.65,1110.60,1210.65,1350.65,1550.65, ...
    1830.65,2160.65,2420.65,2590.65,2700,2700];
molar=[28.964,28.964,28.964,28.964,28.964,28.964,28.962,28.962, ...
    28.880,28.560,28.070,26.920,26.660,26.500,25.850,24.690, ...
    22.660,19.940,17.940,16.840,16.170,16.170];
lapse=[-6.5e-3,0,1e-3,2.8e-3,0,-2.8e-3,-2e-3,1.693e-3, ...
    5e-3,1e-2,2e-2,1.5e-2,1e-2,7e-3,5e-3,4e-3,3.3e-3, ...
    2.6e-3,1.7e-3,1.1e-3,0];

Pbase=zeros(size(z));
rhobase=zeros(size(z));
Pbase(1)=101325;
rhobase(1)=Pbase(1)/(R*temp(1));

for i=1:(numel(z)-1)
    dz=z(i+1)-z(i);
    if lapse(i)~=0
        c1=1+gravity_gradient*(temp(i)/lapse(i)-z(i));
        exponent=c1*g0/(R*lapse(i));
        tratio=temp(i+1)/temp(i);
        correction=exp(gravity_gradient*g0*dz/(R*lapse(i)));
        Pbase(i+1)=Pbase(i)*tratio^(-exponent)*correction;
        rhobase(i+1)=rhobase(i)*tratio^(-(exponent+1))*correction;
    else
        expo=-g0*dz*(1-gravity_gradient*(z(i+1)+z(i))/2)/(R*temp(i));
        Pbase(i+1)=Pbase(i)*exp(expo);
        rhobase(i+1)=rhobase(i)*exp(expo);
    end
end

rho=zeros(size(h));
P=zeros(size(h));
Tkin=zeros(size(h));
Meff=zeros(size(h));
for j=1:numel(h)
    hj=h(j);
    i=find(z<=hj,1,'last');
    if i==numel(z), i=numel(z)-1; end
    dz=hj-z(i);
    if lapse(i)~=0
        Tlocal=temp(i)+lapse(i)*dz;
        c1=1+gravity_gradient*(temp(i)/lapse(i)-z(i));
        exponent=c1*g0/(R*lapse(i));
        tratio=Tlocal/temp(i);
        correction=exp(gravity_gradient*g0*dz/(R*lapse(i)));
        P(j)=Pbase(i)*tratio^(-exponent)*correction;
        rho(j)=rhobase(i)*tratio^(-(exponent+1))*correction;
    else
        Tlocal=temp(i);
        expo=-g0*dz*(1-gravity_gradient*(hj+z(i))/2)/(R*temp(i));
        P(j)=Pbase(i)*exp(expo);
        rho(j)=rhobase(i)*exp(expo);
    end
    frac=(hj-z(i))/(z(i+1)-z(i));
    Meff(j)=molar(i)+(molar(i+1)-molar(i))*frac;
    Tkin(j)=Tlocal*(Meff(j)/molar0);
end

a=sqrt(gamma*R.*Tkin);
mu=sutherland_beta*Tkin.^1.5./(Tkin+sutherland_C);
molecule_mass=(Meff*1e-3)/avogadro;
number_density=rho./molecule_mass;
lambda=1./(sqrt(2)*pi*number_density*molecular_diameter^2);
mach=v./a;

if isnan(characteristic_length_m)
    re=NaN(size(h));
    kn=NaN(size(h));
    regime=repmat({''},size(h));
else
    re=rho.*v*characteristic_length_m./mu;
    kn=lambda/characteristic_length_m;
    regime=repmat({'transition'},size(h));
    regime(kn<=0.01)={'continuum'};
    regime(kn>=10)={'free-molecular'};
end

atm.rho_kg_m3=rho;
atm.pressure_Pa=P;
atm.temperature_K=Tkin;
atm.speed_of_sound_m_s=a;
atm.dynamic_viscosity_Pa_s=mu;
atm.molar_mass_g_mol=Meff;
atm.mean_free_path_m=lambda;
atm.mach=mach;
atm.reynolds=re;
atm.knudsen=kn;
atm.flow_regime=regime;
atm.valid_altitude_m=[0 2e6];
atm.source=['Independent reconstruction of atmosphere/Knudsen model ', ...
    'described in Gaspar MSc thesis (2014); layer values cross-checked ', ...
    'against recovered thesis-era development source.'];
end
