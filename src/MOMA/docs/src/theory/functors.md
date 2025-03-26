# Functorial Analysis

MOMA uses functors and natural transformations to analyze relationships between different levels of the economy (micro vs. macro).

## Micro-Macro Functor

The micro-macro functor maps financial events from the micro level to the macro level:

```julia
date = Date("2025-01-15")
diagram = create_money_creation_diagram(1000.0, date)
F = create_micro_macro_functor(diagram)
```

### Object Mapping

For each account object, the functor:
1. Prepends "Macro" to the agent name
2. Preserves the account type
3. Maintains the asset/liability classification

Example:
```julia
micro_obj = create_account_object("CB", "PaperMoney", Asset())
macro_obj = F.object_map[micro_obj]  # MacroCB:PaperMoney (Asset)
```

### Morphism Mapping

For each money flow, the functor:
1. Maps source and target accounts
2. Preserves the amount
3. Maintains the date

Example:
```julia
micro_morph = create_morphism(source, target, 1000.0, date)
macro_morph = F.morphism_map[micro_morph]
```

### Functorial Properties

The functor preserves:

1. **Composition**:
   ```julia
   # F(g ∘ f) = F(g) ∘ F(f)
   comp = compose_morphisms(f, g)
   @assert F.morphism_map[comp] == compose_morphisms(F.morphism_map[f], F.morphism_map[g])
   ```

2. **Identity**:
   ```julia
   # F(id_A) = id_F(A)
   id_morph = create_morphism(obj, obj, 0.0, date)
   F_id = F.morphism_map[id_morph]
   @assert F_id.source == F_id.target
   ```

## Natural Transformations

Natural transformations represent systematic relationships between different functors:

```julia
F = create_micro_macro_functor(diagram)
G = create_micro_macro_functor(diagram)  # Different perspective
η = create_natural_transformation(F, G, diagram)
```

### Components

For each object in the source category, a natural transformation provides:
1. A morphism between its images under F and G
2. Identity-like behavior (zero amount)
3. Compatibility with the functorial structure

Example:
```julia
obj = create_account_object("CB", "PaperMoney", Asset())
component = η.components[obj]  # Morphism: F(obj) → G(obj)
```

### Naturality

The natural transformation ensures that all diagrams commute:

```
F(A) ---F(f)--→ F(B)
  |              |
η_A ↓            ↓ η_B
  |              |
G(A) ---G(f)--→ G(B)
```

This means:
```julia
# η_B ∘ F(f) = G(f) ∘ η_A
for morph in diagram.morphisms
    path1 = compose_morphisms(F.morphism_map[morph], η.components[morph.target])
    path2 = compose_morphisms(η.components[morph.source], G.morphism_map[morph])
    @assert path1 == path2
end
```

## Applications

Functorial analysis helps:

1. **Scale Analysis**:
   - Map micro-level transactions to macro effects
   - Preserve structural relationships
   - Track system-wide impacts

2. **Multiple Perspectives**:
   - Compare different economic viewpoints
   - Verify consistency between levels
   - Identify emergent properties

3. **System Evolution**:
   - Track changes over time
   - Maintain categorical properties
   - Ensure coherent transformations

## See Also

- [Category Theory](category.md) for mathematical foundations
- [Financial Events](events.md) for event types
- [API Reference](../api/functors.md) for function details 