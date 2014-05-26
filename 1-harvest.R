###############################################################################
## Crawl the PBP data
## For help with Mongo, https://gist.github.com/Btibert3/7751989#file-rmongodb-tutorial-md
###############################################################################


## load the packages
library(rmongodb)
library(RCurl)
library(rjson)
library(plyr)


## connect to mongo db instance
mongo = mongo.create("localhost")
mongo.is.connected(mongo)


## hardcode the variables 
EP = 'http://www.nicetimeonice.com/api/seasons/'
DB = "nhlpbp"
SEASON = '20132014'

###############################################################################
## Get the ids we already have grabbed and saved into Mongo 
###############################################################################

## define the vector where we will save the games we have (if any)
gameids = character()

## build the namespace
DBNS = paste(DB, "rawpbp", sep=".")

## define the query
query = mongo.bson.buffer.create()
mongo.bson.buffer.append(query, "season", SEASON)
query = mongo.bson.from.buffer(query)

## define the fields we want to pull
fields = mongo.bson.buffer.create()
mongo.bson.buffer.append(fields, "gameid", 1L)
mongo.bson.buffer.append(fields, "_id", 0L)
fields = mongo.bson.from.buffer(fields)

## make the cursor
cursor = mongo.find(mongo, ns = DBNS, query = query, fields = fields)

## iterate over the cursor
while (mongo.cursor.next(cursor)) {
  
  # iterate and grab the next record
  tmp = mongo.bson.to.list(mongo.cursor.value(cursor))
  # make it a character vector
  tmp = tmp$gameid
  # bind to the master dataframe
  gameids = c(gameids, tmp)
  
} #ENDWHILE

## cleanup
rm(cursor, query, fields)


###############################################################################
## Get the list of gameids from the API
###############################################################################

## get the page of the current seasons gameids from an awesome API
URL = paste0("http://www.nicetimeonice.com/api/seasons/", SEASON, "/games")
gids = getURL(URL)
gids = fromJSON(gids) 
gids = do.call(rbind.data.frame, gids)
gids = data.frame(apply(gids, 2, as.character), stringsAsFactors=F)
gids$date2 = as.Date(strptime(gids$date, "%a %b %d, %Y"))



###############################################################################
## Find the game ids that are not in Mongodb
###############################################################################

## define the current seasons games through yesterday
gids = subset(gids, date2 <= Sys.Date()-1)
games_cs = unique(gids$gameID)

## the difference in the lists
games_diff = setdiff(games_cs, gameids)


###############################################################################
## for the ids not in mongo, try to grab the data and send to mogno
###############################################################################


## loop and get the games
for (game in games_diff) {
  
  ## getting the game
  cat("getting game ", game, "\n")
  
  ## build the url for the game
  BASE = "http://live.nhl.com/GameData/"
  URL = paste0(BASE, SEASON, "/", game, "/PlayByPlay.json")
  
  ## try to get the game data -- skip to the next if not there
  raw_pbp = tryCatch(getURL(URL), 
                     error=function(e) e)
  if (inherits(raw_pbp, "error")) {
    cat("ERROR: problem retrieving game ", game, "\n")
    next
  }
  
  ## attempt to parse the json
  raw_pbp = tryCatch(fromJSON(raw_pbp), 
                     error=function(e) e)
  if (inherits(raw_pbp, "error")) {
    cat("ERROR: problem parsing game ", game, "\n")
    next
  }
  
  ## status
  cat("appears that the game is valid \n")
  
  ## add some metadata to the list
  raw_pbp$season = SEASON
  raw_pbp$gameid = game
  
  ## add the list to our mongo database
  b = mongo.bson.from.list(raw_pbp)
  mongo.insert(mongo, DBNS, b)
  
} #ENDFOR


###############################################################################
## ## clear out the current game metadata and send the current data
###############################################################################

## reset the namespace
DBNS = paste(DB, "gameids", sep=".")

## define the query
query = mongo.bson.buffer.create()
mongo.bson.buffer.append(query, "seasonID", SEASON)
query = mongo.bson.from.buffer(query)

## remove the records that match our query = all documents matching the season
mongo.remove(mongo, DBNS, criteria = query)


## add the data to collection -- loop to add each row as a document
## There might be dupes:  possible refactoring could happen here
## This includes all games, not just those with valid data
for (i in 1:nrow(gids)) {
  tmp_gids = gids[i, ]
  tmp_gids$seasonID = SEASON
  tmp_gids$date2 = NULL
  tmp_list = as.list(tmp_gids)
  b_game = mongo.bson.from.list(tmp_list)
  mongo.insert(mongo, DBNS, b_game)
} #ENDFOR



## how many do we have for the season
mongo.count(mongo, DBNS, query)
