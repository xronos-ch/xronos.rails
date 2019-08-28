add_simple_cal <- function(imp) {
  
  simple_cal_list <- pbapply::pblapply(imp$calprobdistr, function(x) {
    if (nrow(x) == 0) {
      return(data.frame(bp = NA, std = NA))
    }
    middle <- which.min(abs(cumsum(x$density) - 0.5))
    res_sum <- 0
    i <- 1
    while (res_sum < 0.95) {
      start <- middle - i
      stop <- middle + i
      if (start <= 0) {
        start <- 1
      }
      if (stop > nrow(x)) {
        stop <- nrow(x)
      }
      res_sum <- sum(x$density[start:stop], na.rm = T)  
      i <- i + 1
    }
    return(data.frame(bp = x$calage[middle], std = i))
  })
  
  simple_cal <- do.call(rbind, simple_cal_list)
  
  imp %<>% dplyr::mutate(
    cal_bp = simple_cal$bp,
    cal_std = simple_cal$std
  )
  
  return(imp)
  
}
