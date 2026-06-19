function lgd = creaLegendaSAR()
% CREALEGENDASAR: Genera la legenda per l'ambiente 3D

% NaN è un parametro che inseriamo per far disegnare sul grafico dei punti
% che in realtà non esistono, in modo da "forzare" le icone ad apparire,
% per poi personalizzarle con gli stessi colori che usiamo per gli elementi
% reali del nostro grafico
h_drone = plot3(NaN, NaN, NaN, 'bo', 'MarkerSize', 10, 'MarkerFaceColor', 'b', 'DisplayName', 'Drone');
h_socc = plot3(NaN, NaN, NaN, 'r^', 'MarkerSize', 10, 'MarkerFaceColor', 'r', 'DisplayName', 'Soccorritore');
h_los_g = plot3(NaN, NaN, NaN, 'g-', 'LineWidth', 2, 'DisplayName', 'LoS Libera (Segnale OK)');
h_los_r = plot3(NaN, NaN, NaN, 'r-', 'LineWidth', 2, 'DisplayName', 'LoS Ostruita (Ostacolo 3D)');


lgd = legend([h_drone, h_socc, h_los_g, h_los_r], 'Location', 'northeast', 'FontSize', 10, 'Color', 'w');
end