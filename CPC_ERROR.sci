// Airmodus Ltd.
//
// CTO Joonas Vanhanen
// joonas.vanhanen@airmodus.com

// Date of creation: Aug 15, 2018
//


function Y = CPC_ERROR(X)
    ERRORS = ['OPTICS TEMP'
    'SATURATOR TEMP'
    'CONDENSER TEMP'
    'ABS PRESS'
    'NOZ PRESS'
    'LASER POWER'
    'LIQUID LEVEL'
    'AMBIENT TEMP'
    'CRITICAL PRESS']
    
    Y = ERRORS(X+1)
endfunction
