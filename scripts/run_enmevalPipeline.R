#!/usr/bin/env Rscript

# I first cropped the rasters in cropRasters.R
# That script will crop them to the sampling extent plus a buffer

# This script will run the ENMeval pipeline and save the output as an R object

library("ClineHelpR")

dataDIR <- "../clinehelpr_analysis/data/exampleData/ENMeval_bioclim"
plotDIR <- "../testplots"

envList <-
  prepare_rasters(
    raster.dir = file.path(dataDIR, "rasterLayers", "subset"),
    sample.file = file.path( dataDIR,
                            "localityInfo",
                            "sample_localities_maxent_southeast_noNA.csv"),
    header = TRUE,
    bb.buffer = 0.5,
    plotDIR = plotDIR
  )

bg <- partition_raster_bg(env.list = envList,
                          plotDIR = plotDIR, number.bg.points = 500,
                          showPLOTS = TRUE)

# Saved to file and reloaded because rJava ran out of memory
saveRDS(bg, file = file.path(dataDIR, "Robjects", "bg.rds"))
saveRDS(envList, file = file.path(dataDIR, "Robjects", "envList.rds"))

bg <- readRDS(file.path(dataDIR, "Robjects", "bg.rds"))

# Give rJava more memory. Otherwise it will throw an error.
# Here, I used 24GB of RAM.
# Adjust based on your system.
options(java.parameters = "-Xmx4g")

# Run ENMeval.
# Adjust parameters as needed.
# See ENMeval vignette
eval.par <- runENMeval(env.list = envList,
                       bg = bg,
                       parallel = TRUE,
                       categoricals = c("a_crop_nlcd2011_resampled"),
                       partition.method = "checkerboard1",
                       coords = coords,
                       np = 4)

# Save ENMeval results to R object file.
saveRDS(eval.par, file.path(dataDIR, "Robjects", "enm_eval_test.rds"))

# Adjust coordinate bounds as needed.
summarize_ENMeval(
  eval.par = eval.par,
  plotDIR = plotDIR,
  showPLOTS = TRUE,
  minLat = 25,
  maxLat = 45,
  minLon = -100,
  maxLon = -45,
  imp.margins = c(15.1, 4.1, 3.1, 2.1),
  examine.predictions=c("L", "LQ", "LQHP"))

# Use delta.AICc to find best model and plot response curves for it
# For this dataset it was features classes LQH and RM = 2.5
# Saves multiple plots to one PDF.
pdf(file = file.path(dataDIR,
                     "outputFiles",
                     "plots",
                     "ENMeval_responseCurves.pdf"),
    width=7,
    height=7,
    onefile=TRUE)

# Plot response curves.
dismo::response(eval.par@models[[28]])
dev.off()

# I want to save the best model so I can open it in QGIS
# Which was LQH feature classes with RM = 2.5
raster::writeRaster(eval.par@predictions@layers[[28]],
                    filename = file.path(dataDIR,
                                         "outputFiles",
                                         "plots",
                                         "LQH_2.5.tif"),
                    format = "GTiff",
                    device = "GTiff")

