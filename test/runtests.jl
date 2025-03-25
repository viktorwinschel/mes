using Test
using MES

@testset "MES.jl" begin
    @testset "Category Operations" begin
        # Test category creation
        objects = ["A", "B", "C"]
        morphisms = Dict(
            ("A", "B") => ["f"],
            ("B", "C") => ["g"]
        )
        category = create_category(objects, morphisms)

        @test category.objects == objects
        @test category.morphisms == morphisms
        @test isempty(category.composition)

        # Test adding morphisms
        add_morphism!(category, "A", "C", "h")
        @test "h" in category.morphisms[("A", "C")]

        # Test pattern creation
        pattern = create_pattern(category, ["A", "B"], [("A", "B")])
        @test pattern.objects == ["A", "B"]
        @test pattern.links == [("A", "B")]
        @test pattern.category == category

        # Test colimit calculation
        colimit = calculate_colimit(pattern)
        @test haskey(colimit, "object")
        @test haskey(colimit, "morphisms")
        @test length(colimit["morphisms"]) == 2  # One for each object in pattern
    end

    @testset "Pattern Operations" begin
        # Create a test category
        category = create_category(
            ["X", "Y", "Z"],
            Dict(
                ("X", "Y") => ["f"],
                ("Y", "Z") => ["g"]
            )
        )

        # Test pattern creation
        pattern = create_pattern(category, ["X", "Y"], [("X", "Y")])
        @test pattern.category == category
        @test pattern.objects == ["X", "Y"]
        @test pattern.links == [("X", "Y")]

        # Test colimit calculation
        colimit = calculate_colimit(pattern)
        @test startswith(colimit["object"], "Colimit_")
        @test length(colimit["morphisms"]) == 2
    end

    @testset "Edge Cases" begin
        # Test empty category
        empty_category = create_category(String[], Dict{Tuple{String,String},Vector{String}}())
        @test isempty(empty_category.objects)
        @test isempty(empty_category.morphisms)

        # Test pattern with no links
        pattern = create_pattern(empty_category, String[], Tuple{String,String}[])
        @test isempty(pattern.objects)
        @test isempty(pattern.links)

        # Test colimit of empty pattern
        colimit = calculate_colimit(pattern)
        @test haskey(colimit, "object")
        @test isempty(colimit["morphisms"])
    end
end