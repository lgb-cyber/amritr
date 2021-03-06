% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/biomarkerPipeline.R
\name{biomarkerPipeline}
\alias{biomarkerPipeline}
\title{biomarkerPipeline}
\usage{
biomarkerPipeline(X = X, Y = Y, topranked = 50,
  validation = "Mfold", M = 5, iter = 1, threads = 1,
  progressBar = TRUE, pathways = pathways)
}
\arguments{
\item{X}{nxp matrix - training dataset}

\item{Y}{binary variable}

\item{topranked}{- top features ranked using p-value to build a classification panel}

\item{validation}{(Mfold/loocv)}

\item{M}{- # of folds}

\item{iter}{- Number of times to repeat cross-validation}

\item{threads}{- number of nodes (each CV runs on a separate node)}

\item{progressBar}{= (TRUE/FALSE)}

\item{pathways}{- list of data.frame containing pathway to genes mapping}
}
\description{
build various biomarker panels
}
