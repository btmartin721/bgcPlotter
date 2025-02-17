#' Makes Phi ~ Hybrid Index Plots for Alpha and Beta
#'
#' This function generates the Phi ~ Hybrid Index genomic cline plot
#' shown in Gompert et al. (2012). Outlier genomic clines are colored black,
#' whereas non-outliers are gray. Phi is the Prob. Ancestry for P1.
#' 1-Phi = P(P0 ancestry). The plot can be printed to the plot
#' window in Rstudio (default) or saved to file by specifying a file prefix
#' with the saveToFile option.
#'
#' Calculates Phi and Plots Phi ~ Hybrid Index, Highlighting Outliers.
#' @param outlier.list List of data.frames returned from get_bgc_outliers().
#'                     see ?get_bgc_outliers for more info
#' @param popname Population name to use as the plot title
#' @param overlap.zero Boolean. If TRUE, outliers include when the credible
#'                     doesn't contain 0
#' @param qn.interval Boolean. If TRUE, outliers = outside quantile interval
#' @param both.outlier.tests If TRUE, outliers = both overlap.zero and
#'                           qn.interval
#' @param line.size Size of regression lines in plot. Default = 0.25
#' @param line.alpha Opacity of regression lines. Default = 0.5
#' @param saveToFile If specified, saves plots to file. The value
#'                   for saveToFile should be the prefix for the filename
#'                   you want to save to
#' @param plotDIR Directory path. If saveToFile is specified, plots are
#'                saved in this directory
#' @param showPLOTS Boolean Whether to print the plots to the screen
#' @param device File format to save plot. Supports ggplot2::ggsave devices
#' @param neutral.color Color for non-outlier loci. Default = "gray"
#' @param neutral.line.color Color for dashed linear line showing mean
#'                           Default = "black"
#' @param neutral.line.size Size for dashed linear line showing mean.
#'                          Default = 1.0
#' @param zero.line Boolean to include linear line for alpha=0 and beta=0.
#'                  Default = TRUE
#' @param zero.linetype Character string to set linetype for zero.line.
#'                      Default = "dashed"
#' @param alpha.color Color for alpha outlier loci. Default = "blue"
#' @param beta.color Color for beta outlier loci. Default = "red"
#' @param both.color Color for SNPs that are both alpha and beta outliers.
#'                   Default = "purple"
#' @param margins Vector of margins for phi plot: c(Top, Right, Bottom, Left)
#'                Top is extended to include the Hybrid Index histogram
#' @param margin.units Units for margins parameter. Default = "points"
#' @param phi.height Height for Phi plot. Default = 7
#' @param phi.width Width for Phi plot. Default = 7
#' @param phi.units Units for phi height and width. Default = "in"
#' @param phi.text.size Size for Phi plot text. Default = 18
#' @param phi.dpi DPI for saving Phi plot. Default = 300
#' @param hist.height Height of Hybrid Index histogram in Phi data coordinates
#'                    E.g., If you want the histogram to be equal to half the
#'                    height of the phi plot, set hist.height to 0.5
#' @param hist.width Height of Hybrid Index histogram in Phi data coordinates
#'                   E.g., If you want the histogram to be the same width
#'                   as the Phi plot, set this to 1.0
#' @param hist.x.origin X Origin (in Phi data coordinates) for Hybrid Index
#'                      histogram
#' @param hist.y.origin Y origin (in Phi data coordinates) for Hybrid Index
#'                      histogram. Set to just above the Phi plot by default
#' @param hist.color Color of Hybrid Index histogram
#' @param hist.fill Fill for Hybrid Index histogram
#' @param hist.axis.text.size Text size for histogram x-axis
#' @param hist.axis.title.size Title size for histogram x-axis
#' @param hist.binwidth Binwidth for Hybrid Index histogram
#' @export
#' @examples
#' phiPlot(outlier.list = outliers, saveToFile = "pop1_phiPlot",
#' plotDIR = "./bgc_plots", device = "png")
#'
#' phiPlot(outlier.list = gene.outliers, popname = "Mus musculus",
#' line.size = 0.1, qn.interval = FALSE, overlap.zero = FALSE,
#' both.outlier.tests = TRUE, saveToFile = "mus_phiPlot")
#'
#' phiPlot(outlier.list = full.outliers, popname = "G. gorilla",
#' overlap.zero = FALSE)
phiPlot <- function(outlier.list,
                    popname = "Population 1",
                    overlap.zero = TRUE,
                    qn.interval = TRUE,
                    both.outlier.tests = FALSE,
                    line.size = 0.25,
                    line.alpha = 0.5,
                    saveToFile = NULL,
                    plotDIR = "./plots",
                    showPLOTS = FALSE,
                    device = "pdf",
                    neutral.color = "gray",
                    neutral.line.color = "black",
                    neutral.line.size = 1.0,
                    zero.line = TRUE,
                    zero.linetype = "dashed",
                    alpha.color = "blue",
                    beta.color = "red",
                    both.color = "purple",
                    margins = c(150.0, 5.5, 5.5, 5.5),
                    margin.units = "points",
                    phi.height = 7,
                    phi.width = 7,
                    phi.units = "in",
                    phi.text.size = 18,
                    phi.dpi = 300,
                    hist.height = 1.5,
                    hist.width = 1.0,
                    hist.x.origin = 0.0,
                    hist.y.origin = 1.05,
                    hist.color = "gray57",
                    hist.fill = "gray57",
                    hist.axis.text.size = 12,
                    hist.axis.title.size = 12,
                    hist.binwidth = 0.1){

  # To use the dplyr pipe.
  `%>%` <- dplyr::`%>%`

  snps <- outlier.list[[1]] # SNPs data.frame
  hi <- outlier.list[[3]] # hybrid index data.frame

  rm(outlier.list)
  gc()

  # If only want crazy.a and crazy.b outliers
  if (both.outlier.tests){
    overlap.zero = FALSE
    qn.interval = FALSE
    writeLines("\n\nboth.outlier.tests is set.")
    writeLines("Ignoring overlap.zero qn.interval settings\n")
    snps$alpha.signif <-
      snps$crazy.a == TRUE

    snps$beta.signif <-
      snps$crazy.b == TRUE

    snps$both <- (snps$crazy.a == TRUE & snps$crazy.b == TRUE)
  }

  # TRUE if alpha/beta excess/outliers.
  if (overlap.zero & qn.interval){
      snps$alpha.signif <-
        (!is.na(snps$alpha.excess) | !is.na(snps$alpha.outlier))
      snps$beta.signif <-
        (!is.na(snps$beta.excess) | !is.na(snps$beta.outlier))
      snps$both <-
        ((!is.na(snps$alpha.excess) |
            !is.na(snps$alpha.outlier)) &
           (!is.na(snps$beta.excess) |
              !is.na(snps$beta.outlier)))

  } else if (overlap.zero & !qn.interval){
      snps$alpha.signif <- (!is.na(snps$alpha.excess))
      snps$beta.signif <- (!is.na(snps$beta.excess))
      snps$both <- (!is.na(snps$alpha.excess) & !is.na(snps$beta.excess))

  } else if (!overlap.zero & qn.interval){
      snps$alpha.signif <- (!is.na(snps$alpha.outlier))
      snps$beta.signif <- (!is.na(snps$beta.outlier))
      snps$both <- (!is.na(snps$alpha.outlier) & !is.na(snps$beta.outlier))

  } else if (!overlap.zero & !qn.interval & !both.outlier.tests){
    mywarning <-
      paste(
        "\n\noverlap.zero, qn.interval, and both.outlier.tests",
        "were all FALSE. Setting both.outlier.tests to TRUE\n\n"
      )
      warning(paste(strwrap(mywarning), collapse = "\n"))

      snps$alpha.signif <-
        snps$crazy.a == TRUE

      snps$beta.signif <-
        snps$crazy.b == TRUE

      snps$both <-
        (snps$crazy.a == TRUE & snps$crazy.b == TRUE)

  }

  isAlphaOutliers <- TRUE
  isBetaOutliers <- TRUE

  # If there aren't any alpha or beta outliers.
  if (all(snps$alpha.signif == FALSE)){
    isAlphaOutliers <- FALSE
    writeLines("\n\nWarning: No alpha outliers were identified.\n")
    if (both.outlier.tests){
      writeLines("\n\nTry setting both.outlier.tests to FALSE")
    }
  }

  if (all(snps$beta.signif == FALSE)){
    isBetaOutliers <- FALSE
    writeLines("\n\nWarning: No beta outliers were identified.\n\n")
    if (both.outlier.tests){
      writeLines("\n\nTry setting both.outlier.tests to FALSE")
    }
  }

  hilist <- list()

  # TRUE if alpha/beta excess or outlier.
  for (i in 1:nrow(snps)){
    hilist[[i]] <- get_phi_ih(hi, snps$alpha[[i]], snps$beta[[i]])
    hilist[[i]]$alpha <- snps[i,"alpha.signif"]
    hilist[[i]]$beta <- snps[i, "beta.signif"]
    hilist[[i]]$both <- snps[i, "both"]
  }

  rm(snps, hi)
  gc()

  # Scale phi from 0 to 1.
  for (i in 1:length(hilist)){
    hilist[[i]]$phi01 <- range01(hilist[[i]]$phi)
  }

  gc()

  # Reorder by hybrid index.
  hilist <- lapply(hilist, function(i) i[order(i$hi),])

  # Initialize.
  atMin <- FALSE
  atMax <- FALSE

  # Gets rid of values that loop back around.
  # Per Gompert and Buerkle (2011). Bayesian Estimation of Genomic
  # Clines. Molecular Ecology.
  for (i in 1:length(hilist)){
    for (j in 1:nrow(hilist[[i]])){
      if (hilist[[i]][j, 7] > 0.0 &
          atMin == FALSE &
          atMax == FALSE){
            hilist[[i]][j, 7] <- 0.0
            next
      }

      if (hilist[[i]][j, 7] == min(hilist[[i]]$phi01) &
          atMin == FALSE &
          atMax == FALSE){
            atMin = TRUE
            hilist[[i]][j, 7] <- 0.0
            next
      }

      if (hilist[[i]][j, 7] < max(hilist[[i]]$phi01) &
          atMin == TRUE &
          atMax == FALSE){
            hilist[[i]][j, 7] <- hilist[[i]][j, 7]
            next
      }

      if (atMax == FALSE &
          atMin == TRUE &
          hilist[[i]][j, 7] == max(hilist[[i]]$phi01)){
        atMax = TRUE
        hilist[[i]][j, 7] <- max(hilist[[i]]$phi01)
        next
      }

      if (atMax == TRUE & atMin == TRUE){
        hilist[[i]][j, 7] <- max(hilist[[i]]$phi01)
        next
      }
    }
    atMin <- FALSE
    atMax <- FALSE
  }
  gc()

  # Make into long format for plotting both alpha and beta on one plot.
  hi.final <-
    reshape2::melt(data = hilist,
                               id.vars = c("hi", "phi01", "id", "phi"))

  rm(hilist)
  gc()

  # Concatenate value (TRUE or FALSE), variable (alpha or beta), and L1
  # (locus number). Used for grouping in ggplot. Otherwise the clines would
  # be averaged into one line.
  hi.final$trues <- as.factor(apply(format(hi.final[,c("value", "variable", "L1")]),
                                     1, paste, collapse = " "))

  hi.final$varVal <- as.factor(apply(format(hi.final[,c("variable", "value")]),
                                    1, paste, collapse = ""))

  # Order factor levels so that outliers get plotted on top.
  # Want to plot FALSE values first, then TRUE on top.
  hi.final$levels <-
    factor(
      hi.final$varVal,
      levels = c(
        "bothFALSE",
        "alphaFALSE",
        "betaFALSE",
        "alpha TRUE",
        "beta TRUE",
        "both TRUE"
      )
    )

  # Order trues factor levels by levels column.
  hi.final$trues2 <-
    factor(hi.final$trues,
           levels = unique(hi.final$trues[order(hi.final$levels)]),
           ordered = TRUE)

  ### Combined alpha and beta plot.
  phi.plot <- ggplot2::ggplot(hi.final) +
    ggplot2::geom_smooth(
      ggplot2::aes(hi,
                   phi01,
                   colour = levels,
                   group = trues2),
      method = "lm",
      formula = y ~ poly(x, 5),
      se = FALSE,
      size = line.size, 
      alpha = line.alpha
    ) +
    ggplot2::xlab(label = "Hybrid Index") +
    ggplot2::ylab(label = expression("Prob. P1 Ancestry (" * Phi * ")")) +
    ggplot2::theme_bw() +
    ggplot2::theme(
      panel.border = ggplot2::element_blank(),
      panel.grid.major = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      axis.line = ggplot2::element_line(colour = "black"),
      axis.text = ggplot2::element_text(size = phi.text.size,
                                        colour = "black"),
      text = ggplot2::element_text(size = phi.text.size,
                                   colour = "black"),
      axis.ticks = ggplot2::element_line(size = ggplot2::rel(1.5)),
      plot.margin = ggplot2::unit(margins,
                                  margin.units)
    ) +
    ggplot2::scale_y_continuous(limits = c(0, 1),
                                oob = scales::squish) +
    ggplot2::scale_x_continuous(limits = c(0, 1)) +
    ggplot2::scale_colour_manual(
      name = "Loci",
      values = c(neutral.color, neutral.color, neutral.color, alpha.color, beta.color, both.color),
      labels = c(
        "Neutral (Alpha)",
        "Neutral (Beta)",
        "Neutral (Both)",
        "Alpha Outliers",
        "Beta Outliers",
        "Both Outliers"
      )
    ) +
    ggplot2::ggtitle(label = paste0(popname, " Phi Plot"))

  if (zero.line == TRUE) {
    phi.plot <-
      phi.plot + ggplot2::geom_smooth(
        ggplot2::aes(hi, phi01),
        hi.final,
        formula = y ~ x,
        method = "lm",
        se = FALSE,
        size = neutral.line.size,
        color = neutral.line.color,
        linetype = zero.linetype
      )
  }


  # Make histogram plot of Hybrid Indices
  hg <- ggplot2::ggplot(hi.final, ggplot2::aes(x=hi)) +
    ggplot2::geom_histogram(binwidth = hist.binwidth,
                            colour = hist.color,
                            fill = hist.fill) +
    ggplot2::theme_bw() +
    ggplot2::theme(axis.line.y = ggplot2::element_blank(),
                   axis.line.x = ggplot2::element_line(colour = "black",
                                                       size = 0.2),
                   axis.text.y=ggplot2::element_blank(),
                   axis.text.x=ggplot2::element_text(colour="black",
                                                     size=hist.axis.text.size),
                   axis.ticks = ggplot2::element_blank(),
                   axis.title.y = ggplot2::element_blank(),
                   axis.title.x=ggplot2::element_text(colour="black",
                                                      size=hist.axis.title.size),
                   panel.border = ggplot2::element_blank(),
                   panel.grid.major = ggplot2::element_blank(),
                   panel.grid.minor = ggplot2::element_blank()) +
    ggplot2::scale_x_continuous(name = "Hybrid Index",
                                breaks = c(0.0, 0.5, 1.0),
                                expand = c(0, 0)) +
    ggplot2::coord_cartesian(xlim = c(0.0, 1.0))

  rm(hi.final)
  gc()

  phi.plot <- phi.plot +
    ggplot2::annotation_custom(
      ggplot2::ggplotGrob(hg),
      xmin = hist.x.origin,
      xmax = hist.width,
      ymin = hist.y.origin,
      ymax = hist.height
    )

  if (!is.null(saveToFile)){
    # If saveToFile is specified, save plot as PDF.
    # Create plotDIR if doesn't already exist.
    dir.create(plotDIR, showWarnings = FALSE)

    ggplot2::ggsave(
      filename = paste0(saveToFile, "_hiXphi_alphaAndBeta.pdf"),
      plot = phi.plot,
      device = device,
      plotDIR,
      width = phi.width,
      height = phi.height,
      dpi = phi.dpi,
      units = phi.units
    )

  }

  if (isTRUE(showPLOTS)){
      # If showPLOTS is TRUE.
      print(phi.plot)
  }

  gc()
}

#' Scale atomic vector from 0 to 1.
#' @param x Atomic vector
#' @return Atomic vector scaled 0 to 1
#' @noRd
range01 <- function(x){(x-min(x))/(max(x)-min(x))}

#' Get Phi for locus i. Must be within for loop 1:Nloci
#' @param h data.frame with Hybrid Indices for all admixed individuals
#' @param a Alpha value at locus i
#' @param b Beta value at locus i
#' @return data.frame h with new phi column
#' @noRd
get_phi_ih <- function(h, a, b){
  h$phi <- h$hi + (2 * (h$hi - h$hi**2)) * (a + (b * (2*h$hi - 1)))
  return(h)
}
