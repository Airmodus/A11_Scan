// Airmodus Ltd.
//
// CTO Joonas Vanhanen
// joonas.vanhanen@airmodus.com

// Date of creation: Aug 15, 2018
//


function Y = PSM_NOTE(X)
    NOTES = ['LIQUID LEVEL'
    'WARMING UP STATE'
    'STEPPING CHANGE'
    'VALVE DRAINING'
    'VALVE DRYING']
    
    Y = NOTES(X+1)
endfunction
