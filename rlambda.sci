function r=rlambda(t,press)
dm=3.7e-10;
avoc=6.022e23;

r=kaasuv()*t/(sqrt(2.)*avoc*press*%pi*dm*dm);
endfunction
