function Attenuazione_dB = calcolaNeve(distanza_m, R_s, a, b)
% CALCOLANEVE Calcola l'attenuazione dovuta alla neve in caduta.
% L'attenuazione specifica è calcolata in dB/km e poi 
% moltiplicata per la distanza euclidea convertita in chilometri.

% Calcolo dell'attenuazione specifica (dB/km)
A_spec = a * (R_s ^ b);

% Conversione della distanza da metri a chilometri
distanza_km = distanza_m / 1000;

% Calcolo attenuazione totale
Attenuazione_dB = A_spec * distanza_km;
end