# ================================================
#                     DESCRIPTION
# -------------------------------------------------
# Authors:    Nicholas Renegar
#
# Date:       1 Dec 2019
#
# Details:    This code creates NHL draftkings lineups based on some simple stacking rules. It combines with the Python and R code that takes Draftkings contest info, and streamlines the process of creating valid lineups, and removing injured players.

#
# Inputs:     (1) Player dataframe. This is a dataframe in R
#
# Outputs:    (1) Outputs lineups to be uploaded directly to Draftkings for daily lineups.
#
# Notes:      - Gurobi is required to run this script - can be modified for open source solvers (e.g. GLPK).
#             - View PARAMETERS sections to see that all parameters are appropriately set.
# ================================================

# ================================================
#                    PARAMETERS
# ================================================
# num_teams:    Draftkings requires players from 3 different teams.
#               We also add an upper limit on the number of teams to increase stacking
min_teams = 3
max_teams = 4

# salary_cap:  total lineup salary cap constraint
salary_cap = 50000

# path_to_proj: filepath for NHL Draftkings folder
path_to_proj = "//Github/NHL DraftKings"
path_to_input = string(path_to_proj,"/Output/MIPS Model Input.csv")

#Number of overlap in players allowed between any two lineups
num_overlap=6

#Number of lineups to create
num_lineups=50

# ===========================================================
#                        LOAD PACKAGES
# ===========================================================

# To install DataFrames, simply run Pkg.add("DataFrames")
using DataFrames

#Load Gurobi
using Gurobi

# Once again, to install run Pkg.add("JuMP")
using JuMP

# ===========================================================
#          LOADING DATAFRAMES & ADD GAME/TEAM INFO
# ===========================================================
player_info = readtable(path_to_input);
num_players = size(player_info,1);

# Populate player_info with the corresponding information each player's teams and games
games = unique(player_info[:GameInfo])
display(games)
num_games = size(games)[1]

teams = unique(player_info[:Team])
display(teams)
num_teams = size(teams)[1]

game_info = zeros(Int, size(games)[1])
team_info = zeros(Int, size(teams)[1])

for j=1:size(games)[1]
    if player_info[1, :GameInfo] == games[j]
        game_info[j] =1
    end
end
for j=1:size(teams)[1]
    if player_info[1, :Team] == teams[j]
        team_info[j] =1
    end
end
players_games = game_info'
players_teams = team_info'


for i=2:num_players
    game_info = zeros(Int, size(games)[1])
    for j=1:size(games)[1]
        if player_info[i, :GameInfo] == games[j]
            game_info[j] =1
        end
    end
    team_info = zeros(Int, size(teams)[1])
    for j=1:size(teams)[1]
        if player_info[i, :Team] == teams[j]
            team_info[j] =1
        end
    end
    players_games = vcat(players_games, game_info')
    players_teams = vcat(players_teams, team_info')
end

# ===========================================================
#                    LINEUP FUNCTION
# ===========================================================
function get_lineup(player_info)
    
    # create dataframes to store solutions for automated DraftKings upload
    lineup = DataFrame(Int,num_lineups,9)
    col_names_lineups = ["C1","C2","W1","W2","W3","D1","D2","G","Util"]
    names!(lineup.colindex, map(parse, col_names_lineups))
    
    # create dataframe for overlap constraints
    overlap = zeros(num_players,num_lineups)

    # create dataframe for objective values
    scores = DataFrame(Float64,num_lineups,1)
    col_names = ["Objective"]
    names!(scores.colindex, map(parse, col_names))

    m = Model(solver=GurobiSolver(OutputFlag=0))

    # variable for whether we select players in lineup
    @variable(m, player_lineup[i=1:num_players,j=1:9], Bin)

    # variable to see if team is used
    @variable(m, team_lineup[k=1:num_teams], Bin)

    # variable to see if game is used
    @variable(m, game_lineup[k=1:num_games], Bin)

    # nine players constraint
    @constraint(m, sum(sum(player_lineup[i,j] for j=1:9) for i=1:num_players) == 9)

    # each player used at most once
    for i in 1:num_players
        @constraint(m, sum(player_lineup[i,j] for j=1:9) <= 1)
    end

    # salary constraint
    @constraint(m, sum(player_info[i,:Salary]*sum(player_lineup[i,j] for j=1:9) for i=1:num_players) <= salary_cap)

    # one C1
    @constraint(m, sum(player_lineup[i,1] for i=1:num_players) == 1)

    # one C2
    @constraint(m, sum(player_lineup[i,2] for i=1:num_players) == 1 )

    # one W1
    @constraint(m, sum(player_lineup[i,3] for i=1:num_players) == 1)

    # one W2
    @constraint(m, sum(player_lineup[i,4] for i=1:num_players) == 1)

    # one W3
    @constraint(m, sum(player_lineup[i,5] for i=1:num_players) == 1)

    # one D1
    @constraint(m, sum(player_lineup[i,6] for i=1:num_players) == 1)

    # one D2
    @constraint(m, sum(player_lineup[i,7] for i=1:num_players) == 1)

    # one G
    @constraint(m, sum(player_lineup[i,8] for i=1:num_players) == 1)

    # one Util
    @constraint(m, sum(player_lineup[i,9] for i=1:num_players) == 1)

    # each player only used for their position
    for i in 1:num_players
        @constraint(m, player_lineup[i,1] <= player_info[i,:C1])
        @constraint(m, player_lineup[i,2] <= player_info[i,:C2])
        @constraint(m, player_lineup[i,3] <= player_info[i,:W1])
        @constraint(m, player_lineup[i,4] <= player_info[i,:W2])
        @constraint(m, player_lineup[i,5] <= player_info[i,:W3])
        @constraint(m, player_lineup[i,6] <= player_info[i,:D1])
        @constraint(m, player_lineup[i,7] <= player_info[i,:D2])
        @constraint(m, player_lineup[i,8] <= player_info[i,:G])
        @constraint(m, player_lineup[i,9] <= player_info[i,:Util])
    end

    # at least min different teams
    @variable(m, used_team[i=1:num_teams], Bin)
    @constraint(m, constr[i=1:num_teams], used_team[i] <= sum(sum(players_teams[t, i]*player_lineup[t,j] for t=1:num_players) for j=1:9))
    @constraint(m, sum(used_team[i] for i=1:num_teams) >= min_teams)
    
    # at most max different teams
    @constraint(m, constr[i=1:num_teams], 9 * used_team[i] >= sum(sum(players_teams[t, i]*player_lineup[t,j] for t=1:num_players) for j=1:9))
    @constraint(m, sum(used_team[i] for i=1:num_teams) <= max_teams)
    
    # no offense and defense from the same game (ignoring utility player)
    @variable(m, used_game_offense[i=1:num_games], Bin)
    @constraint(m, constr[i=1:num_games, t=1:num_players], used_game_offense[i] >= players_games[t, i]*player_lineup[t,1])
    @constraint(m, constr[i=1:num_games, t=1:num_players], used_game_offense[i] >= players_games[t, i]*player_lineup[t,2])
    @constraint(m, constr[i=1:num_games, t=1:num_players], used_game_offense[i] >= players_games[t, i]*player_lineup[t,3])
    @constraint(m, constr[i=1:num_games, t=1:num_players], used_game_offense[i] >= players_games[t, i]*player_lineup[t,4])
    @constraint(m, constr[i=1:num_games, t=1:num_players], used_game_offense[i] >= players_games[t, i]*player_lineup[t,5])
    @constraint(m, constr[i=1:num_games, t=1:num_players], 1-used_game_offense[i] >= players_games[t, i]*player_lineup[t,6])
    @constraint(m, constr[i=1:num_games, t=1:num_players], 1-used_game_offense[i] >= players_games[t, i]*player_lineup[t,7])
    @constraint(m, constr[i=1:num_games, t=1:num_players], 1-used_game_offense[i] >= players_games[t, i]*player_lineup[t,8])

    # objective function
    @objective(m, Max, sum(player_info[i,:Points]*sum(player_lineup[i,j] for j=1:9) for i=1:num_players))

    # Solve the integer programming problem
    println("\tgenerating ", num_lineups, " lineups...")

    for w in 1:num_lineups
        println("\t",w)

        # add new overlap constraint
        if w > 1
            @constraint(m, sum(overlap[i,w-1]*sum(player_lineup[i,j] for j=1:9) for i=1:num_players) <= num_overlap)
        end
        status = solve(m)
        println("Objective value: ", getobjectivevalue(m))

        # add lineup to lineup dataframe (including player ID for DK upload)
        for i in 1:num_players
            if sum(getvalue(player_lineup[i,j]) for j=1:9) >= 0.99
                overlap[i,w] = 1
                if getvalue(player_lineup[i,1]) >= 0.99
                    lineup[w,1] = player_info[i,:ID]
                elseif getvalue(player_lineup[i,2]) >= 0.99
                    lineup[w,2] = player_info[i,:ID]
                elseif getvalue(player_lineup[i,3]) >= 0.99
                    lineup[w,3] = player_info[i,:ID]
                elseif getvalue(player_lineup[i,4]) >= 0.99
                    lineup[w,4] = player_info[i,:ID]
                elseif getvalue(player_lineup[i,5]) >= 0.99
                    lineup[w,5] = player_info[i,:ID]
                elseif getvalue(player_lineup[i,6]) >= 0.99
                    lineup[w,6] = player_info[i,:ID]
                elseif getvalue(player_lineup[i,7]) >= 0.99
                    lineup[w,7] = player_info[i,:ID]
                elseif getvalue(player_lineup[i,8]) >= 0.99
                    lineup[w,8] = player_info[i,:ID]
                elseif getvalue(player_lineup[i,9]) >= 0.99
                    lineup[w,9] = player_info[i,:ID]
                end
            end
        end
        
    end
    
    return lineup
end


# ===========================================================
#                         RUNNING CODE
# ===========================================================
println("running models to generate lineups...")
@printf("\n")
lineups2 = get_lineup(player_info)
println("\tdone.")
@printf("\n")

println("finished running models.")
@printf("\n")
# ===========================================================
#                    WRITE LINEUPS TO FILE
# ===========================================================
print("writing lineups to Lineups folder...")

path_to_output = string(path_to_proj, "/Output/DK Lineups for Upload.csv")
writetable(path_to_output,lineups2)
    

