# TODO

## Holism / complexification
- [x] Add colimit construction to CircuitLayer: model Circuit, Oscillation, SynchronyState as colimits of neuron diagrams, with cocone maps as the integration morphisms (NeuralAssembly etc.)
- [x] Verify that the colimit-produced inclusion functor classifies as complexification under BBD (should be automatic from the universal property)
- [x] Extend holism.jl to cover the energy/dissipation axis: integration morphisms should carry free-energy input (ATP or FreeEnergy object) to reflect that complexification requires an energy gradient

## Query framework
- [ ] create a way to query the categorical structure e.g. to ask what the connection/relation is between two entities - what is X composed of (part-whole relationships)? How do x and y interact? and so on
## Testing
- [ ] create comprehensive unit test setup for all layers
- [ ] create integration test for complete organism and for social level including several organisms