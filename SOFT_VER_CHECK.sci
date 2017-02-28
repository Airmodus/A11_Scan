
// Gives the major version of the Scilab

function vvv=SOFT_VER_CHECK()
    
    v = getversion();
    vv = strsplit(v);
    vvv = strtod(vv($-4),'.');

endfunction
