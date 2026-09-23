
function [vG,vD]=gravity_turn(Isp1,Isp2,Isp3,Isp4,Mp1,Mp2,Mp3,Mp4,M_1,M_2,M_3,M_4,T_1,T_2,T_3,T_4)

global m01 m02 m03 m04 g0 T1 T2 T3 T4 A Cd rh0  Re hgr_turn tf md1 md2 md3 md4 tb1 tb2 tb3 tb4 N tc1 tc2 tc3 h_orbit q
% Descriçăo da funçăo
Alt = 0.5;              %[m] Alt above sea level
% N=2;
% 
% m_stage_gross = [195796, 25751, 10948];% 1st, 2nd,3d
% T= [T1 T2 T3 T4];
% tb = [tb1 tb2 tb3]
% First stage(Solid Fuel)
m_prop1=  Mp1 ;%108365;       % [kg] Propellant mass
m_prop2=  Mp2 ;%85000;
m_prop3=  Mp3 ;
m_prop4=  Mp4 ;
% h_orbit = H=;%200000;
% Isp1 = 311 ; % [s]  Specific impulse
% Isp2 = 342;
% Isp3 = 430;
% Isp4 = 430;

g0     = 9.81;        % [m/s^2] Constant at its sea-level value
m01  = M_1;         % [kg] Initial mass
m02  = M_2;
m03  = M_3;
m04  = M_4;
d   = 3;           % [m]  Diameter
A   = pi*d^2/4;       % [m^2]Frontal area
% Cd  = 0.5 ;             % Drag coefficient,assumed to have the constant value
rh0 = 1.225;          % [kg/m^3]
% H0 = 7500;            % [m] Density scale height
% Re = 6378e3;          % [m] Earth's radius
hgr_turn = 1500;       % [m] Rocket starts the gravity turn when h = hgr_turn
% tb1 = 180 ;%160.8;  % [s] Fuell burn time, first stage
% tb2 = 155;%200;
% tb3 = 195;
% tb4 = 180;
tc1=5; 
tc2=5;
tc3=5;
md1 = (m_prop1)/tb1; % [kg/s]Propellant mass flow rate
md2 = (m_prop2)/tb2;
md3 = (m_prop3)/tb3;
md4 = (m_prop4)/tb4;
T1   = T_1;%md1*(Isp1*g0);    % [N] Thrust (mean) 2000000;% 5885000;
T2   = T_2;%md2*(Isp2*g0);   %1500000;% 801000;%
T3   = T_3;%md3*(Isp3*g0);
T4   = T_4;%md4*(Isp4*g0);
mf1 = m01 - m_prop1;     % [kg] Final mass of the rocket(first stage is empty)
mf2 = m02 - m_prop2;     % [kg] Final mass of the rocket(first stage is empty)
mf3 = m03 - m_prop3;
mf4 = m04 - m_prop4;
t0 = 0;               % Rocket launch time
if N==2
    tf = t0 + tb1 + tc1 + tb2;
elseif N == 3
    tf = t0 + tb1 + tc1 + tb2 + tc2 + tb3 ;
elseif N ==4
    tf = t0 + tb1 + tc1 + tb2 + tc2 + tb3 + tc3 + tb4;
end
% tf = t0 + tb1 + tb2+ tb3 +tb4;      % The time when propellant is completely burned
%and the thrust goes to zero
t_range     = [t0,tf];  % Integration interval

% Launch initial conditions:
gamma0 = 89.5/180*pi;       % Initial flight path angle
v0 = 0;   % Velocity (m/s)  % Earth's Rotation considered in eq of motion.
x0 = 0;   % Downrange distance [km]
h0 = Alt; % Launch site altitude [km]
vD0 = 0;  % Loss due to drag (Velocity)[m/s]
vG0 = 0;  % Loss due to gravity (Velocity)[m/s]
q0 = 0;
state0   = [v0, gamma0, x0, h0, vD0, vG0];
% Solve initial value problem for ordinary differential equations
[t,state] = ode45(@RocketDynEq,t_range,state0) ;
v     = state(:,1)/1000;      % Velocity [km/s]
gamma = state(:,2)*180/pi;    % Flight path angle  [deg]
x     = state(:,3)/1000;      % Downrange distance [km]
h     = state(:,4)/1000;      % Altitude[km]
vD    = -state(:,5);%/1000;     % Loss due to drag (Velocity)[m/s]
vG    = -state(:,6);%/1000;     % Loss due to gravity (Velocity)[m/s]


% q(i) = 1/2*Rho*v(i)^2; %...Dynamic pressure
% if abs(vG-vG0) > 0.2 && abs(vD-vD0) > 0.1
% return
% else 

plot(t,h,'b');
hold on;
grid on;
plot(t,h,'.b');
title('Rocket Ascent');
xlabel('time[s]');
ylabel('Altitude[km]');
text(80,5,'...','Color',[0 0 1], 'VerticalAlignment','middle',...
    'HorizontalAlignment','left','FontSize',14 );
figure
plot(t,gamma);
xlabel('t');
ylabel('phi');
figure
plot(x,h);
xlabel('downrange[km]');
ylabel('Altitude[km]');
figure
plot(t,x);
xlabel('time');
ylabel('downrange[km]');

% figure
% plot(h, D)
% xlabel('Altitude (km)')
% ylabel('Drag (N/m^2)')
% axis([-inf, inf, -inf, inf])
% grid

% figure
% plot(h, q)
% xlabel('Altitude (km)')
% ylabel('Dynamic pressure (N/m^2)')
% axis([-inf, inf, -inf, inf])
% grid

% 
% % VEGA Rocket: First Stage P80
% fprintf('\n Two Stage Rocket\n')
% fprintf('\n Propellant mass           = %4.2f [kg]',m_prop1)
% % fprintf('\n Gross mass                = %4.2f [kg]',m_stage_gross(1))
% fprintf('\n Isp                       = %4.2f [s]',Isp1)
% fprintf('\n Thrust(mean)              = %4.2f [kN]',T1/1000)
% fprintf('\n Thrust(mean)              = %4.2f [kN]',T2/1000)
% fprintf('\n Initial flight path angle = %4.2f [deg]',gamma0*180/pi)
% fprintf('\n Final speed               = %4.2f [km/s]',v(end))
% fprintf('\n Final flight path angle   = %4.2f [deg]',gamma(end))
% fprintf('\n Altitude                  = %4.2f [km]',h(end))
% fprintf('\n Downrange distance        = %4.2f [km]',x(end))
 fprintf('\n Drag loss                 = %4.2f [km/s]',vD(end))
 fprintf('\n Gravity loss              = %4.2f [km/s]',vG(end))
% fprintf('\n');

end
