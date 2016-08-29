// Diffusional losses for laminar tube flow according to Gormley & Kennedy 1949

function res=ltubefl(dpp,plength,pflow,temp,press)

rmuu=%pi*diffuus(dpp,temp,press)*plength/pflow;

for i=1:length(dpp)
if rmuu(i) < 0.02
res(i)=1-2.56*rmuu(i)^(2/3)+1.2*rmuu(i)+0.177*rmuu(i)^(4/3);
else
res(i)=0.819*exp(-3.657*rmuu(i))+0.097*exp(-22.3*rmuu(i))+0.032*exp(-57*rmuu(i));
end
end
endfunction
