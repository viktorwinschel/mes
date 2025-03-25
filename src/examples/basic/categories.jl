"""
Basic Category Theory Examples

These examples demonstrate fundamental concepts from category theory:
- Category creation and manipulation
- Functor construction
- Natural transformations
"""

using MES

# Example 1: Simple category with composition
function example_simple_category()
    # Create a category with three objects and two morphisms
    objects = ["A", "B", "C"]
    morphisms = Dict(
        ("A", "B") => ["f"],
        ("B", "C") => ["g"]
    )
    category = create_category(objects, morphisms)

    # Add a composed morphism
    add_morphism!(category, "A", "C", "h")
    compose_morphisms!(category, "f", "g", "h")

    return category
end

# Example 2: Functor between categories
function example_functor()
    # Source category
    source = create_category(
        ["X", "Y"],
        Dict(("X", "Y") => ["f"])
    )

    # Target category
    target = create_category(
        ["P", "Q"],
        Dict(("P", "Q") => ["g"])
    )

    # Create functor
    object_map = Dict("X" => "P", "Y" => "Q")
    morphism_map = Dict("f" => "g")

    return source, target, object_map, morphism_map
end

# Example 3: Natural transformation
function example_natural_transformation()
    # Two functors between the same categories
    source = create_category(
        ["A", "B"],
        Dict(("A", "B") => ["f"])
    )

    target = create_category(
        ["X", "Y"],
        Dict(("X", "Y") => ["g", "h"])
    )

    # Natural transformation components
    components = Dict(
        "A" => "α_A",  # Component at A
        "B" => "α_B"   # Component at B
    )

    return source, target, components
end

# Example 4: Adjoint functors
function example_adjoint_functors()
    # Category C
    c = create_category(
        ["A", "B"],
        Dict(("A", "B") => ["f"])
    )

    # Category D
    d = create_category(
        ["X", "Y"],
        Dict(("X", "Y") => ["g"])
    )

    # Left adjoint functor F: C → D
    f_obj = Dict("A" => "X", "B" => "Y")
    f_mor = Dict("f" => "g")

    # Right adjoint functor G: D → C
    g_obj = Dict("X" => "A", "Y" => "B")
    g_mor = Dict("g" => "f")

    return c, d, f_obj, f_mor, g_obj, g_mor
end

# Run all examples
function run_basic_examples()
    println("Running basic category theory examples...")

    println("\n1. Simple Category:")
    cat = example_simple_category()
    println("Objects: ", cat.objects)
    println("Morphisms: ", cat.morphisms)

    println("\n2. Functor:")
    src, tgt, obj_map, mor_map = example_functor()
    println("Source category: ", src.objects)
    println("Target category: ", tgt.objects)
    println("Object map: ", obj_map)

    println("\n3. Natural Transformation:")
    src, tgt, components = example_natural_transformation()
    println("Components: ", components)

    println("\n4. Adjoint Functors:")
    c, d, f_obj, f_mor, g_obj, g_mor = example_adjoint_functors()
    println("Left adjoint object map: ", f_obj)
    println("Right adjoint object map: ", g_obj)
end