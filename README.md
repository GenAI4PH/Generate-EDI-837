# Generate-EDI-837

A small Python utility to replace Protected Health Information (PHI) in ANSI X12 EDI 837 Professional (837P) files with synthetic data while preserving the EDI 5010 structure. This repository contains a proof-of-concept script (Replace_PHI.py), an example 837 file, and supporting test data.

## Features

- Parses an EDI 837P sample and replaces subscriber-level PHI (name, address, birth date, gender, subscriber ID) with synthetic values.
- Preserves EDI segment structure and segment/element separators.
- Generates synthetic diagnosis and procedure codes and plausible service dates.
- Writes a converted 837 file suitable for testing and development when PHI-free EDI data is required.

## Files of interest

- `Replace_PHI.py` - Main Python script that performs PHI replacement and creates an output EDI file.
- `Sample_837P.txt` - Example EDI 837P file used as input.
- `Subscribers.csv` - CSV with subscriber records used to inject synthetic patient demographics.
- `Proof of Concepts and project plan` / `Proof of Concept and project plan.docx` - Project planning documents and POC notes.
- `Example of Test Scenarios` / `Example test case scenarios.docx` - Example test scenarios and acceptance criteria.

## Requirements

- Python 3.8+
- No external packages required (uses Python standard library: csv, random, datetime, pathlib, os).

## Installation

Clone the repository and run the script with a Python 3 interpreter:

```bash
git clone https://github.com/GenAI4PH/Generate-EDI-837.git
cd Generate-EDI-837
python Replace_PHI.py
```

## Configuration

The script uses hard-coded UNC-style paths near the top of `Replace_PHI.py`:

```python
EDI_INPUT = r"\\Generate_EDI\Sample EDI\Sample_837P.txt"
SUBSCRIBER_CSV = r"\\Generate_EDI\Support Data\Subscribers.csv"
OUTPUT_DIR = r"\\Generate_EDI\Sample EDI\Output"
```

Before running, update these paths to point to the files and output directory on your machine. You can also modify constants controlling replacement behavior:

- `SEG_TERM` — EDI segment terminator (default `~`).
- `ELM_SEP` — EDI element separator (default `*`).
- `DIAG_CODES`, `PROC_CODES` — Lists of synthetic diagnosis/procedure codes used.
- `CHARGE_RANGE` — Tuple min/max charge values for generated service lines.

Ensure `Subscribers.csv` has at least these column headers: `LastName,FirstName,MiddleInitial,Street1,Street2,City,State,ZipCode,BirthDate,Gender` where `BirthDate` is in `YYYY-MM-DD` format.

## Usage

1. Update the file paths in `Replace_PHI.py` to match your environment.
2. Ensure `Subscribers.csv` exists and is populated with synthetic subscriber rows.
3. Run:

```bash
python Replace_PHI.py
```

The script will write `Converted_837P.txt` into `OUTPUT_DIR` and print the output path.

## Notes and limitations

- This is a proof-of-concept tool intended for generating PHI-free sample EDI files for testing and development only. It is not a full EDI parser or validator.
- The script assumes a relatively simple 837 structure and detects the subscriber loop by checking an HL segment's third/fourth element value (`22`). Complex EDI files with nested loops or non-standard formatting may not be handled correctly.
- Claim totals are recomputed from generated service line charges, but more advanced balancing (taxes, adjustments) is not implemented.
- Use with care: although this tool replaces obvious subscriber PHI fields, there may be other PHI present in other segments (e.g., pay-to, rendering provider, or free-form notes). Review converted files before sharing.

## Testing

You can verify output by comparing `Sample_837P.txt` and `Converted_837P.txt`. Look for replaced subscriber names, addresses, dates, and subscriber ID values that start with `SUB` followed by digits (e.g., `SUB123456`).

## Contributing

Contributions and improvements are welcome. If you'd like to:

- Improve parsing robustness (use a dedicated EDI parsing library)
- Add more realistic synthetic data generation
- Add automated tests

Open an issue or submit a pull request describing your change.

## License

This repository does not include a license file. If you plan to share or accept contributions, add a LICENSE (for example, MIT or Apache-2.0).

## Contact

Maintainer: GenAI4PH (GitHub user)

