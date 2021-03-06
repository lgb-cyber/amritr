#' Build ensemble sPLSDA classification panel
#'
#' takes in predited weights and true labels and determines performance characterisitcs
#' @param X.train - list of training datasets (nxpi); i number of elements
#' @param Y.train - n-vector of class labels
#' @param keepList = list of keepX
#' @param ncomp = Number of components
#' @param X.test - list of test datasets (nxpi); i number of elements
#' @param Y.test - n-vector of class labels
#' @export
ensemble.splsda = function(X.train, Y.train, keepXList, ncomp, X.test, Y.test, filter, topranked){
  if(is.null(X.test)){  ## run if no test set is provided (only build ensemble models)
    result <- mapply(function(X.train, keepX) {
      sPLSDA(X.train, Y.train, keepX, ncomp, X.test = NULL, Y.test = NULL,
        filter = filter, topranked = topranked)
    }, X.train = X.train, keepX = keepXList, SIMPLIFY = FALSE)
    Y.vote <- error <- NA
  } else { ## run if test set is provided
    if(length(X.train) == length(X.test)){   ## if the same numbers of train and test datasets are available
      result <- mapply(function(X.train, X.test, keepX) {
        sPLSDA(X.train, Y.train, keepX, ncomp, X.test = X.test, Y.test = Y.test,
          filter = filter, topranked = topranked)
      }, X.train = X.train, X.test = X.test, keepX = keepXList, SIMPLIFY = FALSE)
      predConcat <- lapply(result, function(i) {
        i$predictResponse
      }) %>% zip_nPure()

      Y.vote <- lapply(predConcat, function(i){
        apply(do.call(cbind, i), 1, function(z) {
          temp = table(z)
          if (length(names(temp)[temp == max(temp)]) > 1) {
            "zz"
          }
          else {
            names(temp)[temp == max(temp)]
          }
        })
      })

      error = do.call(rbind, lapply(Y.vote, function(i){
        temp <- table(pred = factor(i, levels = c(levels(Y.test), "zz")), truth = unlist(Y.test))
        diag(temp) <- 0
        error = c(colSums(temp)/summary(Y.test), sum(temp)/length(Y.test),
          mean(colSums(temp)/summary(Y.test)))
        names(error) <- c(names(error)[1:nlevels(Y.test)], "ER", "BER")
        error
      }))
    } else { ## if the different numbers of train and test datasets are available
      comDataset <- intersect(names(X.train), names(X.test))
      X.train <- X.train[comDataset]
      X.test <- X.test[comDataset]
      keepXList <- keepXList[comDataset]

      result <- mapply(function(X.train, X.test, keepX) {
        sPLSDA(X.train, Y.train, keepX, ncomp, X.test = NULL, Y.test = NULL,
          filter = filter, topranked = topranked)
      }, X.train = X.train, X.test = X.test, keepX = keepXList, SIMPLIFY = FALSE)
      predConcat <- lapply(result, function(i) {
        i$predictResponse
      }) %>% zip_nPure()

      Y.vote <- lapply(predConcat, function(i){
        apply(do.call(cbind, i), 1, function(z) {
          temp = table(z)
          if (length(names(temp)[temp == max(temp)]) > 1) {
            "zz"
          }
          else {
            names(temp)[temp == max(temp)]
          }
        })
      })

      error = do.call(rbind, lapply(Y.vote, function(i){
        temp <- table(pred = factor(i, levels = c(levels(Y.test), "zz")), truth = unlist(Y.test))
        diag(temp) <- 0
        error = c(colSums(temp)/summary(Y.test), sum(temp)/length(Y.test),
          mean(colSums(temp)/summary(Y.test)))
        names(error) <- c(names(error)[1:nlevels(Y.test)], "ER", "BER")
        error
      }))
    }
  }

  return(list(result = result, Y.vote = Y.vote, perfTest = error, X.train = X.train, Y.train = Y.train, keepXList = keepXList, filter = filter, topranked = topranked, ncomp = ncomp))
}

#' Estimate test error using repeated cross-validation
#'
#'
#' @param object - ensemble.splsda object
#' @param validation = Mfold or loo
#' @param M - # of folds
#' @param iter - Number of iterations of cross-validation
#' @param threads - # of cores, running each iteration on a separate node
#' @param progressBar = TRUE (show progress bar or not)
#' @export
perfEnsemble.splsda = function(object, validation = "Mfold", M = M, iter = iter, threads = threads,
  progressBar = TRUE){
  library(dplyr)
  X <- object$X.train
  Y = object$Y.train
  n = length(Y)
  keepXList = object$keepXList
  filter = object$filter
  topranked = object$topranked
  ncomp <- object$ncomp

  if (validation == "Mfold") {
    folds <- lapply(1:iter, function(i) createFolds(Y, k = M))
    require(parallel)
    cl <- parallel::makeCluster(mc <- getOption("cl.cores", threads))
    parallel::clusterExport(cl, varlist = c("ensemble.splsdaCV", "sPLSDA", "X", "Y",
      "keepXList", "ncomp", "M", "folds", "progressBar", "filter", "topranked"), envir = environment())
    cv <- parallel::parLapply(cl, folds, function(foldsi,
      X, Y, keepXList, ncomp, M, progressBar, filter, topranked) {
      library(dplyr); library(pROC); library(OptimalCutpoints); library(amritr)
      ensemble.splsdaCV(X = X, Y = Y, keepXList = keepXList, ncomp = ncomp,
        M = M, folds = foldsi, progressBar = progressBar, filter = filter, topranked = topranked)
    }, X, Y, keepXList, ncomp, M, progressBar, filter, topranked) %>% amritr::zip_nPure()
    parallel::stopCluster(cl)
    perf <- do.call(rbind, cv$error) %>% as.data.frame %>%
      mutate(Method = rownames(.)) %>%
      tidyr::gather(ErrName, Err, -Method) %>%
      dplyr::group_by(Method, ErrName) %>%
      dplyr::summarise(Mean = mean(Err), SD = sd(Err))
  } else {
    folds = split(1:n, rep(1:n, length = n))
    M = n
    cv <- ensemble.splsdaCV(X = X, Y = Y, keepXList = keepXList, ncomp = ncomp,
      M = M, folds = foldsi, progressBar = progressBar, filter = filter, topranked = topranked)
    perf <- cv$error %>% as.data.frame %>%
      mutate(Method = rownames(.)) %>%
      tidyr::gather(ErrName, Mean, -Method)
    perf$SD <- NA
  }
  result = list()
  result$perf = perf
  method = "splsdaEnsemble.mthd"
  result$meth = "splsdaEnsemble.mthd"
  class(result) = c("perf", method)
  return(invisible(result))
}

#' Estimate cross-validation error using cross-validation
#'
#'
#' @param X - list of training datasets (nxpi); i number of elements
#' @param Y - n-vector of class labels
#' @param keepXList = list of keepX
#' @param M - # of folds
#' @param folds - list of length M, where each element contains the indices for samples for a given fold
#' @param progressBar (TRUE/FALSE) - show progress bar or not
#' @param filter - "none" or "p.value"
#' @param topranked - # of significant features to use to build classifier
#' @export
ensemble.splsdaCV = function(X, Y, keepXList, ncomp, M, folds, progressBar, filter, topranked) {
  J <- length(X)
  assign("X.training", NULL, pos = 1)
  assign("Y.training", NULL, pos = 1)
  X.training = lapply(folds, function(x) {
    lapply(1:J, function(y) {
      X[[y]][-x, ]
    })
  })
  Y.training = lapply(folds, function(x) {
    Y[-x]
  })
  X.test = lapply(folds, function(x) {
    lapply(1:J, function(y) {
      X[[y]][x, , drop = FALSE]
    })
  })
  Y.test = lapply(folds, function(x) {
    Y[x]
  })
  predConcatList <- list()
  if (progressBar == TRUE)
    pb <- txtProgressBar(style = 3)
  for (i in 1:M) {
    if (progressBar == TRUE)
      setTxtProgressBar(pb, i/M)
    result <- mapply(function(X.train, X.test, keepX) {

      sPLSDA(X.train, Y.train = Y.training[[i]], keepX,
        ncomp, X.test = X.test,
        Y.test = Y.test[[i]], filter = filter, topranked = topranked)

    }, X.train = X.training[[i]], X.test = X.test[[i]], keepX = keepXList, SIMPLIFY = FALSE)

    predConcatList[[i]] <- lapply(result, function(i) {
      do.call(cbind, i$predictResponse)
    })

  }

  predConcat0 <- predConcatList %>% zip_nPure()
  predConcat <- lapply(predConcat0, function(i) do.call(rbind, i))

  predConcat <- lapply(1 : 3, function(i){
    do.call(cbind, lapply(predConcat, function(j){
      j[, i]
    }))
  })

  Y.vote <- lapply(predConcat, function(i) {
    apply(i, 1, function(z) {
      temp = table(z)
      if (length(names(temp)[temp == max(temp)]) >
          1) {
        "zz"
      }
      else {
        names(temp)[temp == max(temp)]
      }
    })
  })
  error = do.call(rbind, lapply(Y.vote, function(i) {
    temp <- table(pred = factor(i, levels = c(levels(Y),
      "zz")), truth = unlist(Y))
    diag(temp) <- 0
    error = c(colSums(temp)/summary(Y), sum(temp)/length(Y),
      mean(colSums(temp)/summary(Y)))
    names(error) <- c(names(error)[1:nlevels(Y)],
      "ER", "BER")
    error
  }))
  rownames(error) <- colnames(predConcat0[[1]][[1]])

  return(list(error = error))
}
