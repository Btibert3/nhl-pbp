## function to calculate the angle of the event relative to the offensive goal
calcAngle = function(ex, ey, gx) {
  ## http://goo.gl/EQE5K
  ## uses site above, but adjusts slightly to make calc easier 
  ex = ifelse(gx==89, ex, -ex)
  ey = ifelse(gx==89, ey, -ey)
  #deltaY = abs(ey) - 0  ## abs(ey) keeps lw/rw shots/events at the same angle
  deltaY = ey - 0  ## this option allows us to have +/- values, to indicate L/R wings
  deltaX = 89 - ex
  #angleInDegrees = atan(deltaY / deltaX) * 180 / pi
  angleInDegrees = atan2(deltaY, deltaX) * 180 / pi
  angleAdj = angleInDegrees
  return(angleAdj)
}

# calcAngle = function(ex, ey, gx, makeEqual=F) {
#   ## http://goo.gl/EQE5K
#   ## uses site above, but adjusts slightly to make calc easier 
#   ex = ifelse(gx==89, ex, -ex)
#   ey = ifelse(gx==89, ey, -ey)
#   #deltaY = abs(ey) - 0  ## abs(ey) keeps lw/rw shots the same angle
#   ## makeEqual = FALSE allows negative angles to keep lw/rw angles, TRUE = same
#   deltaY = ifelse(makeEqual==F, ey - 0, abs(ey) - 0)  
#   deltaX = 89 - ex
#   angleInDegrees = atan(deltaY / deltaX) * 180 / pi
#   angleInDegrees = atan2(deltaY, deltaX) * 180 / pi
#   angleAdj = angleInDegrees
#   return(angleAdj)
# }




