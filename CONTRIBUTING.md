# Contributing to MES

Thank you for your interest in contributing to MES! This document provides guidelines and workflows for contributing to the project.

## Development Setup

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR-USERNAME/mes.git
   cd mes
   ```
3. Set up development environment:
   ```julia
   using Pkg
   Pkg.develop(path=".")
   ```

## Development Workflow

### Code Changes

1. Create a new branch:
   ```bash
   git checkout -b feature-name
   ```

2. Make your changes
3. Run tests:
   ```julia
   julia --project=. test/test.jl
   ```
4. Update documentation if needed

### Documentation

Documentation is built using Documenter.jl. The documentation source files are in `docs/src/`.

To build documentation locally:
```julia
cd docs
julia --project=. make.jl
```

Documentation sections:
- `src/index.md`: Main page
- `src/theory/`: Theory and concepts
- `src/examples/`: Usage examples
- `src/api/`: API reference

### Commit Guidelines

- Use clear, descriptive commit messages
- Include related issue numbers if applicable
- Keep commits focused and atomic

### Pull Request Process

1. Update documentation for new features
2. Ensure all tests pass
3. Update `NEWS.md` if applicable
4. Create pull request with:
   - Clear description of changes
   - Reference to related issues
   - Screenshots for UI changes

## Documentation Structure

```
docs/
├── src/
│   ├── index.md
│   ├── theory/
│   │   ├── categories.md
│   │   └── patterns.md
│   ├── examples/
│   │   └── momat/
│   └── api/
└── make.jl
```

## Release Process

1. Update version in `Project.toml`
2. Update `NEWS.md`
3. Create a new tag:
   ```bash
   git tag v1.0.0
   git push --tags
   ```

## Questions or Problems?

- Open an issue for bugs
- Use discussions for questions and ideas
- Tag maintainers for urgent issues 