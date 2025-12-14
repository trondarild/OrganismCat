# energy and thermodynamics layer
# input complex, energy rich molecules
# output ATP, entropy, low energy molecules
export ThermoLayer
@present ThermoLayer(FreeSymmetricMonoidalCategory) begin
  (ComplexMolecule, ATP, Entropy, LowEnergyMolecule)::Ob
  # Processes
  Metabolize::Hom(ComplexMolecule, ATP⊗Entropy⊗LowEnergyMolecule)
end 