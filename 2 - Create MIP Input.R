library(dplyr)

# Clear the workstation and set directory path
rm(list=ls())

path_to_proj = "./Github/NHL DraftKings"
setwd(path_to_proj)

#=====================================================================#
#      Begin with DK Salaries and Positions (From Contest Lobby)      #
#=====================================================================#
#Get salaries
path_to_salaries = paste(path_to_proj,"/Data//DKSalaries.csv",sep = "")
player_salaries = read.csv(path_to_salaries, header = TRUE, stringsAsFactors = FALSE) %>% arrange(Name)

#=====================================================================#
#                  Remove Injured Players from CBS                    #
#=====================================================================#
path_to_injuries_cbs = paste(path_to_proj,"/Data/Injuries_CBS.csv",sep = "")
injuries_cbs = read.csv(path_to_injuries_cbs, header = TRUE, stringsAsFactors = FALSE) %>% arrange(Name)

#Remove Injured Players
player_salaries_noinjuries <- player_salaries[!(player_salaries$Name %in% injuries_cbs$Name),]

#=====================================================================#
#                Prepare Input Dataframe for MIP                      #
#=====================================================================#
# number of players we are using
num_players = nrow(player_salaries)

# create dataframe for model input
players = data.frame(matrix(vector(), num_players, 16,
                            dimnames=list(c(), c("ID","Name", "Salary","Position", "Points",
                                                 "C1","C2","W1","W2","W3","D1","D2", "G", "Util",
                                                 "Team","GameInfo"))),
                     
                     stringsAsFactors=F)
# add player names, salaries, and positions
players$ID = player_salaries$ID
players$Name = player_salaries$Name
players$Salary = player_salaries$Salary
players$Position = player_salaries$Position
players$Team = player_salaries$Team
players$GameInfo = player_salaries$Game.Info

# determine which position each player can be counted for
players = players %>% 
  mutate(C1 = ifelse(Position %in% c("C"), 1, 0),
         C2 = ifelse(Position %in% c("C"), 1, 0),
         W1 = ifelse(Position %in% c("LW", "RW"), 1, 0),
         W2 = ifelse(Position %in% c("LW", "RW"), 1, 0),
         W3 = ifelse(Position %in% c("LW", "RW"), 1, 0),
         D1 = ifelse(Position %in% c("D"), 1, 0),
         D2 = ifelse(Position %in% c("D"), 1, 0),
         G = ifelse(Position %in% c("G"), 1, 0),
         Util = ifelse(Position %in% c("LW", "RW","C", "D"), 1, 0))

# add points predictions, variance
players$Points = player_salaries$AvgPointsPerGame

write.csv(players,paste(path_to_proj,'/Output/MIPS Model Input.csv',sep=""))