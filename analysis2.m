clear; clc; close all;
datadir = '/Users/yinancaojake/Documents/Postdoc/coronavirus/COVID-19-master-12Feb/time_series/';
cd(datadir)

folderpath = fullfile(datadir, '*.csv');    % What is the meaning of "/**/" ???
filelist   = dir(folderpath);
name       = {filelist.name};
name       = name(~strncmp(name, '.', 1));   % No files starting with '.'

figure('position', [219, 539, 1149, 327])
China = []; Over = [];
for i = 1
    fn = [datadir,name{i}];
    T = readtable(fn);
    
    time = table2array(T(1,5:end));
    tt = datenum(time);
    tt = tt-tt(1);

    regionName = T.Var2(2:end);
    d = T(2:end,5:end);
    d = table2array(d);
    d = str2double(d);

    IndexC = strfind(regionName,'China');
    inside = find(not(cellfun('isempty',IndexC)));
    outside = setdiff(1:length(IndexC),inside)';

    s = [nansum(d(inside,:),1); nansum(d(outside,:),1)];
    s = log(s);

msize = 10;
order = 5;
f = [];
dofilter = 0;
for k = 1:2
    p = polyfit(tt,s(k,:)',order);
    if dofilter
       f(:,k) = polyval(p,tt);
    else
       f(:,k) = s(k,:)';
    end
end
subplot(1,3,1)
plot(tt(1:end),(exp(f))','o-','markersize',msize,'markerfacecolor','w')
axis square;axis tight
xlabel('Time point')
ylabel('Confirmed cases')
set(gca,'fontsize',14,'box','off','linewidth',1)

subplot(1,3,2)
semilogy(tt(1:end),(exp(f))','o-','markersize',msize,'markerfacecolor','w')
axis square;axis tight
xlabel('Time point')
ylabel('Confirmed cases (log scale)')
set(gca,'fontsize',14,'box','off','linewidth',1)

    slope = [];
    x1 = f;
    n = 7; % how many days in window
    time = [];
    for t = 1:size(x1,1)-n+1
        for k = 1:2
            y = x1(t:t+n-1,k);
            b = glmfit(tt(t:t+n-1),y);
            slope(t,k) = b(2);
            time(t) = mean(tt(t:t+n-1));
        end
    end
    subplot(1,3,3)
    plot(time,slope,'o-','markersize',msize,'markerfacecolor','w')
    axis square; 
    xlabel('Time point')
    ylabel('Slope estimate (using log scale)')
    legend({'In mainland China';'Outside'},'box','off')
    set(gca,'fontsize',14,'box','off','linewidth',1)
    text(9,0.48,'[7-day moving window]','fontsize',12)
end

