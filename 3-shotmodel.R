###############################################################################
## Calculate shot probability
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
pbp = dbGetQuery(ch, "SELECT * FROM plays WHERE shotind = 1 AND seasonid = '20132014' ")

## extract the shots removing empty net goals
shots = subset(pbp, nchar(p2name)>0)

## keep only games that ended in regular time
## sqldf defaults to MySQL so I need to tell sqldf to use SQLite to avoid headachess
tmp = sqldf("SELECT gameid, max(period) as period FROM shots GROUP BY gameid",drv="SQLite")
tmp = subset(tmp, period == 3)
shots = subset(shots, gameid %in% tmp$gameid)
rm(tmp)

## remove shots that are more than 90 from the goal
shots = subset(shots, gdist < 90)


###############################################################################
## some quick summary stats
###############################################################################
with(shots, table(styp2))
with(shots, table(styp2, goalind))
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
g = g + geom_point(aes(colour=factor(I(goalind*-1))), alpha=.65) 
g = g + scale_colour_brewer(palette="Set1")
# ---- bin to show where the goal areas are ---
# g = g + stat_binhex()
# g = g + scale_fill_gradient(colours=c("blue", "red"), name="Frequency")
# ---- a contour plot -------
# g = g + geom_density2d()
# g = g + ylim(-42.5, 42.5) + xlim(-100, 100) 
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
g = g + geom_point(aes(colour=factor(I(goalind*-1))), alpha=.65) 
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


# ###############################################################################
# ## Fit the models
# ## TODO: a calc on how long the last shot was since previous OR rebound ind?
# ## TODO: think about fitting models on newer data that has shot type
# ###############################################################################

# ## fit a basic logistic regression with distance
shot_model = glm(goalind ~ gdist * angle_all + wing, data=shots, family=binomial())
#shot_model = glm(goalind ~ gdist * angle_all + wing + styp2, data=shots, family=binomial())
summary(shot_model)
save(shot_model, file="output/shot-model.Rdata")


## quick discussion
## if fit a model on newer data, could include shot type, which is significant
## I am assuming there are no difference between seasons
## I am fitting a model on shots 90 feet or closer
