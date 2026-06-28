# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

OrganismCat models multiple levels of biological cognition and physiology using applied category theory in Julia. Each biological level is represented as a symmetric monoidal category (SMC) using Catlab.jl's `@present` macro, and processes are composed into wiring diagrams with `@program`.

## Running Code

There is no formal package structure or test suite yet. Files are run as standalone Julia scripts:

```julia
# Run a layer file directly
julia src/organismlayer.jl

# Or interactively in a Julia REPL
include("src/organismlayer.jl")
```

Key dependencies (install via Pkg if missing):
```julia
using Pkg
Pkg.add(["Catlab", "Bibliography"])
```

## Architecture

The project is organized as a hierarchy of biological levels, each defined as a separate file:

| Layer | File | Status | Description |
|-------|------|--------|-------------|
| Thermodynamic | `thermolayer.jl` | Done | Metabolic energy (ComplexMolecule → ATP⊗Entropy) |
| Neuronal | `neuronallayer.jl` | Done | Spiking activity and allostasis |
| Circuit | `circuitlayer.jl` | TODO | Neural circuit motifs |
| Network | `networklayer.jl` | TODO | Sensation, perception, memory, attention |
| Prediction | `predictionlayer.jl` | Done | Active inference / predictive processing |
| Organ | `organlayer.jl` | TODO | Organ-level interactions |
| Organ System | `organsystemlayer.jl` | TODO | Cross-system physiology |
| Organism | `organismlayer.jl` | Partial | Composes thermo + neuronal + prediction layers |
| Social | `sociallevel.jl` | TODO | Social entities and interactions |
| Societal | `societallevel.jl` | TODO | Societal structures and dynamics |
| Environment | `environmentlevel.jl` | TODO | Organism-environment interactions |

**`organismlayer.jl`** is the main composition file — it `include()`s the lower-level layers and constructs `FinFunctor` mappings between them (e.g., mapping `ActiveInference` → `NeuronalActivity`).

**`common.jl`** provides shared utilities: `draw()` for styled wiring diagrams, and `draw_anchored_model()` / `describe_model_latex()` for citation-annotated diagrams (integrates with Bibliography.jl).

## Key Catlab Patterns

**Defining a layer** (symmetric monoidal category):
```julia
@present ThermoLayer(FreeSymmetricMonoidalCategory) begin
  (ComplexMolecule, ATP, Entropy)::Ob
  Metabolize::Hom(ComplexMolecule, ATP⊗Entropy)
end
```

**Composing processes** into a wiring diagram:
```julia
process = @program ThermoLayer (c::ComplexMolecule) begin
  a, e, l = Metabolize(c)
  return a, e, l
end
draw(process)
```

**Mapping between levels** with a functor:
```julia
F = FinFunctor(F_ob, F_hom, C_source, C_target)
```

## Citation Integration

`common.jl` supports anchoring wiring diagram nodes to BibTeX citations:
- `refs = import_bibtex("references/organismcat_refs.bib")` loads the bibliography
- `link_map` is a `Dict` mapping morphism symbols (e.g., `:Predict`) to BibTeX keys
- `draw_anchored_model(diagram, refs, link_map)` renders diagrams with "Author (Year)" labels
- `describe_model_latex(wd, link_map)` generates LaTeX prose with `\cite{}` commands
