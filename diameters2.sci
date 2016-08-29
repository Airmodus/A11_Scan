function [d,a] = diameters2(sat,di,ef,axa,plt)

sat2 = [0.1:0.01:1.5];

global X Y

X = sat;
Y = di;

a0 = [0.13 -1.147 1.099];
[a,fval,exitflag,output] = fminsearch(NORM_EXP_FIT2,a0)

d = (EXP_FIT2(a,axa))';

'diameters2'

clear X Y

if plt == 1 then
    figure(11)
    plot(sat,di,'.')
    set(gca(),"auto_clear","off")
    plot(sat2,EXP_FIT2(a,sat2),'-')
    plot(axa,EXP_FIT2(a,axa),'o')
    xlabel('Saturator flow rate [lpm]','fontsize',3)
    ylabel('Diameter [nm]','fontsize',3)
    legend(['Measurement';'Fit';'Bins'])
    xs2png(gcf(),'Dp_vs_Qsat.png')
    h = gca()
    h.font_size = 3;
    clear h
end
endfunction
