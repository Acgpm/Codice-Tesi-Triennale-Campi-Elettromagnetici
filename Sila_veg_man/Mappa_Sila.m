
%  STEP 1: SETUP AMBIENTE 3D - DRONE E SOCCORRITORI
clc; clear; close all;

%% 1. PARAMETRI DI CONFIGURAZIONE
nomeFileMappa = 'output_hh.tif';

% Posizione DRONE (Coordinate X, Y in metri dal centro mappa)
drone_X = -300;   
drone_Y = -600;   
drone_altezzaVolo = 150; % metri sopra il terreno

% Posizione SOCCORRITORI (Usando i vettori possiamo posizionarne molteplici)
socc_X  = [-300, 100, 100, -100];   
socc_Y  = [-20, 100, -400, -200];
socc_altezzaPersona = 1.8; % Altezza da terra (metri)

% Risoluzione del raggio (numero di campioni)
nPuntiRaggio = 100;

% --- PARAMETRI VEGETAZIONE (Modello RET) ---
veg_X_min = -200;
veg_X_max = 100;
veg_Y_min = -350;
veg_Y_max = 50;
veg_altezza = 20; % Altezza media della vegetazione in metri

% Parametri estratti dalla letteratura per il Modello RET
alfa_RET = 0.95;
beta_RET = 45.34;
W_RET = 0.71;
sigma_tau_RET = 0.73;

%% 2. IMPORTAZIONE MAPPA DEM E INTERPOLAZIONE
disp('Caricamento mappa DEM in corso');
% Vengono restituite 3 matrici di coordinate
[X_metri, Y_metri, Z_metri] = importaMappaSAR(nomeFileMappa);

% I due punti trasformano la matrice in un unico vettore colonna
% scatteredInterpolant crea un oggetto matematico che serve a calcolare
% l'altezza del terreno senza che vi sia corrispondenza precisa di pixel
F_dem = scatteredInterpolant(X_metri(:), Y_metri(:), Z_metri(:), 'linear', 'nearest');
disp('Mappa caricata e interpolante creata.');

%% 3. CALCOLO QUOTE ASSOLUTE (Z)
% Prendiamo la quota Z del terreno in quel punto preciso
z_terreno_drone = F_dem(drone_X, drone_Y);
% Calcoliamo la quota assoluta del drone nel cielo
drone_Z = z_terreno_drone + drone_altezzaVolo;

% idem per soccorritori
z_terreno_socc  = F_dem(socc_X, socc_Y);
socc_Z  = z_terreno_socc  + socc_altezzaPersona;

%% 4. VISUALIZZAZIONE SCENARIO 3D
disp('Generazione ambiente 3D');
% I parametri (sinistra) hanno dei valori (destra)
figure('Name', 'Setup ambiente con analisi visiva LoS', 'Color', 'w', 'Position', [100, 100, 900, 600]);

% surf disegna il terreno come una superficie continua usando le 3 matrici.
% EdgeColor none rimuove il colore nero dai bordi del terreno. Facealpha
% rende la superficie leggermente trasparente
surf(X_metri, Y_metri, Z_metri, 'EdgeColor', 'none', 'FaceAlpha', 0.6);

% Usiamo una palette cromatica standard di MATLAB per distinguere
% l'altitudine
colormap parula; 

% hold on freeza il grafico in modo da poterci disegnare sopra. grid on
% attiva la griglia per facilitare la lettura delle coordinate
hold on; grid on;


% Disegno della Bounding Box della Vegetazione
% Creiamo i vertici del prisma rettangolare basandoci sulle quote del terreno
x_veg_box = [veg_X_min, veg_X_max, veg_X_max, veg_X_min];
y_veg_box = [veg_Y_min, veg_Y_min, veg_Y_max, veg_Y_max];
z_base_box = F_dem(x_veg_box, y_veg_box); % Quota del terreno ai 4 angoli
z_top_box = z_base_box + veg_altezza;     % Quota delle cime degli alberi

% Disegno la "chioma" superiore
patch(x_veg_box, y_veg_box, z_top_box, 'g', 'FaceAlpha', 0.2, 'EdgeColor', 'g', 'LineWidth', 1.5);
text(veg_X_min + 50, veg_Y_min + 50, max(z_top_box) + 10, 'Area Vegetazione', 'Color', [0 0.5 0], 'FontWeight', 'bold');

% bo indica che il marcatore deve essere un cerchio blu.
plot3(drone_X, drone_Y, drone_Z, 'bo', 'MarkerSize', 10, 'MarkerFaceColor', 'b');

% Linea tratteggiata in verticale per visualizzare l'altitudine rispetto al
% suolo. b-- indica che la linea è blu e tratteggiata.
plot3([drone_X, drone_X], [drone_Y, drone_Y], [z_terreno_drone, drone_Z], 'b--', 'LineWidth', 1.5);
text(drone_X, drone_Y, drone_Z + 15, ' Drone', 'FontWeight', 'bold', 'Color', 'b');

% Vettore dei punti di campionamento (da 0 = Drone a 1 = Soccorritore)
t = linspace(0, 1, nPuntiRaggio); 

% Ciclo iterativo per analizzare ogni soccorritore individualmente
numSoccorritori = length(socc_X);

% Ho impostato questa frequenza operativa in quanto nei vari paper
% scientifici è d'uso comune la 2.4GHz
frequenza = 2.4e9; 
% Anche qui ho fatto riferimento ad alcuni paper che danno una potenza
% trasmessa per i droni in scenari di emergena tra i 20-30 dBm (1 Watt)
Pt_drone = 30;
% Qui, sempre da un paper, ho estrapolato il fatto valori così bassi di
% guadagno sono un'assunzione che viene fatta in quanto il drone non
% conosce a priori l'orientamento dell'antenna dei dispersi a terra, quindi
% si opta per un qualcosa che possa rappresentare l'omnidirezionale
Gt = 2;           
Gr = 2;            

for i = 1:numSoccorritori
    % Coordinate del soccorritore corrente
    sX = socc_X(i);
    sY = socc_Y(i);
    sZ = socc_Z(i);
    
    % simbolo del soccorritore sulla mappa
    plot3(sX, sY, sZ, 'r^', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
    text(sX, sY, sZ + 15, [' Socc. ', num2str(i)], 'FontWeight', 'bold', 'Color', 'r');
    
    % distanza euclidea tra drone e soccorritore
    distanza_3D = sqrt((sX - drone_X)^2 + (sY - drone_Y)^2 + (sZ - drone_Z)^2);
    
    % Il vettore t serve a spezzettare la distanza 3D, che a seconda dei
    % valori assunti ci restituisce una certa posizione. Ad esempio se t=0
    % abbiamo la posizione del drone, se t=1 la posizione del soccorritore.
    % Le 3 variabili raggio contengono le coordinate 3D di questi punti.
    raggio_X = drone_X + t * (sX - drone_X);
    raggio_Y = drone_Y + t * (sY - drone_Y);
    raggio_Z = drone_Z + t * (sZ - drone_Z);
    
    % Qui prendiamo le coordinate X e Y della distanza e utilizziamo la
    % F_dem, ovvero la funzione per calcolare l'altezza sotto quel punto
    % specifico (la variabile clearance sottrae l'altezza del filo -
    % altezza della montagna). 
    z_terreno_raggio = F_dem(raggio_X, raggio_Y);
    clearance = raggio_Z - z_terreno_raggio;
    
    % costrutto if per capire se siamo in condizione di spazio libero o
    % modello knife edge
    if all(clearance >= 0)
        coloreRaggio = 'g'; % Verde: la linea è tutta sopra il terreno (LoS Libera)
        PotenzaRx = calcolaFriis(distanza_3D, frequenza, Pt_drone, Gt, Gr);
        fprintf('Soccorritore %d: LoS LIBERA. Potenza Ricevuta: %.2f dBm\n', i, PotenzaRx);
    else
        coloreRaggio = 'r'; % Rosso: la linea interseca il terreno (LoS Ostruita)
        
        % Cerchiamo il punto con il più basso valore di clearance perché ci
        % serve per calcolare la distanza fino alla cima dell'ostacolo che
        % blocca la visuale. La distanza d1 serve per capire la distanza
        % tra la montagna ed il drone utilizzando l'indice per capire quale
        % dei segmenti l'ha colpita.
        [min_clearance, indice_ostacolo] = min(clearance);
        h_ostacolo = abs(min_clearance);
        d1 = t(indice_ostacolo) * distanza_3D;
        d2 = distanza_3D - d1;
        
        % Calcolo attenuazione knife-edge
        PerditaDiffrazione = calcolaKnifeEdge(h_ostacolo, d1, d2, frequenza);
        
        % La potenza finale è Friis + il guadagno di diffrazione (che è negativo)
        PotenzaBase = calcolaFriis(distanza_3D, frequenza, Pt_drone, Gt, Gr);
        PotenzaRx = PotenzaBase + PerditaDiffrazione;
        
        fprintf('Soccorritore %d: LoS OSTRUITA. Altezza ostacolo: %.2fm.\n', i, h_ostacolo);
        fprintf('  -> Potenza Ricevuta (con Diffrazione): %.2f dBm\n', PotenzaRx);    end
    
    % 2. CALCOLO INTERSEZIONE CON LA VEGETAZIONE (Modello RET)
    % Identifichiamo quali campioni 3D del raggio cadono fisicamente dentro il volume boschivo
    punti_in_veg = (raggio_X >= veg_X_min & raggio_X <= veg_X_max) & ...
        (raggio_Y >= veg_Y_min & raggio_Y <= veg_Y_max) & ...
        (raggio_Z >= z_terreno_raggio & raggio_Z <= (z_terreno_raggio + veg_altezza));

    % Calcoliamo la distanza d (in metri) attraversata nella vegetazione
    step_raggio = distanza_3D / (nPuntiRaggio - 1);
    d_veg = sum(punti_in_veg) * step_raggio;

    % Se il raggio entra nella vegetazione, applichiamo il modello RET
    if d_veg > 0
        % Richiamo della funzione e sottrazione della perdita
        PerditaVegetazione = calcolaRET(d_veg, alfa_RET, beta_RET, W_RET, sigma_tau_RET);
        PotenzaRx = PotenzaRx - PerditaVegetazione; % La funzione restituisce la perdita in dB positivo

        fprintf('  -> Rilevato attraversamento Vegetazione: %.2f m\n', d_veg);
        fprintf('  -> Attenuazione RET calcolata: %.2f dB. Nuova Rx Finale: %.2f dBm\n', PerditaVegetazione, PotenzaRx);
    end
    fprintf('\n'); % Riga vuota per ordine in console


    % Disegno la linea di vista nello spazio 3D
    plot3(raggio_X, raggio_Y, raggio_Z, 'Color', coloreRaggio, 'LineWidth', 1);
end

%Descrizione grafico
title('Step 2: Tratteggio Linee di Vista (Verde = Libera, Rosso = Ostruita)');
xlabel('X - Est (m)');
ylabel('Y - Nord (m)');
zlabel('Z - Quota (m)');
view(3);

%leggenda
lgd=creaLegendaSAR;

% Personalizzazione del colore del testo del grafico
personalizzaGraficaSAR(gca, lgd);

% Da questa simulazione riconosciamo dei valori in Spazio libero pari a
% circa -63/-65 dBm. Questi valori nascono dalla semplice applicazione
% dell'equazione di Friis, e sono coerenti anche con il calcolo
% approssimativo che si può fare con carta e penna considerando potenza 
% trasmessa, guadagno e path loss (pari circa a -97 dB).

% I valori invece in spazio ostruito nascono dall'applicazione del modello
% knife edge in cui viene calcolata l'altezza dell'ostacolo roccioso, il
% parametro di diffrazione di Fresnel-Kirchoff, e ciò si traduce in 
% un'attenuazione addizzionale di altri 30 dB che sottratti ai -60 in
% spazio libero ci permette di ottenere proprio i valori in output

% Un'ultima osservazione. Sempre in letteratura si riconoscono dei limiti
% fisici operativi nei sistemi di comunicazione radio e cellulari, la cui
% potenza si aggira intorno ai -104/-120 dBm. Affinché un ricevitore mantenga attivo
% il collegamento radio, deve avere una soglia minima tra i -90 ed i -100,
% pertanto il risultato a posteriori della nostra analisi fatta offline ci
% dice che i soccorritori in zona d'ombra d'ostacolo rischiano di rimanere
% chiusi fuori dai contatti radio in quanto si trovano già ad una soglia
% che sta per cedere a causa della zona d'ombra

% Richiamo la heatmap aggiornata con i parametri della vegetazione
risoluzione_griglia = 20;
[Matrice_Potenza_HM, figura_HM] = generaHeatmapCopertura(X_metri, Y_metri, F_dem, ...
    drone_X, drone_Y, drone_Z, socc_X, socc_Y, socc_altezzaPersona, ...
    Pt_drone, Gt, Gr, frequenza, risoluzione_griglia, ...
    veg_X_min, veg_X_max, veg_Y_min, veg_Y_max, veg_altezza, ...
    alfa_RET, beta_RET, W_RET, sigma_tau_RET);