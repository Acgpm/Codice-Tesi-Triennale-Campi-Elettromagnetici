%  STEP 2: SIMULAZIONE MANUALE CON OROGRAFIA, VEGETAZIONE E NEVE
clc; clear; close all;

%% 1. PARAMETRI DI CONFIGURAZIONE
nomeFileMappa = 'output_hh.tif';

% Posizione DRONE (Coordinate X, Y in metri dal centro mappa)
drone_X = -300;   
drone_Y = -600;   
drone_altezzaVolo = 100; % metri sopra il terreno locale

% Posizione SOCCORRITORI 
socc_X  = [-300, 100, 100, -100];   
socc_Y  = [-20, 100, -400, -200];
socc_altezzaPersona = 1.8; 

nPuntiRaggio = 100;

% Parametri Elettromagnetici
frequenza = 2.4e9; 
Pt_drone = 30; 
Gt = 2;           
Gr = 2;            

% --- PARAMETRI VEGETAZIONE (Modello RET) ---
veg_X_min = -350;
veg_X_max = 150;
veg_Y_min = -450;
veg_Y_max = 50;
veg_altezza = 20; 

alfa_RET = 0.95;
beta_RET = 45.34;
W_RET = 0.71;
sigma_tau_RET = 0.73;

% --- PARAMETRI NEVE IN CADUTA ---
tasso_nevicata_Rs = 15; % mm/hr (Intensità della nevicata)
coeff_neve_a = 1.86; % Coefficiente empirico per 2.4 GHz
coeff_neve_b = 0.5;    % Coefficiente empirico per 2.4 GHz

%% 2. IMPORTAZIONE MAPPA DEM E INTERPOLAZIONE
disp('Caricamento mappa DEM in corso...');
[X_metri, Y_metri, Z_metri] = importaMappaSAR(nomeFileMappa);
F_dem = scatteredInterpolant(X_metri(:), Y_metri(:), Z_metri(:), 'linear', 'nearest');
disp('Mappa caricata e interpolante creata.');

%% 3. CALCOLO QUOTE ASSOLUTE (Z)
z_terreno_drone = F_dem(drone_X, drone_Y);
drone_Z = z_terreno_drone + drone_altezzaVolo;

z_terreno_socc  = F_dem(socc_X, socc_Y);
socc_Z  = z_terreno_socc  + socc_altezzaPersona;

%% 4. VISUALIZZAZIONE SCENARIO 3D E CALCOLO ATTENUAZIONI
disp('Generazione ambiente 3D...');

figure('Name', 'Setup ambiente con analisi visiva LoS, Vegetazione e Neve', 'Color', 'w', 'Position', [100, 100, 900, 600]);
surf(X_metri, Y_metri, Z_metri, 'EdgeColor', 'none', 'FaceAlpha', 0.6);
colormap parula; hold on; grid on;

% Disegno della Vegetazione
[X_veg, Y_veg] = meshgrid(linspace(veg_X_min, veg_X_max, 50), linspace(veg_Y_min, veg_Y_max, 50));
Z_veg_base = F_dem(X_veg, Y_veg);
Z_veg_top = Z_veg_base + veg_altezza;
surf(X_veg, Y_veg, Z_veg_top, 'FaceColor', 'g', 'FaceAlpha', 0.2, 'EdgeColor', 'none');
text(veg_X_min + 50, veg_Y_min + 50, max(Z_veg_top(:)) + 15, 'Area Vegetazione', 'Color', [0 0.5 0], 'FontWeight', 'bold');

% Disegno Drone
plot3(drone_X, drone_Y, drone_Z, 'bo', 'MarkerSize', 10, 'MarkerFaceColor', 'b');
plot3([drone_X, drone_X], [drone_Y, drone_Y], [z_terreno_drone, drone_Z], 'b--', 'LineWidth', 1.5);
text(drone_X, drone_Y, drone_Z + 15, ' Drone', 'FontWeight', 'bold', 'Color', 'b');

t = linspace(0, 1, nPuntiRaggio); 
numSoccorritori = length(socc_X);

fprintf('\n--- RISULTATI SIMULAZIONE MANUALE ---\n');

for i = 1:numSoccorritori
    sX = socc_X(i); sY = socc_Y(i); sZ = socc_Z(i);
    
    plot3(sX, sY, sZ, 'r^', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
    text(sX, sY, sZ + 15, [' Socc. ', num2str(i)], 'FontWeight', 'bold', 'Color', 'r');
    
    distanza_3D = sqrt((sX - drone_X)^2 + (sY - drone_Y)^2 + (sZ - drone_Z)^2);
    
    raggio_X = drone_X + t * (sX - drone_X);
    raggio_Y = drone_Y + t * (sY - drone_Y);
    raggio_Z = drone_Z + t * (sZ - drone_Z);
    
    z_terreno_raggio = F_dem(raggio_X, raggio_Y);
    clearance = raggio_Z - z_terreno_raggio;
    
    % 1. Calcolo attenuazione base (Friis) ed eventuale diffrazione (Knife-Edge)
    if all(clearance >= 0)
        coloreRaggio = 'g'; 
        PotenzaRx = calcolaFriis(distanza_3D, frequenza, Pt_drone, Gt, Gr);
        fprintf('S%d: LoS LIBERA. Rx Base (Spazio Libero): %.2f dBm\n', i, PotenzaRx);
    else
        coloreRaggio = 'r'; 
        [min_clearance, indice_ostacolo] = min(clearance);
        h_ostacolo = abs(min_clearance);
        d1 = t(indice_ostacolo) * distanza_3D;
        d2 = distanza_3D - d1;
        
        PerditaDiffrazione = calcolaKnifeEdge(h_ostacolo, d1, d2, frequenza);
        PotenzaBase = calcolaFriis(distanza_3D, frequenza, Pt_drone, Gt, Gr);
        PotenzaRx = PotenzaBase + PerditaDiffrazione; 
        
        fprintf('S%d: LoS OSTRUITA (Ostacolo: %.2fm). Rx Parziale: %.2f dBm\n', i, h_ostacolo, PotenzaRx);
    end
    
    % 2. Calcolo intersezione con la Vegetazione (Modello RET)
    punti_in_veg = (raggio_X >= veg_X_min & raggio_X <= veg_X_max) & ...
                   (raggio_Y >= veg_Y_min & raggio_Y <= veg_Y_max) & ...
                   (raggio_Z >= z_terreno_raggio & raggio_Z <= (z_terreno_raggio + veg_altezza));
    
    step_raggio = distanza_3D / (nPuntiRaggio - 1);
    d_veg = sum(punti_in_veg) * step_raggio;
    
    if d_veg > 0
        PerditaVegetazione = calcolaRET(d_veg, alfa_RET, beta_RET, W_RET, sigma_tau_RET);
        PotenzaRx = PotenzaRx - PerditaVegetazione; 
        fprintf('  -> Attenuazione Boscosa: %.2f dB (Tratta %.2fm)\n', PerditaVegetazione, d_veg);
    end
    
    % 3. Calcolo Attenuazione Neve in caduta
    PerditaNeve = calcolaNeve(distanza_3D, tasso_nevicata_Rs, coeff_neve_a, coeff_neve_b);
    PotenzaRx = PotenzaRx - PerditaNeve;
    
    fprintf('  -> Attenuazione Neve: %.2f dB. Rx FINALE: %.2f dBm\n', PerditaNeve, PotenzaRx);
    fprintf('--------------------------------------------------\n');
    
    plot3(raggio_X, raggio_Y, raggio_Z, 'Color', coloreRaggio, 'LineWidth', 1);
end

title('Tratteggio Linee di Vista: Analisi Orografica, Boscosa e Neve');
xlabel('X - Est (m)'); ylabel('Y - Nord (m)'); zlabel('Z - Quota (m)');
view(3);

lgd=creaLegendaSAR;
personalizzaGraficaSAR(gca, lgd);

%% 5. VISUALIZZAZIONE HEATMAP 2D (Efficienza Copertura)
% NOTA: Affinché la heatmap rifletta la neve, assicurati di aggiornare 
% in futuro il file generaHeatmapCopertura.m passando i parametri della neve!
disp('Generazione Heatmap 2D...');
risoluzione_griglia = 20;
[Matrice_Potenza_HM, figura_HM] = generaHeatmapCopertura(X_metri, Y_metri, F_dem, ...
    drone_X, drone_Y, drone_Z, socc_X, socc_Y, socc_altezzaPersona, ...
    Pt_drone, Gt, Gr, frequenza, risoluzione_griglia, ...
    veg_X_min, veg_X_max, veg_Y_min, veg_Y_max, veg_altezza, ...
    alfa_RET, beta_RET, W_RET, sigma_tau_RET);