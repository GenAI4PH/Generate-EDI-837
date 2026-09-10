---
name: generate-synthea-files
description: Generate synthetic Synthea CSV files for one or more U.S. states using an optional patient count, state list, and random seed. Use when the user asks to generate patient, claims-support, or Synthea source files for this EDI 837 project.
---

# Generate Synthea Files

Run the bundled PowerShell generator from the repository root:

```powershell
& .\.Claude\skills\generate-synthea-files\scripts\generate-synthea-files.ps1
```

Accept these user inputs:

- `PatientCount`: number of patients to generate **per state**. Default: `1`.
- `State`: one postal abbreviation, a comma-separated list, or `All`. Default: `VA`.
- `Seed`: integer random seed. Default: `1`.

Pass supplied values as named parameters. Examples:

```powershell
& .\.Claude\skills\generate-synthea-files\scripts\generate-synthea-files.ps1 -PatientCount 10 -State VA -Seed 42
& .\.Claude\skills\generate-synthea-files\scripts\generate-synthea-files.ps1 -PatientCount 5 -State 'VA,NJ,CA, NY' -Seed 100
& .\.Claude\skills\generate-synthea-files\scripts\generate-synthea-files.ps1 -PatientCount 2 -State All
```

If the user omits an input, do not ask for it; use the default. Treat state abbreviations case-insensitively and allow whitespace around commas. `All` means all 50 U.S. states. Do not silently ignore invalid state values: report the validation error and show the accepted format.

The script writes all state results from one invocation into a timestamped directory under `generated/`. After it completes, report the output directory, requested patients per state, states processed, seed, and actual patient row count. If generation fails, report the failing state and retain the partial output for diagnosis.
