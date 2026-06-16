function visualizzaHeatmapSAR(x_grid, y_grid, mappaCopertura, socc_X, socc_Y, drone_X, drone_Y)
% visualizzaHeatmapSAR Genera una mappa di calore 2D (contour) della potenza 
% ricevuta e posiziona gli agenti sulla mappa.

figure('Name', 'Mappa di Copertura 2D (Heatmap)', 'Color', 'w', 'Position', [150, 150, 800, 650]);

% Creazione del grafico a curve di livello riempite (Contour)
contourf(x_grid, y_grid, mappaCopertura, 20, 'LineStyle', 'none');
colormap turbo; % Colormap ad alto contrasto, ottima per i segnali RF
c = colorbar;
c.Label.String = 'Potenza Ricevuta (Caso Peggiore) [dBm]';
c.Label.FontWeight = 'bold';

hold on; grid on;

% Plotta la posizione dei soccorritori sulla mappa 2D
plot(socc_X, socc_Y, 'w^', 'MarkerSize', 10, 'MarkerFaceColor', 'r', 'DisplayName', 'Soccorritori');
for i = 1:length(socc_X)
    text(socc_X(i) + 15, socc_Y(i) + 15, ['S', num2str(i)], 'Color', 'w', 'FontWeight', 'bold');
end

% Plotta il punto OTTIMALE trovato per il Drone
plot(drone_X, drone_Y, 'ko', 'MarkerSize', 12, 'MarkerFaceColor', 'g', 'LineWidth', 2, 'DisplayName', 'Drone Ottimale');
text(drone_X + 20, drone_Y + 20, 'DRONE', 'Color', 'k', 'FontWeight', 'bold');

title('Heatmap della Potenza Ricevuta (Grid Search)');
xlabel('Distanza Est (X) [m]');
ylabel('Distanza Nord (Y) [m]');
legend('Location', 'northeast');

% Uniformiamo lo stile estetico scuro come per il grafico 3D
ax2 = gca;
ColoreScuro = [0.1 0.1 0.1];
ax2.XColor = ColoreScuro; ax2.YColor = ColoreScuro;
ax2.Title.Color = ColoreScuro; ax2.XLabel.Color = ColoreScuro; ax2.YLabel.Color = ColoreScuro;
end