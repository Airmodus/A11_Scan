function [d] = diameters_interpolation(sat,di,axa,plt)

global X Y

X = sat;
Y = di;

M(:,1) = X;
M(:,2) = Y;

M = gsort(M,'lr','i')

X = M(:,1);
Y = M(:,2);

[d]=interpln([X';Y'],axa)

ind = find(axa == max(axa))
d(ind) = min(di)

if max(d) > 4 then
    d = min(d,4)
end


clear X Y

'diameters_interpolation'

if plt == 1 then
    figure(11)
    plot(sat,di,'.')
    set(gca(),"auto_clear","off")
    plot(axa,d,'o-')
    xlabel('Saturator flow rate [lpm]','fontsize',3)
    ylabel('Diameter [nm]','fontsize',3)
    legend(['Measurement';'Bins'])
//    xs2png(gcf(),'Dp_vs_Qsat.png')
    h = gca()
    h.font_size = 3;
    clear h
end

endfunction
