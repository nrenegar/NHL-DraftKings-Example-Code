# NHL-DraftKings-Example-Code

This code complements the ideas from the paper 'Picking Winners' by David Scott Hunter, Juan Pablo Vielma, and Tauhid Zaman (http://web.mit.edu/jvielma/www/publications/Picking-Winners.pdf), to create winning NHL DraftKings (DK) lineups.

It is intended to give a streamlined approach to the process. It begins with the DK salary file, that must be manually downloaded from the site per ToS (shown below)  

![Image description](https://i.ibb.co/FWY7wf1/Screen-Shot-2019-12-01-at-6-02-50-PM.jpg)

Step 1. The first part of the code then uses Selenium in Python (with chromedriver) to access CBS Sports and find all injured players. 

Step 2. The second part of the code uses R to take the DK salary information, remove injured players, and uses dplyr to structure the data for the lineup optimization.

Step 3. The third part of the code then uses Julia with JuMP, and the Gurobi optimization software, to automatically create 50 lineups (in rough accordance with the ideas in the code released with the paper https://github.com/dscotthunter/Fantasy-Hockey-IP-Code). The lineups are saved as a 2d array of DK ID numbers, which can be automatically uploaded to the site (see below). Note that Gurobi is commercial software, but this can all be redone with GLPK.

![Image description](https://i.ibb.co/vBbwmq7/Screen-Shot-2019-12-01-at-7-52-26-PM.jpg)

Therefore this code takes the concept from 'Picking Winners', and streamlines it so that lineups can be output within a few minutes, allowing you to react as late as possible to injury information. 

Note: The code is just a piece of what I actually implemented, and a rough framework for how to do this. This repo needs a little more work if you want to be profitable.

Have fun with it!
