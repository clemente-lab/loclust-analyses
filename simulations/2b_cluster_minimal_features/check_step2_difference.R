#!/usr/bin/env Rscript
# Check what Step2Selection does and its parameters

library(traj)

cat("Step2Selection function signature:\n")
cat(capture.output(args(Step2Selection)), sep="\n")

cat("\n\nStep2Selection help:\n")
help_text <- capture.output(help(Step2Selection))
if (length(help_text) > 0) {
  cat(help_text, sep="\n")
} else {
  cat("No help available via capture.output, checking function structure...\n")
  cat(capture.output(str(Step2Selection)), sep="\n")
}
