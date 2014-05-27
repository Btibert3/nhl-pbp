###############################################################################
## Crawl the PBP data
## For help with Mongo, https://gist.github.com/Btibert3/7751989#file-rmongodb-tutorial-md
###############################################################################

## load the packages
library(rmongodb)
library(RCurl)
library(rjson)
library(plyr)
library(RMySQL)
library(stringr)
library(lubridate)

## source the helper functions
source("R/find-angle.R")
source("R/parse-pbp.R")
source("R/shot-loc.R")

## connect to mongo db instance
mongo = mongo.create("localhost")
mongo.is.connected(mongo)

## setup the namepsace for the raw PBP data
DBNS = "nhlpbp.rawpbp"

## connect to MySQL
drv = dbDriver("MySQL")
ch = dbConnect(drv, user="root", password="password", db="nhlpbp")

## the columns that we want to keep from the PBP data
pbp_cols = readRDS("R/colnames.rds")


###############################################################################
## We can't apply a function, so we have to loop to build a dataframe frame
## from each raw JSON file and write the cleaned data to MySQL
###############################################################################

## TODO:
########### find the games that are not in the parsed table before running 
########### code below

## some helper sql while developing
# dbGetQuery(ch, "CREATE TABLE plays_old LIKE plays;")
# dbGetQuery(ch, "INSERT plays_old SELECT * FROM plays;")
# dbGetQuery(ch, "TRUNCATE TABLE plays;")

## create the cursor of the games we will parse
## seasons parsed 20132014, 20122013, 20112012, 20102011
query = mongo.bson.buffer.create()
mongo.bson.buffer.append(query, "season", "20132014")
query = mongo.bson.from.buffer(query)
mongo.count(mongo, DBNS, query)
cursor = mongo.find(mongo, ns = DBNS, query = query)


start = Sys.time()
## iterate over the cursor and assemble the data
while (mongo.cursor.next(cursor))
{
  # iterate and grab the next record
  tmp = mongo.bson.to.list(mongo.cursor.value(cursor))
  
  # if data is not in tmp, go to the next record
  if (! "data" %in% names(tmp)) {
    cat("game data not found in : ", tmp$gameid)
    next
  }
  cat("starting the parse and save of game: ", tmp$gameid, "\n")
  
  # use the helper function to parse the data
  plays = tryCatch(parsePBP(tmp), error = function(e) e)
  if (inherits(plays, "error")) {
    cat("error with parsing the plays.  Moving on\n")
    next
  }

  # put on the shot location (the goal location is at 0)
  plays = tryCatch(shotLOC(plays), error = function(e) e)
  if (inherits(plays, "error")) {
    cat("error with parsing the shot locations.  Moving on\n")
    next
  }
  
  # calculate the angle relative to the goal -- calc is +/- for the wing
  plays = transform(plays, angle = calcAngle(xcoord, ycoord, gx))
  
  ## convert the shots to same half of ice and standardize the angle
  plays = transform(plays,
                    xcoord_all = ifelse(gx == -89, -1*xcoord, xcoord),
                    ycoord_all = ifelse(gx == -89, -1*ycoord, ycoord), 
                    angle_all = ifelse(angle < 0 , -1* angle, angle),
                    wing = ifelse(angle < 0 , "R", "L"),
                    styp2 = stype)
  
  # time expired etc
  plays = transform(plays, mins_expired = period * (minute(ms(time))+1))
  
  # keep the columns we want -- use our columns and only keep those that are in it
  # some columns may not be in our list, as they were removed by the NHL
  COLS = which(names(plays) %in% pbp_cols)
  to_db = plays[, COLS]
  
  # write the data to MySQL
  dbWriteTable(ch, "plays", to_db, append=T)
} #endwhile

query = mongo.bson.buffer.create()
mongo.bson.buffer.append(query, "season", "20122013")
query = mongo.bson.from.buffer(query)
mongo.count(mongo, DBNS, query)
cursor = mongo.find(mongo, ns = DBNS, query = query)


## iterate over the cursor and assemble the data
while (mongo.cursor.next(cursor))
{
  # iterate and grab the next record
  tmp = mongo.bson.to.list(mongo.cursor.value(cursor))
  
  # if data is not in tmp, go to the next record
  if (! "data" %in% names(tmp)) {
    cat("game data not found in : ", tmp$gameid)
    next
  }
  cat("starting the parse and save of game: ", tmp$gameid, "\n")
  
  # use the helper function to parse the data
  plays = tryCatch(parsePBP(tmp), error = function(e) e)
  if (inherits(plays, "error")) {
    cat("error with parsing the plays.  Moving on\n")
    next
  }
  
  # put on the shot location (the goal location is at 0)
  plays = tryCatch(shotLOC(plays), error = function(e) e)
  if (inherits(plays, "error")) {
    cat("error with parsing the shot locations.  Moving on\n")
    next
  }
  
  # calculate the angle relative to the goal -- calc is +/- for the wing
  plays = transform(plays, angle = calcAngle(xcoord, ycoord, gx))
  
  ## convert the shots to same half of ice and standardize the angle
  plays = transform(plays,
                    xcoord_all = ifelse(gx == -89, -1*xcoord, xcoord),
                    ycoord_all = ifelse(gx == -89, -1*ycoord, ycoord), 
                    angle_all = ifelse(angle < 0 , -1* angle, angle),
                    wing = ifelse(angle < 0 , "R", "L"),
                    styp2 = stype)
  
  # time expired etc
  plays = transform(plays, mins_expired = period * (minute(ms(time))+1))
  
  # keep the columns we want -- use our columns and only keep those that are in it
  # some columns may not be in our list, as they were removed by the NHL
  COLS = which(names(plays) %in% pbp_cols)
  to_db = plays[, COLS]
  
  # write the data to MySQL
  dbWriteTable(ch, "plays", to_db, append=T)
} #endwhile





query = mongo.bson.buffer.create()
mongo.bson.buffer.append(query, "season", "20112012")
query = mongo.bson.from.buffer(query)
mongo.count(mongo, DBNS, query)
cursor = mongo.find(mongo, ns = DBNS, query = query)


## iterate over the cursor and assemble the data
while (mongo.cursor.next(cursor))
{
  # iterate and grab the next record
  tmp = mongo.bson.to.list(mongo.cursor.value(cursor))
  
  # if data is not in tmp, go to the next record
  if (! "data" %in% names(tmp)) {
    cat("game data not found in : ", tmp$gameid)
    next
  }
  cat("starting the parse and save of game: ", tmp$gameid, "\n")
  
  # use the helper function to parse the data
  plays = tryCatch(parsePBP(tmp), error = function(e) e)
  if (inherits(plays, "error")) {
    cat("error with parsing the plays.  Moving on\n")
    next
  }
  
  # put on the shot location (the goal location is at 0)
  plays = tryCatch(shotLOC(plays), error = function(e) e)
  if (inherits(plays, "error")) {
    cat("error with parsing the shot locations.  Moving on\n")
    next
  }
  
  # calculate the angle relative to the goal -- calc is +/- for the wing
  plays = transform(plays, angle = calcAngle(xcoord, ycoord, gx))
  
  ## convert the shots to same half of ice and standardize the angle
  plays = transform(plays,
                    xcoord_all = ifelse(gx == -89, -1*xcoord, xcoord),
                    ycoord_all = ifelse(gx == -89, -1*ycoord, ycoord), 
                    angle_all = ifelse(angle < 0 , -1* angle, angle),
                    wing = ifelse(angle < 0 , "R", "L"),
                    styp2 = stype)
  
  # time expired etc
  plays = transform(plays, mins_expired = period * (minute(ms(time))+1))
  
  # keep the columns we want -- use our columns and only keep those that are in it
  # some columns may not be in our list, as they were removed by the NHL
  COLS = which(names(plays) %in% pbp_cols)
  to_db = plays[, COLS]
  
  # write the data to MySQL
  dbWriteTable(ch, "plays", to_db, append=T)
} #endwhile





query = mongo.bson.buffer.create()
mongo.bson.buffer.append(query, "season", "20102011")
query = mongo.bson.from.buffer(query)
mongo.count(mongo, DBNS, query)
cursor = mongo.find(mongo, ns = DBNS, query = query)


## iterate over the cursor and assemble the data
while (mongo.cursor.next(cursor))
{
  # iterate and grab the next record
  tmp = mongo.bson.to.list(mongo.cursor.value(cursor))
  
  # if data is not in tmp, go to the next record
  if (! "data" %in% names(tmp)) {
    cat("game data not found in : ", tmp$gameid)
    next
  }
  cat("starting the parse and save of game: ", tmp$gameid, "\n")
  
  # use the helper function to parse the data
  plays = tryCatch(parsePBP(tmp), error = function(e) e)
  if (inherits(plays, "error")) {
    cat("error with parsing the plays.  Moving on\n")
    next
  }
  
  # put on the shot location (the goal location is at 0)
  plays = tryCatch(shotLOC(plays), error = function(e) e)
  if (inherits(plays, "error")) {
    cat("error with parsing the shot locations.  Moving on\n")
    next
  }
  
  # calculate the angle relative to the goal -- calc is +/- for the wing
  plays = transform(plays, angle = calcAngle(xcoord, ycoord, gx))
  
  ## convert the shots to same half of ice and standardize the angle
  plays = transform(plays,
                    xcoord_all = ifelse(gx == -89, -1*xcoord, xcoord),
                    ycoord_all = ifelse(gx == -89, -1*ycoord, ycoord), 
                    angle_all = ifelse(angle < 0 , -1* angle, angle),
                    wing = ifelse(angle < 0 , "R", "L"),
                    styp2 = stype)
  
  # time expired etc
  plays = transform(plays, mins_expired = period * (minute(ms(time))+1))
  
  # keep the columns we want -- use our columns and only keep those that are in it
  # some columns may not be in our list, as they were removed by the NHL
  COLS = which(names(plays) %in% pbp_cols)
  to_db = plays[, COLS]
  
  # write the data to MySQL
  dbWriteTable(ch, "plays", to_db, append=T)
} #endwhile

end = Sys.time()







