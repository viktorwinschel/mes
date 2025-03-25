using MES

# Create a simple category with three objects and two morphisms
objects = ["A", "B", "C"]
morphisms = Dict(
    ("A", "B") => ["f"],
    ("B", "C") => ["g"]
)
category = create_category(objects, morphisms)

# Add a new morphism
add_morphism!(category, "A", "C", "h")

# Create a pattern in the category
pattern_objects = ["A", "B"]
pattern_links = [("A", "B")]
pattern = create_pattern(category, pattern_objects, pattern_links)

# Calculate the colimit
colimit_result = calculate_colimit(pattern)

# Print results
println("Category objects: ", category.objects)
println("Category morphisms: ", category.morphisms)
println("Pattern objects: ", pattern.objects)
println("Pattern links: ", pattern.links)
println("Colimit result: ", colimit_result)