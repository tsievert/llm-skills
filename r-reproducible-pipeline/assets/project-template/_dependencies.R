# Never run. renv scans this file so that packages used only at run time, which static
# scanning of _targets.R and R/ cannot see, still end up in renv.lock.
library(quarto) # tar_quarto() renders through the quarto R package
