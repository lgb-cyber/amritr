% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/supportFunc_splsda.R
\name{tuned.sPLSDA}
\alias{tuned.sPLSDA}
\title{sPLSDA model after tuning of the number of variables}
\usage{
tuned.sPLSDA(X.train, Y.train, keepXgrid, ncomp, X.test = X.test,
  Y.test = Y.test, filter = filter, topranked = topranked,
  validation = validation, M = M, iter = iter, threads = threads,
  progressBar = progressBar, optimal = optimal,
  errorMethod = errorMethod)
}
\arguments{
\item{keepXgrid}{sequence of integers (# of variables to select per component)}

\item{ncomp}{number of components}

\item{M}{Number of folds in the cross-validation}

\item{X}{nxp dataset}

\item{Y}{vector of phenotype labels with names(Y) == rownames(X)}

\item{validatoin}{"Mfold" or "loo"}
}
\description{
takes in predited weights and true labels and determines performance characterisitcs
}
