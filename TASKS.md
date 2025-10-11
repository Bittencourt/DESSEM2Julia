# Project tasks and roadmap

This project ingests DESSEM input files (.DAT and related text files) and converts them into structured Julia objects persisted to JLD2.

## Phases

1. Foundations
   - [ ] Agree on scope, supported DESSEM version(s), and file coverage
   - [ ] Collect sample datasets of DESSEM inputs
   - [ ] Establish coding standards, test strategy, CI
   - [ ] Define core data model (types) and module layout

2. Parsers (per file type)
   - [ ] Identify all DESSEM input files and specs
   - [ ] Create a registry of parsers (filename -> handler)
   - [ ] Implement and test parsers incrementally (see Parser tasks)

3. Persistence
   - [ ] Map parsed structures to JLD2 schema
   - [ ] Implement save/load to JLD2
   - [ ] Round-trip tests (parse -> save -> load -> compare)

4. CLI / API
   - [ ] Provide a function `convert(input_dir, output_path)`
   - [ ] Add a simple CLI entry point using `julia --project` invocation

5. Documentation & Examples
   - [ ] Usage guide and examples
   - [ ] File coverage matrix and known limitations

## Parser tasks (to be broken down per file)

- Common infrastructure
  - [ ] Line/column utilities, comment stripping, section markers
  - [ ] Robust numeric parsing with locale handling (decimal comma vs dot)
  - [ ] Error reporting with file/line context
  - [ ] Property-based tests for parsers

- Initial target files (adjust based on DESSEM version)
  - [ ] DADGER.DAT
  - [ ] DECOMP-style linking files if applicable
  - [ ] HYDRE.DAT / CAD-based hydro data as applicable
  - [ ] TTERM.DAT
  - [ ] CUSTOS.DAT
  - [ ] REE/UTE related files

Add tasks as we confirm the exact file list.

## Acceptance criteria

- Parsing coverage documented and tested for all chosen files
- Deterministic output JLD2 schema with versioning
- Tests green on CI (Windows and Linux)