# Compute probability of win-tie-lose with softmax and model parameters
# rOptions.
computeLayerSoftmax <- function(game, rOptions, meanGoals) {
  homeMeanGoals <- meanGoals[1]
  awayMeanGoals <- meanGoals[2]
  strNorm <- game$strNorm 
  homeStr <- strNorm[1, ]
  awayStr <- strNorm[2, ]
  strAgg <- game$strAgg
  zs <- computeZs(rOptions, homeMeanGoals, awayMeanGoals,
      homeStr, awayStr, strAgg)
  gamePrediction <- computePredictionSoftmax(zs)
  pWinTieLose <- gamePrediction[["pWinTieLose"]]
  gamePrediction[["strNormBeta"]] <- game$strNormBeta
  gamePrediction[["strAgg"]] <- game$strAgg
  
  if (game$hasOutcome) {
    pOutcome <- pWinTieLose %*% as.numeric(game$outcome)
    gamePrediction[["p"]] <- pOutcome
  }
  
  gamePrediction
}

computeZs <- function(rOptions, homeMeanGoals, awayMeanGoals,
    homeStr, awayStr, strAgg) {
  z1 <- log(homeMeanGoals) +
      rOptions$strBeta * (homeStr[1] + awayStr[2])
  z2 <- rOptions$tieBias + rOptions$tieBeta * diff(strAgg) ^ 2
  z3 <- log(awayMeanGoals) +
      rOptions$strBeta * (awayStr[1] + homeStr[2])
  z <- c(z1, z2, z3)
  z
}

computePredictionSoftmax <- function(zs) {
  pWinTieLose <- exp(zs) / sum(exp(zs))
  gamePrediction <- list()
  gamePrediction[["pWinTieLose"]] <- pWinTieLose
  gamePrediction
}
