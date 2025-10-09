#!/usr/bin/Rscript

# For arguments
library(data.table)
library(optparse)
library(ggplot2)
library(hash)

removeNans <- function(listy) {
    new_list <- list()
    for (i in 1:length(listy)) {
        if (is.nan(listy[[i]])) {
            if (i == 0) {
                new_list[[i]] <- 1
            } else {
                new_list[[i]] <- 0
            }
        } else {
            new_list[[i]] <- listy[[i]]
        }
    }
    nl <- as.vector(new_list, "character")
    return (nl)
}

# Reads in the cluster measure scores
loadData <- function(file, scores=FALSE, num_traj=NULL, num_dtw=NULL) {
    con <- file(file, 'r')
    if (scores) {
        noise.counter <- 0
        cluster <- NULL
        dbscan <- NULL
        traj <- list()
        dtw <- list()
        allscores <- list()
        while (TRUE) {
            line = readLines(con, n = 1)
            if ( length(line) == 0 )
                break
            split.string <- strsplit(line, '\t')
            # If it's a new header update noise.counter
            if ( 'NVI' %in% split.string[[1]]) {
                noise.counter <- noise.counter + 1
                score.strings <- split.string[2:length(split.string)]
                scores <- list(cluster = cluster, dbscan = dbscan, traj = traj, dtw = dtw)
                class(scores) <- paste("Noise level", noise.counter)
                allscores[[length(allscores) + 1]] <- scores
            }
            else {
                split.string.sub <- strsplit(split.string[[1]][1], '-')

                # Suppress warnings about NAs being introduced
                suppressWarnings(hold.scores <- list(NVI = as.numeric(split.string[[1]][2]),
                                                     F_Measure = as.numeric(split.string[[1]][3]),
                                                     V_Measure = as.numeric(split.string[[1]][4]),
                                                     Rand_Index = as.numeric(split.string[[1]][5])))
                class(hold.scores) <- "Clustering Measures"
                hold.length <- length(hold.scores)

                if ("cluster" %in% split.string[[1]])
                    cluster <- hold.scores
                else if ( "dbscan" %in% split.string[[1]])
                    dbscan <- hold.scores
                else if ('traj' %in% split.string.sub[[1]])
                    traj[[as.numeric(split.string.sub[[1]][1]) - 1]] <- hold.scores
                else if ('dtw' %in% split.string.sub[[1]])
                    dtw[[as.numeric(split.string.sub[[1]][1]) - 1]] <- hold.scores
            }
        }
        scores <- list(cluster = cluster, dbscan = dbscan, traj = traj, dtw = dtw)
        class(scores) <- paste("Noise level", noise.counter)
        allscores[[length(allscores) + 1]] <- scores
        close(con)
        return (allscores[2:length(allscores)])
    }
    else {
        print(paste("Reading in clustering from", file))
        keys <- list()
        clusterings <- hash()
        dtw_index <- 0
        traj_index <- 0
        # Read each line
        while (TRUE) {
            line = readLines(con, n = 1)
            if ( length(line) == 0 )
                break
            split.string <- strsplit(line, '\t')
            if ('cluster' %in% split.string[[1]]) {
                count <- 0
                poten_keys <- split.string[[1]][2:length(split.string[[1]])]
                for (key in poten_keys){
                    skey = strsplit(key, '-')[[1]]
                    if ("traj" %in% skey){
                        if (as.character(num_traj) %in% skey){
                            keys[length(keys) + 1] <- key
                            traj_index <- count
                        }
                    }
                    else if ('dtw' %in% skey){
                        if (as.character(num_dtw) %in% skey){
                            keys[length(keys) + 1] <- key
                            dtw_index <- count
                        }
                    }
                    else {
                        keys[length(keys) + 1] <- key
                    }
                    count <- count + 1
                }
            }
            else {
                func <- split.string[[1]][1]
                results <- c(split.string[[1]][2],
                             split.string[[1]][3],
                             split.string[[1]][4],
                             split.string[[1]][traj_index],
                             split.string[[1]][dtw_index])
                results <- removeNans(sapply(results, as.numeric))
                map <- hash(keys, results)


                if (!(func %in% keys(clusterings)))
                    clusterings[[func]] <- list()
                clusterings[[func]][[length(clusterings[[func]]) + 1]] <- map
            }
        }
        close(con)
        return (clusterings)
    }
}

# Evaluate the scores for each of the numbers of clusterings
evaluate.scores <- function(scores, NVI_Flag=FALSE) {
    evals <- rep(0, length(scores))
    if (NVI_Flag) {
        vals <- mapply('-', rep(1, length(scores)), scores)
        vals <- sapply(vals, abs)
        index <- which.min(vals)
        evals[index] = 1
    } else {
        index <- which.max(scores)
        evals[index] = 1
    }
    return (evals)
}

# Determines the number of clusters to use for the graph
# based on the number that gives the highest average score
find.num.clusts <- function(data, method) {
    len <- length(data[[1]]$traj)
    avg.NVI <- rep(0, len)
    avg.F_Measure <- rep(0, len)
    avg.V_Measure <- rep(0, len)
    avg.Rand_Index <- rep(0, len)
    if ('traj' %in% method) {
        for (i in c(1:length(data))) {
            for (j in c(1:len)) {
                avg.NVI[j] <- avg.NVI[j] + data[[i]]$traj[[j]]$NVI
                avg.F_Measure[j] <- avg.F_Measure[j] + data[[i]]$traj[[j]]$F_Measure
                avg.V_Measure[j] <- avg.V_Measure[j] + data[[i]]$traj[[j]]$V_Measure
                avg.Rand_Index[j] <- avg.Rand_Index[j] + data[[i]]$traj[[j]]$Rand_Index
            }
        }
        evals <- rep(0, length(data[[1]]$traj))
    }
    else if ('dtw' %in% method) {
        for (i in c(1:length(data))) {
            for (j in c(1:len)) {
                avg.NVI[j] <- avg.NVI[j] + data[[i]]$dtw[[j]]$NVI
                avg.F_Measure[j] <- avg.F_Measure[j] + data[[i]]$dtw[[j]]$F_Measure
                avg.V_Measure[j] <- avg.V_Measure[j] + data[[i]]$dtw[[j]]$V_Measure
                avg.Rand_Index[j] <- avg.Rand_Index[j] + data[[i]]$dtw[[j]]$Rand_Index
            }
        }
        evals <- rep(0, length(data[[1]]$dtw))
    }
    flag = FALSE
    for (i in list(avg.NVI, avg.F_Measure, avg.V_Measure, avg.Rand_Index)){
        vals <- mapply("/", i, len - 1)
        if (! flag){
            evals <- mapply("+", evals, evaluate.scores(vals, TRUE))
            flag = TRUE
        } else {
            evals <- mapply("+", evals, evaluate.scores(vals))
        }
    }
    return (which.max(evals))
}

# Translates the scores from four individual scores into a single value
sum.scores <- function(data) {
    if (is.na(data$NVI)){
        NVI <- 0
    } else {
        if (1 < data$NVI) {
            NVI <- -1
        }
        else {
            NVI <- -1 * data$NVI
        }
    }
    # Translate the NVI score
    val <- (sum(c(NVI, data$F_Measure, data$V_Measure, data$Rand_Index)))
    return (val)
}

# Parses the scores into a data.frame
parse.scores <- function(data, scoring='all', parse.method="auto") {
    # Select the number of clusters that give the
    # highest average scores across all noise levels
    if ('auto' %in% c(parse.method)) {
        clusts.traj <- find.num.clusts(data, 'traj')
        clusts.dtw <- find.num.clusts(data, 'dtw')
    }
    clusterData <- rep(0, length(data))
    dbscanData <- rep(0, length(data))
    trajData <- rep(0, length(data))
    dtwData <- rep(0, length(data))

    if ('all' %in% scoring) {
        for (i in 1:length(data)){
            # Create the cluster Data
            clusterData[i] <- sum.scores(data[[i]]$cluster)
            dbscanData[i] <- sum.scores(data[[i]]$dbscan)
            trajData[i] <- sum.scores(data[[i]]$traj[[clusts.traj]])
            dtwData[i] <- sum.scores(data[[i]]$dtw[[clusts.dtw]])
        }
    }
    else if ('NVI' %in% scoring){
        for (i in 1:length(data)){
            # Create the cluster Data
            clusterData[i] <- data[[i]]$cluster$NVI
            dbscanData[i] <- data[[i]]$dbscan$NVI
            trajData[i] <- data[[i]]$traj[[clusts.traj]]$NVI
            dtwData[i] <- data[[i]]$dtw[[clusts.dtw]]$NVI
        }
    }
    else if ('F_Measure' %in% scoring){
        for (i in 1:length(data)){
            # Create the cluster Data
            clusterData[i] <- data[[i]]$cluster$F_Measure
            dbscanData[i] <- data[[i]]$dbscan$F_Measure
            trajData[i] <- data[[i]]$traj[[clusts.traj]]$F_Measure
            dtwData[i] <- data[[i]]$dtw[[clusts.dtw]]$F_Measure
        }
    }
    else if ('V_Measure' %in% scoring){
        for (i in 1:length(data)){
            # Create the cluster Data
            clusterData[i] <- data[[i]]$cluster$V_Measure
            dbscanData[i] <- data[[i]]$dbscan$V_Measure
            trajData[i] <- data[[i]]$traj[[clusts.traj]]$V_Measure
            dtwData[i] <- data[[i]]$dtw[[clusts.dtw]]$V_Measure
        }
    }
    else if ('Rand_Index' %in% scoring){
        for (i in 1:length(data)){
            # Create the cluster Data
            clusterData[i] <- data[[i]]$cluster$Rand_Index
            dbscanData[i] <- data[[i]]$dbscan$Rand_Index
            trajData[i] <- data[[i]]$traj[[clusts.traj]]$Rand_Index
            dtwData[i] <- data[[i]]$dtw[[clusts.dtw]]$Rand_Index
        }
    }
    clusterData <- clusterData[1:length(clusterData)]
    dbscanData <- dbscanData[1:length(dbscanData)]
    trajData <- trajData[1:length(trajData)]
    dtwData <- dtwData[1:length(dtwData)]

    frame <- data.frame(clusterData, dbscanData, trajData, dtwData)
    return (list(frame, clusts.traj, clusts.dtw))
}

print.hash <- function(hash, space='', depth=0) {
    d <- depth + 1
    for (key in keys(hash)){
        print(paste(space, 'Key:', as.character((key)), 'Values:'))
        if (is.hash(hash[[key]])){
            suppressWarnings(print.hash(hash[[key]], paste(space, '-', sep=''), d))
        } else if (is.list(hash[[key]])){
            for (i in 1:length(hash[[key]])){
                item <- hash[[key]][[i]]
                if (is.hash(item)) {
                    suppressWarnings(print.hash(item, paste(space, '-', sep=' '), d))
                } else {
                    print(paste(space, item))
                }
            }
        }
        else {
            print(paste(space, hash[[key]]))
        }
    }
}

# Converts the data on which functions have error into a data frame
parse.data <- function(data) {
    listOfFuncs = list()
    listOfErrors = list()
    # For each function
    for (key in keys(data)){
        listOfFuncs[[length(listOfFuncs) + 1]] <- key
        wrong.cluster <- 0
        wrong.dbscan <- 0
        wrong.traj <- 0
        wrong.dtw <- 0
        # Will be a list
        total <- 0
        values <- data[[key]]

        for (item in values){
            for (k in keys(item)){
                if (k != 'original_trajectory' &&
                    item[[k]] != item[['original_trajectory']]){
                    if (k == 'cluster') {
                        wrong.cluster <- wrong.cluster + 1
                    } else if (k == 'dbscan') {
                        wrong.dbscan <- wrong.dbscan + 1
                    } else if ('traj' %in% strsplit(k, '-')[[1]]) {
                        wrong.traj <- wrong.traj + 1
                    } else {
                        wrong.dtw <- wrong.dtw + 1
                    }
                }
            }
            total <- total + 1
        }

        toPercent <- function(x) {
            return (as.integer(100*x / total))
        }
        listOfErrors[[length(listOfErrors) + 1]] <- c(toPercent(wrong.cluster), toPercent(wrong.dbscan),
                                                      toPercent(wrong.traj), toPercent(wrong.dtw))
    }

    listOfMethods <- c('kmeans', 'dbscan', 'traj', 'dtw')
    table_str = 'Function\tMethod\tError'
    counter <- 0
    for (j in 1:length(listOfFuncs)) {
        Func <- listOfFuncs[[j]]
        for (i in 1:length(listOfMethods)) {
            new_str <- paste(Func, listOfMethods[[i]], listOfErrors[[j]][[i]], sep='\t')
            table_str <- paste(table_str, new_str, sep='\n')
            counter <- counter + 1
        }
    }
    t <- read.table(header=TRUE, text=table_str)
    return (t)
}

# Takes a data frame containing the relevent data and creates line graph
lineplot.scores <- function(data, prefix='none') {
    par(pch=21, col='black')
    par(mfrow=c(1,1))
    x = c(1:length(data$clusterData))
    if ('none' %in% prefix)
        heading <- "Overall Clustering Scores"
    else
        heading <- paste(prefix, "clustering Scores")
    xrange <- range(x)
    ranges <- list(range(data$cluster), range(data$dbscan), range(data$traj), range(data$dtw))
    min <- 0
    max <- 0
    # Get the ranges
    for (range in ranges) {
        if (!is.nan(range[[1]]) && range[[1]] < min) {
            min <- range[[1]]
        }
        if (!is.nan(range[[2]]) && range[[2]] > max) {
            max <- range[[2]]
        }
    }
    yrange <- range(data$cluster)
    yrange[1] <- min
    yrange[2] <- max + (max / 2)
    plot(xrange, yrange, type="n", main=heading, xlab="Noise Level (%)", ylab="Score")
    colors <- rainbow(4)
    type <- "b"
    types <- rep(1, 4)
    plotchar <- seq(18, 18+4,1)
    lines(x, data$cluster, type=type,  pch=plotchar[1], lty=types[1], col=colors[1])
    lines(x, data$dbscan, type=type, pch=plotchar[2], lty=types[2], col=colors[2])
    lines(x, data$traj, type=type, pch=plotchar[3], lty=types[3], col=colors[3])
    lines(x, data$dtw, type=type, pch=plotchar[4], lty=types[4], col=colors[4])
    legend(xrange[1], yrange[2],
           c("Lodi-Kmeans", "Lodi-DBSCAN", "traj", "dtwclust-gak"),
           cex=0.8, title="Clustering Methods",
           col=colors, pch=plotchar, lty=types)
}

# Creates bar plots of the number of errors for each type of function
barplot.errors <- function(cluster_data, directory, noise=0, flip=TRUE) {
    len <- length(unique(cluster_data$Function))
    lines <- seq(0.5, 0.5 + (1 * len), 1)
    if (flip) {
    ggplot(cluster_data, aes( factor(Function), Error, fill = Method)) +
        geom_bar(stat="identity",  position = "dodge", size=1) +
        scale_fill_brewer(palette = "Set1") +
        geom_vline(xintercept=lines, linetype='dashed', colour='grey30', size=0.25) +
        theme(panel.grid.major = element_blank(),
              plot.title = element_text(hjust = 0.5),
              plot.subtitle = element_text(hjust = 1)) +
        coord_flip() + ylab("Error (%)") + xlab ("Function") +
        ggtitle("Error Rates by Function", subtitle = paste("Noise Level", noise, '%'))
    } else {
    ggplot(cluster_data, aes( factor(Function), Error, fill = Method)) +
        geom_bar(stat="identity",  position = "dodge", size=1) +
        scale_fill_brewer(palette = "Set1") +
        geom_vline(xintercept=lines, linetype='dashed', colour='grey30', size=0.25) +
        theme(panel.grid.major = element_blank(),
              plot.title = element_text(hjust = 0.5),
              plot.subtitle = element_text(hjust = 1)) +
        ylab("Error (%)") + xlab ("Function") +
        ggtitle("Error Rates by Function", subtitle = paste("Noise Level", noise, '%'))
    }
    ggsave(filename=paste(directory, noise, "-BarPlot.png", sep=''))
}

# The script part
main <- function() {
    # Python style argument parsing
    option_list <- list(
                        make_option(c('-i','--input_fp'), type='character',
                                    default='compare_clustering.csv',#../../lodiData/comparison-2TrajPerCluster/combinedScores.csv',
                                    help='Name of the file containing the clustering assignments'),
                       make_option(c('-m','--max_noise'), type='character',
                                   default='30',
                                   help='Maximum amount of noise for any of the test cases'),
                       make_option(c('-s', '--score_fp'), type='character',
                                    default='scores.csv',
                                    help='Name of the file containing the scores from the various evaluation measures'),
                        make_option(c('-d', '--directory'), type='character',
                                    default='./',
                                    help='The directory to read/write files from/to')
                        )
    opt_parser <- OptionParser(option_list=option_list)
    opt <- parse_args(opt_parser)
    data <- loadData(paste(opt$directory, opt$score_fp, sep=''), scores=TRUE)

    # Create the line plots of the cluster measure scores
    for (i in c('NVI', 'F_Measure', 'V_Measure', 'Rand_Index')){
        output <- parse.scores(data, i)
        parsed = output[[1]]
        png(paste(opt$directory, paste(i, "comparison.png", sep='-'), sep=''))
        lineplot.scores(parsed, i)
        dev.off()
    }
    output <- parse.scores(data, i)
    parsed = output[[1]]
    # +1 b/c the first index is 2 clusters
    clusts.traj = output[[2]] + 1
    clusts.dtw = output[[3]] + 1
    png(paste(opt$directory, "Comparison.png", sep=''))
    lineplot.scores(parsed)
    dev.off()

    # Create bar graphs in each noise directory

    for (i in 1:as.numeric(opt$max_noise)) {
        if (i < 10) {
            file <- paste(opt$directory, 'noise0',i, '/', opt$input_fp, sep='')
        } else
        {
            file <- paste(opt$directory, 'noise',i, '/',opt$input_fp, sep='')
        }
        cluster_data <- loadData(file, FALSE, clusts.traj, clusts.dtw)
        parsed <- parse.data(cluster_data)
        #png(paste(opt$directory, "BarPlot.png", sep=''))
        #dev.off()
        barplot.errors(parsed, opt$directory, i)
    }

    return (parsed)
}

data <- main()
