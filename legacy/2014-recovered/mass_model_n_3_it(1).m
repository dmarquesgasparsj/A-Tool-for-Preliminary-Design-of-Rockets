% function mass_model para 3 estagios
% if b=0
% %     function mass_model
% %      function mass_model_boosters


function [m0,tb1,tb2,tb3,V1perc,V2perc,V3perc,Mp1,Mp2,Mp3,M_1,M_2,M_3]=mass_model_n_3_it (DeltaVestimation,Mpl,Isp1,Isp2,Isp3,OF1,OF2,OF3) % Eps = Epsilon = structural factor
% clear all
% clc
% DeltaVestimation=8000;
% Mpl=200;
% Isp1=300;
% Isp2=350;
% Isp3=400;
% OF1=3;
% OF2=3;
% OF3=3;
% T_1= 100*1000;
% T_2=50*1000;
% T_3= 10*1000;
% V1perc= 40;
% V2perc= 40;
% V3perc= 20;

% prompt={'Enter Thrust of 1 stage(kN):','Enter Thrust of 2 stage(kN):','Enter Thrust of 3 stage(kN):'};
% title='Thrust for each Stage (kN)';
% answer=inputdlg(prompt,title);
% T_1= str2double(answer{1});
% T_2= str2double(answer{2});
% T_3= str2double(answer{2});
% 
% T_1= T_1*1000;
% T_2= T_2*1000;
% T_3= T_3*1000;
% 
% prompt={'Enter % of 1 stage:','Enter % of 2 stage','Enter % of 3 stage:'};
% title='Delta-V division';
% answer=inputdlg(prompt,title);
% V1perc= str2double(answer{1});
% V2perc= str2double(answer{2});
% V3perc= str2double(answer{3});
% 
% 
% 
% V1perc= V1perc/100;
% V2perc= V2perc/100;
% V3perc= V3perc/100;
% 
% 
% while V1perc + V2perc + V3perc ~= 1
%     
%     prompt={'Enter % of 1 stage:','Enter % of 2 stage','Enter % of 3 stage'};
%     title='Delta-V division';
%     answer=inputdlg(prompt,title);
%     V1perc= str2double(answer{1});
%     V2perc= str2double(answer{2});
%     V3perc= str2double(answer{3});
%     
%     V1perc= V1perc/100;
%     V2perc= V2perc/100;
%     V3perc= V3perc/100;
% end
 g0=9.81;
% 
% Msel=zeros(441,9);
% Mglobal = zeros(13,8,441);
% V1per=zeros(1,21);
% V2per=zeros(1,441);

ii=0;
iii=1;
for V1perc = (V1perc-0.1):0.01:(V1perc+0.1)
    %     iii=iii+1;
    ii=ii+1;
    
    V1per(ii)=V1perc;
    
    for V2perc = (V2perc-0.1):0.01:(V2perc+0.1)
        
        V2per(iii)=V2perc;
        
        if (1 - V1per(ii) - V2per(iii))>=0   % garantir que V3per nă é negatvo
            V3per = 1 - V1per(ii) - V2per(iii);
            
            if V3per >= V3perc -0.11 && V3per <= V3perc +0.1
                
                
                %fprintf('%g %g %g\n',V1per, V2per, V3per);
                
                
                Mglobal(:,1,iii)=V1per(ii);
                Mglobal(:,2,iii)=V2per(iii);
                
                
                DeltaV1 = V1per(ii)*DeltaVestimation; % ciclo for de 40 a 60% por exemplo
                DeltaV2 = V2per(iii)*DeltaVestimation;
                % DeltaV3 = V3per*DeltaVestimation
                
                k1=exp(DeltaV1/(Isp1*g0));
                k2=exp(DeltaV2/(Isp2*g0));
                k3=exp((DeltaVestimation-DeltaV1-DeltaV2)/(Isp3*g0));
                
                
                iiii=0;
                for Eps3 = 0.05:0.01:0.17
                    
                    iiii=iiii+1;
                    
                    Mglobal(iiii,7,iii)=(Mpl*(Eps3*(k3-1))/(1-Eps3*k3));
                    
                    % Upperstage
                    Ms3=round(Mpl*(Eps3*(k3-1))/(1-Eps3*k3));
                    
                    Mp3=Mpl*((k3-1)*(1-Eps3))/(1-Eps3*k3);
                    
                    M_3= Ms3+Mp3+Mpl;
                    
                    % Temos as densidades e o MixtureRatio definidos de todos os propellants
                    %
                    
                    % Mp3=Mp3*1.02; % Safety factor 2%
                    E_3=100; % Nozzle area ratio
                    M_Nozzle=125*(Mp3/5400)^(2/3)*(E_3/10)^(1/4);
                    Mo3=OF3*Mp3/(OF3+1);
                    Mf3=Mp3 /(OF3+1);
                    M_Prop_H2=Mf3;
                    M_Prop_LOX=Mo3;
                    M_H2_Tank=0.128*M_Prop_H2; % Akin Mass Estimation Relationships
                    M_LOX_Tank=0.0107*M_Prop_LOX; % Akin Mass Estimation Relationships
                    % M_fairing=4.95*Area_fairing^1.15; % Akin, definiçăo da mass do fairing pela Area
                    M_avionics=10*M_3^0.361; %Akin definiçăo massa avionics
                    % M_Motor_Solid_Rocket = 0.135*M_propellants; % Akin, possivel definiçăo de masa para os boosters de combustivel solido
                    M_Thrust_Structure= 2.55*10^-4*T_3; % Akin definition pede Thrust e Newton
                    Ms3e=round(M_H2_Tank+M_LOX_Tank+M_Thrust_Structure+M_avionics+M_Nozzle); %+M_fairing+M_avionics
                    
                    %             fprintf('%d\n Structural Mass',Ms3);
                    %             fprintf('\n\n -----------------------------------\n')
                    %             fprintf('%d\n Structural Mass Heuristic\n',Ms3e);
                    %             fprintf('\n\n -----------------------------------\n')
                    Mglobal(iiii,8,iii)=(M_H2_Tank+M_LOX_Tank+M_Thrust_Structure+M_avionics+M_Nozzle);
                    
                    if abs(Mglobal(iiii,7,iii)-Mglobal(iiii,8,iii))<=1000
                        fprintf('3 estagio: %g %g \n',[Mglobal(iiii,7,iii) Mglobal(iiii,8,iii)]);
                        Msel(ii,1)=V1per(ii);
                        Msel(ii,2)=V2per(iii);
                        Msel(ii,5)=Eps3;
                        Msel(ii,8)=Mglobal(iiii,7,ii);
                        
                    end
                    
                    
                end
                
                iiiii=0;
                for Eps2 = 0.05:0.01:0.17
                    %2 stage
                    
                    iiiii=iiiii+1;
                    
                    Ms2=round(M_3*(Eps2*(k2-1))/(1-Eps2*k2));
                    
                    Mglobal(iiiii,5,iii)=(M_3*(Eps2*(k2-1))/(1-Eps2*k2));
                    
                    Mp2=M_3*((k2-1)*(1-Eps2))/(1-Eps2*k2);
                    
                    M_2= M_3+Ms2+Mp2;
                    
                    % Temos as densidades e o MixtureRatio definidos de todos os propellants
                    %
                    % Mp2=Mp2*1.02; % Safety factor 2%
                    E_2=100; % Nozzle area ratio
                    M_Nozzle=125*(Mp2/5400)^(2/3)*(E_2/10)^(1/4);
                    Mo2=OF2*Mp2/(OF2+1);
                    Mf2=Mp2 /(OF2+1);
                    M_Prop_H2=Mf2;
                    M_Prop_LOX=Mo2;
                    M_H2_Tank=0.128*M_Prop_H2; % Akin Mass Estimation Relationships
                    M_LOX_Tank=0.0107*M_Prop_LOX; % Akin Mass Estimation Relationships
                    % M_fairing=4.95*Area_fairing^1.15; % Akin, definiçăo da mass do fairing pela Area
                    M_avionics=10*(M_2-M_3)^0.361; %Akin definiçăo massa avionics
                    % M_Motor_Solid_Rocket = 0.135*M_propellants; % Akin, possivel definiçăo de masa para os boosters de combustivel solido
                    M_Thrust_Structure= 2.55*10^-4*T_2; % Akin definition pede Thrust e Newton
                    Ms2e=round(M_H2_Tank+M_LOX_Tank+M_avionics+M_Thrust_Structure+M_Nozzle);%+M_fairing;
                    
                    Mglobal(iiiii,6,iii)=(M_H2_Tank+M_LOX_Tank+M_avionics+M_Thrust_Structure+M_Nozzle);
                    
                    
                    if abs(Mglobal(iiiii,5,iii)-Mglobal(iiiii,6,iii))<=1000
                        fprintf('2 estagio: %g %g \n',[Mglobal(iiiii,5,iii) Mglobal(iiiii,6,iii)]);
                        Msel(ii,1)=V1per(ii);
                        Msel(ii,2)=V2per(iii);
                        Msel(ii,4)=Eps2;
                        Msel(ii,7)=Mglobal(iiii,5,ii);
                    end
                    
                    
                end
                
                iiiiii=0;
                for Eps1 = 0.05:0.01:0.17
                    %1 stage
                    
                    iiiiii=iiiiii+1;
                    
                    Ms1=round(M_2*(Eps1*(k1-1))/(1-Eps1*k1));
                    
                    Mglobal(iiiiii,3,iii)=(M_2*(Eps1*(k1-1))/(1-Eps1*k1));
                    
                    Mp1=M_2*((k1-1)*(1-Eps1))/(1-Eps1*k1);
                    
                    LOW=M_2+Ms1+Mp1;
                    
                    m0=LOW;
                    % Temos as densidades e o MixtureRatio definidos de todos os propellants
                    %
                    % Mp1=Mp1*1.02; % Safety factor 2%
                    E_1=100; % Nozzle area ratio
                    M_Nozzle=125*(Mp1/5400)^(2/3)*(E_1/10)^(1/4);
                    Mo1=OF1*Mp1/(OF1+1);
                    Mf1=Mp1 /(OF1+1);
                    M_Prop_H2=Mf1;
                    M_Prop_LOX=Mo1;
                    M_H2_Tank=0.128*M_Prop_H2; % Akin Mass Estimation Relationships
                    M_LOX_Tank=0.0107*M_Prop_LOX; % Akin Mass Estimation Relationships
                    % M_fairing=4.95*Area_fairing^1.15; % Akin, definiçăo da mass do fairing pela Area
                    M_avionics=10*(LOW-M_2-M_3)^0.361; %Akin definiçăo massa avionics
                    % M_Motor_Solid_Rocket = 0.135*M_propellants; % Akin, possivel definiçăo de masa para os boosters de combustivel solido
                    M_Thrust_Structure= 2.55*10^-4*T_1; % Akin definition pede Thrust e Newton
                    Ms1e=round(M_H2_Tank+M_LOX_Tank+M_Thrust_Structure+M_avionics+M_Nozzle); %+M_fairing+M_avionics
                    
                    Mglobal(iiiiii,4,iii)=(M_H2_Tank+M_LOX_Tank+M_avionics+M_Thrust_Structure+M_Nozzle);
                    
                    if abs(Mglobal(iiiiii,3,iii)-Mglobal(iiiiii,4,iii))<=100
                        fprintf('1 estagio: %g %g \n',[Mglobal(iiiiii,3,iii) Mglobal(iiiiii,4,iii)]);
                        Msel(ii,1)=V1per(ii);
                        Msel(ii,2)=V2per(iii);
                        Msel(ii,3)=Eps1;
                        Msel(ii,6)=Mglobal(iiii,3,ii);
                        
                    end
                    
                    
                    
                    
                end
                iii=iii+1;
            end
            
        else
            continue
        end
        
        
        
    end
    
    
    
    
end


for i6=1:1:length(Msel(:,1))
    if Msel(i6,6)>0 && Msel(i6,7)>0 && Msel(i6,8)>0
        Msel(i6,9)=Msel(i6,6)+Msel(i6,7)+Msel(i6,8);
    end
end

MMsel=Msel(:,9);

LOW=min(MMsel(MMsel~=0));
% LOWidx=find(MMsel==LOW);
LOWidx = find(MMsel(:,1)==LOW);

dV1=Msel(LOWidx,1);
dV2=Msel(LOWidx,2);
Eps1=Msel(LOWidx,3);
Eps2=Msel(LOWidx,4);
Eps3=Msel(LOWidx,5);

dV1final=dV1*DeltaVestimation;
dV2final=dV2*DeltaVestimation;
k1=exp(dV1final/(Isp1*g0));
k2=exp(dV2final/(Isp2*g0));
k3=exp((DeltaVestimation-dV1final-dV2final)/(Isp3*g0));

Ms3=round(Mpl*(Eps3*(k3-1))/(1-Eps3*k3));
Mp3=Mpl*((k3-1)*(1-Eps3))/(1-Eps3*k3);
M_3= Ms3+Mp3+Mpl;

Ms2=M_3*(Eps2*(k2-1))/(1-Eps2*k2);
Mp2= M_3*((k2-1)*(1-Eps2))/(1-Eps2*k2);
M_2=Ms2+Mp2+M_3;

Ms1=(M_2*(Eps1*(k1-1))/(1-Eps1*k1)); 
Mp1= M_2*((k1-1)*(1-Eps1))/(1-Eps1*k1);
M_1=Ms1+Mp1+M_2;         

tb1= Mp1*g0*Isp1/T_1;
tb2= Mp2*g0*Isp2/T_2;
tb3= Mp3*g0*Isp3/T_3;
m0=LOW;

T2W_1 = T_1/(m0*9.81);
T2W_2 = T_2/(M_2*9.81);
T2W_3 = T_3/(M_3*9.81);


% prompt={'Diameter of 1 stage (m):','Diameter of 2 stage(m)','Diameter of 3 stage(m):'};
% title='Diameter for each Stage (m)';
% answer=inputdlg(prompt,title);
% d1= str2double(answer{1});
% d2= str2double(answer{2});
% d3= str2double(answer{2});

if Mpl < 2000
    
    d1=2.11;
    d2=1.84;
    d3=1.79;
    
    ld1=5.823;
    ld2=2.647;
    ld3=1.48;
    
    l1=ld1*d1;
    l2=ld2*d2;
    l3=ld3*d3;
    
elseif Mpl >= 2000 && Mpl < 20000
    
    d1=3.84;
    d2=3.58;
    d3=3.32;
    
    ldbooster=7.313;
    ld1=8.574;
    ld2=2.278;
    ld3=0.8744;
   
    l1=ld1*d1;
    l2=ld2*d2;
    l3=ld3*d3;
    
else
    
    d1=4.43;
    d2=4.18;
    d3=4.1;
    
    ldbooster=11.99;
    ld1=6.2413;
    ld2=2.7715;
    ld3=1.0024;

    l1=ld1*d1;
    l2=ld2*d2;
    l3=ld3*d3;    
    
end


save variaveis3
return
%LOW=Mpl*(k1*k2*(1-Eps1)*(1-Eps2))/((1-Eps1*k1)*(1-Eps2*k2));
% fprintf('%d\n Lift off weight',LOW);
% fprintf('\n\n -----------------------------------\n')
% fprintf('%d\n M3 estimation\n',M_3);
% fprintf('\n\n -----------------------------------\n')
% fprintf('%d\n M2 estimation\n',M_2);
% fprintf('\n\n -----------------------------------\n')
% fprintf('%d\n Delta V estimation\n',DeltaVestimation);
% fprintf('\n\n -----------------------------------\n')
% fprintf('%d\n T/W_1\n',T2W_1);
% fprintf('\n\n -----------------------------------\n')
% fprintf('%d\n T/W_2\n',T2W_2);
% fprintf('\n\n -----------------------------------\n')
% fprintf('%d\n T/W_3\n',T2W_3);
% fprintf('\n\n -----------------------------------\n')


end




% prompt={'Enter Structural 1:','Enter Structural 2:','Enter Structural 3:'};
% title='Structural factor';
% answer=inputdlg(prompt,title);
% Eps1 = str2double(answer{1});
% Eps2= str2double(answer{2});
% Eps3 = str2double(answer{3});