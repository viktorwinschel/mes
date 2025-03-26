@testset "Functorial Mappings" begin
    date = Date("2025-01-15")

    @testset "Micro-Macro Functor" begin
        # Create test diagram
        diagram = create_money_creation_diagram(1000.0, date)
        F = create_micro_macro_functor(diagram)

        # Test functor structure
        @test F.source_category == "Micro"
        @test F.target_category == "Macro"
        @test length(F.object_map) == length(diagram.objects)
        @test length(F.morphism_map) == length(diagram.morphisms)

        # Test object mapping
        for obj in diagram.objects
            macro_obj = F.object_map[obj]
            @test macro_obj.agent == "Macro" * obj.agent
            @test macro_obj.account == obj.account
            @test macro_obj.acc_type == obj.acc_type
        end

        # Test morphism mapping
        for morph in diagram.morphisms
            macro_morph = F.morphism_map[morph]
            @test macro_morph.source == F.object_map[morph.source]
            @test macro_morph.target == F.object_map[morph.target]
            @test macro_morph.amount == morph.amount
            @test macro_morph.date == morph.date
        end

        # Test functorial properties
        for i in 1:length(diagram.morphisms)-1
            f = diagram.morphisms[i]
            g = diagram.morphisms[i+1]
            if f.target == g.source  # If composable
                # F(g ∘ f) = F(g) ∘ F(f)
                comp = compose_morphisms(f, g)
                F_comp = F.morphism_map[comp]
                comp_F = compose_morphisms(F.morphism_map[f], F.morphism_map[g])

                @test F_comp.source == comp_F.source
                @test F_comp.target == comp_F.target
                @test F_comp.amount == comp_F.amount
            end
        end
    end

    @testset "Natural Transformations" begin
        # Create two different functors
        diagram = create_money_creation_diagram(1000.0, date)
        F = create_micro_macro_functor(diagram)
        G = create_micro_macro_functor(diagram)  # Same structure, different instance

        # Create natural transformation
        η = create_natural_transformation(F, G, diagram)

        # Test structure
        @test η.source_functor == F
        @test η.target_functor == G
        @test length(η.components) == length(diagram.objects)

        # Test naturality condition
        for morph in diagram.morphisms
            source_obj = morph.source
            target_obj = morph.target

            # Get the relevant morphisms for the naturality square
            F_morph = F.morphism_map[morph]
            G_morph = G.morphism_map[morph]
            η_source = η.components[source_obj]
            η_target = η.components[target_obj]

            # Test commutativity of naturality square
            # η_target ∘ F_morph = G_morph ∘ η_source
            path1 = compose_morphisms(F_morph, η_target)
            path2 = compose_morphisms(η_source, G_morph)

            @test path1.source == path2.source
            @test path1.target == path2.target
            @test path1.amount == path2.amount
        end
    end
end