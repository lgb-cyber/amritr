% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/supportFunc_ensembleSvm.R
\name{ensembleSvmCV}
\alias{ensembleSvmCV}
\title{table of classification performances}
\usage{
ensembleSvmCV(X, Y, M, folds, progressBar)
}
\arguments{
\item{weights}{are the predicted scores/probablities of test data}

\item{trubeLabels}{are the true labels associated with the test data}

\item{direction}{= "auto", ">", "<"}
}
\description{
takes in predited weights and true labels and determines performance characterisitcs
}
