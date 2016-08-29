// Function for Cutoff Fit

function y = CUTOFF(a,x)

//y = a(4)./(a(1) + exp(a(2).*x.^a(3)));

y = a(1).*x.^a(2) + a(3);

//y = 1 - exp((a(1)-x)./a(2) + x.^a(3));
endfunction
