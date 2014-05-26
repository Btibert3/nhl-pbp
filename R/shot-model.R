###############################################################################
## Calculate shot probability
###############################################################################

## set the directory
setwd("~/Dropbox/Projects/nhl-playoffs-pbp")

## load the libraries
library(rjson)
library(RCurl)
library(plyr)
require(jpeg)
library(rpart)
library(e1071)
library(ggplot2)
library(nnet)

## read in the full PBP data
pbp = readRDS("data/playoff1213-pbp.rds")

## stanley cup games
# sc = subset(pbp, hometeamnick %in% c('Bruins', 'Blackhawks') 
#             & awayteamnick %in% c('Bruins','Blackhawks'))

## extract the shots removing empty net goals
shots = subset(pbp, 
               subset = sind==1 & nchar(g_goalie)>0,
               select = c('gameid', 'seasonid', 'awayteamnick', 'hometeamnick',
                          'eventid','period', 'homeind', 'stype', 'p1name',
                          'strength','time', 'altVideo', 'desc', 'xcoord', 
                          'ycoord','gx', 'gdist', 'angle', 'gind'))

## standardize the shots
shots = transform(shots,
                  xcoord_all = ifelse(gx == -89, -1*xcoord, xcoord),
                  ycoord_all = ifelse(gx == -89, -1*ycoord, ycoord), 
                  angle_all = ifelse(angle < 0 , -1* angle, angle),
                  wing = ifelse(angle < 0 , "R", "L"),
                  styp2 = stype)
shots$styp2 = as.character(shots$styp2)
shots$styp2[is.na(shots$stype)] = 'Other'
shots$styp2[shots$stype == 'Wrap-Around'] = 'Other'
shots$styp2[shots$stype == 'Deflection'] = 'Other'
shots$wing = as.factor(shots$wing)
shots$styp2 = factor(shots$styp2, 
                        levels = c("Other", "Backhand", "Slap Shot",
                                   "Snap Shot", "Tip-In", "Wrist Shot"))

## remove sots with distance greater than 90
shots = subset(shots, gdist < 90)


## table that should prove that shots are standardized


###############################################################################
## some quick summary stats
###############################################################################
with(shots, table(stype))
with(shots, table(stype, gind))
with(shots, hist(angle))
with(shots, hist(gdist))


###############################################################################
## plot all shots as reported 
## -- TODO: Just the rink? no legend or fix labels/colors
## help on just rink = http://goo.gl/LQPHX
## binhex = http://goo.gl/ZsMu1
###############################################################################


rink = readJPEG("figs/rink.jpg", native=F)
g = ggplot(shots, aes(x=xcoord, y=ycoord)) 
g = g + annotation_raster(rink, -100, 100, -42.5, 42.5, interpolate=FALSE)
# ---- scatter plot for each shot ------
# g = g + geom_point(aes(colour=factor(I(gind*-1))), alpha=.65) 
# g = g + scale_colour_brewer(palette="Set1")
# ---- bin to show where the goal areas are ---
# g = g + stat_binhex()
# g = g + scale_fill_gradient(colours=c("blue", "red"), name="Frequency")
# ---- a contour plot -------
g = g + geom_density2d()
g = g + ylim(-42.5, 42.5) + xlim(-100, 100) 
g + theme(      
 axis.line = element_blank(), axis.ticks = element_blank(),
 axis.text.x = element_blank(), axis.text.y = element_blank(), 
 axis.title.x = element_blank(), axis.title.y = element_blank(),
 legend.position = "none", 
 panel.background = element_blank(), 
 panel.border = element_blank(), 
 panel.grid.major = element_blank(), 
 panel.grid.minor = element_blank(), 
 plot.title = element_blank())


###############################################################################
## plot just the half rink - standardized shot data
###############################################################################

halfrink = readJPEG("figs/half-rink.jpg", native=F)
g = ggplot(shots, aes(x=xcoord_all, y=ycoord_all)) 
g = g + annotation_raster(halfrink, 0, 100, -42.5, 42.5, interpolate=FALSE)
# ---- scatter plot for each shot ------
g = g + geom_point(aes(colour=factor(I(gind*-1))), alpha=.65) 
g = g + scale_colour_brewer(palette="Set1")
# ---- bin to show where the goal areas are ---
# g = g + stat_binhex()
# g = g + scale_fill_gradient(colours=c("blue", "red"), name="Frequency")
# ---- a contour plot -------
#g = g + geom_density2d()
g = g + ylim(-42.5, 42.5) + xlim(0, 100) 
g + theme(      
 axis.line = element_blank(), axis.ticks = element_blank(),
 axis.text.x = element_blank(), axis.text.y = element_blank(), 
 axis.title.x = element_blank(), axis.title.y = element_blank(),
 legend.position = "none", 
 panel.background = element_blank(), 
 panel.border = element_blank(), 
 panel.grid.major = element_blank(), 
 panel.grid.minor = element_blank(), 
 plot.title = element_blank())




###############################################################################
## start to summarize the data to help think about specifying the model
###############################################################################

## summary of shot types, distance, goal, angle
shot.sum = ddply(shots, .(stype), summarise,
                 nshots = length(gameid),
                 avgDist = mean(gdist),
                 avgAngle = mean(angle),
                 gpct = round(mean(gind), 3))
arrange(shot.sum, desc(nshots))





## 

## can we use a neearest neightbors where we dont have to put all of the shots
## into the same region of the ice?


# 
# 
# 
# ## TODO: do a summary that shows goal prob by angle per hockeyanalytics article
# 
# ## plot the shots 
# 
# ###############################################################################
# ## Fit the models
# ## TODO: a calc on how long the last shot was since previous OR rebound ind?
# ###############################################################################
# 
# 
# ## fit a basic logistic regression with distance
mod_1 = glm(gind ~ gdist + angle_all + wing + styp2, data=shots, family=binomial())
## might need to interact distance and angle, as dist chews up a ton of significance
# mod_1 = glm(gind ~ gdist + angle_all + styp2, data=shots, family=binomial())
# mod_1 = glm(gind ~ styp2 + angle_all, data=shots, family=binomial())
tmp = transform(shots, sprob = predict(mod_1, newdata = shots, type="response"))
summary(mod_1)
write.table(tmp, file="output/shots-modeled.csv", sep=",", row.names=F)
# tmp = subset(tmp, awayteamnick=='Bruins' & hometeamnick=='Blackhawks')
# ## need to account for rapid shots have higher ability to score -- time since last?
# ## Example = first Hawks goal in game 2 of Stanley cup
# 
# ## fit a classification tree -- change CP
# mod_2 = rpart(gind ~ gdist,  data=shots, method="class")
# 
# ## support vector machine -- why wont it plot?
# shots$gflag = as.factor(ifelse(shots$gind==1, 'Y', 'N'))
# mod_3 = svm(gflag ~ gdist, data=shots)
# 
