optimizeRNN <- function(tTree, gTree, gi, rData, outputPath) {
  rOptions <- rData$rOptions
  rOutput <- rData$rOutput
  rData <- list(rOptions=rOptions, rOutput=rOutput)
  x <- trainRNN(rData, outputPath)
  rOptions <- rData[["rOptions"]]
  rOptions$isOptimized <- TRUE
  rData[["rOptions"]] <- rOptions
  rData <- updateRNN(x, rData)
  rData
}

trainRNN <- function(rData, outputPath) {
  rOptions <- rData[["rOptions"]]
  rOutput <- rData[["rOutput"]]
  x <- getModel(rOptions)
  xLBd <- getModelLBd(rOptions)
  xUBd <- getModelUBd(rOptions)
  n <- length(x)
  iterFile <- paste(outputPath, rOptions$iterName, ".csv", sep="")
  
  if (file.exists(iterFile)) {
    file.remove(iterFile)
  }

  fn <- constructComputer(rData, iterFile, TRUE)
  fi <- constructComputer(rData, iterFile, FALSE)
  
  cores <- min(detectCores() - 1, n)
  cluster <- makeCluster(cores)
  clusterExport(cluster, c(ls(envir=.GlobalEnv), "dskellam"),
      envir=.GlobalEnv)
  gr <- function(x, n.=n, fn.=fn, e=1e-06, cluster.=cluster) {
      computeGradientPar(x, n, fi, e, cluster)
  }
  optimObj <- optim(x, fn, gr, method="L-BFGS-B",
      lower=xLBd, upper=xUBd, control=list(trace=3, lmm=rOptions$lmm,
      factr=rOptions$factr, REPORT=1))
  stopCluster(cluster)
  x <- readIter(iterFile)
  file.remove(iterFile)
  x
}

computeGradientPar <- function(x, n, f, e, cluster) {
  I <- c(1: n)
  g <- parSapply(cluster, I, function(i, f.=f, x.=x, e.=e) {
      xForDiff <- x
      xForDiff[i] <- xForDiff[i] + e
      xBackDiff <- x
      xBackDiff[i] <- xBackDiff[i] - e
      y <- (f(xForDiff) - f(xBackDiff)) / (2 * e)
      y})
  g
}
