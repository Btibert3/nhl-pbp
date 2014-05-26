## parse the raw JSON game into a dataframe with team info, goal loc, etc.
parsePBP = function(x) {
  require(plyr)
  require(stringr)
  tmp <- x$data$game
  # extract the teams
  team = data.frame(awayteamid = tmp$awayteamid,
                    awayteamname = tmp$awayteamname,
                    awayteamnick = tmp$awayteamnick,
                    hometeamname = tmp$hometeamname,
                    hometeamnick = tmp$hometeamnick,
                    hometeamid = tmp$hometeamid,
                    stringsAsFactors=F)
  # parse the pbp data
  tmp = tmp$plays$play
  df = data.frame(stringsAsFactors=F)
  for(i in 1:length(tmp)) {
    z = tmp[[i]]  
    # parse the data into a data frame
    df.temp <- as.data.frame(t(unlist(z)), stringsAsFactors=F)  
    df.temp$seqnum <- i
    # append the data
    df = rbind.fill(df, df.temp)
  }
  # join on the metadata about the game
  df = cbind(df, team)
  df$homeind = as.numeric(df$teamid == df$hometeamid)
  df$gameid = x$gameid
  df$seasonid = x$season
  # fix the columns with the helper function
  fixCols = function(df) {
    # fix the data types
    COLS = c('hsog','asog','xcoord','ycoord','period','teamid')
    for (COL in COLS) {
     if (COL %in% colnames(df)) {
      df[,COL] = as.numeric(df[,COL])
     }
    }
    # shot data
    df$shotind = as.numeric(df$type %in% c('Shot','Goal'))
    df$goalind[df$shotind==1] = as.numeric(df$type[df$shotind==1] == 'Goal')
    return(df)
  }
  # fix the columns
  df = fixCols(df)
  ## extract the shot type
  shotType = function(x) {
    require(stringr)
    pattern = "[A-Za-z]+ Shot|Backhand|Tip-In|Wrap-Around|Deflection"
    tmp = str_extract(x, pattern)
    return(tmp)
  }
  df = transform(df, stype = shotType(df$desc))
  df$stype = as.character(df$stype)
  df$emptynet = NA
  ## return the data frame
  return(df)
}