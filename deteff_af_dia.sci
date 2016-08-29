function [y,a2] = deteff_af_dia(sat,di,ef,axa,plt)

D = [1:0.01:5];

global X Y

X = di;
Y = ef;

//a0 = [0.9 1 1 1];
a0 = [-1.374669769123703  -5.145282456570960   0.850152060648299]
//options = optimset('MaxFunEvals',1e6,'TolFun',1e-21,'TolX',1e-21,'MaxIter',1e6);
[a2,fval,exitflag,output] = fminsearch(NORM_CUTOFF,a0)

y = (CUTOFF(a2,axa))';

'deteff_af_dia'

clear X Y

if plt == 1 then

    figure(10)
    plot(di,ef,'.')
    set(gca(),"auto_clear","off")
    plot(D,CUTOFF(a2,D),'-')
    plot(axa,CUTOFF(a2,axa),'o')
    xlabel('Diameter [nm]','fontsize',3)
    ylabel('Detection efficiency','fontsize',3)
    h1 = legend(['Measurement';'Fit';'Bins'],'pos',4)
    h = gca()
    h.font_size = 3;
    h.tight_limits = "on"
    h.data_bounds = [1,0,0;5,1,0]
    clear h
end
endfunction
