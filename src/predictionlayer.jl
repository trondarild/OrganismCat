# prediction layer, builds on neural layer

@present ActiveInference(FreeSymmetricMonoidalCategory) begin
  (Sensation, PredictiveModel, Prediction, Divergence, Action)::Ob
  # Processes
  Predict::Hom(PredictiveModel, Prediction)
  Comparison::Hom(Sensation ⊗ Prediction, Divergence)
  Modelupdate::Hom(Divergence ⊗ PredictiveModel, PredictiveModel)
  Regulation::Hom(PredictiveModel, Action)
end

