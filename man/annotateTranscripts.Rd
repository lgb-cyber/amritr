% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/functions.R
\name{annotateTranscripts}
\alias{annotateTranscripts}
\title{table of classification performances}
\usage{
annotateTranscripts(features, filter, mart)
}
\arguments{
\item{weights}{are the predicted scores/probablities of test data}

\item{trubeLabels}{are the true labels associated with the test data}

\item{direction}{= "auto", ">", "<"}
}
\description{
takes in predited weights and true labels and determines performance characterisitcs
}
