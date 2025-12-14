# neuronal layer
# input: ATP, AP rhythms
# output: AP rhythms,

@present NeuronalActivity(FreeSymmetricMonoidalCategory) begin
  (ATP, AP_Rhythm, Entropy, EntropicTissue, OrderedTissue)::Ob
  # Processes
  SpikingActivity::Hom(ATP⊗AP_Rhythm, AP_Rhythm⊗Entropy)
  Allostasis::Hom(ATP⊗AP_Rhythm⊗EntropicTissue, Entropy⊗OrderedTissue)
end