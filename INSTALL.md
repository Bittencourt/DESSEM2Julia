# Installation Guide

This guide covers multiple ways to install the DESSEM2Julia package for parsing DESSEM data files.

## Table of Contents

- [Requirements](#requirements)
- [Installation Options](#installation-options)
  - [Option 1: Install from GitHub (Recommended)](#option-1-install-from-github-recommended)
  - [Option 2: Install from General Registry](#option-2-install-from-general-registry)
  - [Option 3: Development Mode](#option-3-development-mode)
  - [Option 4: Local Installation](#option-4-local-installation)
- [Dependencies](#dependencies)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)
- [Next Steps](#next-steps)

---

## Requirements

- **Julia Version**: 1.6, 1.7, or 1.8
- **Operating System**: Windows, macOS, or Linux
- **Internet Connection**: Required for downloading dependencies

---

## Installation Options

### Option 1: Install from GitHub (Recommended)

Install the latest development version directly from GitHub:

```julia
using Pkg
Pkg.add(url="https://github.com/Bittencourt/DESSEM2Julia.jl")
```

Or using the package mode in the REPL (press `]` to enter):

```julia
add https://github.com/Bittencourt/DESSEM2Julia.jl
```

**Advantages**:
- Access to the latest features and bug fixes
- No registration required
- Direct from the source repository

---

### Option 2: Install from General Registry

Once the package is registered in Julia's General Registry, you can install it with:

```julia
using Pkg
Pkg.add("DESSEM2Julia")
```

Or in package mode:

```julia
add DESSEM2Julia
```

**Note**: Check the [README.md](README.md) for registration status.

---

### Option 3: Development Mode

For contributors or users who want to modify the package, development mode is recommended:

1. **Clone the repository**:

```bash
git clone https://github.com/Bittencourt/DESSEM2Julia.jl.git
cd DESSEM2Julia.jl
```

2. **Activate development mode in Julia**:

```julia
using Pkg
Pkg.develop(PackageSpec(path="C:\\Users\\pedro\\programming\\DSc\\DESSEM2Julia"))
```

Or in package mode:

```julia
dev C:\\Users\\pedro\\programming\\DSc\\DESSEM2Julia
```

**Advantages**:
- Changes to the source code are immediately reflected
- Ideal for development and testing
- No need to reinstall after making changes

---

### Option 4: Local Installation

Install the package from a local directory without Git tracking:

1. **Download or extract the package** to your local machine

2. **Install from local path**:

```julia
using Pkg
Pkg.add(PackageSpec(path="C:\\path\\to\\DESSEM2Julia"))
```

Or in package mode:

```julia
add C:\\path\\to\\DESSEM2Julia
```

**Use Case**: When you have a local copy but don't need development mode

---

## Dependencies

DESSEM2Julia automatically installs the following dependencies:

| Package | Version | Purpose |
|---------|---------|---------|
| **Colors** | 0.12 | Color utilities for visualization |
| **Compose** | 0.9 | Graphics composition for network diagrams |
| **GraphPlot** | 0.5, 0.6 | Network topology visualization |
| **Graphs** | 1.8, 1.9, 1.10, 1.11 | Graph data structures |
| **JLD2** | 0.4, 0.5 | Fast data serialization/storage |

### Standard Library Dependencies

These are included with Julia and don't require installation:

- **Dates**: Date and time handling
- **Printf**: Formatted output

---

## Verification

After installation, verify that the package is working correctly:

### 1. Check Package Installation

```julia
using Pkg
Pkg.status("DESSEM2Julia")
```

Expected output:
```
    Status `~/.julia/environments/v1.x/Project.toml`
  [5b3a2f8f] DESSEM2Julia v0.1.0
```

### 2. Test Basic Functionality

```julia
using DESSEM2Julia

# Test the greet function
greet()
# Output: "Hello, DESSEM2Julia!"

# Test a parser (if you have DESSEM data files)
# termdat = parse_termdat("path/to/TERMDAT.DAT")
```

### 3. Run Full Test Suite

If you installed in development mode or have the source:

```julia
using Pkg
Pkg.test("DESSEM2Julia")
```

Expected output:
```
Testing DESSEM2Julia
     Testing Running tests...
      Status `C:\...\test\Project.toml`
  ...
Test Summary: | Pass  Total  Time
...
      Testing DESSEM2Julia tests passed
```

### 4. Verify Parser Exports

Check that all exported functions are available:

```julia
using DESSEM2Julia

# List exported functions
names(DESSEM2Julia)
```

Expected exports include:
- `parse_termdat`
- `parse_entdados`
- `parse_operut`
- `parse_dadvaz`
- `greet`
- And 28 more parsers

---

## Troubleshooting

### Issue: Package Not Found

**Error**: `ERROR: ArgumentError: Package DESSEM2Julia not found in registry`

**Solution**:
- Ensure you're using Julia 1.6 or later
- Try installing from GitHub instead: `Pkg.add(url="https://github.com/Bittencourt/DESSEM2Julia.jl")`

### Issue: Dependency Conflicts

**Error**: `ERROR: Unsatisfiable requirements detected`

**Solution**:
- Update your Julia environment: `Pkg.update()`
- Ensure Julia version compatibility (1.6-1.8)
- Check for conflicting packages in your environment

### Issue: GraphPlot/Graphs Version Conflict

**Error**: Version mismatch between GraphPlot and Graphs

**Solution**:
- Manually specify compatible versions:
```julia
Pkg.add(PackageSpec(name="Graphs", version="1.9"))
Pkg.add(PackageSpec(name="GraphPlot", version="0.5"))
```

### Issue: Cannot Activate Development Mode

**Error**: Path not recognized

**Solution**:
- Use forward slashes or raw strings: `Pkg.develop(PackageSpec(path=raw"C:\Users\pedro\programming\DSc\DESSEM2Julia"))`
- Verify the path exists: `isdir("C:\\Users\\pedro\\programming\\DSc\\DESSEM2Julia")`

### Issue: Tests Fail After Installation

**Solution**:
- Ensure you're in the correct Julia environment
- Try reinstalling: `Pkg.build("DESSEM2Julia")`
- Check test data files are present in the repository

---

## Next Steps

After successful installation:

1. **Read the [README.md](README.md)** for project overview and quick start
2. **Explore the [Quick Start Guide](docs/planning/QUICK_START_GUIDE.md)** for hands-on examples
3. **Check the [Entity Relationships](docs/ENTITY_RELATIONSHIPS.md)** for data model understanding
4. **Run the examples** in the `examples/` directory:
   ```bash
   julia examples/parse_sample_case.jl
   ```
5. **Browse the documentation**:
   - [Documentation Hub](docs/README.md)
   - [File Formats](docs/file_formats.md)
   - [Type System](docs/type_system.md)

---

## Getting Help

If you encounter issues not covered here:

1. **Check existing documentation** in the `docs/` directory
2. **Review GitHub Issues**: https://github.com/Bittencourt/DESSEM2Julia.jl/issues
3. **Open a new issue** with:
   - Julia version (`VERSION`)
   - Package version (`Pkg.status()`)
   - Full error message and stack trace
   - Minimal reproducible example

---

## Additional Resources

- **DESSEM Documentation**: See [DESSEM Format Specifications](docs/dessem-complete-specs.md)
- **Parser Implementation Guides**: [docs/parsers/](docs/parsers/)
- **Example Scripts**: [examples/README.md](examples/README.md)
- **Project Structure**: [docs/REPOSITORY_STRUCTURE.md](docs/REPOSITORY_STRUCTURE.md)

---

**Last Updated**: 2026-01-09

**Package Version**: 0.1.0

**Julia Compatibility**: 1.6, 1.7, 1.8
