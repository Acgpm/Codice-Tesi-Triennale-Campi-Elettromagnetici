function Gd_dB = calcolaKnifeEdge(h, d1, d2, f_Hz)
c = 3e8;
lambda = c / f_Hz;

% Calcolo del parametro di Fresnel v
v = h * sqrt((2 * (d1 + d2)) / (lambda * d1 * d2));

% Applicazione del sistema di 5 equazioni di Lee per trovare il Guadagno Gd(dB)
if v <= -1
    Gd_dB = 0;
elseif v <= 0
    Gd_dB = 20 * log10(0.5 - 0.62 * v);
elseif v <= 1
    Gd_dB = 20 * log10(0.5 * exp(-0.95 * v));
elseif v <= 2.4
    Gd_dB = 20 * log10(0.4 - sqrt(0.1184 - (0.38 - 0.1 * v)^2));
else
    Gd_dB = 20 * log10(0.225 / v);
end
end