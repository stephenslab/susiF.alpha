#TODO
#Recover stat

#' @title Sum of Single Functions using sufficient statistics
#'
#' @description Implementation of the SuSiF method
#'
#' @details tbd
#'
#' @param Bhat A p by t matrix of estimated effects.
#'
#' @param Shat A p by t matrix of standard errors.
#'
#' @param R A p by p correlation matrix. It should be estimated from
#'   the same samples used to compute \code{Bhat} and \code{Shat}. Using
#'   an out-of-sample matrix may produce unreliable results.
#'
#'  @param N The sample size.
#'
#' @param var_y a T vector of The sample variance of Y at each time point , defined as \eqn{y'y/(n-1)}.
#'   When the sample variance cannot be provided, the coefficients
#'   (returned from \code{coef}) are computed on the "standardized" X, y
#'   scale.
#'
#' @param XtX A p by p matrix \eqn{X'X} in which the columns of X
#'   are centered to have mean zero.
#'
#' @param Xty A p by T matrix \eqn{X'y} in which y and the columns of X are
#'   centered to have mean zero.
#'
#' @param yty A T by T scalar \eqn{y'y} in which y is centered to have mean
#'   zero.
#'
#' @param L integer, number of effect considered.
#'
#' @param wav_trans logical, if true the algorithm will consider that the summary statistics based on wavelet transformed data (\code{Bhat} and \code{Shat}).
#'  if False, the algorithm will rescale \code{Bhat} and \code{Shat} to obtain summary statistics from wavelet regression. Default set as FALSE .
#'
#' @param pos vector of length J, corresponding to position/time pf
#' the observed column in Y, if missing suppose that the observation
#' are evenly spaced
#'
#' @param prior specify the prior used in susif. Three choice are
#' available "normal", "mixture_normal", "mixture_normal_per_scale"
#'
#' @param verbose If \code{verbose = TRUE}, the algorithm's progress,
#' and a summary of the optimization settings, are printed to the
#' console.
#'
#' @param plot_out If \code{plot_out = TRUE}, the algorithm's progress,
#' and a summary of the optimization settings, are ploted.
#'
#' @param tol A small, non-negative number specifying the convergence
#' tolerance for the IBSS fitting procedure. The fitting procedure
#' will halt when the difference in the variational lower bound, or
#' \dQuote{ELBO} (the objective function to be maximized), is less
#' than \code{tol}.
#'
#' @param maxit Maximum number of IBSS iterations to perform.
#'
#' @param cov_lev numeric between 0 and 1, corresponding to the
#' expected level of coverage of the cs if not specified set to 0.95
#'
#'
#'
#' @examples
#' library(ashr)
#'rsnr <- 1#wished root signal noise ratio
#'N <- 200   #Number of individuals
#'P <- 20 # Number of covariates
#'pos1 <- 1#Position of the causal covariate
#'lev_res <- 6
#'temp_func <-  simu_IBSS_per_level(lev_res )
#'f1 <-  temp_func$sim_func
#'plot( f1, type ="l")
#'G = matrix(sample(c(0, 1,2), size=N*P, replace=TRUE), nrow=N, ncol=P) #Genotype
#'beta0       <- 0
#'beta1       <- 1
#'noisy.data  <- list()
#'for ( i in 1:N)
#'{
#'  f1_obs <- f1
#'  noise <- rnorm(length(f1), sd=  (1/  rsnr ) * var(f1))
#'  noisy.data [[i]] <-   beta1*G[i,pos1]*f1_obs+ beta1*G[i,4]*f1_obs  +  noise
#'
#'}
#'noisy.data <- do.call(rbind, noisy.data)
#'plot( noisy.data[1,], type = "l", col=(G[1, pos1]*3+1),
#'      main="Observed curves \n colored by the causal effect", ylim= c(-40,40), xlab="")
#'for ( i in 2:N)
#'{
#'  lines( noisy.data[i,], type = "l", col=(G[i, pos1]*3+1))
#'
#'}
#'legend(x=0.3,
#'       y=-10,
#'       lty = rep(1,3),
#'       legend= c("0", "1","2"),
#'       col=c("black","blue","yellow"))
#'
#'Y <- noisy.data
#'X <- G
#'
#'Y <- apply(Y, 2,scale)
#'X <- apply(X, 2,scale)
#'
#'W <- DWT2(Y)
#'update_D <- W
#'Y_f <- cbind( W$D,W$C) #Using a column like phenotype
#'
#'update_Y <- Y_f
#'v1       <- rep(1,nrow(Y_f) )
#'tt       <- cal_Bhat_Shat(Y_f,X,v1)
#'Bhat     <- tt$Bhat
#'Shat     <- tt$Shat
#'XtX   <- t(X)%*%X
#'Xty   <- t(X)%*%Y_f
#'yty   <- t(Y_f)%*%Y_f
#'var_y <- apply(Y_f, 2,var)
#'R     <- cor(X)
#'
#'out <- susiF_ss(Bhat, Shat, R, N , var_y, XtX, Xty, yty, L = 2, wav_trans=TRUE)
#'
#'
#' @export
#'
susiF_ss <- function(Bhat, Shat, R, N , var_y, XtX, Xty, yty,
                     L = 2,
                     wav_trans=FALSE,
                     pos = NULL,
                     prior = "mixture_normal_per_scale",
                     verbose = TRUE,
                     plot_out = TRUE,
                     maxit = 100,
                     tol = 1e-3,
                     cov_lev = 0.95

)
{
 # L = 2;  pos = NULL;  prior = "mixture_normal_per_scale";  verbose = TRUE;  plot_out = TRUE;  maxit = 100;  tol = 1e-6;  cov_lev = 0.95;wav_trans=TRUE
  if( prior %!in% c("normal", "mixture_normal", "mixture_normal_per_scale"))
  {
    stop("Error: provide valid prior input")
  }

  ## Input error messages

  if (is.null(pos))
  {
    pos <- 1:ncol(Xty)
  }


  #reshaping of the data
  if ( !(length(pos)==ncol(Xty))) #miss matching positions and number of observations
  {
    stop("Error: number of position provided different from the number of column of Y")
  }

  if (missing(N))
    stop("N must be provided")
  if (any(N <= 1))
    stop("N must be more than 1")

  # Check sufficient statistics.
  missing_Bhat = c(missing(Bhat), missing(Shat), missing(R))
  missing_XtX = c(missing(XtX), missing(Xty), missing(yty))


  if (all(missing_Bhat) & all(missing_XtX))
    stop("Please provide either all of bhat, Shat, R, N, var_y or all of ",
         "XtX, Xty, yty, N")
  if (any(missing_bhat) & any(missing_XtX))
    stop("Please provide either all of bhat, Shat, R, N, var_y or all of ",
         "XtX, Xty, yty, n")
  if (all(missing_Bhat) & any(missing_XtX))
    stop("Please provide all of XtX, Xty, yty, N")
  if (all(missing_XtX) & any(missing_Bhat))
    stop("Please provide all of Bhat, Shat, R, N, var_y")
  if ((!any(missing_XtX)) & (!all(missing_Bhat)))
    warning("Only using information from XtX, Xty, yty, N")
  if (!any(missing_Bhat)) {
    if (!all(missing_XtX))
      warning("Only using information from Bhat, Shat, R, N, var_y")

    # Compute XtX, Xty, yty from Bhat, Shat, R, N, var_y.
    if (length(Shat) == 1)
      Shat = rep(Shat,length(Bhat))
    if (length(Bhat) != length(Shat))
      stop("The length of Bhat does not agree with length of Shat")
    if (anyNA(Bhat) || anyNA(Shat))
      stop("The input summary statistics have missing values")
    if (any(Shat == 0))
      stop("Shat contains one or more zeros")

    that = bhat/shat
    that[is.na(that)] = 0
    R2 = that^2/(that^2 + N-2)
    sigma2 = (N-1)*(1-R2)/(N-2)


    if (missing(var_y)) {
      XtX = (n-1)*R
      Xty = sqrt(sigma2) * sqrt(n-1) * that
      var_y = 1
    } else {
      XtXdiag = var_y * sigma2/(shat^2)
      Xty = that * var_y * sigma2/shat
      XtX = R
      XtX = R * sqrt(XtXdiag)
      XtX = t(XtX)
      XtX = XtX * sqrt(XtXdiag)
      XtX = XtX + t(XtX)
      XtX = XtX/2
    }
    yty = var_y * (n-1)
  }


  #Check input XtX.
  if (ncol(XtX) != length(Xty))
    stop(paste0("The dimension of XtX (",nrow(XtX)," by ",ncol(XtX),
                ") does not agree with expected (",length(Xty)," by ",
                length(Xty),")"))
  if (!is_symmetric_matrix(XtX)) {
    message(red("XtX is not symmetric; forcing XtX to be symmetric by",
                "replacing XtX with (XtX + t(XtX))/2"))
    XtX = XtX + t(XtX)
    XtX = XtX/2
  }



  if(!is.wholenumber(log2(dim(Bhat)[2])) | !(sum( duplicated(diff( pos)))== (length(pos) -2)) ) #check wether dim(Y) not equal to 2^J or if the data are unevenly spaced
  {


    ### To be dealt with later -----
    inter_pol.obj <- interpol_mat(Y, pos)
    Y             <- inter_pol.obj$Y
    bp            <-  inter_pol.obj$bp
    outing_grid   <- inter_pol.obj$grid
    if(verbose)
    {
      message( "Response matrix dimensions not equal to nx 2^J \n or unevenly spaced data \n interpolation procedure used")
    }
  }  else{

    outing_grid <- 1:dim(Bhat)[2]
  }
  #W <- DWT2(Y) ###### perform transform (still under construction .....)

  ### Definition of some static parameters ---
  indx_lst <-  gen_wavelet_indx(log2(length( outing_grid)))

  original_data <- make_data_suff_stat(
    Bhat      = Bhat,
    Shat      = Shat,
    R         = R,
    N         = N,
    var_y     = var_y,
    XtX       = XtX,
    Xty       = Xty,
    yty       = yty,
    wav_trans = wav_trans
  )



  update_data <- original_data
  ### Definition of some dynamic parameters ---

   #Using a column like phenotype, temporary matrix that will be regularly updated
  G_prior        <-  init_prior( data     =  update_data ,
                                 prior    = prior,
                                 indx_lst = indx_lst )
  susiF_ss.obj   <-  init_susiF_ss_obj(L, G_prior, update_data )

  # numerical value to check breaking condition of while
  check <- 1
  h     <- 0


  #potentially usefull of one would like to provide "starting values"
  update_data <- cal_expected_residual(susiF_ss.obj,update_data)
  if(susiF_ss.obj$L==1)
  {



    update_data <- get_partial_residual(susiF_ss.obj,update_data,l=1)
    tt          <- cal_Bhat_Shat(susiF_ss.obj,update_data,partial=TRUE)
    Bhat        <- tt$Bhat
    Shat        <- tt$Shat #UPDATE. could be nicer
    tpi         <-  get_pi(susiF.obj,l)
    G_prior     <- update_prior(G_prior, tpi= tpi ) #allow EM to start close to previous solution (to double check)

    EM_out  <- EM_pi(G_prior  = G_prior,
                     Bhat     =  Bhat,
                     Shat     =  Shat,
                     indx_lst =  indx_lst
    )





    susiF_ss.obj <-  update_susiF_obj(susiF_ss.obj = susiF_ss.obj ,
                                      l         = l,
                                      EM_pi     = EM_out,
                                      Bhat      = Bhat,
                                      Shat      = Shat,
                                      indx_lst  = indx_lst
    )


  }else{
    while(check >tol & (h/L) <maxit)
    {


      for( l in 1:susiF_ss.obj$L)
      {
        update_data <- get_partial_residual(susiF_ss.obj,update_data,l=l)

        tt <- cal_Bhat_Shat(susiF_ss.obj,update_data,partial=TRUE)
        Bhat <- tt$Bhat
        Shat <- tt$Shat #UPDATE. could be nicer
        tpi <-  get_pi(susiF_ss.obj,l)
        G_prior <- update_prior(G_prior, tpi= tpi ) #allow EM to start close to previous solution (to double check)

        EM_out  <- EM_pi(G_prior  = G_prior,
                         Bhat     =  Bhat,
                         Shat     =  Shat,
                         indx_lst =  indx_lst
        )


        susiF_ss.obj <- update_susiF_obj(
                                          susiF_ss.obj = susiF_ss.obj,
                                          l            = l,
                                          EM_pi        = EM_out,
                                          Bhat         = Bhat,
                                          Shat         = Shat,
                                          indx_lst     = indx_lst
                                          )
        update_data  <- update_expected_residual(
                                                  susiF_ss.obj = susiF_ss.obj,
                                                  data         = update_data,
                                                  l            = l
                                                  )
      }#end for l in 1:L

      update_data  <- cal_expected_residual(susiF_ss.obj, update_data)


      if( h >2 )
      {
        susiF_ss.obj <- update_ELBO( susiF_ss.obj,
                                     get_objective(
                                                   susiF_ss.obj = susiF_ss.obj,
                                                   data         = original_data
                                                  )
                                    )
      }



       sigma2       <- estimate_residual_variance(susiF_ss.obj,data= update_data)
         susiF_ss.obj <- update_residual_variance(  susiF_ss.obj, sigma2 = sigma2 )


      if(length(susiF_ss.obj$ELBO)>1 )#update parameter convergence,
      {
        check <- diff(susiF_ss.obj$ELBO)[(length( susiF_ss.obj$ELBO )-1)]
      }
      h <-  h+1
    }#end while
  }#end if


  #preparing output
  susiF_ss.obj <- out_prep(susiF_ss.obj )
  return(susiF_ss.obj)
}

