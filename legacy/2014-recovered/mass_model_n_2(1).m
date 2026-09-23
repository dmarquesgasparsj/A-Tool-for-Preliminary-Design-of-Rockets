% function mass_model para 2 estágios
% if b=0
% %     function mass_model
% %      function mass_model_boosters

function [m0,M_2,tb1,tb2,T_1,T_2,V1perc,V2perc,Mp1,Mp2,M_1]=mass_model_n_2 (DeltaVestimation,Mpl,Isp1,Isp2,OF1,OF2) % Eps = Epsilon = structural factor, vai ter que sair burn time para a trajectory
% clear all
% clc
% DeltaVestimation=9500;
% Mpl=5000;
% Isp1=400;
% Isp2=450;
% OF1=2;
% OF2=3;
% T_1=10000;
% T_2=10000;
% V1perc=50;
% V2perc=50;

prompt={'Enter Thrust of 1 stage (kN):','Enter Thrust of 2 stage (kN)'};
title='Thrust for each Stage(kN)';
answer=inputdlg(prompt,title);
T_1= str2double(answer{1});
T_2= str2double(answer{2});

T_1=T_1*1000;
T_2=T_2*1000;

prompt={'Enter % of 1 stage:','Enter % of 2 stage'};
title='Delta-V division';
answer=inputdlg(prompt,title);
V1perc= str2double(answer{1});
V2perc= str2double(answer{2});


data_LOW = zeros(20,2,20);
Mglobal = zeros(13,5,21);
Msel=zeros(21,7);
occ=zeros(1,20);

V1perc= V1perc/100;
V2perc= V2perc/100;

while V1perc + V2perc ~= 1
    
    prompt={'Enter % of 1 stage:','Enter % of 2 stage'};
    title='Delta-V division';
    answer=inputdlg(prompt,title);
    V1perc= str2double(answer{1});
    V2perc= str2double(answer{2});
    
    V1perc= V1perc/100;
    V2perc= V2perc/100;
    
end

V1per=zeros(1,21);
DeltaV1=zeros(1,21);
k1=zeros(1,21);
k2=zeros(1,21);

% Variar V1per +-10%
iii=1;
ii=1;

% Fazer while T/W > 1.2 para garantir o Lift Off

for V2per = (V2perc-0.1):0.01:(V2perc+0.1)     % ciclo for para %V1 a variar% +-10%
    iii=iii+1;
    iiii=1;
    iiiii=1;
    V1per(ii) = 1 - V2per;
    Mglobal(:,1,ii)=V1per(ii);
    
    %     perV2=perV1*100-39;
    %     perV3=round(perV2);
    %   DeltaV1 = perV1*DeltaVestimation;
    % plot(LOW,perV1)
    % %(2,perV1)
    % ttt=ttt+1;
    % LOW(1,perV3)=DeltaV1;
    
    g0=9.81;
    %         fprintf('\n\n -----------------------------------\n')
    %         fprintf('%d\n Percen V2per ',ii);
    %         fprintf('\n\n -----------------------------------\n')
    DeltaV1(ii) = V1per(ii)*DeltaVestimation;
    
    k1(ii)=exp(DeltaV1(ii)/(Isp1*g0));
    k2(ii)=exp((DeltaVestimation-DeltaV1(ii))/(Isp2*g0));
    
    for Eps2 = 0.05:0.01:0.17
        
        Mglobal(iiii,3,ii)=(Mpl*(Eps2*(k2(ii)-1))/(1-Eps2*k2(ii)));
        
        
        
        Ms2=Mpl*(Eps2*(k2(ii)-1))/(1-Eps2*k2(ii));%/10 % Arredondamento para baixo as dezenas
        %         Ms2=round(Ms2);
        %         Ms2=Ms2*10;
        %
        Mp2= Mpl*((k2(ii)-1)*(1-Eps2))/(1-Eps2*k2(ii));
        %
        M_2=Ms2+Mp2+Mpl;
        %
        % Temos as densidades e o MixtureRatio definidos de todos os propellants
        % % Mp4=Mp4*1.02; % Safety factor 2%
        E_2=20; % Nozzle area ratio
        Mo2=OF2*Mp2/(OF2+1);
        Mf2=Mp2 /(OF2+1);
        M_Prop_H2=Mf2;
        M_Prop_LOX=Mo2;
        M_H2_Tank=0.128*M_Prop_H2;                 % Akin Mass Estimation Relationships
        M_LOX_Tank=0.0107*M_Prop_LOX;             % Akin Mass Estimation Relationships
        %                 M_fairing=4.95*Area_fairing^1.15;          % Akin, definiçăo da mass do fairing pela Area
        %M_Nozzle=125*(Mp2/5400)^(2/3)*(E_2/10)^(1/4);
        M_avionics=10*M_2^0.361;                 % Akin definiçăo massa avionics
        %                 M_Motor_Solid_Rocket = 0.135*Mp2;          % Akin, possivel definiçăo de masa para os boosters de combustivel solido
        M_Thrust_Structure= 2.55*10^-4*T_2;        % Akin definition pede Thrust e Newton
        M_Eng=(7.81*10^-4*T_2+3.37*10^-5*T_2*E_2^0.5 + 59)*0.2;
        %                 Ms2e=(M_H2_Tank+M_LOX_Tank+M_Thrust_Structure+M_avionics+M_Nozzle)/10;              %+M_fairing;%+M_avionics+M_Thrust_Structure;
        %                 Ms2e=round(Ms2e);
        %                 Ms2e=Ms2e*10;
        Mglobal(iiii,5,ii)=(M_H2_Tank+M_LOX_Tank+M_Thrust_Structure+M_avionics+M_Eng);%+M_Nozzle
        Ms2e=(M_H2_Tank+M_LOX_Tank+M_Thrust_Structure+M_avionics+M_Eng);%+M_Nozzle
        
        %         fprintf('\n\n -----------------------------------\n');
        %         fprintf('%d\n Structural factor 2 ',Eps2);
        %         fprintf('\n\n -----------------------------------\n');
        %         fprintf('%d\n Structural Mass 2 ',Ms2);
        %         fprintf('\n\n -----------------------------------\n');
        %         fprintf('%d\n Structural Mass Heuristic 2\n',Ms2e);
        %         fprintf('\n\n -----------------------------------\n');
        %         fprintf('\n\n -----------------------------------\n')
        
        if Mglobal(iiii,3,ii)/Mglobal(iiii,5,ii) <= 1.1 && Mglobal(iiii,3,ii)/Mglobal(iiii,5,ii) > 0.9
            fprintf('2 estagio: %g %g %g %g\n',[Mglobal(iiii,3,ii) Mglobal(iiii,5,ii) Eps2 V1per(ii)]);
            Msel(ii,1)=V1per(ii);
            Msel(ii,2)=V2per;
            Msel(ii,4)=Eps2;
            Msel(ii,6)=Mglobal(iiii,3,ii);
            
        end
        
        
        iiii=iiii+1;
        
    end
    
    
    for Eps1 = 0.05:0.01:0.17
        
        Mglobal(iiiii,2,ii)=(M_2*(Eps1*(k1(ii)-1))/(1-Eps1*k1(ii)));
        Ms1=(M_2*(Eps1*(k1(ii)-1))/(1-Eps1*k1(ii))); % Arredondamento para baixo as dezenas
        %         Ms1=round(Ms1);
        %         Ms1=Ms1*10;
        %
        Mp1= M_2*((k1(ii)-1)*(1-Eps1))/(1-Eps1*k1(ii));
        
        %
        LOW=M_2+Ms1+Mp1;
        %
        E_1=30; % Nozzle area ratio
        Mo1=OF1*Mp1/(OF1+1);
        Mf1=Mp1 /(OF1+1);
        M_Prop_H2=Mf1;
        M_Prop_LOX=Mo1;
        M_H2_Tank=3*0.128*M_Prop_H2;                 % Akin Mass Estimation Relationships
        M_LOX_Tank=3*0.0107*M_Prop_LOX; % Akin Mass Estimation Relationships
        % M_fairing=4.95*Area_fairing^1.15; % Akin, definiçăo da mass do fairing pela Area
        %         M_Nozzle=125*(Mp1/5400)^(2/3)*(E_1/10)^(1/4);
        M_avionics=10*LOW^0.361;   %Akin definiçăo massa avionics
        % M_Motor_Solid_Rocket = 0.135*M_propellants; % Akin, possivel definiçăo de masa para os boosters de combustivel solido
        M_Eng=(7.81*10^-4*T_1+3.37*10^-5*T_1*E_1^0.5 + 59);
        M_Thrust_Structure= 1.55*10^-4*T_1; % Akin definition pede Thrust e Newton
        %                 Ms1e=(M_H2_Tank+M_LOX_Tank+M_Thrust_Structure+M_avionics+M_Nozzle)/10; %+M_fairing+M_avionics
        %                 Ms1e=round(Ms1e);
        %                 Ms1e=Ms1e*10;
        Ms1e=(M_H2_Tank+M_LOX_Tank+M_Thrust_Structure+M_avionics+M_Eng);
        Mglobal(iiiii,4,ii)=(M_H2_Tank+M_LOX_Tank+M_Thrust_Structure+M_avionics+M_Eng);%+M_Nozzle
        %         fprintf('\n\n -----------------------------------\n')
        %         fprintf('%d\n Structural factor 1 ',Eps1);
        %         fprintf('\n\n -----------------------------------\n')
        %         fprintf('%d\n Structural Mass 1',Ms1);
        %         fprintf('\n\n -----------------------------------\n')
        %         fprintf('%d\n Structural Mass Heuristic 1\n',Ms1e);
        %         fprintf('\n\n -----------------------------------\n')
        %         fprintf('\n\n -----------------------------------\n')
        
        % plot(LOW,V1per)
        
        
        if Mglobal(iiiii,2,ii)/Mglobal(iiiii,4,ii) <= 1.1 && Mglobal(iiiii,2,ii)/Mglobal(iiiii,4,ii) > 0.9
            fprintf('1 estagio: %g %g %g %g\n',[Mglobal(iiiii,2,ii) Mglobal(iiiii,4,ii) Eps1 V1per(ii)]);
            
            Msel(ii,3)=Eps1;
            Msel(ii,5)=Mglobal(iiiii,2,ii);
        end
        
        
        iiiii=iiiii+1;
        
        
        
        
    end
    
    %     if Ms1==Ms1e && Ms2==Ms2e
    %
    %         data_LOW(iii,1,:)=Eps1;
    %         data_LOW(iii,2,:)=Eps2;
    %         occ(iii)=1;
    %     end
    ii=ii+1;
    
    % end
    % data_LOW_low=zeros(sum(occ),2,15);
    %
    % for a=1:size(occ,1)
    %
    %     if    occ(a)==1
    %         data_LOW_low(a,:,:)=data_LOW(a,:,:);
    %     end
    %
    % end
    
end
for i6=1:1:length(Msel(:,1))
    if Msel(i6,5)>0 && Msel(i6,6)>0
        Msel(i6,7)=Msel(i6,5)+Msel(i6,6);
    end
end

MMsel=Msel(:,7);

LOW=min(MMsel(MMsel~=0));
%LOWidx=find(MMsel==LOW);  % retorna o indice do valor escolhido (low LOW)
LOWidx = find(MMsel(:,1)==LOW);

dV1=Msel(LOWidx,1);
dV2=Msel(LOWidx,2);
Eps1=Msel(LOWidx,3);
Eps2=Msel(LOWidx,4);

dV1final=dV1*DeltaVestimation;

k1=exp(dV1final/(Isp1*g0));
k2=exp((DeltaVestimation-dV1final)/(Isp2*g0));

Ms2=Mpl*(Eps2*(k2-1))/(1-Eps2*k2);
Mp2= Mpl*((k2-1)*(1-Eps2))/(1-Eps2*k2);
M_2=Ms2+Mp2+Mpl;

Ms1=(M_2*(Eps1*(k1-1))/(1-Eps1*k1)); 
Mp1= M_2*((k1-1)*(1-Eps1))/(1-Eps1*k1);
M_1= Ms1+Mp1+M_2;      
       
tb1= (Mp1*g0*Isp1)/T_1;
tb2= (Mp2*g0*Isp2)/T_2;

m0=LOW;



fprintf('%d\n Lift off weight',LOW);
fprintf('\n\n -----------------------------------\n')


T2W_1 = T_1/(LOW*9.81);
T2W_2 = T_2/(M_2*9.81);


% prompt={'Diameter of 1 stage (m):','Diameter of 2 stage(m)'};
% title='Diameter for each Stage (m)';
% answer=inputdlg(prompt,title);
% d1= str2double(answer{1});
% d2= str2double(answer{2});

if Mpl < 2000
    
    V_fair=0.6959*exp(0.0044*M_fair);
    
    d1=2.11;
    d2=1.84;
    
    ld1=5,823;
    ld2=2,647;
    
    l1=ld1*d1;
    l2=ld2*d2;
    
elseif Mpl >= 2000 && Mpl < 20000
    
    V_fair=8.9067*exp(0.0009*M_fair);
    
    
    d1=3.84;
    d2=3.58;
    
    
    ldbooster=7,313;
    ld1=8,574;
    ld2=2,278;
    
    l1=ld1*d1;
    l2=ld2*d2;
    
else
    
    V_fair=17.891*exp(0.0005*M_fair);
    
    
    d1=4.43;
    d2=4.18;
    
    ldbooster=11,99;
    ld1=6,2413;
    ld2=2,7715;
    
    l1=ld1*d1;
    l2=ld2*d2;
    
end
save all;
return

% Sabendo os valores do vector que estăo bem, fazer as contas para LOW
% Para cada Delta-V e Eps1 & Eps2 fazer as contas para obter o valor mais
% pequeno de LOW
% DeltaV1 = V1per*DeltaVestimation;
% k1(ii)=exp(DeltaV1/(Isp1*g0));
% k2(ii)=exp((DeltaVestimation-DeltaV1)/(Isp2*g0));
%
% Ms2=(Mpl*(Eps2*(k2(ii)-1))/(1-Eps2*k2(ii)))/10; % Arredondamento para baixo as dezenas
% Ms2=round(Ms2);
% Ms2=Ms2*10;
% Mp2= Mpl*((k2(ii)-1)*(1-Eps2))/(1-Eps2*k2(ii));
% M_2=Ms2+Mp2+Mpl;
%
% Ms1=(Mpl*(Eps2*(k2(ii)-1))/(1-Eps2*k2(ii)))/10; % Arredondamento para baixo as dezenas
% Ms1=round(Ms1);
% Ms1=Ms1*10;
% Mp1= M_2*((k1(ii)-1)*(1-Eps1))/(1-Eps1*k1(ii));
% LOW=M_2+Ms1+Mp1;
%
%
%
% LOW = zeros(2,21);
% MIN_LOW=min(LOW(2,:));

% Ms1= Mpl*((k1(ii)-1)*k2(ii)*Eps1*(1-Eps2))/((1-Eps1*k1(ii))*(1-Eps2*k2(ii)));
% Mp1= Mpl*((k1(ii)-1)*k2(ii)*(1-Eps1)*(1-Eps2))/((1-Eps1*k1(ii))*(1-Eps2*k2(ii)));
% LOW(2,perV3) = Mpl*(k1(ii)*k2(ii)*(1-Eps1)*(1-Eps2))/((1-Eps1*k1(ii))*(1-Eps2*k2(ii)));
% LOW = Mpl*(k1(ii)*k2(ii)*(1-Eps1)*(1-Eps2))/((1-Eps1*k1(ii))*(1-Eps2*k2(ii)));
% MIN_LOW=min(LOW(2,:));


%
% fprintf('%d\n Lift off weight',LOW);
% fprintf('\n\n -----------------------------------\n')
% fprintf('%d\n M2 estimation\n',M_2);
% fprintf('\n\n -----------------------------------\n')
% fprintf('%d\n Delta V estimation\n',DeltaVestimation);
% fprintf('\n\n -----------------------------------\n')
% fprintf('%d\n T/W_1\n',T2W_1);
% fprintf('\n\n -----------------------------------\n')
% fprintf('%d\n T/W_2\n',T2W_2);
% fprintf('\n\n -----------------------------------\n')
% Temos as densidades e o MixtureRatio definidos de todos os propellants
%
% M_H2_Tank=0.128*M_Prop_H2; % Akin Mass Estimation Relationships
% M_LOX_Tank=0.0107*M_Prop_LOX; % Akin Mass Estimation Relationships
% M_fairing=4.95*Area_fairing^1.15; % Akin, definiçăo da mass do fairing pela Area
% M_avionics=10*LOW^0.361; %Akin definiçăo massa avionics
% M_Motor_Solid_Rocket = 0.135*M_propellants; % Akin, possivel definiçăo de masa para os boosters de combustivel solido
% M_Thrust_Structure= 2.55*10^-4*Thrust; % Akin definition pede Thrust e Newton

% Comparaçăo heuristica

% Engine and Nozzle
% Propellant tank
% thrust structre
% Avionics
end
