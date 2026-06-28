# Modelling the inter-level map: is there a consensus?

A working note on how the literature formalises the mapping *between* levels of
description/explanation with category theory, and where OrganismCat sits within it.

## Short answer

No consensus. The field has converged on the *tool* — morphisms, and especially
functors, are agreed to be the right language for an inter-level map — but not on
the *construction*. The disagreement is substantive, not cosmetic: which
categorical gadget you reach for depends on which inter-level relation you mean.

## What everyone agrees on

- A level is an object with internal structure, not a bare set: a category of
  structures, a state space, or a dynamical system.
- The relation between levels is a structure-preserving map, chosen so that chains
  of inter-level maps compose.
- Compositionality is the payoff. A chain of locally valid maps is globally valid,
  which is what turns such a framework from a descriptive device into a generative
  and verifiable one.

## Where the works part company

Three live constructions, each answering a different question.

1. **Levels-as-categories, inter-level map as a functor.**
   Dewar, Fletcher & Hudetz (2019), extending List (2018). Each level is a
   category; supervenience or reduction is a functor between them. The refinements
   concern *which* functor: drop surjectivity for essential surjectivity, read
   reduction off Beth-style definability, classify what a map forgets via the
   forgetful-functor trichotomy (structure / properties / stuff), and use
   adjunctions where determination runs both ways. The hierarchy lives at the level
   of categories-of-categories.

2. **Systems-as-objects in one category, inter-level map as a morphism
   (span/cospan or colimit).**
   Gim (2021). A mechanism is a *diagram* in a single category: wholes are
   colimits, integrated systems are cospans, and the part–whole (constitutive)
   relation is deliberately neither a function nor causal. Marom et al. (2026) is a
   hybrid — assembly (α) and reduction (β) morphisms within one category `Dyn`,
   plus an implementation functor `F: Nat → Art` between two such hierarchies.

3. **A non-categorical cross-level operator.**
   Vélez-Cruz & Laubichler (2026). The same inter-level coupling is carried by
   state-space cross-level mappings (matrices). A reminder that category theory has
   not won the field by default; it is one bet among several.

## The crux

"The mapping between levels" is underdetermined until you say which relation you
mean:

- a **functor** is natural for supervenience and implementation (one level
  determines another);
- a **cospan or colimit** is natural for aggregation and constitution (parts
  compose into a whole), where the relation is not a function — and, on Gim's
  argument, not causal;
- an **adjunction** is natural where determination is two-way.

For *explanation* specifically (as against description), Gim's non-causal,
constitutive reading of the inter-level relation is itself contested.

## Where OrganismCat stands

The project already makes both moves, and the distinction above suggests they are
complementary rather than competing:

- **Within a layer**, processes compose via the symmetric monoidal structure and
  wiring diagrams (`@present` / `@program`). This is the camp-2 idiom — monoidal
  composition of parts, the natural home for cospans and colimits.
- **Between layers**, levels are mapped with `FinFunctor` (e.g.
  `ActiveInference → NeuronalActivity`). This is the camp-1 idiom — levels as
  categories, the inter-level map as a functor.

So the two "camps" answer different questions: how parts compose *within* a level,
versus how one level relates to another *across* levels. OrganismCat's current
design — monoidal composition inside, functors across — is a coherent synthesis,
not a fence-sit.

Open choices worth being deliberate about:

- Should the cross-layer functor be required to be *essentially surjective* rather
  than surjective (Dewar's point), so that representationally equivalent variants
  at the finer layer are allowed?
- For aggregation steps that are genuinely not functional (many fine states → one
  coarse state, with information lost), is a plain `FinFunctor` the right tool, or
  should those be modelled as cospans/colimits and only the determinate steps as
  functors? This is exactly the functor-vs-cospan tension above.
- Where a coarse layer constrains a finer one as well as the reverse, an
  **adjunction** between layers may capture more than a single functor.

## References

(All linked under `references/`.)

- Dewar, N., Fletcher, S. C., & Hudetz, L. (2019). Extending List's Levels.
  In *Category Theory in Physics, Mathematics, and Philosophy*, 63–81.
- Gim, J. (2021). *A Categorical Formalism of Mechanism* (PhD dissertation,
  Seoul National University).
- List, C. (2018). Levels: descriptive, explanatory, and ontological. *Noûs*.
- Marom, L., Tibbits, S., Zardini, G., & Buehler, M. J. (2026). A Category-Theoretic
  Framework from Biological Mechanics to Engineered Stimulus-Response Systems.
  arXiv:2604.26367.
- Vélez-Cruz, N., & Laubichler, M. (2026). The extended life cycle: a
  multilevel–multiscale modelling framework for extended evolutionary dynamics.
  *Royal Society Open Science*, 13, 251872.
