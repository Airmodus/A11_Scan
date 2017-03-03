
//------------------------------------------------------------------------------
// AIRMODUS A11 inversion code for scanning raw (.dat) data 
// v.0.6.1

// by Joonas Vanhanen (joonas.vanhanen@airmodus.com)

// Inverts PSM scan data into size distributions
// Corrects data for diffusion losses
// Plots and saves inverted data

// Functions / .sci-files used:
// diameters2.sci
// deteff_af_dia.sci
// NORM_EXP_FIT2.sci
// EXP_FIT2.sci
// NORM_CUTOFF.sci
// CUTOFF.sci
// losses.sci
// visc.sci
// reynolds.sci
// diffuus.sci
// ltubefl.sci
// cunn.sci
// rlambda.sci
// kaasuv.sci
// averagedata.sci

// Note: requires A11 calibration file!

// Output file format (M(row,column)) (comma separated):
// First row: Diameters for bin limits in nm (first value M(1,1) is always zero)
// Column n. 1: date (Matlab datenum format)
// Column n. 2: Total number concentration above the upper limit of size distribution (M(1,2))
// Column n. 3->: Particle number concentration in size bins in #/cc (NOTE:
// not in dN/dlogDp)

// Copyright 2016 Airmodus Ltd.

// Licensed under the EUPL, Version 1.1 or – as soon they 
// will be approved by the European Commission - subsequent
// versions of the EUPL (the "Licence");
// You may not use this work except in compliance with the
// Licence.
// You may obtain a copy of the Licence at:

// https://joinup.ec.europa.eu/software/page/eupl5

// Unless required by applicable law or agreed to in 
// writing, software distributed under the Licence is
// distributed on an "AS IS" basis,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied.
// See the Licence for the specific language governing
// permissions and limitations under the Licence.

//------------------------------------------------------------------------------

warning('off')

clear
clearglobal
xdel(winsid())
[u,t,n]=file(); 
i = grep(n',"/(?:.*\.sci|.*\.sce)$/","r");
fullpath = n(i(1))
[path,fname,extension] = fileparts(fullpath)
chdir(path)
p = pwd()
getd(p)
clear p

sv = SOFT_VER_CHECK()

if sv < 6 then
    stacksize('max')
    gstacksize('max')
end

[filename,datapath] = uigetfile(['*.dat'],"",'SELECT THE DATA FILE');
datet = (part(filename,$-11:$-4));

// Name of the calibration file
[calib,datapath_cal] = uigetfile(['*.txt'],"",'SELECT THE CALIBRATION FILE');  


// USER INPUTS
//------------------------------------------------------------------------------

labels=["File name for inverted data";"Number of bins";"Number of scans to average";"Dilution factor";"Saving on 1/0";"Plotting on 1/0";"Diffusion correction on 1/0";"Sampling tube length [cm]";"Sampling tube radius [cm]";"Sampling tube flow rate [lpm]";"Temperature [Kelvin]";"Pressure [Pascal]"];
[ok,fileid1,bn,avenum,DF,wanttosave,plotting,diffcorr,inletl,inletr,inletfr,temp,pres]=getvalue("Give input parameters for the inversion code",labels,...
     list("str",1,"vec",1,"vec",1,"vec",1,"vec",1,"vec",1,"vec",1,"vec",1,"vec",1,"vec",1,"vec",1,"vec",1),["INVERTED_PSM_DATA";"5";"1";"1";"0";"1";"0";"40";"0.2";"2.5";"293";"101325"])

if avenum >1 then
    averaging = 1;
else
    averaging = 0;
end

//------------------------------------------------------------------------------

// INVERSION
//------------------------------------------------------------------------------

// Importing measurement data
header = 1;
[A,comments]=csvRead(datapath+'/'+filename,',',[],'string',[],[],[],header);

// Finding the values
t=A(:,1);
day = strtod(part(t,1:2));
month = strtod(part(t,4:5));
year = strtod(part(t,7:10));
hour = strtod(part(t,12:13));
minute = strtod(part(t,15:16));
second = strtod(part(t,18:19));
tim=datenum(year,month,day,hour,minute,second);
c=strtod(A(:,2),'.')./DF; //concentration from PSM (1/cm3) (corrected for dilution)
sat_f=strtod(A(:,4),'.'); // saturator flow rate (lpm)

//shifting the data to account for time delay
timedelay = 3;
conc=c(timedelay+1:$);
flow=sat_f(1:$-timedelay);
time=tim(1:$-timedelay);

// Find min and max saturator flow rates
k = find(sat_f ~= 0);
flowmax = round(100*max(sat_f))/100;
//SET MANUALLY
flowmin = 0.1
//flowmax = 1.3
clear k

// Define the bins for saturator flow rates
n = bn;
n0 = 0;
apu = n0:1:n;
a = (flowmax/flowmin).^(1/(n-n0));
P0 = flowmax./a.^n;
satflow = P0.*a.^apu;

conc=c;
flow=sat_f;
time=tim;

pvm=datenum(strtod(part(datet,1:4)),strtod(part(datet,5:6)),strtod(part(datet,7:8)));
apuaika = datevec(pvm);

// Import the calibration file
cal = fscanfMat(datapath_cal+'/'+calib);
sat=cal(:,1);   // Saturator flow rates
di=cal(:,2);    // Diameters
ef=cal(:,3);    // Detection efficiensies

// Fit calibration data cut-off diameter as a function of saturator flow rate
[dia,a] = diameters2(sat,di,ef,satflow,plotting);

// Fit calibration data detection efficiency as a function of diameter (at highest sat flow)
[deteff,a2] = deteff_af_dia(sat,di,ef,dia,plotting);

// Search number of scans
k1 = find(flow > 0.97*flowmin & flow < 1.03*flowmin);
k2 = min(k1);

nscan = [];
for i = 1:length(flow)
    if i < length(flow) then
        if i<=k2 then
            nscan(i) = 0;
        elseif round(100*flow(i))/100 == flowmin & round(100*flow(i+1))/100 ~= flowmin & i<length(flow) then
            nscan(i) = nscan(i-1)+1;
        else
            nscan(i) = nscan(i-1);
        end
    end
    if i == length(flow) then
        nscan(i) = nscan(i-1);
    end
end

clear k1 k2

// Averaging over a full scan and to bins

r = satflow;
lr=size(r,2);
for i = 1:max(nscan)
    k = find(nscan == i);
    timenew(i) = min(time(k)); // Time stamp from beginning of one scan
    for iii = 1:lr-1
        meanflow(iii) = (satflow(iii+1)+satflow(iii))/2;
    end
    for ii = 1:lr
        if ii == 1
            k1 = find(flow<meanflow(ii) & flow>satflow(ii) & nscan == i)
            conc1b(i,ii) = nanmean(conc(k1));
        elseif ii<lr & ii>1
            k1 = find(flow>meanflow(ii-1) & flow<meanflow(ii) & nscan == i);
            conc1b(i,ii) = nanmean(conc(k1));
        elseif ii == lr
            k1 = find(flow>meanflow(ii-1) & flow<satflow(ii) & nscan == i);
            conc1b(i,ii) = nanmean(conc(k1));
        end
    end
end

clear k k1

k = isnan(conc1b);
conc1b(k) = 0;
clear k

conc1c = conc1b;

// Differentiate concentration
dconc=[];
for i=1:lr-1
    meanflow(i) = (r(i+1)+r(i))/2;
    diameter(i) = EXP_FIT2(a,meanflow(i));
    DETEFF(i) = CUTOFF(a2,diameter(i));
    dconc(:,i)=((conc1c(:,i+1)-conc1c(:,i)))./DETEFF(i);
end

// Find all data with diameter larger than the largest bin

k = find(round(100.*flow)./100 == flowmin)
CONC3NM = average_data(time(k),conc(k),timenew,'mean')./max(DETEFF);
clear k

// Correction for diffusion losses
if diffcorr == 1
    inletl = inletl * 1e-2;
    inletr = inletr * 1e-2;
    peneff=losses(dia,inletfr,inletr,inletl,temp,pres,plotting);
    for i=1:size(dia,1)-1
        dconc(:,i)=dconc(:,i)./peneff(i);
    end
end

// Set all the negative values to zero
dconc=max(dconc,0);

// Averaging data HERE
if averaging == 1 & avenum <= size(timenew,1) then
    for ii = 1:size(dconc,1)-avenum
        ave_dconc(ii,:) = mean(dconc(ii:ii+avenum,:),'r')
        ave_time(ii) = mean(timenew(ii))
        ave_conc3nm(ii) = mean(CONC3NM(ii))
    end
    dconc = ave_dconc;
    timenew = ave_time;
    CONC3NM = ave_conc3nm;
end

// Change concentration to dN/dlogdp units
dat_inv = [];
for i=1:size(dia,1)-1
    dlogdp(i)=log10(dia(i)*1e-9)-log10(dia(i+1)*1e-9);
    dat_inv(:,i)=dconc(:,i)./dlogdp(i);
end

if plotting == 1 then
    
    f = figure(1)
    plot(diameter,dconc,'.-')
    title('Size distributions / scan','fontsize',3)
    xlabel('Diameter [nm]','fontsize',3)
    ylabel('Concentration #/cc','fontsize',3)
    h = gca()
    h.font_size = 2;
    f.background = -2
    clear f h
    
    conc5=max(dat_inv,0.01);
    concmin=floor(log10(min(conc5)));
    concmax=ceil(log10(max(conc5)));
    conc6=log10(conc5);
    conc6 = [conc6 ones(size(conc6,1),1)];
    
    f = figure(2)
    clf()
    xset("colormap",jetcolormap(64))
//    conc6=[conc6 ones(size(conc6,1),1)]
    grayplot(timenew,dia,conc6)
    colorbar(concmin,concmax)
    e = gce();
    e.parent.title.text = "dN/dlogDp";
    title(datet,'fontsize',3)
    xlabel('Time','fontsize',3)
    ylabel('Diameter [nm]','fontsize',3)
    h = gca()
    v1 = h.x_ticks.locations
    v2 = (datevec(v1))
    for i = 1:size(v2,1)
        tick(i,:) = [string(v2(i,4))+':'+msprintf("%02d",v2(i,5))+':'+msprintf("%02d",round(v2(i,6)))];
    end
    h.x_ticks.labels = tick
    h.font_size = 2;
    f.background = -2
    clear f h
    
    f = figure(3)
    dconc1 = max(dconc,0.01)
    CONC3NM = max(CONC3NM,0.01)
    plot(timenew,dconc1,'.-')
    plot(timenew,CONC3NM,'k*-')
    title('Time series','fontsize',3)
    xlabel('Time','fontsize',3)
    ylabel('Concentration #/cc','fontsize',3)
    h = gca()
    v1 = h.x_ticks.locations
    v2 = (datevec(v1))
    for i = 1:size(v2,1)
        tick(i,:) = [string(v2(i,4))+':'+msprintf("%02d",v2(i,5))+':'+msprintf("%02d",round(v2(i,6)))];
    end
    h.x_ticks.labels = tick
    h.font_size = 2;
    f.background = -2
    for i = 1:size(dia,1)-1
        legstring(i) = [string(round(dia(i+1).*100)./100) + " - " + string(round(dia(i).*100)./100) + " nm"]
    end
    
    l = legend([legstring;">"+string(round(100.*max(dia))./100)+" nm"],'pos',-1)
    l.background = -2
    h.tight_limits = "on"
    h.data_bounds = [min(timenew),max(timenew),10,10^(ceil(log10(max(max(dconc1),max(CONC3NM)))))]
    h.log_flags = "nln" ; // set Y axes to logarithmic scale
    clear f
end

// Saving data (#/cc; not dN/dlogDp)
if wanttosave == 1
    diasave = [0,dia'];
    savingpath = uigetdir("","Choose directory for data saving")
    POLKU = savingpath+'/'+fileid1+'_'+datet+'.dat';
    concsave = [CONC3NM, dconc];
    table = [diasave; timenew concsave];
    csvWrite(table,POLKU,',')
end

if sv < 6 then
    stacksize('min')
    gstacksize('min')
end
