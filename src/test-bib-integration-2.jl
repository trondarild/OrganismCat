# 
# using Pkg; Pkg.add("Bibliography") 
using Catlab, Catlab.Theories, Catlab.WiringDiagrams, Catlab.Graphics
using Bibliography

@present ActiveInference(FreeSymmetricMonoidalCategory) begin
  (Sensation, PredictiveModel, Prediction, Divergence, Action)::Ob
  
  # Processes
  Predict::Hom(PredictiveModel, Prediction)
  Comparison::Hom(Sensation ⊗ Prediction, Divergence)
  Modelupdate::Hom(Divergence ⊗ PredictiveModel, PredictiveModel)
  Regulation::Hom(PredictiveModel, Action)
end

# Simulating a loaded .bib file
const bib_data = """
@article{friston2010free,
  title={The free-energy principle: a unified brain theory?},
  author={Friston, Karl},
  journal={Nature reviews neuroscience},
  year={2010}
}
@article{clark2013whatever,
  title={Whatever next? Predictive brains, situated agents, and the future of cognitive science},
  author={Clark, Andy},
  journal={Behavioral and brain sciences},
  year={2013}
}
@article{sterling2015principles,
  title={Principles of neural design},
  author={Sterling, Peter and Laughlin, Simon},
  year={2015}
}
"""
tstbibname = "tst.bib"
joinpath(@__DIR__, tstbibname) |> open

# Parse the bib file into a Dictionary
# In practice: refs = import_bibtex("my_refs.bib")
import Bibliography: import_bibtex
refs = joinpath(@__DIR__, tstbibname) |> import_bibtex

# Map the symbol of the Hom to the BibTeX key
const model_citations = Dict(
  :Predict => "friston2010free",
  :Comparison => "clark2013whatever",
  :Regulation => "sterling2015principles",
  :Sensation => "sterling2015principles"
  # :Modelupdate is left un-anchored for this example
)

# function draw_with_citations(diagram, ref_db, link_map)
#   to_graphviz(diagram; 
#     labels = true,
#     cell_attrs = Dict(
#       :label => (box) -> begin
#          op_name = box.value
#          # Check if we have a citation key for this operation
#          if haskey(link_map, op_name)
#            key = link_map[op_name]
#            entry = ref_db[key]
#            # Format as "Author (Year)"
#            # Note: Bibliography.jl structures access authors as a list
#            auth = entry.authors[1].last # simplistic author fetch
#            year = entry.date.year
#            return "$(op_name)\n[$auth, $year]"
#          else
#            return string(op_name)
#          end
#       end
#     )
#   )
# end

function format_citation(entry::Bibliography.Entry)
  # Safety check: Handle missing authors
  if isempty(entry.authors)
    author_text = "Anon"
  else
    # Extract the last name of the first author
    # Note: Bibliography.jl 'authors' is a Vector of Names
    author_text = entry.authors[1].last
  end

  # Safety check: Handle missing date/year
  # Depending on the entry type, date might be missing or structured differently
  year_text = hasproperty(entry, :date) ? string(entry.date.year) : "n.d."

  return "$author_text ($year_text)"
end

# Changed ::Dict to ::AbstractDict to support OrderedDicts
function make_node_label(box_value, ref_db::AbstractDict, link_map::AbstractDict)
  # Check if this operation has a corresponding BibTeX key
  if haskey(link_map, box_value)
    key = link_map[box_value]
    
    # Check if the key actually exists in the loaded bibliography
    if haskey(ref_db, key)
      entry = ref_db[key]
      citation_text = format_citation(entry)
      return "$(box_value)\n[$citation_text]"
    else
      # Fallback if key is in map but not in .bib file
      return "$(box_value)\n[Missing Ref: $key]"
    end
  else
    # No citation mapped, return just the name
    return string(box_value)
  end
end

using Catlab.Graphics

using Catlab.Graphics

# Changed ::Dict to ::AbstractDict here as well
using Catlab.WiringDiagrams
using Catlab.Graphics
import Catlab.Graphics.Graphviz

function draw_anchored_model(diagram, ref_db::AbstractDict, link_map::AbstractDict)
  # 1. Convert to Wiring Diagram
  wd = to_wiring_diagram(diagram)
  
  # 2. Generate the basic Graphviz object
  g = to_graphviz(wd; labels=true, node_attrs=Dict(:shape=>"box", :style=>"filled", :fillcolor=>"#f0f0f0"))
  
  # 3. Post-Process: Find and Replace Labels
  for stmt in g.stmts
    if stmt isa Graphviz.Node
      # Catlab names nodes like "n1", "n2". 
      # We use Regex to grab the first sequence of digits found in the name.
      m = match(r"(\d+)", stmt.name)
      
      # If we found digits, parse them
      if !isnothing(m)
        box_id = parse(Int, m[1])
        
        # Verify this ID exists in our WiringDiagram
        if box_id > 0 && box_id <= nboxes(wd)
          # Get the operation name from the semantic model
          original_val = box(wd, box_id).value
          
          # Generate the new citation label
          new_label = make_node_label(original_val, ref_db, link_map)
          
          # Update the Graphviz node
          stmt.attrs[:label] = new_label
        else
           # This catches internal nodes (like junctions) that aren't boxes
           # println("Node $(stmt.name) is not a functional box.")
        end
      else
        println("Could not parse ID from node: ", stmt.name)
      end
    end
  end
  
  return g
end

function describe_model_latex(wiringdiagram, link_map)
  # We iterate over the boxes in the diagram to build a sentence
  descriptions = String[]
  
  for box in boxes(wiringdiagram)
    op_name = box.value
    if haskey(link_map, op_name)
      # Append the latex cite command
      bib_key = link_map[op_name]
      push!(descriptions, "The process \\texttt{$(op_name)} is performed \\cite{$(bib_key)}")
    else
      push!(descriptions, "The process \\texttt{$(op_name)} occurs")
    end
  end
  
  return join(descriptions, ", followed by ") * "."
end

# Example Usage:

# Pick a key you know exists
test_entry = refs["friston2010free"] 
println(format_citation(test_entry)) 
# Expected Output: "Friston (2010)"
# Test a mapped op
println(make_node_label(:Predict, refs, model_citations))

# Test an unmapped op
println(make_node_label(:Sensation, refs, model_citations))

# Example Usage:
# Define a process: Predict -> Comparison
process = id(generator(ActiveInference, :Sensation)) ⊗  generator(ActiveInference, :Predict) ⋅ 
    generator(ActiveInference, :Comparison) 
process |>
    to_wiring_diagram
to_graphviz(process)
# Draw it
#draw_with_citations(processb, refs, model_citations)
draw_anchored_model(process, refs, model_citations)

latex_text = describe_model_latex(process |> to_wiring_diagram, model_citations)
println(latex_text)
