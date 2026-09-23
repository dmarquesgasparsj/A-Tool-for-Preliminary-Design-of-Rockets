function [Isp1,Isp2,Isp3,Isp4,OF4,OF3,OF2,OF1]=propellant_4 (g0)

format short g
menuchoice = menu('Choose Propellant 1 Stage','LOX/H_2'...
    ,'LOX/Hydrazine','LOX/RP-1','Nitrogen Tetroxide/RP-1', ...
    'Nitrogen Tetroxide/HTPB','LOX/HTPB','F2/H2'...
    ,'Nitrogen Tetroxide/MMH','Nitrogen Tetroxide/UDMH',...
    'Nitrogen Tetroxide/Hydrazine');

if menuchoice == 1
    Isp1 = 462*0.8;
    name = 'LOX/H_2';
    OF1 = 3.8;       % Mixture Ratio
    rho_ox = 1142;  % density Oxidizer
    rho_f = 71;     % density Fuel
    cstar = 2423;
    gamma = 1.21;
end
if menuchoice == 2
    Isp1 = 363*0.8;
    name = 'LOX/Hydrazine';
    OF1 = 1.20;
    rho_ox = 1142;
    rho_f = 1010;
    cstar = 1911;
    gamma = 1.14;
end
if menuchoice == 3
    Isp1 = 347*0.8;
    name = 'LOX/RP-1';
    OF1 = 2.27;
    rho_ox = 1142;
    rho_f = 810;
    cstar = 1799;
    gamma = 1.14;
end
if menuchoice == 4
    Isp1 = 328*0.8;
    name = 'Nitrogen Tetroxide/RP-1';
    OF1 = 3.51;
    rho_ox = 1440;
    rho_f = 810;
    cstar = 1075;
    gamma = 1.17;
end
if menuchoice == 5
    Isp1 = 297*0.8;
    name = 'Nitrogen Tetroxide/HTPB';
    OF1 = 3.17;
    rho_ox = 1440;
    rho_f = 1810;
    cstar = 1667;
    gamma = 1.23;
end
if menuchoice == 6
    Isp1 = 317*0.8;
    name = 'LOX/HTPB';
    OF1 = 2.04;
    rho_ox = 1142;
    rho_f = 1810;
    cstar = 1793;
    gamma = 1.23;
end
if menuchoice == 7
    Isp1 = 441*0.8;
    name = 'F2/H2';
    OF1 = 4.26;
    rho_ox = 1509;
    rho_f = 71;
    cstar = 2569;
    gamma = 1.29;
end
if menuchoice == 8
    Isp1 = 318*0.8;
    name = 'Nitrogen Tetroxide/MMH';
    OF1 = 1;
    rho_ox = 1440;
    rho_f = 878;
    cstar = 1640;
    gamma = 1.27;
end
if menuchoice == 9
    Isp1 = 313*0.8;
    name = 'Nitrogen Tetroxide/UDMH';
    OF1 = 1.75;
    rho_ox = 1440;
    rho_f = 789;
    cstar = 1715;
    gamma = 1.24;
end
if menuchoice == 10
    Isp1 = 309*0.8;
    name = 'Nitrogen Tetroxide/Hydrazine';
    OF1 = 2.21;
    rho_ox = 1440;
    rho_f = 1010;
    cstar = 1601;
    gamma = 1.23;
end

format short g
menuchoice = menu('Choose Propellant 2 Stage','LOX/H_2'...
    ,'LOX/Hydrazine','LOX/RP-1','Nitrogen Tetroxide/RP-1', ...
    'Nitrogen Tetroxide/HTPB','LOX/HTPB','F2/H2'...
    ,'Nitrogen Tetroxide/MMH','Nitrogen Tetroxide/UDMH',...
    'Nitrogen Tetroxide/Hydrazine');

if menuchoice == 1
    Isp2 = 462*0.9;
    name = 'LOX/H_2';
    OF2 = 3.8;
    rho_ox = 1142;
    rho_f = 71;
    cstar = 2423;
    gamma = 1.21;
end
if menuchoice == 2
    Isp2 = 363*0.9;
    name = 'LOX/Hydrazine';
    OF2 = 1.20;
    rho_ox = 1142;
    rho_f = 1010;
    cstar = 1911;
    gamma = 1.14;
end
if menuchoice == 3
    Isp2 = 347*0.9;
    name = 'LOX/RP-1';
    OF2 = 2.27;
    rho_ox = 1142;
    rho_f = 810;
    cstar = 1799;
    gamma = 1.14;
end
if menuchoice == 4
    Isp2 = 328*0.9;
    name = 'Nitrogen Tetroxide/RP-1';
    OF2 = 3.51;
    rho_ox = 1440;
    rho_f = 810;
    cstar = 1075;
    gamma = 1.17;
end
if menuchoice == 5
    Isp2 = 297*0.9;
    name = 'Nitrogen Tetroxide/HTPB';
    OF2 = 3.17;
    rho_ox = 1440;
    rho_f = 1810;
    cstar = 1667;
    gamma = 1.23;
end
if menuchoice == 6
    Isp2 = 317*0.9;
    name = 'LOX/HTPB';
    OF2 = 2.04;
    rho_ox = 1142;
    rho_f = 1810;
    cstar = 1793;
    gamma = 1.23;
end
if menuchoice == 7
    Isp2 = 441*0.9;
    name = 'F2/H2';
    OF2 = 4.26;
    rho_ox = 1509;
    rho_f = 71;
    cstar = 2569;
    gamma = 1.29;
end
if menuchoice == 8
    Isp2 = 318*0.9;
    name = 'Nitrogen Tetroxide/MMH';
    OF2 = 1;
    rho_ox = 1440;
    rho_f = 878;
    cstar = 1640;
    gamma = 1.27;
end
if menuchoice == 9
    Isp2 = 313*0.9;
    name = 'Nitrogen Tetroxide/UDMH';
    OF2 = 1.75;
    rho_ox = 1440;
    rho_f = 789;
    cstar = 1715;
    gamma = 1.24;
end
if menuchoice == 10
    Isp2 = 309*0.9;
    name = 'Nitrogen Tetroxide/Hydrazine';
    OF2 = 2.21;
    rho_ox = 1440;
    rho_f = 1010;
    cstar = 1601;
    gamma = 1.23;
end

format short g
menuchoice = menu('Choose Propellant 3 Stage','LOX/H_2'...
    ,'LOX/Hydrazine','LOX/RP-1','Nitrogen Tetroxide/RP-1', ...
    'Nitrogen Tetroxide/HTPB','LOX/HTPB','F2/H2'...
    ,'Nitrogen Tetroxide/MMH','Nitrogen Tetroxide/UDMH',...
    'Nitrogen Tetroxide/Hydrazine');

if menuchoice == 1
    Isp3 = 462*0.95;
    name = 'LOX/H_2';
    OF3 = 3.8;
    rho_ox = 1142;
    rho_f = 71;
    cstar = 2423;
    gamma = 1.21;
end
if menuchoice == 2
    Isp3 = 363*0.95;
    name = 'LOX/Hydrazine';
    OF3 = 1.20;
    rho_ox = 1142;
    rho_f = 1010;
    cstar = 1911;
    gamma = 1.14;
end
if menuchoice == 3
    Isp3 = 347*0.95;
    name = 'LOX/RP-1';
    OF3 = 2.27;
    rho_ox = 1142;
    rho_f = 810;
    cstar = 1799;
    gamma = 1.14;
end
if menuchoice == 4
    Isp3 = 328*0.95;
    name = 'Nitrogen Tetroxide/RP-1';
    OF3 = 3.51;
    rho_ox = 1440;
    rho_f = 810;
    cstar = 1075;
    gamma = 1.17;
end
if menuchoice == 5
    Isp3 = 297*0.95;
    name = 'Nitrogen Tetroxide/HTPB';
    OF3 = 3.17;
    rho_ox = 1440;
    rho_f = 1810;
    cstar = 1667;
    gamma = 1.23;
end
if menuchoice == 6
    Isp3 = 317*0.95;
    name = 'LOX/HTPB';
    OF3 = 2.04;
    rho_ox = 1142;
    rho_f = 1810;
    cstar = 1793;
    gamma = 1.23;
end
if menuchoice == 7
    Isp3 = 441*0.95;
    name = 'F2/H2';
    OF3 = 4.26;
    rho_ox = 1509;
    rho_f = 71;
    cstar = 2569;
    gamma = 1.29;
end
if menuchoice == 8
    Isp3 = 318*0.95;
    name = 'Nitrogen Tetroxide/MMH';
    OF3 = 1;
    rho_ox = 1440;
    rho_f = 878;
    cstar = 1640;
    gamma = 1.27;
end
if menuchoice == 9
    Isp3 = 313*0.95;
    name = 'Nitrogen Tetroxide/UDMH';
    OF3 = 1.75;
    rho_ox = 1440;
    rho_f = 789;
    cstar = 1715;
    gamma = 1.24;
end
if menuchoice == 10
    Isp3 = 309*0.95;
    name = 'Nitrogen Tetroxide/Hydrazine';
    OF3 = 2.21;
    rho_ox = 1440;
    rho_f = 1010;
    cstar = 1601;
    gamma = 1.23;
end

% 4 stage
format short g
menuchoice = menu('Choose Propellant 4 Stage','LOX/H_2'...
    ,'LOX/Hydrazine','LOX/RP-1','Nitrogen Tetroxide/RP-1', ...
    'Nitrogen Tetroxide/HTPB','LOX/HTPB','F2/H2'...
    ,'Nitrogen Tetroxide/MMH','Nitrogen Tetroxide/UDMH',...
    'Nitrogen Tetroxide/Hydrazine');

if menuchoice == 1
    Isp4 = 462;
    name = 'LOX/H_2';
    OF4 = 3.8;
    rho_ox = 1142;
    rho_f = 71;
    cstar = 2423;
    gamma = 1.21;
end
if menuchoice == 2
    Isp4 = 363;
    name = 'LOX/Hydrazine';
    OF4 = 1.20;
    rho_ox = 1142;
    rho_f = 1010;
    cstar = 1911;
    gamma = 1.14;
end
if menuchoice == 3
    Isp4 = 347;
    name = 'LOX/RP-1';
    OF4 = 2.27;
    rho_ox = 1142;
    rho_f = 810;
    cstar = 1799;
    gamma = 1.14;
end
if menuchoice == 4
    Isp4 = 328;
    name = 'Nitrogen Tetroxide/RP-1';
    OF4 = 3.51;
    rho_ox = 1440;
    rho_f = 810;
    cstar = 1075;
    gamma = 1.17;
end
if menuchoice == 5
    Isp4 = 297;
    name = 'Nitrogen Tetroxide/HTPB';
    OF4 = 3.17;
    rho_ox = 1440;
    rho_f = 1810;
    cstar = 1667;
    gamma = 1.23;
end
if menuchoice == 6
    Isp4 = 317;
    name = 'LOX/HTPB';
    OF4 = 2.04;
    rho_ox = 1142;
    rho_f = 1810;
    cstar = 1793;
    gamma = 1.23;
end
if menuchoice == 7
    Isp4 = 441;
    name = 'F2/H2';
    OF4 = 4.26;
    rho_ox = 1509;
    rho_f = 71;
    cstar = 2569;
    gamma = 1.29;
end
if menuchoice == 8
    Isp4 = 318;
    name = 'Nitrogen Tetroxide/MMH';
    OF4 = 1;
    rho_ox = 1440;
    rho_f = 878;
    cstar = 1640;
    gamma = 1.27;
end
if menuchoice == 9
    Isp4 = 313;
    name = 'Nitrogen Tetroxide/UDMH';
    OF4 = 1.75;
    rho_ox = 1440;
    rho_f = 789;
    cstar = 1715;
    gamma = 1.24;
end
if menuchoice == 10
    Isp4 = 309;
    name = 'Nitrogen Tetroxide/Hydrazine';
    OF4 = 2.21;
    rho_ox = 1440;
    rho_f = 1010;
    cstar = 1601;
    gamma = 1.23;
end

deltaVe1= Isp1*g0;
deltaVe2= Isp2*g0;
deltaVe3= Isp3*g0;
deltaVe4= Isp4*g0;
end