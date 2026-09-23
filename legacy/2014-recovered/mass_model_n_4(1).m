% function mass_model para 4 estagio
% if b=0
% %     function mass_model
% %      function mass_model_boosters

function [m0,tb1,tb2,tb3,tb4,T_1,T_2,T_3,T_4,V1perc,V2perc,V3perc,V4perc,Mp1,Mp2,Mp3,Mp4,M_1,M_2,M_3,M_4]=mass_model_n_4 (DeltaVestimation,Mpl,Isp1,Isp2,Isp3,Isp4,OF1,OF2,OF3,OF4) % Eps = Epsilon = structural factor
clear all
clc
DeltaVestimation=9200;
Mpl=1500;
Isp1=280;
Isp2=289;
Isp3=294;
Isp4=317;
OF1=3;
OF2=3;
OF3=3;
OF4=4;
T_1= 2092*1000;  % Valores do Vega
T_2=959*1000;
T_3= 230*1000;
T_4=2.2*1000;
V1perc= 20;
V2perc= 25;
V3perc= 40;
V4perc= 15;

% while T2W1 <1.2  % Implementar ciclo while de segurança

% prompt={'Enter Thrust of 1 stage (kN):','Enter Thrust of 2 stage(kN)','Enter Thrust of 3 stage(kN):','Enter Thrust of 4 stage(kN):'};
% title='Thrust for each Stage (kN)';
% answer=inputdlg(prompt,title);
% T_1= str2double(answer{1});
% T_2= str2double(answer{2});
% T_3= str2double(answer{2});
% T_4= str2double(answer{2});
% 
% prompt={'Enter % of 1 stage:','Enter % of 2 stage','Enter % of 3 stage:','Enter % of 4 stage'};
% title='Delta-V division';
% answer=inputdlg(prompt,title);
% V1perc= str2double(answer{1});
% V2perc= str2double(answer{2});
% V3perc= str2double(answer{3});
% V4perc= str2double(answer{4});

% T_1= T_1*1000;  % Valores do Vega
% T_2= T_2*1000;
% T_3= T_3*1000;
% T_4= T_4*1000;

% T_1= 3040*1000;  % Valores do Vega
% T_2=1200*1000;
% T_3= 213*1000;
% T_4=2.45*1000;
% V1perc= 40;
% V2perc= 30;
% V3perc= 15;
% V4perc= 15;

V1perc= V1perc/100;
V2perc= V2perc/100;
V3perc= V3perc/100;
V4perc= V4perc/100;


while V1perc + V2perc + V3perc + V4perc ~= 1
    
    prompt={'Enter % of 1 stage:','Enter % of 2 stage','Enter % of 3 stage','Enter % of 4 stage'};
    title='Delta-V division';
    answer=inputdlg(prompt,title);
    V1perc= str2double(answer{1});
    V2perc= str2double(answer{2});
    V3perc= str2double(answer{3});
    V4perc= str2double(answer{4});
    
    V1perc= V1perc/100;
    V2perc= V2perc/100;
    V3perc= V3perc/100;
    V4perc= V4perc/100;
end

g0=9.81;

Mglobal = zeros(13,11,9261);

Msel=zeros(9261,13);

V3per=zeros(1,9261);
V2per=zeros(1,441);
V1per=zeros(1,21);

ii=0;
iii=0;
iiii=0;
for V1percc = (V1perc-0.1):0.01:(V1perc+0.1)
    ii=ii+1;
    
    V1per(ii)=V1percc;
    
    for V2percc= (V2perc-0.1):0.01:(V2perc+0.1)
        iii=iii+1;
        V2per(iii)=V2percc;
        
        for V3percc = (V3perc-0.1):0.01:(V3perc+0.1)
            iiii=iiii+1;
            V3per(iiii)=V3percc;
            
            if (1- V3per(iiii) -V2per(iii) - V1per(ii)) > 0
                V4per = 1 - V3per(iiii) -V2per(iii) - V1per(ii);
                
                if V4per >= V4perc -0.1 && V4per <= V4perc +0.1
                    
                    
                    %                     fprintf('%g %g %g %g \n', V1per(ii) , V2per(iii), V3per(iiii), V4per);
                    
                    
                    Mglobal(:,1,iiii)=V1per(ii);
                    Mglobal(:,2,iiii)=V2per(iii);
                    Mglobal(:,3,iiii)=V3per(iiii);
                    
                    DeltaV1 = V1per(ii)*DeltaVestimation; % ciclo for de 40 a 60% por exemplo
                    DeltaV2 = V2per(iii)*DeltaVestimation;
                    DeltaV3 = V3per(iiii)*DeltaVestimation;
                    % DeltaV4 = V4per*DeltaVestimation
                    
                    k1=exp(DeltaV1/(Isp1*g0));
                    k2=exp(DeltaV2/(Isp2*g0));
                    k3=exp(DeltaV3/(Isp3*g0));
                    k4=exp((DeltaVestimation-DeltaV1-DeltaV2-DeltaV3)/(Isp4*g0));
                    
                    % Upperstage
                    iiiii=0;
                    for Eps4 = 0.05:0.01:0.17
                        
                        iiiii=iiiii+1;
                        
                        Mglobal(iiiii,10,ii)=(Mpl*(Eps4*(k4-1))/(1-Eps4*k4));
                        
                        Ms4=round(Mpl*(Eps4*(k4-1))/(1-Eps4*k4));
                        
                        Mp4=Mpl*((k4-1)*(1-Eps4))/(1-Eps4*k4);
                        
                        M_4=Mpl+Ms4+Mp4;
                        
                        % Temos as densidades e o MixtureRatio definidos de todos os propellants
                        %
                        % Mp4=Mp4*1.02; % Safety factor 2%
                        E_4=100; % Nozzle area ratio
                        M_Nozzle=125*(Mp4/5400)^(2/3)*(E_4/10)^(1/4);
                        Mo4=OF4*Mp4/(OF4+1);
                        Mf4=Mp4 /(OF4+1);
                        M_Prop_H2=Mf4;
                        M_Prop_LOX=Mo4;
                        M_H2_Tank=0.128*M_Prop_H2; % Akin Mass Estimation Relationships
                        M_LOX_Tank=0.0107*M_Prop_LOX; % Akin Mass Estimation Relationships
                        % M_fairing=4.95*Area_fairing^1.15; % Akin, definiçăo da mass do fairing pela Area
                        M_avionics=10*M_4^0.361; %Akin definiçăo massa avionics
                        % M_Motor_Solid_Rocket = 0.135*M_propellants; % Akin, possivel definiçăo de masa para os boosters de combustivel solido
                        M_Eng=7.81*10^-4*T_4+3.37*10^-5*T_4*E_4^0.5 + 59;
                        M_Thrust_Structure= 2.55*10^-4*T_4; % Akin definition pede Thrust e Newton
                        Ms4e=round(M_H2_Tank+M_LOX_Tank+M_avionics+M_Thrust_Structure+M_Nozzle+M_Eng);%+M_fairing
                        Mglobal(iiiii,11,ii)=(M_H2_Tank+M_LOX_Tank+M_Thrust_Structure+M_avionics+M_Nozzle+M_Eng);
                        
                        if Mglobal(iiiii,11,ii)/Mglobal(iiiii,10,ii) <= 1.1 && Mglobal(iiiii,11,ii)/Mglobal(iiiii,10,ii) > 0.9
                            fprintf('4 estagio: %g %g\n',[Mglobal(iiiii,10,ii) Mglobal(iiiii,11,ii)]);
                            Msel(ii,1)=V1per(ii);
                            Msel(ii,2)=V2per(iii);
                            Msel(ii,3)=V3per(iiii);
                            Msel(ii,4)=V4per;
                            Msel(ii,8)=Eps4;
                            Msel(ii,12)=Mglobal(iiiii,10,ii);
                            
                        end
                        
                        
                        %3 stage
                    end
                    
                    iiiiii=0;
                    for Eps3 = 0.05:0.01:0.17
                        
                        iiiiii=iiiiii+1;
                        
                        Mglobal(iiiiii,8,ii)=(M_4*(Eps3*(k3-1))/(1-Eps3*k3));
                        
                        Ms3=round(M_4*(Eps3*(k3-1))/(1-Eps3*k3));
                        
                        Mp3=M_4*((k3-1)*(1-Eps3))/(1-Eps3*k3);
                        
                        M_3= M_4+Ms3+Mp3;
                        
                        % Temos as densidades e o MixtureRatio definidos de todos os propellants
                        %
                        % Mp4=Mp4*1.02; % Safety factor 2%
                        E_3=60; % Nozzle area ratio
                        M_Nozzle=125*(Mp3/5400)^(2/3)*(E_3/10)^(1/4);
                        Mo3=OF3*Mp3/(OF3+1);
                        Mf3=Mp3 /(OF3+1);
                        M_Prop_H2=Mf3;
                        M_Prop_LOX=Mo3;
                        M_H2_Tank=0.128*M_Prop_H2; % Akin Mass Estimation Relationships
                        M_LOX_Tank=0.0107*M_Prop_LOX; % Akin Mass Estimation Relationships
                        % M_fairing=4.95*Area_fairing^1.15; % Akin, definiçăo da mass do fairing pela Area
                        M_avionics=10*(M_3-M_4)^0.361; %Akin definiçăo massa avionics
                        % M_Motor_Solid_Rocket = 0.135*M_propellants; % Akin, possivel definiçăo de masa para os boosters de combustivel solido
                        M_Eng=7.81*10^-4*T_3+3.37*10^-5*T_3*E_3^0.5 + 59;
                        M_Thrust_Structure= 2.55*10^-4*T_3; % Akin definition pede Thrust e Newton
                        Ms3e=round(M_H2_Tank+M_LOX_Tank+M_avionics+M_Thrust_Structure+ M_Nozzle+M_Eng);%+M_fairing
                        Mglobal(iiiiii,9,ii)=(M_H2_Tank+M_LOX_Tank+M_Thrust_Structure+M_avionics+M_Nozzle+M_Eng);
                        
                        
                        if Mglobal(iiiiii,8,ii)/Mglobal(iiiiii,9,ii) <= 1.1 && Mglobal(iiiiii,8,ii)/Mglobal(iiiiii,9,ii) > 0.9
                            fprintf('3 estagio: %g %g\n',[Mglobal(iiiiii,8,ii) Mglobal(iiiiii,9,ii)]);
                            Msel(ii,1)=V1per(ii);
                            Msel(ii,2)=V2per(iii);
                            Msel(ii,3)=V3per(iiii);
                            Msel(ii,4)=V4per;
                            Msel(ii,7)=Eps4;
                            Msel(ii,11)=Mglobal(iiiiii,8,ii);
                        end
                        
                        
                        %2 stage
                    end
                    
                    iiiiiii=0;
                    
                    
                    
                    for Eps2= 0.05:0.01:0.17
                        
                        iiiiiii=iiiiiii+1;
                        
                        Mglobal(iiiiiii,6,ii)=(M_3*(Eps2*(k2-1))/(1-Eps2*k2));
                        
                        Ms2=round(M_3*(Eps2*(k2-1))/(1-Eps2*k2));
                        
                        Mp2=M_3*((k2-1)*(1-Eps2))/(1-Eps2*k2);
                        
                        M_2= M_3+Ms2+Mp2;
                        
                        % Temos as densidades e o MixtureRatio definidos de todos os propellants
                        %
                        % Mp2=Mp2*1.02; % Safety factor 2%
                        E_2=30; % Nozzle area ratio
                        M_Nozzle=125*(Mp2/5400)^(2/3)*(E_2/10)^(1/4);
                        Mo2=OF2*Mp2/(OF2+1);
                        Mf2=Mp2 /(OF2+1);
                        M_Prop_H2=Mf2;
                        M_Prop_LOX=Mo2;
                        M_H2_Tank=0.128*M_Prop_H2; % Akin Mass Estimation Relationships
                        M_LOX_Tank=0.0107*M_Prop_LOX; % Akin Mass Estimation Relationships
                        % M_fairing=4.95*Area_fairing^1.15; % Akin, definiçăo da mass do fairing pela Area
                        M_avionics=10*M_2^0.361; %Akin definiçăo massa avionics
                        % M_Motor_Solid_Rocket = 0.135*M_propellants; % Akin, possivel definiçăo de masa para os boosters de combustivel solido
                        M_Eng=7.81*10^-4*T_2+3.37*10^-5*T_2*E_2^0.5 + 59;
                        M_Thrust_Structure= 2.55*10^-4*T_2; % Akin definition pede Thrust e Newton
                        Ms2e=round(M_H2_Tank+M_LOX_Tank+M_avionics+M_Thrust_Structure+M_Nozzle+M_Eng);%+M_fairing
                        Mglobal(iiiiiii,7,ii)=(M_H2_Tank+M_LOX_Tank+M_Thrust_Structure+M_avionics+M_Nozzle+M_Eng);
                        
                        if Mglobal(iiiiiii,7,ii)/Mglobal(iiiiiii,6,ii) <= 1.1 && Mglobal(iiiiiii,7,ii)/Mglobal(iiiiiii,6,ii) > 0.9
                            fprintf('2 estagio: %g %g\n',[Mglobal(iiiiiii,6,ii) Mglobal(iiiiiii,7,ii)]);
                            Msel(ii,1)=V1per(ii);
                            Msel(ii,2)=V2per(iii);
                            Msel(ii,3)=V3per(iiii);
                            Msel(ii,4)=V4per;
                            Msel(ii,6)=Eps2;
                            Msel(ii,10)=Mglobal(iiiiiii,6,ii);
                            
                        end
                        
                        
                    end
                    %1 stage
                    
                    iiiiiiii=0;
                    
                    for Eps1 = 0.05:0.01:0.17
                        
                        iiiiiiii=iiiiiiii+1;
                        
                        Mglobal(iiiiiiii,4,ii)=(M_2*(Eps1*(k1-1))/(1-Eps1*k1));
                        Ms1=round(M_2*(Eps1*(k1-1))/(1-Eps1*k1));
                        
                        Mp1=M_2*((k1-1)*(1-Eps1))/(1-Eps1*k1);
                        
                        LOW=Ms1+Mp1+M_2;
                        
                        m0=LOW;
                        % Temos as densidades e o MixtureRatio definidos de todos os propellants
                        %
                        % Mp1=Mp1*1.02; % Safety factor 2%
                        E_1=20; % Nozzle area ratio
                        M_Nozzle=125*(Mp1/5400)^(2/3)*(E_1/10)^(1/4);
                        Mo1=OF1*Mp1/(OF1+1);
                        Mf1=Mp1 /(OF1+1);
                        M_Prop_H2=Mf1;
                        M_Prop_LOX=Mo1;
                        M_H2_Tank=0.128*M_Prop_H2; % Akin Mass Estimation Relationships
                        M_LOX_Tank=0.0107*M_Prop_LOX; % Akin Mass Estimation Relationships
                        % M_fairing=4.95*Area_fairing^1.15; % Akin, definiçăo da mass do fairing pela Area
                        M_avionics=10*LOW^0.361; %Akin definiçăo massa avionics
                        % M_Motor_Solid_Rocket = 0.135*M_propellants; % Akin, possivel definiçăo de masa para os boosters de combustivel solido
                        M_Eng=7.81*10^-4*T_1+3.37*10^-5*T_1*E_1^0.5 + 59;
                        M_Thrust_Structure= 2.55*10^-4*T_1; % Akin definition pede Thrust e Newton
                        Ms1e=round(M_H2_Tank+M_LOX_Tank+M_Thrust_Structure+M_avionics+M_Nozzle+M_Eng); %+M_fairing+M_avionics
                        
                        Mglobal(iiiiiiii,5,ii)=(M_H2_Tank+M_LOX_Tank+M_Thrust_Structure+M_avionics+M_Nozzle+M_Eng);
                        
                        if Mglobal(iiiiiiii,4,ii)/Mglobal(iiiiiiii,5,ii) <= 1.1 && Mglobal(iiiiiiii,4,ii)/Mglobal(iiiiiiii,5,ii) > 0.9
                            fprintf('1 estagio: %g %g\n',[Mglobal(iiiiiiii,4,ii) Mglobal(iiiiiiii,5,ii)]);
                            Msel(ii,1)=V1per(ii);
                            Msel(ii,2)=V2per(iii);
                            Msel(ii,3)=V3per(iiii);
                            Msel(ii,4)=V4per;
                            Msel(ii,5)=Eps1;
                            Msel(ii,9)=Mglobal(iiiiiiii,4,ii);
                            
                        end
                        
                        
                    end
                    
                    
                end
            else
                continue
            end
            
        end
        
    end
    
    
end


for i6=1:1:length(Msel(:,1))
    if Msel(i6,9)>0 && Msel(i6,10)>0 && Msel(i6,11)>0 && Msel(i6,12)>0
        Msel(i6,13)=Msel(i6,9)+Msel(i6,10)+Msel(i6,11)+Msel(i6,12);
    end
end

MMsel=Msel(:,13);

LOW=min(MMsel(MMsel~=0));
% LOWidx=find(MMsel==LOW);
LOWidx = find(MMsel(:,1)==LOW);

dV1=Msel(LOWidx,1);
dV2=Msel(LOWidx,2);
dV3=Msel(LOWidx,3);
dV4=Msel(LOWidx,4);
Eps1=Msel(LOWidx,5);
Eps2=Msel(LOWidx,6);
Eps3=Msel(LOWidx,7);
Eps4=Msel(LOWidx,8);

dV1final=dV1*DeltaVestimation;
dV2final=dV2*DeltaVestimation;
dV3final=dV3*DeltaVestimation;

k1=exp(DeltaV1/(Isp1*g0));
k2=exp(DeltaV2/(Isp2*g0));
k3=exp(DeltaV3/(Isp3*g0));
k4=exp((DeltaVestimation-dV1final-dV2final-dV3final)/(Isp4*g0));

Ms4=(Mpl*(Eps4*(k4-1))/(1-Eps4*k4));
Mp4=Mpl*((k4-1)*(1-Eps4))/(1-Eps4*k4);
M_4= Ms4+Mp4+Mpl;


Ms3=(M_4*(Eps3*(k3-1))/(1-Eps3*k3));
Mp3=M_4*((k3-1)*(1-Eps3))/(1-Eps3*k3);
M_3= Ms3+Mp3+M_4;

Ms2=M_3*(Eps2*(k2-1))/(1-Eps2*k2);
Mp2= M_3*((k2-1)*(1-Eps2))/(1-Eps2*k2);
M_2=Ms2+Mp2+M_3;

Ms1=(M_2*(Eps1*(k1-1))/(1-Eps1*k1)); 
Mp1= M_2*((k1-1)*(1-Eps1))/(1-Eps1*k1);
M_1=Ms1+Mp1+M_2;       


T2W_1 = T_1/(LOW*9.81);
T2W_2 = T_2/(M_2*9.81);
T2W_3 = T_3/(M_3*9.81);
T2W_4 = T_4/(M_4*9.81);


tb1= Mp1*g0*Isp1/T_1;
tb2= Mp2*g0*Isp2/T_2;
tb3= Mp3*g0*Isp3/T_3;
tb4= Mp4*g0*Isp4/T_4;

% prompt={'Diameter of 1 stage (m):','Diameter of 2 stage(m)','Diameter of 3 stage(m):','Diameter of 4 stage(m):'};
% title='Diameter for each Stage (m)';
% answer=inputdlg(prompt,title);
% d1= str2double(answer{1});
% d2= str2double(answer{2});
% d3= str2double(answer{2});
% d4= str2double(answer{2});


if Mpl < 2000
    
    d1=2.11;
    d2=1.84;
    d3=1.79;
    d4=1.9;
    
    
    ld1=5,823;
    ld2=2,647;
    ld3=1,48;
    ld4=0.99;
    
    l1=ld1*d1;
    l2=ld2*d2;
    l3=ld3*d3;
    l4=ld4*d4;

elseif Mpl >= 2000 && Mpl < 20000
    
    d1=3.84;
    d2=3.58;
    d3=3.32;
    
    ldbooster=7,313;
    ld1=8,574;
    ld2=2,278;
    ld3=0,8744;
    ld4=0.99; % valor a determinar
    
    l1=ld1*d1;
    l2=ld2*d2;
    l3=ld3*d3;
    l4=ld4*d4;

else
    
    d1=4.43;
    d2=4.18;
    d3=4.1;
    
    ldbooster=11,99;
    ld1=6,2413;
    ld2=2,7715;
    ld3=1,0024;
    ld4=0.99; % valor a determinar
    
    l1=ld1*d1;
    l2=ld2*d2;
    l3=ld3*d3;
    l4=ld4*d4;

end

save variaveis_4
return

fprintf('%d\n Lift off weight',LOW);
fprintf('\n\n -----------------------------------\n')
fprintf('%d\n M4 estimation\n',M_4);
fprintf('\n\n -----------------------------------\n')
fprintf('%d\n M3 estimation\n',M_3);
fprintf('\n\n -----------------------------------\n')
fprintf('%d\n M2 estimation\n',M_2);
fprintf('\n\n -----------------------------------\n')
fprintf('%d\n Delta V estimation\n',DeltaVestimation);
fprintf('\n\n -----------------------------------\n')
fprintf('%d\n T/W_1\n',T2W_1);
fprintf('\n\n -----------------------------------\n')
fprintf('%d\n T/W_2\n',T2W_2);
fprintf('\n\n -----------------------------------\n')
fprintf('%d\n T/W_3\n',T2W_3);
fprintf('\n\n -----------------------------------\n')
fprintf('%d\n T/W_4\n',T2W_4);
fprintf('\n\n -----------------------------------\n')

end