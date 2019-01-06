function [U lambda pr llikevec mae time_trace rankvec] = PTF_Gibbs(xi,id,R)
    K=length(id);
    for k=1:K 
        N(k) = max(id{k}); 
    end
    Nnon0=length(id{1,1});
    Train=round(0.95*Nnon0);

    rng(0);
    a=5e-1*ones(1,K);
    U=cell(1,K);
    for k=1:K
        U{1,k} = sampleDirMat(a(k)*ones(1,N(k)),R);
        U{1,k} = U{1,k}';
    end

    c=1;
    epsi=1/R;
    pr=betarnd(c*epsi,c*(1-epsi));
    gr=0.1;
    % lambda=1/R.*ones(1,R);
    lambda=gamrnd(gr,pr/(1-pr),1,R);

    iterN=500;
    burnin=300;
    step=4;
    sampleN=(iterN-burnin)/step;
    % samPsi=zeros(size(Psi));

    rp = randperm(Nnon0);

    xitrain=xi(rp(1:Train));
    xitest=xi(rp(Train+1:end));
    %idtrainvec=idtrain;
    idtrain=cell(1,K);
    for k=1:K
        idtrain{k} = id{k}(rp(1:Train));
        idtest{k} = id{k}(rp(Train+1:end));
    end
    llikevec=zeros(iterN,1);

    zetair=unormalzetair(U,idtrain,lambda);
    xitrainlatent=truncated_Poisson_rnd(sum(zetair,2));
    xir=mnrnd(xitrainlatent,zetair./repmat(sum(zetair,2),1,R));

    llikevec=zeros(iterN,1);
    rmsevec=zeros(iterN,1);
    maevec=zeros(iterN,1);
    msevec=zeros(iterN,1);
    r=zeros(iterN,1);

    tic
    for iter=1:iterN
    %     iter
        [xsumr,xr]=tensorsum(xir,idtrain,N);
        pr=betarnd(c*epsi+xr,c*(1-epsi)+gr);
        for r=1:R
            for k=1:K
                U{1,k}(:,r) = sampleDirMat(a(k)+xsumr{1,k}(:,r)',1)';
            end
        end
        lambda=gamrnd(gr+xr,pr);
        %zetair=computezetair_new(U,idtrain,lambda);
        zetair=unormalzetair(U,idtrain,lambda);
        xitrainlatent=truncated_Poisson_rnd(sum(zetair,2));
        xir=mnrnd(xitrainlatent,zetair./repmat(sum(zetair,2),1,R));
    %     xi=xigenerate(X,id);
%         xir=mnrnd(xitrain,zetair);
        if iter>burnin & mod(iter-burnin,step)==0
            if iter==(burnin+step)
                lambdasam=lambda/sampleN;
                Usam=U;
                for k=1:K
                    Usam{1,k}=Usam{1,k}/sampleN;                
                end
            else
                lambdasam=lambdasam+lambda/sampleN;
                for k=1:K
                    Usam{1,k}=Usam{1,k}+U{1,k}/sampleN;                
                end
            end
        end

            if iter==1 
                time_trace(iter) = toc;
                tic;
            else
                time_trace(iter) = time_trace(iter-1) + toc;
                tic;
            end 

            [llike auc_test]=evaluation(xi(rp(Train+1:end)),idtest,U,lambda);
            llikevec(iter)=llike;
            auc_vec(iter)=auc_test;
            rankvec(iter)=sum(pr>0.6);
           fprintf('iteration= %d;loglikelihood= %f, auc=%f, time elapsed= %f, rank=%d\n', iter, llike, auc_test, time_trace(iter),rankvec(iter));
           subplot(4,1,1),plot(time_trace(1:iter),llikevec(1:iter));
           subplot(4,1,1),plot(time_trace(1:iter),auc_vec(1:iter));
           subplot(4,1,3),plot(sort(lambda));
           subplot(4,1,4),plot(sort(pr));
           
           drawnow;
    end
end