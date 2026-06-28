# holism.jl
# Functor-theoretic models of holism and complexification between biological levels.
#
# Two complementary frameworks, serving different functions:
#
#   BBD functor classification  (Dewar, Fletcher & Hudetz 2019, §4)
#     Diagnoses an inter-level map by what it forgets (stuff / structure /
#     properties). Complexification = faithful inclusion that forgets stuff
#     (emergent objects) and structure (integration morphisms).
#
#   Colimit construction  (Memex wiki: Complexification process, category theory)
#     Explains how emergent objects arise: each is the colimit of a diagram of
#     lower-level components; the cocone maps become the integration morphisms.
#     The wiki's "successive binding to colimits" produces exactly the kind of
#     inter-level map that BBD then labels complexification.
#
# The two frameworks compose: colimit construction → produces the higher-level
# category; BBD classification → characterises the resulting inclusion functor.

using Catlab
using Catlab.WiringDiagrams
using Catlab.Graphics
using Bibliography
include(joinpath(@__DIR__, "common.jl"))

# ═══════════════════════════════════════════════════════════════════════════════
# I. BBD FUNCTOR CLASSIFICATION
# ═══════════════════════════════════════════════════════════════════════════════

# A functor F: C → D between levels forgets:
#   stuff      when ¬ essentially surjective: objects in D have no C-realizer
#   structure  when ¬ full: morphisms in D have no C-correlate
#   properties when ¬ faithful: distinct C-morphisms collapse in D

struct FunctorClass
    forgets_stuff::Bool        # emergent objects in target
    forgets_structure::Bool    # novel morphisms in target
    forgets_properties::Bool   # distinct morphisms collapse
end

function Base.show(io::IO, fc::FunctorClass)
    labels = String[]
    fc.forgets_stuff      && push!(labels, "stuff (emergent objects)")
    fc.forgets_structure  && push!(labels, "structure (novel morphisms)")
    fc.forgets_properties && push!(labels, "properties (integration/abstraction)")
    isempty(labels) ? print(io, "forgets nothing (equivalence)") :
                      print(io, "forgets: ", join(labels, "; "))
end

function holism_type(fc::FunctorClass)::Symbol
    fc.forgets_stuff && !fc.forgets_properties  && return :complexification
    fc.forgets_stuff &&  fc.forgets_properties  && return :holism_with_integration
    !fc.forgets_stuff && fc.forgets_structure   && return :supervenience
    !fc.forgets_stuff && fc.forgets_properties  && return :abstraction
    !fc.forgets_stuff && !fc.forgets_structure &&
        !fc.forgets_properties                  && return :equivalence
    return :mixed
end

# For free SMCs from @present, essential surjectivity = surjectivity on generators.
function classify_functor(F_ob::Dict, F_hom::Dict, src_pres, tgt_pres)
    src_obs  = generators(src_pres, :Ob)
    tgt_obs  = generators(tgt_pres, :Ob)
    src_homs = generators(src_pres, :Hom)
    tgt_homs = generators(tgt_pres, :Hom)

    ob_image  = Set(values(F_ob))
    hom_vals  = collect(values(F_hom))

    forgets_stuff      = !all(d ∈ ob_image for d ∈ tgt_obs)
    forgets_properties = length(unique(hom_vals)) < length(hom_vals)
    forgets_structure  = !isempty(tgt_homs) &&
                         !all(any(haskey(F_hom, h) && F_hom[h] == d_h
                                  for h ∈ src_homs)
                              for d_h ∈ tgt_homs)

    emergent_obs  = filter(d   -> d ∉ ob_image,        tgt_obs)
    emergent_homs = filter(d_h -> d_h ∉ Set(hom_vals), tgt_homs)

    FunctorClass(forgets_stuff, forgets_structure, forgets_properties),
    emergent_obs, emergent_homs
end

# Typed inter-level functor wrappers.
# Note: Catlab's FinFunctor does not support FreeSymmetricMonoidalCategory
# FinCats in the current version; maps are stored as plain Dicts.

struct ComplexificationFunctor
    ob_map::Dict
    hom_map::Dict
    emergent_objects::Vector
    integration_morphisms::Vector
    classification::FunctorClass
end

struct ReductionFunctor
    ob_map::Dict
    hom_map::Dict
    collapsed_hom_pairs::Vector
    classification::FunctorClass
end

function Base.show(io::IO, f::ComplexificationFunctor)
    println(io, "ComplexificationFunctor  [", holism_type(f.classification), "]")
    println(io, "  ", f.classification)
    println(io, "  emergent objects: ",
                isempty(f.emergent_objects) ? "(none)" :
                join(string.(f.emergent_objects), ", "))
    print(io,   "  integration morphisms: ",
                isempty(f.integration_morphisms) ? "(none)" :
                join(string.(f.integration_morphisms), ", "))
end

function Base.show(io::IO, f::ReductionFunctor)
    println(io, "ReductionFunctor  [", holism_type(f.classification), "]")
    println(io, "  ", f.classification)
    print(io,   "  collapsed pairs: ",
                isempty(f.collapsed_hom_pairs) ? "(none)" :
                join(("$(a) ≡ $(b)" for (a, b) ∈ f.collapsed_hom_pairs), "; "))
end

function make_complexification(F_ob, F_hom, src_pres, tgt_pres)
    fc, emergent_obs, emergent_homs = classify_functor(F_ob, F_hom, src_pres, tgt_pres)
    @assert fc.forgets_stuff "Complexification requires emergent objects"
    @assert !fc.forgets_properties "Complexification must be faithful"
    ComplexificationFunctor(F_ob, F_hom, emergent_obs, emergent_homs, fc)
end

function make_reduction(F_ob, F_hom, src_pres, tgt_pres)
    fc, _, _ = classify_functor(F_ob, F_hom, src_pres, tgt_pres)
    src_homs = generators(src_pres, :Hom)
    collapsed = [(src_homs[i], src_homs[j])
                 for i ∈ 1:length(src_homs)
                 for j ∈ (i+1):length(src_homs)
                 if haskey(F_hom, src_homs[i]) && haskey(F_hom, src_homs[j]) &&
                    F_hom[src_homs[i]] == F_hom[src_homs[j]]]
    ReductionFunctor(F_ob, F_hom, collapsed, fc)
end

# ═══════════════════════════════════════════════════════════════════════════════
# II. COLIMIT CONSTRUCTION
# ═══════════════════════════════════════════════════════════════════════════════

# A Pattern is a typed diagram: nodes typed by generators of some source
# presentation, edges typed by morphisms between them.
struct Pattern
    name::Symbol
    node_types::Vector           # one generator per node
    edges::Vector{Tuple{Int,Int,Any}}  # (src_node, tgt_node, morphism)
end

# A ColimitWitness records the apex and cocone maps of a particular colimit.
# The universal property is: any other cocone factors uniquely through this one.
struct ColimitWitness
    pattern::Pattern
    apex                         # the colimit object (generator in target pres)
    cocone_maps::Vector{Tuple{Int,Any}}  # (node_idx, map to apex)
end

function Base.show(io::IO, cw::ColimitWitness)
    println(io, "ColimitWitness [", cw.pattern.name, " → ", cw.apex, "]")
    for (i, m) ∈ cw.cocone_maps
        println(io, "  node $i (", cw.pattern.node_types[i], ") ──$(m)──▶ ", cw.apex)
    end
end

# Verify that a colimit witness is consistent with the BBD complexification
# classification of a given inclusion functor:
#   - the apex must be an emergent object (in tgt but not in image of ι_ob)
#   - every cocone map must be an integration morphism (in tgt but not in image of ι_hom)
function verify_bbd(cw::ColimitWitness, ι_ob::Dict, ι_hom::Dict, src_pres, tgt_pres)
    fc, emergent_obs, emergent_homs = classify_functor(ι_ob, ι_hom, src_pres, tgt_pres)
    emergent_set = Set(emergent_obs)
    novel_set    = Set(emergent_homs)
    apex_ok  = cw.apex ∈ emergent_set
    maps_ok  = all(m ∈ novel_set for (_, m) ∈ cw.cocone_maps)
    println("  inclusion type: ", holism_type(fc), "  [", fc, "]")
    println("  apex $(cw.apex) is emergent: $apex_ok")
    println("  all cocone maps are integration morphisms: $maps_ok")
    apex_ok && maps_ok
end

# ═══════════════════════════════════════════════════════════════════════════════
# III. PRESENTATIONS
# ═══════════════════════════════════════════════════════════════════════════════

# NeuralBase — individual neuron signalling.
# FreeEnergy makes the thermodynamic constraint explicit: firing requires
# an energy gradient and produces entropy, consistent with the wiki's
# requirement that complexification needs sufficient free energy.

@present NeuralBase(FreeSymmetricMonoidalCategory) begin
    (AP_Rhythm, Entropy, FreeEnergy)::Ob
    Firing::Hom(AP_Rhythm⊗FreeEnergy, AP_Rhythm⊗Entropy)
end

# CircuitLayer — a complexification of NeuralBase.
#
# Emergent objects (no single-neuron realizer):
#   Circuit, Oscillation, SynchronyState
#
# Integration morphisms (no NeuralBase correlate; each consumes FreeEnergy
# and produces Entropy — the wiki's duality of complexification and dissipation):
#   NeuralAssembly      : neuron recruits into a circuit (oscillator coupling)
#   SynchronousOscillation : circuit enters synchronous oscillation
#   PhaseCoordination   : oscillations bind into a synchrony state
#
# Each integration morphism has type X⊗FreeEnergy → Y⊗Entropy, parallel to
# Firing, so the reduction π can collapse all of them to Firing.

@present CircuitLayer(FreeSymmetricMonoidalCategory) begin
    (AP_Rhythm, Entropy, FreeEnergy)::Ob
    Firing::Hom(AP_Rhythm⊗FreeEnergy, AP_Rhythm⊗Entropy)              # inherited
    (Circuit, Oscillation, SynchronyState)::Ob                         # emergent
    NeuralAssembly::Hom(AP_Rhythm⊗FreeEnergy, Circuit⊗Entropy)        # oscillator coupling
    SynchronousOscillation::Hom(Circuit⊗FreeEnergy, Oscillation⊗Entropy)   # circuit integration
    PhaseCoordination::Hom(Oscillation⊗FreeEnergy, SynchronyState⊗Entropy) # cross-circuit binding
end

AP_nb, Entropy_nb, FreeEnergy_nb = generators(NeuralBase, :Ob)
Firing_nb                         = generators(NeuralBase, :Hom)[1]

AP_cl, Entropy_cl, FreeEnergy_cl, Circuit_cl, Oscillation_cl, Sync_cl =
    generators(CircuitLayer, :Ob)
Firing_cl, Assembly_cl, SyncOsc_cl, Phase_cl =
    generators(CircuitLayer, :Hom)

# ─── ι: NeuralBase → CircuitLayer  (upward complexification) ─────────────────

ι_ob  = Dict(AP_nb => AP_cl, Entropy_nb => Entropy_cl, FreeEnergy_nb => FreeEnergy_cl)
ι_hom = Dict(Firing_nb => Firing_cl)

ι = make_complexification(ι_ob, ι_hom, NeuralBase, CircuitLayer)

# ─── π: CircuitLayer → NeuralBase  (downward reduction) ──────────────────────
# All integration morphisms reduce to Firing: the energy+rhythm input and
# entropy output have the same type, but the circuit-level distinctions vanish.

π_ob = Dict(
    AP_cl          => AP_nb,
    Entropy_cl     => Entropy_nb,
    FreeEnergy_cl  => FreeEnergy_nb,
    Circuit_cl     => AP_nb,
    Oscillation_cl => AP_nb,
    Sync_cl        => AP_nb,
)

π_hom = Dict(
    Firing_cl   => Firing_nb,
    Assembly_cl => Firing_nb,
    SyncOsc_cl  => Firing_nb,
    Phase_cl    => Firing_nb,
)

π = make_reduction(π_ob, π_hom, CircuitLayer, NeuralBase)

# ═══════════════════════════════════════════════════════════════════════════════
# IV. COLIMIT WITNESSES — the sequential complexification chain
# ═══════════════════════════════════════════════════════════════════════════════
#
# Each emergent object is the colimit of a diagram of components one level below.
# This realises the wiki's "successive binding to colimits" as a concrete chain:
#
#   NeuronPair  →(colimit)→  Circuit
#   CircuitPair →(colimit)→  Oscillation
#   OscPair     →(colimit)→  SynchronyState

# Step 1: two neurons coupled by Firing → Circuit
neuron_pair = Pattern(
    :NeuronPair,
    [AP_nb, AP_nb],
    [(1, 2, Firing_nb)]
)

circuit_cw = ColimitWitness(
    neuron_pair,
    Circuit_cl,
    [(1, Assembly_cl), (2, Assembly_cl)]
)

# Step 2: two circuits coupled by SynchronousOscillation → Oscillation
circuit_pair = Pattern(
    :CircuitPair,
    [Circuit_cl, Circuit_cl],
    [(1, 2, SyncOsc_cl)]
)

oscillation_cw = ColimitWitness(
    circuit_pair,
    Oscillation_cl,
    [(1, SyncOsc_cl), (2, SyncOsc_cl)]
)

# Step 3: two oscillations coupled by PhaseCoordination → SynchronyState
osc_pair = Pattern(
    :OscillationPair,
    [Oscillation_cl, Oscillation_cl],
    [(1, 2, Phase_cl)]
)

synchrony_cw = ColimitWitness(
    osc_pair,
    Sync_cl,
    [(1, Phase_cl), (2, Phase_cl)]
)

# ═══════════════════════════════════════════════════════════════════════════════
# V. OUTPUT
# ═══════════════════════════════════════════════════════════════════════════════

println("─── BBD functor classification ───────────────────────────────────────")
println("ι: NeuralBase → CircuitLayer")
println(ι)
println()
println("π: CircuitLayer → NeuralBase")
println(π)

println()
println("─── Colimit construction ─────────────────────────────────────────────")
println("Step 1: ", circuit_cw)
println("Step 2: ", oscillation_cw)
println("Step 3: ", synchrony_cw)

println()
println("─── BBD verification of colimit apex and cocone maps (task 2) ────────")
println("Circuit colimit vs ι:")
ok = verify_bbd(circuit_cw, ι_ob, ι_hom, NeuralBase, CircuitLayer)
println("  consistent: $ok")
