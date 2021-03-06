#' customeTheme fucntion for ggplot
#'
#' takes in predited weights and true labels and determines performance characterisitcs
#' @param sizeStripFont font of size of facet labels
#' @param xAngle angle of x-axis labels
#' @param hjust horizontal justification 0-left, 0.5-center, 1-right
#' @param vjust vertical justification 0-low, 0.5-middle, 1-high
#' @param xSize font size of x-axis label
#' @param ySize font size of y-axis label
#' @param xAxisSize font size of x-axis label title
#' @param yAxisSize fotn size of y-axis label title
#' @export
customTheme = function(sizeStripFont, xAngle, hjust, vjust, xSize,
    ySize, xAxisSize, yAxisSize) {
    theme(strip.background = element_rect(colour = "black", fill = "white",
        size = 1), strip.text.x = element_text(size = sizeStripFont),
        strip.text.y = element_text(size = sizeStripFont), axis.text.x = element_text(angle = xAngle,
            hjust = hjust, vjust = vjust, size = xSize, color = "black"),
        axis.text.y = element_text(size = ySize, color = "black"),
        axis.title.x = element_text(size = xAxisSize, color = "black"),
        axis.title.y = element_text(size = yAxisSize, color = "black"),
        panel.background = element_rect(fill = "white", color = "black"))
}



#' table of classification performances
#'
#' takes in predited weights and true labels and determines performance characterisitcs
#' @param weights are the predicted scores/probablities of test data
#' @param trubeLabels are the true labels associated with the test data
#' @param direction = "auto", ">", "<"
#' @export
normalizelibSum = function(genExp) {
    lib.size <- colSums(genExp)
    genExpNorm <- t(log2(t(genExp + 0.5)/(lib.size + 1) * 1e+06))
    return(genExpNorm)
}

#' table of classification performances
#'
#' takes in predited weights and true labels and determines performance characterisitcs
#' @param weights are the predicted scores/probablities of test data
#' @param trubeLabels are the true labels associated with the test data
#' @param direction = "auto", ">", "<"
#' @export
plotSampleHist = function(data = data, main = NULL, xlim = NULL,
    ylim = NULL) {
    for (i in 1:ncol(data)) {
        idx <- data[, i] > -1
        shist(data[idx, i], unit = 0.25, col = i, plotHist = FALSE,
            add = i != 1, main = main, ylim = ylim, xlim = xlim,
            xlab = expression("log"[2] ~ "cpm"))
    }
}


#' table of classification performances
#'
#' takes in predited weights and true labels and determines performance characterisitcs
#' @param weights are the predicted scores/probablities of test data
#' @param trubeLabels are the true labels associated with the test data
#' @param direction = "auto", ">", "<"
#' @export
annotateTranscripts = function(features, filter, mart) {
    attr = c("description", "ucsc", "chromosome_name", "strand",
        "hgnc_symbol", "refseq_mrna")
    if (filter %in% c("ucsc", "trinity")) {
        features = features
    }
    if (filter == "ensembl_gene_id") {
        features <- unlist(lapply(strsplit(features, "\\."),
            function(i) i[1]))
    }

    gene <- rep(NA, length(features))
    if (filter %in% c("ucsc", "ensembl_gene_id")) {
        hk.known <- getBM(attributes = attr, filters = filter,
            values = features, mart = mart)$hgnc_symbol
        gene <- unique(hk.known)
    } else {
        trinityMapFile <- read.delim("/Users/asingh/Documents/Asthma/biomarkerPanels/data/discovery/rnaseq/asthma.trinity.blastx.outfmt6.txt")
        trinityMapFile$Contig <- unlist(lapply(strsplit(as.character(trinityMapFile$query_id),
            "_"), function(i) paste(i[1], i[2], sep = "_")))
        trinityMapFile$UniProt <- unlist(lapply(strsplit(unlist(lapply(strsplit(as.character(trinityMapFile$subject_id),
            "\\|"), function(i) i[[2]])), split = "_"), function(x) x[1]))
        trinityMapFile$GenSym <- unlist(lapply(strsplit(unlist(lapply(strsplit(as.character(trinityMapFile$subject_id),
            "\\|"), function(i) i[[3]])), split = "_"), function(x) x[1]))
        gene <- trinityMapFile$GenSym[trinityMapFile$query_id %in%
            features]
    }
    gene
}


#' table of classification performances
#'
#' takes in predited weights and true labels and determines performance characterisitcs
#' @param weights are the predicted scores/probablities of test data
#' @param trubeLabels are the true labels associated with the test data
#' @param direction = "auto", ">", "<"
#' @export
multiplot <- function(..., plotlist = NULL, file, cols = 1, layout = NULL) {
    library(grid)

    # Make a list from the ... arguments and plotlist
    plots <- c(list(...), plotlist)

    numPlots = length(plots)

    # If layout is NULL, then use 'cols' to determine layout
    if (is.null(layout)) {
        # Make the panel ncol: Number of columns of plots nrow:
        # Number of rows needed, calculated from # of cols
        layout <- matrix(seq(1, cols * ceiling(numPlots/cols)),
            ncol = cols, nrow = ceiling(numPlots/cols))
    }

    if (numPlots == 1) {
        print(plots[[1]])

    } else {
        # Set up the page
        grid.newpage()
        pushViewport(viewport(layout = grid.layout(nrow(layout),
            ncol(layout))))

        # Make each plot, in the correct location
        for (i in 1:numPlots) {
            # Get the i,j matrix positions of the regions that contain
            # this subplot
            matchidx <- as.data.frame(which(layout == i, arr.ind = TRUE))

            print(plots[[i]], vp = viewport(layout.pos.row = matchidx$row,
                layout.pos.col = matchidx$col))
        }
    }
}

#' table of classification performances
#'
#' takes in predited weights and true labels and determines performance characterisitcs
#' @param weights are the predicted scores/probablities of test data
#' @param trubeLabels are the true labels associated with the test data
#' @param direction = "auto", ">", "<"
#' @export
zip_nPure = function(.x, .fields = NULL, .simplify = FALSE) {
    if (length(.x) == 0)
        return(list())
    if (is.null(.fields)) {
        if (is.null(names(.x[[1]]))) {
            .fields <- seq_along(.x[[1]])
        } else {
            .fields <- stats::setNames(names(.x[[1]]), names(.x[[1]]))
        }
    } else {
        if (is.character(.fields) && is.null(names(.fields))) {
            names(.fields) <- .fields
        }
    }
    out <- lapply(.fields, function(i) lapply(.x, .subset2, i))
    if (.simplify)
        out <- lapply(out, simplify_if_possible)
    out
}
