% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/supportFunc_lm.R
\name{lme_interactionBinaryCont}
\alias{lme_interactionBinaryCont}
\title{table of classification performances}
\usage{
lme_interactionBinaryCont(x, y, binary, replicates, xlab, ylab, main,
  lim = NULL)
}
\arguments{
\item{weights}{are the predicted scores/probablities of test data}

\item{trubeLabels}{are the true labels associated with the test data}

\item{direction}{= "auto", ">", "<"}
}
\description{
takes in predited weights and true labels and determines performance characterisitcs
}
