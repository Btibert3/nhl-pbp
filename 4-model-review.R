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
library(ROCR)


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


## r squared -- about .88 r squared
cor(model_accuracy$exp_goals, model_accuracy$goals, use="pairwise.complete.obs")^2


## another approach - AUC on another year of data
season1213 = subset(shots, seasonid == '20122013')
pred = prediction(season1213$sprob, season1213$goalind)
perf = performance(pred, measure = "tpr", x.measure = "fpr") 
auc.tmp <- performance(pred,"auc");
auc <- as.numeric(auc.tmp@y.values)
auc
## at the individual shot level, the auc is about .71, not great