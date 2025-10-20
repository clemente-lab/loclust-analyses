#!/usr/bin/env Rscript
# Check Step2Selection parameters and behavior

library(traj)

cat("Step2Selection function signature:\n")
print(args(Step2Selection))

cat("\n\nTrying to get more details:\n")
cat(capture.output(str(Step2Selection)), sep="\n")

cat("\n\nChecking if there's a help file:\n")
tryCatch({
  h <- help(Step2Selection)
  print(h)
}, error = function(e) {
  cat("No help available\n")
})

cat("\n\nLooking at function body (first 30 lines):\n")
body_lines <- capture.output(print(body(Step2Selection)))
cat(head(body_lines, 30), sep="\n")
