// Norm of Function CUTOFF

function ns = NORM_CUTOFF(a,x,y)

global X Y
ns = norm((CUTOFF(a,X)-Y).^2);
endfunction
