# API Reference

This section provides detailed documentation for the MES API.

## Core Types

```@docs
MES.Category
MES.Pattern
```

## Functions

```@docs
MES.create_category
MES.add_morphism!
MES.create_pattern
MES.calculate_colimit
```

## Other Functions

```@autodocs
Modules = [MES]
Order   = [:function]
Filter = t -> t != :create_category && t != :add_morphism! && t != :create_pattern && t != :calculate_colimit
```