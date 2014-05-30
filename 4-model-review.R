###############################################################################
## Very, very simple view of the model, how well does it fit player outcomes
## TODO: isolate regular season versus playoffs
###############################################################################

## options
options(stringsAsFactors=F)

## load the libraries
library(RMySQL)
library(plyr)
require(jpeg)
library(ggplot2)
library(sqldf)


## connect to MySQL
drv = dbDriver("MySQL")
ch = dbConnect(drv, user="root", password="password", db="nhlpbp")

## not smart, but do a SELECT * from all shots from current season
## because this will drive my model, leaves MAJOR room for improvement to 
## use a wider range of data, isolate regular season versus playoffs, etc.
pbp = dbGetQuery(ch, "SELECT * FROM plays WHERE shotind = 1 ")


## get the model
load("output/shot-model.Rdata")

## apply the model to every shot
shots = transform(pbp, sprob = predict(shot_model, newdata = pbp, type="response"))

## summarize by player/season and expected versus actual goals (regular + posteason)
model_accuracy = ddply(shots, .(pid, playername, seasonid), summarise,
                       shots = length(gameid),
                       exp_goals = sum(sprob),
                       goals = sum(goalind))

## scatterplot
g = ggplot(model_accuracy, aes(goals, exp_goals)) + geom_point(shape=19, alpha=1/4)
g =  g + geom_smooth(method=lm)
g = g + ylab("Expected Goals") + xlab("Actual Goals Scored")
ggsave(file="figs/model-fit.png", width=4, height=4)


