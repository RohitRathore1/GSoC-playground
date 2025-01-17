module SurrogateOptimizationDemo

using Surrogates
using AbstractGPs # access to kernels
using SurrogatesAbstractGPs
using Sobol

export initialize!, optimize!, OptimizationHelper, get_hist, get_solution, Min, Max, Turbo, TurboPolicy # and some concrete subtypes of DSMs and Policies

"""
Maintain a state of the decision support model (e.g. trust regions and local surrogates in TuRBO).

Provide `update!(dsm::DecisionSupportModel, oh::OptimizationHelper, xs, ys)` for aggregation
of evaluations `ys` at points `xs` into a decision model.
TODO: what does a policy need from a dsm?
"""
abstract type DecisionSupportModel end
"""
Decide where we evaluate the objective function next based on information aggregated
in a decision support model.

In particular, take care of details regarding acquisition functions & solvers for them.
An object `policy` of type Policy is callable, run `policy(dsm::DecisionSupportModel)`
to get the next batch of points for evaluation.
A policy may set the flag `isdone` in a decision support model to true (when the cost of
acquiring a new point outweights the information gain).
"""
abstract type Policy end

# idea from BaysianOptimization.jl
@enum Sense Min=-1 Max=1

include("OptimizationHelper.jl")
include("DecisionSupportModels/Turbo/Turbo.jl")
include("Policies/TurboPolicy.jl")
include("utils.jl")

"""
Generate initial sample points, evaluate f on them and process evaluations in
a decision support model.
"""
function initialize!(dsm::DecisionSupportModel, oh::OptimizationHelper) end

"""
Run the optimization loop.
"""
function optimize!(dsm::DecisionSupportModel, policy::Policy, oh::OptimizationHelper)
    # TODO: add `&& oh.total_duration <= oh.max_duration` once ready in oh
    while !dsm.isdone && oh.evaluation_counter <= oh.max_evaluations
        # apply policy to get a new batch
        xs = policy(dsm)
        ys = evaluate_objective!(oh, xs)
        # trigger update of the decision support model,
        # in Turbo, this may further evaluate f when restarting a TR
        update!(dsm, oh, xs, ys)
    end
end

# Ask-tell interface
# Idea: use threads and pass a special objective function that pauses the execution
# of the optimization loop until the objective value is provided by calling `tell!`.
# 'ask!' retrieves the proposed observation locations before pausing the loop.
#
# """
# Return the next observation locations.
# """
# function ask(dsm::DecisionSupportModel, plc::Policy, oh::OptimizationHelper)
# end
#
# """
# Update of the decision suport model to incorporate new values `ys` at points `xs`.
# """
# function tell!(dsm::DecisionSupportModel,
#                oh::OptimizationHelper,
#                xs::Vector{Float64},
#                ys::Vector{Float64})
# end

end # module
