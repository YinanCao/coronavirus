clear; clc; close all;
d = pwd;
datadir = [pwd,'/data/'];
cd(datadir)

folderpath = fullfile(datadir, '*.csv');    % What is the meaning of "/**/" ???
filelist   = dir(folderpath);
name       = {filelist.name};
name       = name(~strncmp(name, '.', 1));   % No files starting with '.'

China = []; Over = [];
for i = 1:length(name)
    fn = [datadir,name{i}];
    t = strfind(name{i},'CSSE - ')+7:strfind(name{i},'.csv')-1;
    time = name{i}(t);
    day = str2double(time(4:5));
    t0 = datenum('01/21/2020 12:00');
    T = readtable(fn);
    
    if any(strcmp('LastUpdate', T.Properties.VariableNames))
        date = T.LastUpdate(1);
    else
        date = T.DateLastUpdated(1);
    end
    if date.Year ~= 2020
        date.Year = 2020;
    end
    date.Hour = 12;
    date.Minute = 0;
    date.Second = 0;
    dd(i) = date;
    time_diff = datenum(date) - t0;
    hours(i) = floor(time_diff * 24);
    
    C = T.Confirmed;
    if any(strcmp('Deaths', T.Properties.VariableNames))
        D = T.Deaths;
    else
        D = zeros(size(C));
    end
    if any(strcmp('Recovered', T.Properties.VariableNames))
        R = T.Recovered;
    else
        R = zeros(size(C));
    end
    Y = [C,D,R]; % confirm, death, recovery
    if any(strcmp('Country_Region', T.Properties.VariableNames))
        region = T.Country_Region;
    elseif any(strcmp('Country', T.Properties.VariableNames))
        region = T.Country;
    end
    IndexC = strfind(region,'China');
    inside = find(not(cellfun('isempty',IndexC)));
    outside = setdiff(1:size(Y,1),inside)';
    China = [China; nansum(Y(inside,:))];
    Over = [Over; nansum(Y(outside,:))];
end
disp('done')
All = {China; Over};


[a,latestDay] = max(hours);
dd(latestDay)
length(hours)
latDaystr = '06/Feb';

%%

close all; clc
ttstr = {'Mainland China';'The rest of the world'};
sym = {'o','s','^'};
figure('position',[316   213   786   742])
for region = 1:2
X = [hours', All{region}];
x = unique(X(:,1));
x1 = [];
for i = 1:length(x)
    m = X(X(:,1)==x(i),:);
    if size(m,1)>1
        m = mean(m);
    end
    x1 = [x1; m];
end
array2table(x1)
nday = size(x1,1);
subplot(2,2,1+region-1)
ccc = {'k','r','g'};
for i = 1:3
    semilogy((x1(:,i+1)),[ccc{i},'-',sym{i}],'markersize',10,...
        'linewidth',1,'markerfacecolor',ccc{i})
    hold on;
    ylim([10^-0.5,10^4.5])
    xlim([0,nday+1])
    grid on
    ylabel('Cases')
end
title(ttstr{region})
set(gca,'fontsize',19,'box','off','linewidth',1,'xtick',[1,nday],...
    'xticklabel',{'21/Jan',latDaystr},'xticklabelrotation',30)

slope = [];
x1 = log(x1);
n = 7; % how many days in window
time = [];
for t = 1:size(x1,1)-n+1
    for k = 2:4
        y = x1(t:t+n-1,k);
        b = glmfit(t:t+n-1,y);
        slope(t,k) = b(2);
        time(t) = mean(t:t+n-1);
    end
end

slope(:,1) = [];

subplot(2,2,3+region-1)
for i = 1:3
    plot(time,slope(:,i),[ccc{i},'-',sym{i}],'markersize',10,...
        'linewidth',1,'markerfacecolor',ccc{i})
    hold on;
end
ylim([-.05,.5])
xlim([0,nday+1])
set(gca,'fontsize',19,'box','off','linewidth',1,'xtick',[1,nday],...
    'xticklabel',{'21/Jan',latDaystr},'xticklabelrotation',30)
ylabel({'Slope estimate';'(7-day running window)'})
if region == 1
    legend({'confirmed';'deaths';'recovery'},'location','sw');
end
grid on
end

