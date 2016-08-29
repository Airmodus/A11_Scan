function Pen = losses(d,Q_lpm,tr,L,temp,press,plt)

// Calculates penetration ratio of particles with diameter d in a tube flow 
// of air as a carrier gas.
// Accounts for turbulent losses, both diffusional and inetrial.
// Plots the penetraion efficiency agains diameter and gives it in a variable
// Pen;
//
// d = particle diameter (vector) [nm]
// Q_lpm = volumetric flow rate in [Liter per minute]
// tr = Tube radius [m]
// L = Tube lenght [m]
// temperature in [Kelvin]
// pressure in [Pascal]

d = d*1e-9; // converting [m] -> [nm]
Q=Q_lpm.*0.001./60; // Q = Volumetric flow rate [m3/s]

//-----------------------------------------------------------------------


rooi = 1.205;
roop = 1000;
vis = visc(temp);
A = %pi.*(tr).^2;
U = Q./A;
Re = reynolds(Q,tr.*2,temp,press);

// diff coeff
D = diffuus(d,temp,press);

// Deposition velocity
Vd = 0;
if (Re > 2000)
    disp('Turbulent flow')
    tau0 = (d.^2.*roop)./(18.*vis);
    f = 0.316./(4.*Re.^(1/4));
    u = (f/2).^(1/2).*U;
    kv = vis./rooi;
    tau = tau0.*u.^2./kv;
    
    // Diffusion
    
    Vd1 = ((0.04.*U)./(Re.^(1/4))).*((rooi.*D)./vis).^(2/3);
    
    // Inertial
    
    Vd2 = zeros(1,length(tau));
    
    for i = 1:length(tau)
        
        if (tau(1,i) < 5.6)
            Vd2(1,i) = u./((1./sqrt(f./2)) + ((1525./(0.81.*tau(1,i).^2))-50.6));
        elseif (tau(1,i) >= 5.6 & tau(1,i) < 33.3)
            Vd2(1,i) = u./((1./sqrt(f./2)) - 13.73 + 5.*log(5.04./((tau(1,i)./5.56) - 0.959)));
        else
            Vd2(1,i) = sqrt(f./2);
        end

    end
    
    Vd = Vd1 + Vd2;
end

Pt = exp((-4.*Vd.*L)./(tr*2.*U));
// Pen = Pt;

// Laminar
// Diffusion losses
Pl = ltubefl(d,L,Q,temp,press);
Pen = Pt.*Pl;

if plt == 1
    figure(15)
    plot(d,Pen,'ro-')
    a = gca();
    a.log_flags = "lnn" ; // set Y axes to logarithmic scale
    ylabel('Penetration efficiency')
    xlabel('Diameter [m]')
end
endfunction
