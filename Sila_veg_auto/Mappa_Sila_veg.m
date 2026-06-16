%  STEP 3: OTTIMIZZAZIONE POSIZIONE DRONE (GRID SEARCH 3D + VEGETAZIONE)
clc; clear; close all;

%% 1. PARAMETRI DI CONFIGURAZIONE
nomeFileMappa = 'output_hh.tif';

% Griglia spaziale di ricerca per il Drone
x_grid_lim = -400:50:400; 
y_grid_lim = -400:50:400; 
z_grid_lim = 20:10:300;   % Quota di volo variabile AGL (metri sopra il terreno locale)

% Posizione SOCCORRITORI
socc_X  = [-300, 100, 100, -100];   
socc_Y  = [-20, 100, -400, -200];
socc_altezzaPersona = 1.8; 
nPuntiRaggio = 100; % Per la visualizzazione finale

% Parametri Elettromagnetici
frequenza = 2.4e9; 
Pt_drone = 30; % dBm
Gt = 2; % dBi
Gr = 2; % dBi

% --- PARAMETRI VEGETAZIONE (Modello RET) ---
veg_X_min = -350;
veg_X_max = 150;
veg_Y_min = -450;
veg_Y_max = 50;
veg_altezza = 15; 

alfa_RET = 0.95;
beta_RET = 45.34;
W_RET = 0.71;
sigma_tau_RET = 0.73;

%% 2. IMPORTAZIONE MAPPA DEM E INTERPOLAZIONE
disp('Caricamento mappa DEM...');
[X_metri, Y_metri, Z_metri] = importaMappaSAR(nomeFileMappa);
F_dem = scatteredInterpolant(X_metri(:), Y_metri(:), Z_metri(:), 'linear', 'nearest');

% Calcolo della quota fissa al suolo per i soccorritori
z_terreno_socc  = F_dem(socc_X, socc_Y);
socc_Z  = z_terreno_socc  + socc_altezzaPersona;
disp('Mappa caricata e interpolante creata.');

%% 3. ALGORITMO GRID SEARCH 3D (X, Y, Z)
disp('Avvio Grid Search 3D (Orografia + Vegetazione)... Attendere.');

mappaCopertura_2D = zeros(length(y_grid_lim), length(x_grid_lim));
MaxPotenza_Ottimale = -Inf;
drone_X = 0; drone_Y = 0; drone_altezzaVolo = 0;

h_wait = waitbar(0, 'Scansione dello spazio aereo...');

for idx_x = 1:length(x_grid_lim)
    for idx_y = 1:length(y_grid_lim)
        
        test_X = x_grid_lim(idx_x);
        test_Y = y_grid_lim(idx_y);
        quota_terreno_locale = F_dem(test_X, test_Y);
        
        miglior_potenza_verticale = -Inf;
        
        for idx_z = 1:length(z_grid_lim)
            test_altezzaVolo = z_grid_lim(idx_z);
            test_Z = quota_terreno_locale + test_altezzaVolo;
            
            potenza_min_garantita = calcolaCoperturaRET(test_X, test_Y, test_Z, ...
                                            socc_X, socc_Y, socc_Z, F_dem, frequenza, Pt_drone, Gt, Gr, ...
                                            veg_X_min, veg_X_max, veg_Y_min, veg_Y_max, veg_altezza, ...
                                            alfa_RET, beta_RET, W_RET, sigma_tau_RET);
            
            if potenza_min_garantita > miglior_potenza_verticale
                miglior_potenza_verticale = potenza_min_garantita;
            end
            
            if potenza_min_garantita > MaxPotenza_Ottimale
                MaxPotenza_Ottimale = potenza_min_garantita;
                drone_X = test_X;
                drone_Y = test_Y;
                drone_altezzaVolo = test_altezzaVolo;
            end
        end
        mappaCopertura_2D(idx_y, idx_x) = miglior_potenza_verticale;
    end
    waitbar(idx_x/length(x_grid_lim), h_wait);
end
close(h_wait);

z_terreno_drone = F_dem(drone_X, drone_Y);
drone_Z = z_terreno_drone + drone_altezzaVolo;

fprintf('\n-> Posizione OTTIMALE 3D individuata autonomamente:\n');
fprintf('   X = %.1f m | Y = %.1f m | Altezza Volo AGL = %.1f m\n', drone_X, drone_Y, drone_altezzaVolo);
fprintf('-> Potenza garantita nel caso peggiore: %.2f dBm\n\n', MaxPotenza_Ottimale);

%% 4. VISUALIZZAZIONE SCENARIO 3D (Posizione Ottimizzata)
disp('Generazione ambiente 3D...');
figure('Name', 'Setup ambiente con analisi visiva LoS', 'Color', 'w', 'Position', [100, 100, 900, 600]);
surf(X_metri, Y_metri, Z_metri, 'EdgeColor', 'none', 'FaceAlpha', 0.6);
colormap parula; hold on; grid on;

% Disegno Vegetazione
[X_veg, Y_veg] = meshgrid(linspace(veg_X_min, veg_X_max, 50), linspace(veg_Y_min, veg_Y_max, 50));
Z_veg_base = F_dem(X_veg, Y_veg);
Z_veg_top = Z_veg_base + veg_altezza;
surf(X_veg, Y_veg, Z_veg_top, 'FaceColor', 'g', 'FaceAlpha', 0.2, 'EdgeColor', 'none');
text(veg_X_min + 50, veg_Y_min + 50, max(Z_veg_top(:)) + 15, 'Area Vegetazione', 'Color', [0 0.5 0], 'FontWeight', 'bold');

% Disegno Drone 
plot3(drone_X, drone_Y, drone_Z, 'bo', 'MarkerSize', 10, 'MarkerFaceColor', 'b');
plot3([drone_X, drone_X], [drone_Y, drone_Y], [z_terreno_drone, drone_Z], 'b--', 'LineWidth', 1.5);
text(drone_X, drone_Y, drone_Z + 15, ' Drone Ottimale', 'FontWeight', 'bold', 'Color', 'b');

t = linspace(0, 1, nPuntiRaggio); 

for i = 1:length(socc_X)
    sX = socc_X(i); sY = socc_Y(i); sZ = socc_Z(i);
    
    plot3(sX, sY, sZ, 'r^', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
    text(sX, sY, sZ + 15, [' Socc. ', num2str(i)], 'FontWeight', 'bold', 'Color', 'r');
    
    distanza_3D = sqrt((sX - drone_X)^2 + (sY - drone_Y)^2 + (sZ - drone_Z)^2);
    
    raggio_X = drone_X + t * (sX - drone_X);
    raggio_Y = drone_Y + t * (sY - drone_Y);
    raggio_Z = drone_Z + t * (sZ - drone_Z);
    
    z_terreno_raggio = F_dem(raggio_X, raggio_Y);
    clearance = raggio_Z - z_terreno_raggio;
    
    if all(clearance >= 0)
        coloreRaggio = 'g'; 
        PotenzaRx = calcolaFriis(distanza_3D, frequenza, Pt_drone, Gt, Gr);
        fprintf('Soccorritore %d: LoS LIBERA. Rx Base: %.2f dBm\n', i, PotenzaRx);
    else
        coloreRaggio = 'r'; 
        [min_clearance, indice_ostacolo] = min(clearance);
        h_ostacolo = abs(min_clearance);
        d1 = t(indice_ostacolo) * distanza_3D;
        d2 = distanza_3D - d1;
        
        PerditaDiffrazione = calcolaKnifeEdge(h_ostacolo, d1, d2, frequenza);
        PotenzaBase = calcolaFriis(distanza_3D, frequenza, Pt_drone, Gt, Gr);
        PotenzaRx = PotenzaBase + PerditaDiffrazione;
        
        fprintf('Soccorritore %d: OSTRUITA (Ostacolo %.2fm). Rx Parziale: %.2f dBm\n', i, h_ostacolo, PotenzaRx);
    end
    
    punti_in_veg = (raggio_X >= veg_X_min & raggio_X <= veg_X_max) & ...
                   (raggio_Y >= veg_Y_min & raggio_Y <= veg_Y_max) & ...
                   (raggio_Z >= z_terreno_raggio & raggio_Z <= (z_terreno_raggio + veg_altezza));
                   
    step_raggio = distanza_3D / (nPuntiRaggio - 1);
    d_veg = sum(punti_in_veg) * step_raggio;
    
    if d_veg > 0
        PerditaVegetazione = calcolaRET(d_veg, alfa_RET, beta_RET, W_RET, sigma_tau_RET);
        PotenzaRx = PotenzaRx - PerditaVegetazione; 
        fprintf('  -> Attenuazione Boscosa: %.2f dB. Rx FINALE: %.2f dBm\n', PerditaVegetazione, PotenzaRx);
    else
        fprintf('  -> Rx FINALE: %.2f dBm\n', PotenzaRx);
    end
    
    plot3(raggio_X, raggio_Y, raggio_Z, 'Color', coloreRaggio, 'LineWidth', 1);
end

title('Posizionamento Ottimale del Drone (Grid Search 3D con RET)');
xlabel('X - Est (m)'); ylabel('Y - Nord (m)'); zlabel('Z - Quota (m)');
view(3);
lgd = creaLegendaSAR;
personalizzaGraficaSAR(gca, lgd);

%% 5. VISUALIZZAZIONE HEATMAP 2D (Efficienza Copertura)
disp('Generazione Heatmap 2D...');
% Richiamo alla funzione heatmap aggiornata che hai già inserito nei file
risoluzione_griglia = 20;
[Matrice_Potenza_HM, figura_HM] = generaHeatmapCopertura(X_metri, Y_metri, F_dem, ...
    drone_X, drone_Y, drone_Z, socc_X, socc_Y, socc_altezzaPersona, ...
    Pt_drone, Gt, Gr, frequenza, risoluzione_griglia, ...
    veg_X_min, veg_X_max, veg_Y_min, veg_Y_max, veg_altezza, ...
    alfa_RET, beta_RET, W_RET, sigma_tau_RET);