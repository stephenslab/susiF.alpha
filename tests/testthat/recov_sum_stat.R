rm(list=ls())
library(testthat)
library(ashr)
library(wavethresh)
library(Rfast)
library(mixsqp)
library(susiF.alpha)
set.seed(2)
f1 <- simu_IBSS_per_level(lev_res=4, alpha=1, prop_decay =1.5)

plot(f1$sim_func, type="l", ylab="y")
N=100
P=10
set.seed(23)
G = matrix(sample(c(0, 1,2), size=N*P, replace=T), nrow=N, ncol=P) #Genotype
beta0       <- 0
beta1       <- 1
pos1 <- 5
noisy.data  <- list()
rsnr=1
for ( i in 1:N)
{
  f1_obs <- f1$sim_func
  noisy.data [[i]] <-   beta1*G[i,pos1]*f1_obs +  rnorm(length(f1$sim_func), sd=  (1/  rsnr ) *sd(f1$sim_func))

}
noisy.data <- do.call(rbind, noisy.data)


Y <- noisy.data
X <- G
W <- DWT2(Y)
update_D <- W
Y_f <- cbind( W$D,W$C) #Using a column like phenotype
update_Y <-Y_f
v1 <- rep(1, dim(X)[2])
tt <-  cal_Bhat_Shat(Y_f,X,v1)
indx_lst <- gen_wavelet_indx(9)
Bhat <- tt$Bhat
Shat <- tt$Shat

tt2 <-  cal_Bhat_Shat(Y,X,v1)
Bhat2 <- tt2$Bhat
Shat2 <- tt2$Shat


W1 <- (GenW(n=  ncol(Shat2)  , filter.number = 10, family = "DaubLeAsymm"))

W <- DWT2(Bhat2 )
WBhat2 <-   cbind( W$D,W$C)
image(WBhat2)
image(Bhat)
plot( Bhat,WBhat2 )

#in terms matrix product

mat_recov <- function(Bhat2, W1)
{
  t_Bhat <- matrix(NA, ncol = ncol(Bhat2),nrow=nrow(Bhat2))
  for ( i  in 1:nrow(t_Bhat))
  {
    tt <- as.vector (Bhat2[i,]%*%W1)
    t_Bhat[i,] <- shifter(tt,-1)
  }
  return(t_Bhat)
}

plot(Bhat, mat_recov(Bhat2,W1))
