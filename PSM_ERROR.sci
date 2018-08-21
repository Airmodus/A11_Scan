// Airmodus Ltd.
//
// CTO Joonas Vanhanen
// joonas.vanhanen@airmodus.com

// Date of creation: Aug 15, 2018
//


// PSM ERROR LIST

function Y = PSM_ERROR(X)
    ERRORS = ['GROWTH TUBE TEMP'
    'SATURATOR TEMP'
    'SATURATOR FLOW'
    'STATUS PREHEATER TEMP'
    'INLET TEMP'
    'MIX1 PRESS'
    'MIX2 PRESS'
    'ABS PRESS'
    'EXCESS FLOW'
    'DRAIN LEVEL'
    'CABIN TEMP'
    'DRAIN TEMP']
    
    Y = ERRORS(X+1)
endfunction

