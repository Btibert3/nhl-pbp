# About

A directory that contains the code to parse and analyze NHL PBP data using `R`.  It is far from perfect, but hopefully the code is helpful to those who are trying to piece together their own similar solutions.  There are many things that could be refactored, but I tend to prefer raw code to speed.  Simply, I like to commit scripts that are a few steps from being DRY but are easier to read and clearly outline the attack plan. 

## How it works

1. `1-harvest.r` is the script that intend to be run interactively.  Use this script to grab the data using your parameters of interest.
2. `2-parse.r` also ***should*** be run interactively, but it's closer to a script that could be run from the command line. Here we are reading in the raw pbp data and beating it into a format that we want for our database.  Once transfored, we load it into a MySQL table for storage.

## The why behind my approach

I poked around a bit here on Github and noticed there were a few approaches to playing around with raw play-by-play data for the NHL.  I reference `@wellsoliver` below because he has some great sports repos, not just for the NHL.  His code shows his ability, but so does mine.  As such, I try to write simple commented code that needs minimal interactivity to be run.  Better approaches would handle the inputs through command line arguments or config files.  That's just one step too far for my needs.

## Some technical details

I am running local instances for both `MySQL` and `MongoDB` on Ubuntu.  You will need these to work through my process.  

For help on installation, the offical docs are pretty straightforward.

Lastly, I assume that you have successfully installed the `rmongodb` and `RMySQL` packages on that same machine.  I use the web version of [RStudio](https://www.rstudio.com/ide/server/) to connect to my local server through the browser.  It's nice running computations on an external machine.


## TODO
1.  Adapt the scripts to be less interactive and accept command line args
2.  Adapt `2-parse.r` to either do fresh ETL-type creation of database or only add new games.
3.  Generate SQL on the fly and add, at a minimum, PKs.

### References and Previous Work Acknowledgements

This repo is heavily inspired by @wellsoliver `py-nhl` [repo](https://github.com/wellsoliver/py-nhl) which collects various data from the NHL, including play-by-play data. 

- A python package for NHL  
-- [py-nhl on Github](https://github.com/wellsoliver/py-nhl?source=c)

- A relatively recent (October 2013) post on `Average Shot Probability`.  Admittedly, I haven't ever really searched for past work, but it makes sense that other data nerds have explored this idea before.  If you like NHL and advanced stats, you **have** to poke around this blog.  
-- [Shot Quality Matters and Maybe it Doesnt](http://statsportsconsulting.com/2013/10/29/nhl-shot-quality-matters-and-maybe-it-doesnt/)

- Nice Time on Ice is an awesome site. Not only is it a dynamic stat site, but its built on top of python and a few other cool open source libraries.  I love that the site exposes a `REST API` that returns `JSON`.  Major hat tip to this site. 
-- [Nice Time on Ice](http://www.nicetimeonice.com/)

- There is an `R` package that is supposed to interface with PBP data as well.  I haven't really played around with it to be completely honest mostly because I wanted to practice and create my own solution.  That said, the fact that they were ambitious enough to package their solution is a reason you should give their efforts a run.  [nhlscrapr](https://github.com/cran/nhlscrapr)

