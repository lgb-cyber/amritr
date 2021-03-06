#' Random forest classification panel
#'
#' build random forest classification panel
#' @param X nxp matrix - training dataset
#' @param Y categorical variables
#' @param family "binomial" or "multinomial"
#' @param X.test nxp matrx  - test dataset
#' @param filter = "none" or "p.value"
#' @param topranked = 50 (top number of features to select and build a classifier)
#' @export
rforest = function (X, Y, X.test = NULL, Y.test = NULL, family = "binomial", filter = "p.value", topranked = 50)
{
  library(randomForest); library(limma); library(pROC); library(OptimalCutpoints);
  X1 <- X
  featIndex <- colnames(X1)
  names(featIndex) <- paste("f", 1:ncol(X1), sep = "_")
  colnames(X1) <- names(featIndex)
  if (filter == "none") {
    X1 <- X1
  }
  if (filter == "p.value") {
    design <- model.matrix(~Y)
    fit <- eBayes(lmFit(t(X1), design))
    top <- topTable(fit, coef = 2, adjust.method = "BH",
      n = nrow(fit))
    X1 <- X1[, rownames(top)[1:topranked]]
  }

  rf.panel <- as.character(featIndex[colnames(X1)])
  y.train0 <- Y[rownames(X1)]
  fit = randomForest(y.train0 ~ ., data = X1, importance = TRUE,
    proximity = TRUE)
  if (!is.null(X.test)) {
    colnames(X.test) <- paste("Feature", 1:ncol(X1), sep = ".")
    predictResponse <- predict(fit, as.matrix(X.test), type = "response")
    probs <- predict(fit, as.matrix(X.test), type = "vote")[, levels(Y)[2]]
    if(family == "binomial"){
      perfTest <- amritr::tperformance(weights = as.numeric(as.matrix(probs)),
        trueLabels = Y.test)
    }
    if(family == "multinomial"){
      mat <- table(Y.test, predictResponse)
      mat2 <- mat
      diag(mat2) <- 0
      classError <- colSums(mat2)/colSums(mat)
      er <- sum(mat2)/sum(mat)
      ber <- mean(classError)
      perfTest <- c(classError, er, ber)
      names(perfTest) <- c(names(classError), "ER", "BER")
    }
  }
  else {
    perfTest <- predictResponse <- NA
  }
  return(list(X = X, Y = Y, fit = fit, perfTest = perfTest, rf.panel = rf.panel,
    predictResponse = predictResponse, family = family, filter = filter, topranked = topranked))
}


#' cross-validation for a random forest panel
#'
#' Estimate test error of random forest panel
#' @param X nxp matrix - training dataset
#' @param Y categorical variables
#' @param M = # of folds
#' @param folds list of length M specifiying which samples are in which fold
#' @param family "binomial" or "multinomial"
#' @param filter = "none" or "p.value"
#' @param topranked = 50 (top number of features to select and build a classifier)
#' @export
rfCV = function(X, Y, M, folds, progressBar, family, filter, topranked)
{
  library(pROC); library(limma); library(randomForest); library(OptimalCutpoints)

  X1 <- X
  featIndex <- colnames(X1)
  names(featIndex) <- paste("f", 1:ncol(X1), sep = "_")
  colnames(X1) <- names(featIndex)

  probs <- predictResponseList <- rf.cvPanels <- list()
  if (progressBar == TRUE)
    pb <- txtProgressBar(style = 3)
  for (i in 1:M) {
    if (progressBar == TRUE)
      setTxtProgressBar(pb, i/M)
    omit = folds[[i]]
    X.train = X1[-omit, , drop = FALSE]
    Y.train = Y[-omit]

    if (filter == "none") {
      X.train1 <- X.train
    }
    if (filter == "p.value") {
      design <- model.matrix(~Y.train)
      fit <- eBayes(lmFit(t(X.train), design))
      top <- topTable(fit, coef = 2, adjust.method = "BH", n = nrow(fit))
      X.train1 <- X.train[, rownames(top)[1:topranked], drop = FALSE]
    }
    X.test1 = X1[omit, colnames(X.train1), drop = FALSE]

    rf.cvPanels[[i]] <- as.character(featIndex[colnames(X.train1)])
    rf.res = randomForest(Y.train ~ ., data = X.train1, importance = TRUE,  proximity = TRUE)
    probs[[i]] <- predict(rf.res, X.test1, type = "vote")[, levels(Y)[2]]
    predictResponseList[[i]] <- predict(rf.res, X.test1, type = "class")
  }
  predictResponse <- unlist(predictResponseList)
  probs <- unlist(probs)
  trueLabels = Y[unlist(folds)]

  if(family == "binomial"){
    perf <- amritr::tperformance(weights = probs, trueLabels = trueLabels)
  }
  if(family == "multinomial"){
    mat <- table(trueLabels, predictResponse)
    mat2 <- mat
    diag(mat2) <- 0
    classError <- colSums(mat2)/colSums(mat)
    er <- sum(mat2)/sum(mat)
    ber <- mean(classError)
    perf <- c(classError, er, ber)
    names(perf) <- c(names(classError), "ER", "BER")
  }
  return(list(probs = probs, trueLabels = trueLabels, perf = perf,
    predictResponse = predictResponse, rf.cvPanels = rf.cvPanels))
}


#' Cross-validation repeated iter number of times
#'
#' Estimate the mean+/-SD test error
#'
#' @param object = rforest object
#' @param validation = "Mfold" or "loo
#' @param M = # of folds
#' @param iter = number of times to repeat cross-validation
#' @param threads = number of cores to use (each cross-valiation scheme performed on a separate node)
#' @param show progress bar or not: progressBar (TRUE/FALSE)
#' @export
perf.rf = function (object, validation = c("Mfold", "loo"), M = 5, iter = 10,
  threads = 4, progressBar = TRUE)
{
  library(dplyr)
  X = object$X
  Y = object$Y
  n = nrow(X)
  filter = object$filter
  topranked = object$topranked
  family = object$family

  if (validation == "Mfold") {
    folds <- lapply(1:iter, function(i) createFolds(Y, k = M))
    require(parallel)
    cl <- parallel::makeCluster(mc <- getOption("cl.cores",
      threads))
    parallel::clusterExport(cl, varlist = c("rfCV", "rforest",
      "X", "Y", "M", "folds", "progressBar", "family", "filter", "topranked"), envir = environment())
    cv <- parallel::parLapply(cl, folds, function(foldsi,
      X, Y, M, progressBar, family, filter, topranked) {
      rfCV(X = X, Y = Y, M = M, folds = foldsi, progressBar = progressBar, family = family,
        filter = filter, topranked = topranked)
    }, X, Y, M, progressBar, family, filter, topranked) %>% amritr::zip_nPure()
    parallel::stopCluster(cl)
    perf <- do.call(rbind, cv$perf) %>% as.data.frame %>%
      gather(ErrName, Err) %>% dplyr::group_by(ErrName) %>%
      dplyr::summarise(Mean = mean(Err), SD = sd(Err))
  }
  else {
    folds = split(1:n, rep(1:n, length = n))
    M = n
    cv <- rfCV(X, Y, M, folds, progressBar, family, filter, topranked)
    perf <- data.frame(Mean = cv$perf) %>% mutate(ErrName = rownames(.))
    perf$SD <- NA
  }

  result = list()
  result$perf = perf
  result$probs = cv$probs
  result$panels = cv$rf.cvPanels
  method = "rf.mthd"
  result$meth = "rf.mthd"
  class(result) = c("perf", method)
  return(invisible(result))
}
