function Attenuazione_dB = calcolaRET(d, alfa, beta_deg, W, sigma_tau)
% CALCOLARET Calcola l'attenuazione dovuta alla vegetazione 
% sfruttando il Modello Radiative Energy Transfer (RET).
%
% Output: Attenuazione in dB (valore positivo)

if d <= 0
    Attenuazione_dB = 0;
    return;
end

% Calcolo della densità ottica (tau) in base alla profondità
tau = sigma_tau * d;

% 1. Componente coerente (I_ri): onda incidente diretta.
% La potenza decresce all'aumentare della profondità a causa 
% dell'assorbimento e dello scattering.
I_ri = exp(-tau);

% 2. Lobo di forward scatter (I_1): energia dispersa in avanti.
% Si ricorre all'approssimazione troncata per alleggerire
% l'onerosità computazionale tipica del modello RET.
M_limite = 5; % Troncamento ai primi 5 ordini di dispersione
sommatoria_I1 = 0;
for m = 1:M_limite
    sommatoria_I1 = sommatoria_I1 + ( (alfa * W * tau)^m ) / factorial(m);
end
I_1 = exp(-tau) * sommatoria_I1;

% 3. Segnale di scatter diffuso isotropico (I_2): 
% Energia dispersa in tutte le direzioni, dominante a grandi profondità.
% Implementazione della componente di coda diffusa empirica.
I_2 = (alfa * (1 - W)) * exp(-tau * 0.5) * (1 - exp(-tau * 0.5));

% Calcolo del rapporto tra potenza ricevuta e potenza in spazio libero
P_ratio = I_ri + I_1 + I_2;

% Evitiamo errori numerici (logaritmo di 0) per profondità estreme
P_ratio = max(P_ratio, 1e-12);

% L'attenuazione viene convertita in dB 
% (Si inserisce il segno negativo in quanto il P_ratio è sempre < 1)
Attenuazione_dB = -10 * log10(P_ratio);
end