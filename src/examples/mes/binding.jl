"""
Binding Examples from MES Book

These examples demonstrate:
- Pattern binding
- Synchronous patterns
- Memory formation
"""

using MES

# Example 1: Pattern binding
function example_pattern_binding()
    # Create a category of neurons
    neurons = create_category(
        ["n1", "n2", "n3", "n4"],
        Dict(
            ("n1", "n2") => ["s12"],
            ("n2", "n3") => ["s23"],
            ("n3", "n4") => ["s34"]
        )
    )

    # Create a synchronous pattern
    pattern = create_pattern(
        neurons,
        ["n1", "n2", "n3"],
        [("n1", "n2"), ("n2", "n3")]
    )

    # Calculate binding
    binding = calculate_colimit(pattern)

    return neurons, pattern, binding
end

# Example 2: Memory formation
function example_memory_formation()
    # Create memory component
    memory = create_memory_component(5, 0.2)  # Capacity 5, decay rate 0.2

    # Create patterns to store
    patterns = [
        Dict("neurons" => ["n1", "n2"], "strength" => 0.8),
        Dict("neurons" => ["n2", "n3"], "strength" => 0.7),
        Dict("neurons" => ["n3", "n4"], "strength" => 0.6)
    ]

    # Store patterns with timestamps
    for pattern in patterns
        push!(memory.records, pattern)
        push!(memory.timestamps, Dates.now())
    end

    return memory
end

# Example 3: Pattern recognition
function example_pattern_recognition()
    # Create co-regulator
    regulator = create_co_regulator(0.6, 0.1)  # Threshold 0.6, decay rate 0.1

    # Initial activations
    activations = Dict(
        "n1" => 0.9,
        "n2" => 0.8,
        "n3" => 0.7
    )

    # Update landscape
    update_landscape!(regulator, activations)

    # Second wave of activations
    new_activations = Dict(
        "n2" => 0.6,
        "n3" => 0.8,
        "n4" => 0.7
    )

    # Update landscape again
    update_landscape!(regulator, new_activations)

    return regulator
end

# Example 4: Complex binding
function example_complex_binding()
    # Create hierarchical category
    levels = Dict(
        0 => ["n1", "n2", "n3", "n4", "n5"],  # Neurons
        1 => ["P1", "P2", "P3"],              # Simple patterns
        2 => ["C1", "C2"]                     # Complex patterns
    )

    hierarchy = create_hierarchical_category(levels)

    # Add bindings for first complex
    add_binding!(hierarchy, "n1", "P1")
    add_binding!(hierarchy, "n2", "P1")
    add_binding!(hierarchy, "n2", "P2")
    add_binding!(hierarchy, "n3", "P2")
    add_binding!(hierarchy, "P1", "C1")
    add_binding!(hierarchy, "P2", "C1")

    # Add bindings for second complex
    add_binding!(hierarchy, "n3", "P3")
    add_binding!(hierarchy, "n4", "P3")
    add_binding!(hierarchy, "n5", "P3")
    add_binding!(hierarchy, "P2", "C2")
    add_binding!(hierarchy, "P3", "C2")

    return hierarchy
end

# Run all examples
function run_binding_examples()
    println("Running binding examples...")

    println("\n1. Pattern Binding:")
    neurons, pattern, binding = example_pattern_binding()
    println("Pattern objects: ", pattern.objects)
    println("Binding: ", binding)

    println("\n2. Memory Formation:")
    memory = example_memory_formation()
    println("Stored patterns: ", length(memory.records))
    println("Timestamps: ", memory.timestamps)

    println("\n3. Pattern Recognition:")
    regulator = example_pattern_recognition()
    println("Final landscape: ", regulator.landscape)

    println("\n4. Complex Binding:")
    hierarchy = example_complex_binding()
    println("Levels: ", hierarchy.levels)
    println("Bindings: ", hierarchy.bindings)
end