function plot_trajectory(traj)
% Gera gráficos simples de altitude, velocidade e ângulo.

t = traj.t;
h = traj.h;
v = traj.v;
gamma_deg = rad2deg(traj.gamma);

figure;
plot(t, h/1000, 'LineWidth', 1.4); grid on;
xlabel('Tempo [s]'); ylabel('Altitude [km]'); title('Perfil de Altitude');

figure;
plot(t, v, 'LineWidth', 1.4); grid on;
xlabel('Tempo [s]'); ylabel('Velocidade [m/s]'); title('Velocidade');

figure;
plot(t, gamma_deg, 'LineWidth', 1.4); grid on;
xlabel('Tempo [s]'); ylabel('\gamma [deg]'); title('Ângulo da Trajetória');
end
