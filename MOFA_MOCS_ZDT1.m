function MOFA_MOCS_ZDT1
    %�����Эͬ��Ŀ��ө����㷨
    %Programmed by Kevin Kong
    %��������ZDT-1
    clc;
    global NP N T_MAX gamma beta0 epsilon M V
    NP = 100;%��Ⱥ��С
    T_MAX = 500;%����������
    N = 100;%�ⲿ������ģ
    gamma = 1;%������ϵ��
    beta0 = 1;%���������
    M = 2;%Ŀ�꺯������
    V = 30;%���߱�������
    t = 1;%��������
    epsilon = get_epsilon();
    %������Χ��[0,1]
    min_range = zeros(1,V);
    max_range = ones(1,V);
    pop = init(NP,M,V,min_range,max_range);%��ʼ����Ⱥ
    Arc = pop(non_domination_sort(pop,M,V),:);%��֧������
    while(t <= T_MAX)
        plot(pop(:,V+1),pop(:,V+2),'*');
        str = sprintf("��%d��",t);
        title(str);
        drawnow;
        offspring = pop;%�Ӵ�
        for i = 1:NP
            for j = 1:NP
                domination = get_domination(pop(i,:),pop(j,:),M,V);
                if(domination ~= -1)
                    %i��j֮�����֧���ϵ
                    g = Arc(1+fix((size(Arc,1)-1)*rand(1)),:);%��Arc�����ѡȡһ��������Ϊg*
                    if(domination == 0)
                        %i֧��j
                        offspring(j,1:V) = firefly_move(pop(i,:),pop(j,:),V,beta0,gamma,true,g);
                        offspring(j,1:V) = outbound(offspring(j,1:V),V,min_range,max_range);
                    else
                        %j֧��i
                        offspring(i,1:V) = firefly_move(pop(j,:),pop(i,:),V,beta0,gamma,true,g);
                        offspring(i,1:V) = outbound(offspring(i,1:V),V,min_range,max_range);
                    end
                else
                    %i��j֮�䲻����֧���ϵ
                    g = Arc(1+fix((size(Arc,1)-1)*rand(1)),:);%��Arc�����ѡȡһ��������Ϊg*
                    res = firefly_move(pop(i,:),pop(j,:),V,beta0,gamma,false,g);
                    offspring(i,1:V) = res(1,:);
                    offspring(i,1:V) = outbound(offspring(i,1:V),V,min_range,max_range);
                    offspring(j,1:V) = res(2,:);
                    offspring(j,1:V) = outbound(offspring(j,1:V),V,min_range,max_range);
                end
            end
        end
        pop = offspring;%����ө���λ��
        for i = 1:N
            pop(i,V+1:V+M) = evaluate_objective(pop(i,:));%����ө������
        end
        Arc = update_Arc(pop,Arc,N,M,V,epsilon);%���æ�-�������·������ά��Arc����
        t = t + 1;
    end
end
%% 
function f = init(N,M,V,min,max)
    %��ʼ����Ⱥ��������ɸ��岢�������ʶ�ֵ
    %N:��Ⱥ��С
    %M:Ŀ�꺯������
    %V:���߱�����
    %min:������Χ����
    %max��������Χ����
    f = [];%��Ÿ����Ŀ�꺯��ֵ,1:V�Ǿ��߱�����V+1:V+2��Ŀ�꺯��ֵ
    for j = 1:V
        delta(j) = (max(j) - min(j))/N;%�����߱���x(j)��������Ȼ��ֳ�N�ȷ�;
        lamda = min(j):delta(j):max(j);%�õ�N��������
        for i = 1:N
            %��N�������������ѡ��һ��
            [~,n] = size(lamda);%������������n
            rand_n = 1 + fix((n-2)*rand(1));%���λ��
            min_range = lamda(rand_n);%��������������
            max_range = lamda(rand_n+1);%��������������
            f(i,j) = min_range + (max_range - min_range)*rand(1);%�������
            lamda(rand_n) = [];%ɾ����������
        end
    end
    %���������ʶ�ֵ
    for i = 1:N
        f(i,V+1:V+M) = evaluate_objective(f(i,:));%����Ŀ�꺯��ֵ
    end
end
%%
function f = evaluate_objective(x)
    %����Ŀ�꺯�������ʶ�ֵ�����Է�����ZDT-1
    global V 
    f = [];
    f(1) = x(1);%Ŀ�꺯��1
    g = 1;
    g_tmp = 0;
    for i = 2:V
        g_tmp = g_tmp + x(i);
    end
    g = g + 9*g_tmp/(V-1);
    f(2) = g*(1-sqrt(x(1)/g));%Ŀ�꺯��2
end
%%
function f = non_domination_sort(x,M,V)
    %��֧������,�õ���֧��⼯
    %M:Ŀ�꺯������
    %V:���߱�����
    [N,~] = size(x);%��ȡ��Ⱥ������
    rank = 1;%pareto�ȼ�
    F(rank).f = [];%��֧��⼯
    pop = [];%��Ⱥ
    for i = 1:N
        %�õ���ߵȼ�����͸�����֧���ϵ
        pop(i).np = 0;%��֧����
        pop(i).sp = [];%֧����弯��
        for j = 1:N
            %����֧����򣺶������Ŀ�꺯��������fk(x1)<=fk(x2)���Ҵ���fk(x1)<fk(x2)
            domination = get_domination(x(i,:),x(j,:),V,M);%���i��j֮���֧���ϵ
            if(domination == 0)
                %i֧��j
                pop(i).sp = [pop(i).sp j];%�Ѹ���j����������֧�伯����
            elseif(domination == 1)
                %i��j֧��
                pop(i).np = pop(i).np + 1;%i�ı�֧����+1
            end
        end
        if(pop(i).np == 0)
            x(i,V+3) = rank;%rank�ȼ���ߣ�Ϊ1
            F(rank).f = [F(rank).f i];%�Ѹ���i���뵽��֧��⼯��
        end
    end
    f = F(rank).f;
end
%%
function res = get_domination(x1,x2,V,M)
    %������������֧���ϵ��x1֧��x2����0��x2֧��x1����1�����򷵻�-1
    less = 0;%С��
    equal = 0;%����
    more = 0;%����
    for k = 1:M
        %����ÿһ��Ŀ�꺯��
        if(x1(V+k) < x2(V+k))
            less = less + 1;
        elseif(x1(V+k) == x2(V+k))
            equal = equal + 1;
        else
            more = more + 1;
        end
    end
    if(more == 0 && equal ~= M)
        %i֧��j
        res = 0;
    elseif(less == 0 && equal ~= M)
        %i��j֧��
        res = 1;
    else
        res = -1;
    end
end
%%
function new_x = firefly_move(x1,x2,V,beta0,gamma,domination,g)
    %ө���x1��x2�ƶ�
    %V:���߱�����
    %beta0:���������
    %gamma:������ϵ��
    %��x1��x2֮�����֧���ϵʱ��omega = omega0��omega0Ϊ[0,1]֮��������
    %��x1��x2֮�䲻����֧���ϵ��omega = 1-omega0
    %gΪ��Ӣ����
    global NP
    r = get_distance(x1(1:V),x2(1:V),V);%���x1��x2֮��ľ���
    beta = get_attraction(r,beta0,gamma);%���x1��x2֮���������
    s = levy_flights();%��ά���л������Ŷ�
    omega0 = rand(1);
    if(domination == true)
        %����֧���ϵ
        r_g = get_distance(x2(1:V),g(1:V),V);%���x2�뾫Ӣ����g֮��ľ���
        beta_g = get_attraction(r_g,beta0,gamma);%���x2��g֮���������
        new_x = x1(1:V) + omega0*beta.*(x1(1:V)-x2(1:V)) + (1-omega0)*beta_g.*(g(1:V)-x2(1:V));
    else
        %������֧���ϵ
        new_x = [];
        r_g = get_distance(x1(1:V),g(1:V),V);%���x1�뾫Ӣ����g֮��ľ���
        beta_g = get_attraction(r_g,beta0,gamma);%���x2��g֮���������
        new_x(1,:) = omega0.*x1(1:V) + (1-omega0)*beta_g.*(g(1:V)-x1(1:V));
        r_g = get_distance(x2(1:V),g(1:V),V);%���x2�뾫Ӣ����g֮��ľ���
        beta_g = get_attraction(r_g,beta0,gamma);%���x2��g֮���������
        new_x(2,:) = omega0.*x2(1:V) + (1-omega0)*beta_g.*(g(1:V)-x2(1:V));
    end
end
%%
function beta = get_attraction(r,beta0,gamma)
    %���ө���x1��x2֮���������
    %r:��ө���֮��ľ���
    %beta0:���������
    %gamma:������ϵ��
    beta = beta0*exp(-1*gamma*r^2);
end
%%
function distance = get_distance(x1,x2,V)
    %���ө���x1��x2֮��ľ���
    distance = norm(x1(1:V)-x2(1:V));
end
%%
function s = levy_flights()
    %��ά���в�������Ŷ�
    beta = 1.5;%betaΪ(0,2]֮��ĳ�����һ��ȡֵΪ1.5
    sigma_u = ((gamma(1+beta)*sin(pi*beta/2))/(gamma((1+beta)/2)*beta*2^((beta-1)/2)))^(1/beta);%0.6966
    sigma_v = 1;
    u = normrnd(0,sigma_u);%������ֵΪ0����׼��Ϊsigma_u����̬�ֲ������ 0<u��0.5232
    v = normrnd(0,sigma_v);%������ֵΪ0����׼��Ϊsigma_v����̬�ֲ������ 0<v��0.3989
    s = u/abs(v)^(1/beta);
end
%%
function x = outbound(x,V,lb,ub)
    %Խ�紦��
    for i = 1:V
        if(x(i)<lb(i))
            x(i) = lb(i);
        elseif(x(i)>ub(i))
            x(i) = ub(i);
        end
    end
end
%%
function epsilon = get_epsilon()
    %��ȡ��-ռ�ŷֱ�������Ŀ�꺯���еĲ���
    global N
    %epsilon = (MAX-MIN)/N
    epsilon = [];
    %ZDT-1�����£�f1(x)��[0,1]
    %f2(x)��[0,10]
    epsilon(1) = (1-0)/N;
    epsilon(2) = (10-0)/N;
end
%%
function res = update_Arc(pop,Arc,N,M,V,epsilon)
    %�����ⲿ����
    %pop:��Ⱥ
    %Arc:�ⲿ����
    %N:�ⲿ������С
    %M:Ŀ�꺯����
    %V:���߱�����
    %epsilon:
    solutions = pop(non_domination_sort(pop,M,V),:);%��֧��⼯
    [n1,~] = size(solutions);%�õ���ǰ��Ⱥ�з�֧���ĸ���
    [n2,~] = size(Arc);%�õ���ǰ�ⲿ�����з�֧���ĸ���
    res = [];
    solutions(:,V+1) = solutions(:,V+1).*(1+epsilon(1));%����֧������
    solutions(:,V+2) = solutions(:,V+2).*(1+epsilon(2));%����֧������
    %n = 0;%��¼�����и�����
    for i = 1:n1
        dominate = 0;
        j = 1;
        while (j <= n2) && (n2 > 0)
            if(get_domination(solutions(i,:),Arc(j,:),V,M) == 0)
                %solutions(i)��֧��Arc(j)
                dominate = dominate + 1;
                Arc(j,:) = [];
                n2 = n2 - 1;
            end
            j = j + 1;
        end
        if(dominate > 0)
            res = [res;solutions(i,:)];%�Ѹý���뵽�ⲿ������
        end
    end
    res = [res;Arc];
end