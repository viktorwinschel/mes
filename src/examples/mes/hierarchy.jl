"""
Hierarchical Examples from MES Book

These examples demonstrate:
- Multiple resolution levels
- Hierarchical categories
- Complex object formation
"""

using MES

# Example 1: Multiple resolution levels
function example_multiple_resolution()
    # Create objects at different levels
    level0 = ["a1", "a2", "a3"]  # Basic elements
    level1 = ["A", "B"]          # First level complexes
    level2 = ["X"]               # Higher level complex

    # Create hierarchical category
    levels = Dict(
        0 => level0,
        1 => level1,
        2 => level2
    )

    hierarchy = create_hierarchical_category(levels)

    # Add bindings between levels
    add_binding!(hierarchy, "a1", "A")
    add_binding!(hierarchy, "a2", "A")
    add_binding!(hierarchy, "a3", "B")
    add_binding!(hierarchy, "A", "X")
    add_binding!(hierarchy, "B", "X")

    return hierarchy
end

# Example 2: Complex object formation
function example_complex_formation()
    # Create memory component
    memory = create_memory_component(10, 0.1)  # Capacity 10, decay rate 0.1

    # Create co-regulator
    regulator = create_co_regulator(0.5, 0.1)  # Threshold 0.5, decay rate 0.1

    # Simulate pattern formation
    activations = Dict(
        "a1" => 0.8,
        "a2" => 0.7,
        "a3" => 0.6
    )

    # Update landscape
    update_landscape!(regulator, activations)

    return memory, regulator
end

# Example 3: Hierarchical binding
function example_hierarchical_binding()
    # Create hierarchical category
    levels = Dict(
        0 => ["n1", "n2", "n3", "n4"],  # Neurons
        1 => ["P1", "P2"],              # Patterns
        2 => ["C"]                      # Complex
    )

    hierarchy = create_hierarchical_category(levels)

    # Add bindings
    add_binding!(hierarchy, "n1", "P1")
    add_binding!(hierarchy, "n2", "P1")
    add_binding!(hierarchy, "n3", "P2")
    add_binding!(hierarchy, "n4", "P2")
    add_binding!(hierarchy, "P1", "C")
    add_binding!(hierarchy, "P2", "C")

    return hierarchy
end

# Run all examples
function run_mes_examples()
    println("Running MES book examples...")

    println("\n1. Multiple Resolution:")
    hierarchy = example_multiple_resolution()
    println("Levels: ", hierarchy.levels)
    println("Bindings: ", hierarchy.bindings)

    println("\n2. Complex Formation:")
    memory, regulator = example_complex_formation()
    println("Landscape: ", regulator.landscape)

    println("\n3. Hierarchical Binding:")
    hierarchy = example_hierarchical_binding()
    println("Levels: ", hierarchy.levels)
    println("Bindings: ", hierarchy.bindings)
end