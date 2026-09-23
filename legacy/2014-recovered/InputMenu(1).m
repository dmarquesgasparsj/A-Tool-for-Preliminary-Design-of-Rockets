%==========================================================================
%                        Engenharia Aeroespacial
%                    Disserataçăo
%                         2ş Semestre 2012/2013
%                       Input Menu (Main)
%  Orientador
%  Prof. Paulo J. S. Gil
%  Student:
%  Diogo Gaspar Nş65539
%
%==========================================================================

%Possibilidade de fazer lista com Launch sites
% possibilidade de perguntarse quer solid stages para o 1 estagio e
% Boosters.

clc
close all;
clear all;

global g0 N tb1 tb2 tb3 tb4;
g0=9.81; %- sea-level acceleration of gravity (m/s^2)
mu=3.986*10^14; %- gravitational parameter (km^3/s^2)
r0=6378.14; %- earth radius (km)

prompt={'Enter your payload mass(kg):','Enter H0 (Km):'}; %,'Enter V0 (m/s):','Enter gamm0:'
% Create all your text fields with the questions specified by the variable prompt.
title='Input Objective';
% The main title of your input dialog interface.
answer=inputdlg(prompt,title);
Mpl = str2double(answer{1});
H0= str2double(answer{2});
% V0= str2double(answer{3});
% Gamma0= str2double(answer{4});

V0= sqrt(3.9860044e5/(6378.14+H0/1000))*1000;

% Vc = sqrt(3.9860044e5/(6378.14+h/1000))*1000;

% if PayloadMass < 500
%        % Definiçăo de Small Medium e Large pelo Turner Apresentar
%        sugestăo
%       elseif PayloadMass > 500
%
% else > 1000
%
% end

prompt={'Enter your Number of Stages(2-4):','Enter number of Boosters(0 if dont exist):'};% 'Enter launch lattitude(0-90ş):',
% Create all your text fields with the questions specified by the variable prompt.
title='Input Data Rocket Design';
% The main title of your input dialog interface.
answer=inputdlg(prompt,title);
N= str2double(answer{1});
Boost = str2double(answer{2});
% launchlat= str2double(answer{2});


% Type of cones of boosters choose 4.
format short g
menuchoice = menu('Choose Rocket Cone Shape','1-Ogive'...
    ,'2-Power','3-Ellipse','4-Haack');

if menuchoice == 1
    Cd = 0.1;
    name = '1';
end
if menuchoice == 2
    Cd = 0.15;
    name = '2';
end
if menuchoice == 3
    Cd = 0.2;
    name = '3';
end
if menuchoice == 4
    Cd = 0.25;
    name = '4';
end

% if M <= .8
% Cd = .4;
% elseif M <= 1.5
% Cd = .8570.*M - .2857;
% elseif M > 1.55
% Cd = .55 + .45.*exp( - .9.*(M - 1.5));
% end

% Relative diameter of stages
% Interstage elements? 1 a desprezar
%Definition of fairing : 1 - diameter? height?

% Determinacao do Delta V com perdas por drag e gravidade e com a latitude
% de lançamento

% Definition of roppelant for each stage - fornecer lista ou tabela com dados de propellants solidos e liquidos;

if N == 2
    [Isp1,Isp2,OF2,OF1]= propellant_2 (g0);
elseif N == 3
    [Isp1,Isp2,Isp3,OF3,OF2,OF1]=propellant_3 (g0);
elseif N == 4
    [Isp1,Isp2,Isp3,Isp4,OF4,OF3,OF2,OF1]=propellant_4 (g0);
end


DeltaV = V0;
% DeltaVrot = 465.1*cos(0.0174533*launchlat);
vDi = 0.008*DeltaV;
vGi = 0.08*DeltaV;
DeltaVestimation = DeltaV+vDi+vGi;%-DeltaVrot
% fprintf('%d\n Delta V estimation\n',deltaVestimation);

% DeltaVdrag = vD;
% DeltaVgravity = vG;
Isp3=0;
Isp4=0;
tb3=0;
tb4=0; % Inicializaçăp p+ara nao dar erro
Mp3=0;
Mp4=0;
M_3=0;
M_4=0;
T_3=0;
T_4=0;

if N == 2
    [m0,M_2,tb1,tb2,T_1,T_2,V1perc,V2perc,Mp1,Mp2,M_1]=mass_model_n_2 (DeltaVestimation,Mpl,Isp1,Isp2,OF1,OF2);
elseif N == 3
    [m0,tb1,tb2,tb3,T_1,T_2,T_3,V1perc,V2perc,V3perc,Mp1,Mp2,Mp3,M_1,M_2,M_3]=mass_model_n_3 (DeltaVestimation,Mpl,Isp1,Isp2,Isp3,OF1,OF2,OF3) ;% Eps = Epsilon = structural factor
elseif N == 4
    [m0,tb1,tb2,tb3,tb4,T_1,T_2,T_3,T_4,V1perc,V2perc,V3perc,V4perc,Mp1,Mp2,Mp3,Mp4,M_1,M_2,M_3,M_4]=mass_model_n_4 (DeltaVestimation,Mpl,Isp1,Isp2,Isp3,Isp4,OF1,OF2,OF3,OF4);
end

[vG,vD]=gravity_turn(Isp1,Isp2,Isp3,Isp4,Mp1,Mp2,Mp3,Mp4,M_1,M_2,M_3,M_4,T_1,T_2,T_3,T_4);

 return
contador=0;
% while abs(vDi-vD)>0.2

while abs(vGi-vG)>0.2
    vDi=vD;
    vGi=vG;
    DeltaVestimation = DeltaV+vDi+vGi-DeltaVrot;
    if N == 2
        [m0,tb1,tb2]=mass_model_n_2_it (DeltaVestimation,Mpl,Isp1,Isp2,OF1,OF2,T_1,T_2,V1perc,V2perc);
    elseif N == 3
        [m0,tb1,tb2,tb3]=mass_model_n_3 (DeltaVestimation,Mpl,Isp1,Isp2,Isp3,OF1,OF2,OF3,T_1,T_2,T_3,V1perc,V2perc,V3perc) ;% Eps = Epsilon = structural factor
    elseif N == 4
        [m0,tb1,tb2,tb3,tb4]=mass_model_n_4 (DeltaVestimation,Mpl,Isp1,Isp2,Isp3,Isp4,OF1,OF2,OF3,OF4,T_1,T_2,T_3,T_4,V1perc,V2perc,V3perc,V4perc);
    end
    contador=contador+1
    [vG,vD]=gravity_turn(Isp1,Isp2,Isp3,Isp4,Mp1,Mp2,Mp3,Mp4,M_1,M_2,M_3,M_4,T_1,T_2,T_3,T_4);
    
end

% end

return

% filename= 'rocket.mat';
% save(rocket.mat,variables) % se as variaveis nao estiverem
% especificadasgrava todas as variaveis do workspace

% mass_model % [Ms, Mp, LOW]=mass_model(Isp,Eps,DeltaVestimations)

if NumberStages == 2
    [vG,vD]=gravity_turn_2(m0,bt1,bt2);   % chama a funçăo gravity turn
elseif NumberStages == 3
    
    [vG,vD]=gravity_turn_3(m0,bt1,bt2,bt3);   % chama a funçăo gravity turn
elseif NumberStages == 4
    
    [vG,vD]=gravity_turn_4(Isp1,Isp2,Isp3,Isp4,Mp1,Mp2,Mp3,Mp4,M_1,M_2,M_3,M_4);   % chama a funçăo gravity turn
end


% Aplicarlimite para delta-V/Ve ser sempre menor que 2,8