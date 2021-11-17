using CSV
using DataFrames 
using Gurobi
using JuMP
using Random


train_filepath = "train_processed.csv"
test_filepath = "test_processed.csv"

CSV.read(train_filepath, DataFrame)
CSV.read(test_filepath, DataFrame)



