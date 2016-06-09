% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/supportFunc_lm.R
\name{descriptiveStat}
\alias{descriptiveStat}
\title{table of classification performances}
\usage{
descriptiveStat(demo, groups, variables, paired = FALSE, pairing = NULL)
}
\arguments{
\item{weights}{are the predicted scores/probablities of test data}

\item{trubeLabels}{are the true labels associated with the test data}

\item{direction}{= "auto", ">", "<"}
}
\description{
takes in predited weights and true labels and determines performance characterisitcs
}
