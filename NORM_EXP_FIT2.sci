// Norm of Function EXP_FIT

function ns = NORM_EXP_FIT2(a,x,y)

global X Y
ns = norm((EXP_FIT2(a,X)-Y).^2);
endfunction
