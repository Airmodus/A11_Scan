function [y] = deteff_dia_interpolat(di,ef,axa,plt)

D = [1:0.01:5];

global X Y

X = di;
Y = ef;

M(:,1) = X;
M(:,2) = Y;

M = gsort(M,'lr','i')

X = M(:,1);
Y = M(:,2);

[y]=interpln([X';Y'],axa)

ind = find(axa == max(axa))
indi = find(di > 2.5)
y(ind) = mean(ef(indi))

y = max(y,0)

clear X Y

if plt == 1 then

    figure(10)
    plot(di,ef,'.')
    set(gca(),"auto_clear","off")
    plot(axa,y,'o-')
    xlabel('Diameter [nm]','fontsize',3)
    ylabel('Detection efficiency','fontsize',3)
    h1 = legend(['Measurement';'Bins'],'pos',4)
    h = gca()
    h.font_size = 3;
    h.tight_limits = "on"
    h.data_bounds = [1,0,0;5,1,0]
    clear h
end
endfunction
