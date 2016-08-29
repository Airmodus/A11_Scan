
function rey=reynolds(pipeflow,pipediameter,t,press)
density=1.29*(273/t)*(press/101325);
pipearea=%pi/4*pipediameter^2;

velocity=pipeflow/pipearea;
rey=density*velocity*pipediameter/visc(t);
endfunction
