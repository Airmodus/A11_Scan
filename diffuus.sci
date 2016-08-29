function res=diffuus(dpp,temp,press)
K=1.38e-23;
res=(K*temp*cunn(dpp,temp,press)) ./(3*3.14*visc(temp)*dpp);
endfunction
