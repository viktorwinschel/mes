"""
Pattern and Colimit Examples

These examples demonstrate:
- Pattern creation in categories
- Colimit calculation
- Pattern matching and recognition
"""

using MES

# Example 1: Simple pattern with colimit
function example_simple_pattern()
    # Create a category
    category = create_category(
        ["A", "B", "C"],
        Dict(
            ("A", "B") => ["f"],
            ("B", "C") => ["g"]
        )
    )

    # Create a pattern
    pattern = create_pattern(
        category,
        ["A", "B"],
        [("A", "B")]
    )

    # Calculate colimit
    colimit = calculate_colimit(pattern)

    return category, pattern, colimit
end

# Example 2: Pattern matching
function example_pattern_matching()
    # Create a category with a known pattern
    category = create_category(
        ["X", "Y", "Z"],
        Dict(
            ("X", "Y") => ["f"],
            ("Y", "Z") => ["g"]
        )
    )

    # Define pattern to match
    pattern = create_pattern(
        category,
        ["X", "Y"],
        [("X", "Y")]
    )

    # Define target pattern
    target = create_pattern(
        category,
        ["Y", "Z"],
        [("Y", "Z")]
    )

    return category, pattern, target
end

# Example 3: Complex pattern with multiple objects
function example_complex_pattern()
    # Create a more complex category
    category = create_category(
        ["A", "B", "C", "D"],
        Dict(
            ("A", "B") => ["f"],
            ("B", "C") => ["g"],
            ("A", "D") => ["h"],
            ("C", "D") => ["i"]
        )
    )

    # Create a pattern with multiple paths
    pattern = create_pattern(
        category,
        ["A", "B", "C", "D"],
        [("A", "B"), ("B", "C"), ("A", "D"), ("C", "D")]
    )

    # Calculate colimit
    colimit = calculate_colimit(pattern)

    return category, pattern, colimit
end

# Example 4: Pattern composition
function example_pattern_composition()
    # Create a category
    category = create_category(
        ["P", "Q", "R", "S"],
        Dict(
            ("P", "Q") => ["f"],
            ("Q", "R") => ["g"],
            ("R", "S") => ["h"]
        )
    )

    # Create two patterns
    pattern1 = create_pattern(
        category,
        ["P", "Q"],
        [("P", "Q")]
    )

    pattern2 = create_pattern(
        category,
        ["R", "S"],
        [("R", "S")]
    )

    # Calculate colimits
    colimit1 = calculate_colimit(pattern1)
    colimit2 = calculate_colimit(pattern2)

    return category, pattern1, pattern2, colimit1, colimit2
end

# Run all examples
function run_pattern_examples()
    println("Running pattern and colimit examples...")

    println("\n1. Simple Pattern:")
    cat, pat, col = example_simple_pattern()
    println("Pattern objects: ", pat.objects)
    println("Colimit: ", col)

    println("\n2. Pattern Matching:")
    cat, pat, target = example_pattern_matching()
    println("Pattern objects: ", pat.objects)
    println("Target objects: ", target.objects)

    println("\n3. Complex Pattern:")
    cat, pat, col = example_complex_pattern()
    println("Pattern objects: ", pat.objects)
    println("Pattern links: ", pat.links)
    println("Colimit: ", col)

    println("\n4. Pattern Composition:")
    cat, pat1, pat2, col1, col2 = example_pattern_composition()
    println("Pattern 1 colimit: ", col1)
    println("Pattern 2 colimit: ", col2)
end