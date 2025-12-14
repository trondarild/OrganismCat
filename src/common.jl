# common code
export draw
# draw wiring diagrams with consistent styling
draw(d::WiringDiagram) = to_graphviz(d,
  orientation=LeftToRight,
  labels=true, label_attr=:xlabel,
  node_attrs=Graphviz.Attributes(
    :fontname => "Courier",
  ),
  edge_attrs=Graphviz.Attributes(
    :fontname => "Courier",
  )
)

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