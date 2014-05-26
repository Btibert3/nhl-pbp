## Function to predict the goal location (x/y coords) for each team in a game
shotLOC = function(df) {
  require(plyr)
  ## set goal locations by using the min shot distance for home team periods 1/3
  ## home goal periods 1/3 = see wikipedia distance below of 11 feet
  G1 =  -89
  G2 = 89
  ## subset the df to include only periods 1/3
  tmp = subset(df, period %in% c(1,3) & shotind==1 & teamid==hometeamid)
  tmp = mutate(tmp, 
               dist1 = sqrt( (xcoord-G1)^2 + (ycoord-0)^2 ),
               dist2 = sqrt( (xcoord-G2)^2 + (ycoord-0)^2 ),
               goalpos = ifelse(dist1 < dist2, "G1", "G2"),
               glocx = ifelse(goalpos=='G1', -89, 89),
               glocy = 0)
  ## for each game, where does the home team shoot for periods 1/3
  home = ddply(tmp, .(seasonid, gameid), summarise,
               goal_pos = ifelse(mean(dist1) < mean(dist2), "G1", "G2"),
               glocx = ifelse(mean(dist1) < mean(dist2), -89, 89),
               glocy = 0)
  ## merge the home locations for periods 1/3 to all events
  m = merge(df, home, all.x=T)
  ## assing the goal loc and distance for every event
  m$gx = NA
  R = which(m$homeind==1 & m$period %in% c(1,3,5,7))
  m$gx[R] = m$glocx[R]
  R = which(m$homeind==0 & m$period %in% c(1,3,5,7))
  m$gx[R] = m$glocx[R] * -1
  R = which(m$homeind==1 & m$period %in% c(2,4,6,8))
  m$gx[R] = m$glocx[R] * -1
  R = which(m$homeind==0 & m$period %in% c(2,4,6,8))
  m$gx[R] = m$glocx[R]
  # append the data
  m = mutate(m,
             gy = 0, 
             gdist = sqrt( (xcoord-gx)^2 + (ycoord-gy)^2 ))
  ## cleanup the temp calcs that we dont need
  m$goal_pos = NULL
  m$glocx = NULL
  m$glocy = NULL
  m$gy = NULL
  ## return the data frame with the extra calcs
  return(m)
}  
