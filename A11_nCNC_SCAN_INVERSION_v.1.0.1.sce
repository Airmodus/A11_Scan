
//------------------------------------------------------------------------------
// AIRMODUS A11 inversion code for scanning raw (.dat) data 
// v.1.0.1

// by Joonas Vanhanen (joonas.vanhanen@airmodus.com)

// Inverts PSM scan data into size distributions
// Corrects data for diffusion losses
// Plots and saves inverted data

// Functions / .sci-files used:
// diameters_interpolation.sci
// deteff_dia_interpolat.sci
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
// SOFT_VER_CHECK.sci
// polyfit.sci
// PSM_ERROR.sci
// PSM_NOTE.sci
// CPC_ERROR.sci

// Note: requires A11 calibration file!

// Output file format (M(row,column)) (comma separated):
// First row: Diameters for bin limits in nm (first value M(1,1) is always zero)
// Column n. 1: date (Matlab datenum format)
// Column n. 2: Total number concentration above the upper limit of size distribution (M(1,2))
// Column n. 3->: Particle number concentration in size bins in dN/dDp or in dN/dlogDp depending on the selection of the user

// Notation for the Dilution Factor = (Q_sample + Q_dilution) / Q_sample
// Q_sample is the volumetric sample flow rate going to the PSM (2.5 lpm)
// Q_dilution is the volumetric flow rate of the filtered dilution air

// Note that the time stamp in with all the data is always start of a scan
// Also the running average is over the upcoming n scans

// Copyright 2019 Airmodus Ltd.

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

if isempty(filename) then
    disp('No data file selected')
    abort
end

// Name of the calibration file
[calib,datapath_cal] = uigetfile(['*.txt'],"",'SELECT THE CALIBRATION FILE');  

if isempty(calib) then
    disp('No calibration file selected')
    abort
end


// USER INPUTS
//------------------------------------------------------------------------------

//labels=["File name for inverted data";"Discard data with instrument errors? 1/0";"Raw data filtering? 1/0";"Number of bins";"Number of scans to average";"Dilution factor";"Saving on 1/0";"Plotting on 1/0";"Diffusion correction on 1/0";"Sampling tube length [cm]";"Sampling tube radius [cm]";"Sampling tube flow rate [lpm]";"Temperature [Kelvin]";"Pressure [Pascal]"];
//[ok,fileid1,ERR,bs,bn,avenum,DF,wanttosave,plotting,diffcorr,inletl,inletr,inletfr,temp,pres]=getvalue("Give input parameters for the inversion code",labels,...
//     list("str",1,"str",1,"str",1,"vec",1,"vec",1,"vec",1,"str",1,"str",1,"str",1,"vec",1,"vec",1,"vec",1,"vec",1,"vec",1),["INVERTED_PSM_DATA";"%t";"%t";"5";"1";"1";"%f";"%t";"%f";"40";"0.2";"2.5";"293";"101325"])

labels1=["File name for inverted data";"Number of bins";"Number of scans to average";"Dilution factor";"Discard data with instrument errors";"Raw data filtering";"Plotting";"Diffusion correction";"Saving";"Save as dN/dlogDp"];

labels2=["Sampling tube length [cm]";"Sampling tube radius [cm]";"Sampling tube flow rate [lpm]";"Temperature [Kelvin]";"Pressure [Pascal]"];

[ok1,fileid1,bn,avenum,DF,ERR,bs,plotting,diffcorr,wanttosave,dndlog]=getvalue("Give input parameters for the inversion code",labels1,list("str",1,"vec",1,"vec",1,"vec",1,"str",1,"str",1,"str",1,"str",1,"str",1,"str",1),["INVERTED_PSM_DATA";"5";"1";"1";"%t";"%t";"%t";"%f";"%f";"%t"])

if diffcorr == '%t' then
    [ok2,inletl,inletr,inletfr,temp,pres]=getvalue("Give input parameters for the diffusion loss calculations",labels2,list("vec",1,"vec",1,"vec",1,"vec",1,"vec",1),["40";"0.2";"2.5";"293";"101325"])
end


if plotting == '%t' then
    plottingg = 1;
else
    plottingg = 0;
end

if avenum >1 then
    averaging = 1;
else
    averaging = 0;
end

//------------------------------------------------------------------------------

// INVERSION
//------------------------------------------------------------------------------

// Importing measurement data
tic()
disp('Importing data')
header = 1;
[A,comments]=csvRead(datapath+'/'+filename,',',[],'string',[],'/9999/',[],header);

// Finding the values
t=A(:,1);
day = strtod(part(t,1:2));
month = strtod(part(t,4:5));
year = strtod(part(t,7:10));
hour = strtod(part(t,12:13));
minute = strtod(part(t,15:16));
second = strtod(part(t,18:19));
tim=datenum(year,month,day,hour,minute,second);
c=strtod(A(:,2),'.').*DF; //concentration from PSM (1/cm3) (corrected for dilution)
sat_f=strtod(A(:,4),'.'); // saturator flow rate (lpm)

// Binary strings for PSM and CPC notes and errors
ERRORS = A(:,45:47);

// Find error values in error values
ind = grep(ERRORS,['Err' 'STAT']);
indr = [];
indc = [];
for i = 1:length(ind)
    if ind(i) <= size(A,1)
        indr(i) = ind(i)
        indc(i) = 1;
    elseif ind(i) > size(A,1) & ind(i) <= 2*size(A,1)
        indr(i) = ind(i)- size(A,1)
        indc(i) = 2;
    elseif ind(i) > 2*size(A,1)
        indr(i) = ind(i) - 2*size(A,1)
        indc(i) = 3;
    end
end
clear i
for i = 1:length(indr)
    for ii = 1:length(indc)
        ERRORS(indr(i),indc(ii)) = '0x0000';
    end
end
PSM_note_bin = dec2bin(hex2dec(part(ERRORS(:,2),3:$)),16);
PSM_err_bin = dec2bin(hex2dec(part(ERRORS(:,3),3:$)),16);
CPC_err_bin = dec2bin(hex2dec(part(ERRORS(:,1),3:$)),16);

PSM_note = [];
PSM_err = [];
CPC_err = [];

for i = 1:size(A,1)
    PSM_note = [PSM_note,strindex(PSM_note_bin(i),'1')]
    PSM_err = [PSM_err,strindex(PSM_err_bin(i),'1')]
    CPC_err = [CPC_err,strindex(CPC_err_bin(i),'1')]
end

if ERR == '%t' then
    ind = find(A(:,46) ~= '0x0000' | A(:,45) ~= '0x0000' | A(:,47) ~= '0x0000')
    c(ind) = %nan;
    if length(ind) == size(A,1) then
        disp('No data without instrument errors')
        abort
    end
end

// List of unique errors and notes in the data set
PSM_note = 16-(gsort(unique(PSM_note),'g','i'));
PSM_err = 16-(gsort(unique(PSM_err),'g','i'));
CPC_err = 16-(gsort(unique(CPC_err),'g','i'));

tictoc = toc()
disp('Elapsed time = ' + string(tictoc) + ' s')
disp('Analysing data')

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
apu = 0:1:bn;
a = (flowmax/flowmin).^(1/(bn));
P0 = flowmax./a.^bn;
satflow = P0.*a.^apu;

pvm=datenum(strtod(part(datet,1:4)),strtod(part(datet,5:6)),strtod(part(datet,7:8)));
apuaika = datevec(pvm);

// Import the calibration file
cal = fscanfMat(datapath_cal+'/'+calib);
sat=cal(:,1);   // Saturator flow rates
di=cal(:,2);    // Diameters
ef=cal(:,3);    // Detection efficiensies

// Fit calibration data cut-off diameter as a function of saturator flow rate
dia = diameters_interpolation(sat,di,satflow,plottingg);

// Fit calibration data detection efficiency as a function of diameter (at highest sat flow)
[deteff] = deteff_dia_interpolat(di,ef,dia',plottingg);

// Search number of scans
k1 = find((100.*flow)./100 == flowmin)
k2 = min(k1);

nscan = [];
for i = 1:length(flow)
    if i < length(flow) then
        if i<=k2 then
            nscan(i) = 0;
        elseif round(100*flow(i))/100 == flowmin & round(100*flow(i+1))/100 ~= flowmin then
            nscan(i) = nscan(i-1)+1;
        else
            nscan(i) = nscan(i-1);
        end
    end
    if i == length(flow) then
        nscan(i) = nscan(i-1);
    end
end

if isempty(nscan) then
    disp('No scans found in the data file')
    abort
end

clear k1 k2

// Averaging over a full scan and to bins

timenew = []; conc1b = []; meanflow = []; diameter = [];
lr=size(satflow,2);
for i = 1:max(nscan)
    k = find(nscan == i);
    timenew(i) = min(time(k)); // Time stamp from beginning of one scan
    for iii = 1:lr-1
        meanflow(iii) = (satflow(iii+1)+satflow(iii))/2;
        diameter(iii) = (dia(iii+1)+dia(iii))/2;
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

DETEFF = deteff_dia_interpolat(di,ef,diameter,0)

// Find all data with diameter larger than the largest bin
k = find(round(100.*flow)./100 == flowmin)
CONC3NM = average_data(time(k),conc(k),timenew,'mean')./max(DETEFF);
clear k

ave_conc = []; ave_time = []; ave_conc3nm = [];
// Take an moving average of the data
if averaging == 1 & avenum <= size(timenew,1) then
    for ii = 1:max(nscan)-avenum
        ave_conc(ii,:) = mean(conc1b(ii:ii+avenum,:),'r')
        ave_time(ii) = mean(timenew(ii))
        ave_conc3nm(ii) = mean(CONC3NM(ii))
    end
    conc1b = ave_conc;
    timenew = ave_time;
    CONC3NM = ave_conc3nm;
end

k = isnan(conc1b);
conc1b(k) = 0;
clear k

// Check the quality of each scan
M = []

for i = 1:size(conc1b,1)
    Cmax = nanmax(conc1b(i,:))
    if sum(conc1b(i,:)) == 0
        cf(1:2) = 0;
    else
        cf = polyfit(satflow,conc1b(i,:)./Cmax,1)
    end
    M(i,:) = [i,cf(2)]
end

dconc=[];
for i=1:lr-1
    dconc(:,i)=((conc1b(:,i+1)-conc1b(:,i)))./DETEFF(i);
end

// Set all scans with no small particltes to 0

if bs == '%t' then
    for i = 1:size(dconc,1)
        if M(i,2) < 0
            dconc(i,:) = 0
        end
    end
end

// Correction for diffusion losses
if diffcorr == '%t'
    inletl = inletl * 1e-2;
    inletr = inletr * 1e-2;
    peneff=losses(dia,inletfr,inletr,inletl,temp,pres,plottingg);
    for i=1:size(dia,2)-1
        peneffave(:,i) = (peneff(i) + peneff(i+1))/2
    end
    for i=1:size(dconc,1)
        dconc(i,:) = dconc(i,:)./peneffave
    end
end

// Set all the negative values to zero
dconc=max(dconc,0.0001);

// Change concentration to dN/dlogdp units
dat_inv = [];
for i=1:size(dia,2)-1
    dlogdp(i)=log10(dia(i)*1e-9)-log10(dia(i+1)*1e-9);
    dat_inv(:,i)=dconc(:,i)./dlogdp(i);
end

ind = find(M(:,2)<0)
dq = size(ind,2) // Number of scans rejected

if plotting == '%t' & dq ~= max(nscan) then
    tictoc = toc()
    disp('Elapsed time = ' + string(tictoc) + ' s')
    disp('Plotting data')
    for i = 1:length(dia)*2-2
        dat_inv_plot(:,i) = dat_inv(:,ceil(i/2))
        dconc_plot(:,i) = dconc(:,ceil(i/2))
        if i == 1
            diaplot(i) = dia(i)
        else
            diaplot(i) = dia(ceil((i+1)/2))
        end
        
    end
    
    f = figure(1)
    plot(diaplot,dconc_plot,'--','color',[0.25,0.25,0.25])
    plot(diameter,dconc,'.-')
    title(['Size distributions / scan ',datet],'fontsize',3)
    xlabel('Diameter [nm]','fontsize',3)
    ylabel('Concentration #/cc','fontsize',3)
    h = gca()
    h.log_flags = "lln"
    h.font_size = 2;
    h.data_bounds = [1,4,max(10^floor(log10(min(dconc_plot))),10),2*(max(dconc_plot))]
    f.background = -2
    h.x_ticks.labels = ['1';'2';'3';'4';'5']
    clear f h
    
    concmin=floor(log10(min(max(dat_inv,0.01))));
    concmax=ceil(log10(max(max(dat_inv,0.01))));
    conc6 = [log10(max(dat_inv(:,1),0.01)) log10(max(dat_inv,0.01))];
    
    f = figure(2)
    clf()
    xset("colormap",jetcolormap(64))
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
 end
 
 if plotting == '%t' then
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
    for i = 1:size(dia,2)-1
        legstring(i) = [string(round(dia(i+1).*100)./100) + " - " + string(round(dia(i).*100)./100) + " nm"]
    end
    
    l = legend([legstring;">"+string(round(100.*max(dia))./100)+" nm"],'pos',-1)
    l.background = -2
    h.tight_limits = "on"
    h.data_bounds = [min(timenew),max(timenew),10,10^(ceil(log10(max(max(dconc1),max(CONC3NM)))))]
    h.log_flags = "nln" ; // set Y axes to logarithmic scale
    clear f
end

tictoc = toc()
disp('Total elapsed time = ' + string(tictoc) + ' s')

disp('--------------------------------------------------')

if dq == max(nscan) then
    disp('!!!All the scans were discarded!!!')
end

if isempty(ind) == 'T' | bs == '%f' then
    disp('Scans discarder = 0')
else
    disp('Scans discarder = ' + string(dq) + '/' + string(max(nscan)))
end

disp('PSM errors = ')
disp('  ' + PSM_ERROR(PSM_err))

disp('CPC errors = ')
disp('  ' + CPC_ERROR(CPC_err))

disp('PSM notes = ')
disp('  ' + PSM_NOTE(PSM_note))

if ERR == 1 & isempty(PSM_err) == 'F' & isempty(PSM_note) == 'F' & isempty(CPC_err) == 'F' then
    disp('All data with errors discarded')
end

disp('--------------------------------------------------')


// Saving data (#/cc; not dN/dlogDp)
if wanttosave == '%t'
    if dndlog == '%f'
        diasave = [0,dia];
        savingpath = uigetdir("","Choose directory for data saving")
        POLKU = savingpath+'/'+fileid1+'_dNdDp_'+datet+'.dat';
        concsave = [CONC3NM, dconc];
        table = [diasave; timenew concsave];
        csvWrite(table,POLKU,',')
    else
        diasave = [0,dia];
        savingpath = uigetdir("","Choose directory for data saving")
        POLKU = savingpath+'/'+fileid1+'_dNdlogDp_'+datet+'.dat';
        concsave = [CONC3NM, dat_inv];
        table = [diasave; timenew concsave];
        csvWrite(table,POLKU,',')
    end
end

if sv < 6 then
    stacksize('min')
    gstacksize('min')
end
