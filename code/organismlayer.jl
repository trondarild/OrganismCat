using Catlab
using Catlab.Graphics: Graphviz
# organism layer - composed from lower levels
include(joinpath(@__DIR__,"common.jl"))
include(joinpath(@__DIR__, "thermolayer.jl"))
include(joinpath(@__DIR__, "neuronallayer.jl"))
include(joinpath(@__DIR__, "predictionlayer.jl"))

# compose energy with neural layers
thermoprocess = @program ThermoLayer (c::ComplexMolecule) begin
  a, e, l = Metabolize(c)
  return a, e, l
end

neuroprocess = @program NeuronalActivity (a::ATP, r::AP_Rhythm, et::EntropicTissue) begin
  r′, e1 = SpikingActivity(a, r)
  e2, ot = Allostasis(a, r, et)
  return r′, e1, e2, ot
end

# compose organism layer and draw
thermoprocess ⋅ neuroprocess |> draw
FinCat(ThermoLayer)
FinCat(NeuronalActivity)

activeinference = @program ActiveInference (s::Sensation, pm::PredictiveModel) begin
  p = Predict(pm)  
  d = Comparison(s, p)
  pm_dash = Modelupdate(d, pm)
  a = Regulation(pm_dash)
  return d, pm_dash, a
end
draw(activeinference)

C_activeInference = FinCat(ActiveInference) 
C_neuronalActivity = FinCat(NeuronalActivity)

# create a functor from NeuronalActivity to ActiveInference
Sensation, PredictiveModel, Prediction, Divergence, Action = generators(ActiveInference, :Ob)
Predict, Comparison, Modelupdate, Regulation = generators(ActiveInference, :Hom)

ATP, AP_Rhythm, Entropy, EntropicTissue, OrderedTissue = generators(NeuronalActivity, :Ob)
SpikingActivity, Allostasis = generators(NeuronalActivity, :Hom)

F_ob = Dict(
    Sensation => AP_Rhythm,
    PredictiveModel => AP_Rhythm,
    Prediction => AP_Rhythm,
    Divergence => AP_Rhythm,
    Action => AP_Rhythm
)

F_hom = Dict(
    Predict => SpikingActivity,
    Comparison => SpikingActivity,
    Modelupdate => SpikingActivity,
    Regulation => SpikingActivity
)

F_activinference = FinFunctor(F_ob, F_hom, C_activeInference, C_neuronalActivity)

# note: this is an unsatisfying mapping since we are mapping everything to AP_Rhythm
# how to improve this? perhaps have a more complex neuronal layer with more structure?
# ie want a particular category for sensations, another for predictive models, etc., that
# perhaps have particular structures or networks in the brain - hippocampus for prediction, cortical layers for comparison