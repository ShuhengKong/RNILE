# RNILE R Package

This R package provides a wrapper for the NILE (Natural Language Information Extraction) Java library using rJava. NILE is designed for processing medical text and extracting structured semantic information including observations, anatomical locations, and modifiers.

## Overview

The RNILE R package converts the original Java implementation into an easy-to-use R interface, allowing R users to leverage the powerful medical NLP capabilities of NILE for:

- **Medical Entity Extraction**: Identify medical terms, conditions, and procedures
- **Anatomical Location Detection**: Extract body parts, organs, and anatomical structures  
- **Modifier Analysis**: Detect descriptive terms that modify medical observations
- **Certainty Assessment**: Determine the certainty level of medical statements
- **Negation Detection**: Identify negative statements and rule-outs

## Installation

### Prerequisites

1. **Java Runtime Environment (JRE)**: Ensure you have Java 8 or higher installed
2. **rJava package**: Install the rJava package for R-Java integration

```r
# Install rJava
install.packages("rJava")

# On some systems, you may need to configure Java
library(rJava)
.jinit()
```

### Install RNILE Package

#### Method 1: Install from Current Directory (Recommended)
```r
# Navigate to the directory containing RNILE folder, then:
install.packages(".", repos = NULL, type = "source")

# Or using absolute path:
install.packages("/path/to/RNILE", repos = NULL, type = "source")
```

#### Method 2: Using devtools
```r
# Install devtools if not already installed
install.packages("devtools")

# Install from current directory
devtools::install(".")

# Or from specific path
devtools::install("/path/to/RNILE")
```

#### Method 3: For Development/Testing (No Installation)
```r
# Load functions directly for testing
source('R/package_initialization.R')
source('R/nile_core_functions.R') 
source('R/nile_utilities.R')

# Initialize Java manually
library(rJava)
.jinit(classpath = "inst/java/NILE.jar")
```

## Quick Start

### Basic Usage

```r
library(RNILE)

# Initialize NILE with default dictionaries
nlp <- init_nile()

# Process medical text
text <- "No filling defects are seen to suggest pulmonary embolism."
result <- process_text(nlp, text)
print(result)
```

### Complete Example

```r
# Run the comprehensive example
run_nile_example()
```

## Core Functions

### Initialization
- `new_nlp()`: Create a new NLP processor
- `init_nile()`: Initialize with default dictionaries

### Dictionary Management
- `add_vocabulary(nlp, file_path, semantic_role)`: Load dictionary from file
- `add_phrase(nlp, term, code, semantic_role)`: Add individual term

### Text Processing
- `dig_text_line(nlp, text)`: Process text and return sentences
- `process_text(nlp, text)`: Process text and return R data frame

### Information Extraction
- `get_semantic_objects(sentence)`: Extract semantic objects from sentence
- `get_text(semantic_obj)`: Get text from semantic object
- `get_codes(semantic_obj)`: Get medical codes
- `get_semantic_role(semantic_obj)`: Get semantic role
- `get_certainty(semantic_obj)`: Get certainty level
- `is_family_history(semantic_obj)`: Check if family history
- `get_modifiers(semantic_obj)`: Get modifiers

### Utilities
- `print_semantic_object(obj)`: Print detailed object information
- `to_short_string(sentence)`: Get sentence summary
- `inspect_nile_classes()`: Inspect available Java classes

## Semantic Roles

NILE recognizes three main semantic roles:

1. **OBSERVATION**: Medical findings, conditions, procedures
   - Examples: "pulmonary embolism", "filling defects", "pneumonia"

2. **LOCATION**: Anatomical locations and structures
   - Examples: "right upper lobe", "pulmonary arteries", "left ventricle"

3. **MODIFIER**: Descriptive terms that modify observations
   - Examples: "acute", "bilateral", "segmental", "chronic"

## Example Outputs

### Simple Processing
```r
nlp <- init_nile()
result <- process_text(nlp, "Patient has acute pulmonary embolism in right upper lobe.")

# Result data frame:
#   sentence_id     entity_text    codes semantic_role certainty family_history
# 1           1           acute    ACUTE      MODIFIER   CERTAIN          FALSE
# 2           1 pulmonary embolism C0034065   OBSERVATION   CERTAIN          FALSE  
# 3           1   right upper lobe      RUL      LOCATION   CERTAIN          FALSE
```

### Negation Detection
```r
result <- process_text(nlp, "Rule out pulmonary embolism.")
# The system will detect "rule out" as negation context
```

### Complex Medical Text
```r
text <- "There are segmental and subsegmental filling defects in the right upper lobe."
sentences <- dig_text_line(nlp, text)
for (sentence in sentences) {
  cat(to_short_string(sentence), "\n")
}
```

## File Structure

```
shk_nile/
└── RNILE/
    ├── DESCRIPTION          # Package metadata
    ├── NAMESPACE           # Exported functions
    ├── R/                  # R source code
    │   ├── zzz.R          # JVM initialization
    │   ├── nlp_wrappers.R # Core wrapper functions
    │   ├── helpers.R      # Helper functions
    │   └── example.R      # Example code
    ├── inst/
    │   └── java/          # Java dependencies
    │       ├── NILE.jar   # Main Java library
    │       ├── dict_obs.txt
    │       ├── dict_locations.txt
    │       ├── dict_modifiers.txt
    │       └── MDD_dict.txt
    ├── tests/
    │   └── testthat/      # Unit tests
    └── man/               # Documentation (generated)
```

## Medical Dictionaries

The package includes several pre-built medical dictionaries:

- **dict_obs.txt**: Medical observations and conditions
- **dict_locations.txt**: Anatomical locations
- **dict_modifiers.txt**: Descriptive modifiers
- **MDD_dict.txt**: Extended medical terminology

### Dictionary Format
```
term|code
pulmonary embolism|C0034065
filling defect|C0332555
```

## Advanced Usage

### Custom Dictionary Loading
```r
nlp <- new_nlp()
add_vocabulary(nlp, "path/to/custom_dict.txt", "OBSERVATION")
```

### Detailed Object Analysis
```r
nlp <- init_nile()
sentences <- dig_text_line(nlp, "Complex medical text here...")
semantic_objs <- get_semantic_objects(sentences[[1]])

for (obj in semantic_objs) {
  print_semantic_object(obj)
}
```

### Modifier Relationships
```r
# Extract modifiers and their relationships
obj <- semantic_objs[[1]]
modifiers <- get_modifiers(obj)
for (mod in modifiers) {
  cat("Modifier:", get_text(mod), "- Role:", get_semantic_role(mod), "\n")
}
```

## Error Handling

The package includes comprehensive error handling:

```r
# Check if rJava is available
if (!require(rJava)) {
  stop("rJava package required")
}

# Initialize with error checking
tryCatch({
  nlp <- init_nile()
}, error = function(e) {
  message("Failed to initialize NILE: ", e$message)
})
```

## Performance Notes

- **JVM Initialization**: The Java Virtual Machine starts when the package loads
- **Memory Usage**: Large dictionaries are loaded into memory
- **Processing Speed**: Text processing speed depends on dictionary size and text complexity

## Troubleshooting

### Common Issues

1. **Java Not Found**
   ```r
   # Check Java installation
   system("java -version")
   
   # Configure Java path if needed
   Sys.setenv(JAVA_HOME="path/to/java")
   ```

2. **rJava Installation Issues**
   ```r
   # On Ubuntu/Debian
   # sudo apt-get install default-jdk r-cran-rjava
   
   # On macOS
   # brew install --cask adoptopenjdk
   ```

3. **Memory Issues with Large Texts**
   ```r
   # Increase JVM memory
   options(java.parameters = "-Xmx4g")
   library(RNILE)
   ```

## Development

### Running Tests
```r
devtools::test()
```

### Building Documentation
```r
devtools::document()
```

### Package Check
```r
devtools::check()
```

## License

This package maintains compatibility with the original NILE project licensing.

## Citation

If you use this package in your research, please cite both the original NILE project and this R implementation.

## Support

For issues related to:
- **R wrapper functionality**: Create issues in this repository
- **Core NILE algorithm**: Refer to original NILE project documentation
- **Medical terminology**: Consult medical coding standards (ICD, SNOMED CT)

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Submit a pull request

## Version History

- **1.0.0**: Initial R wrapper implementation
  - Core functionality wrapper
  - Default dictionary integration
  - Helper functions for R users
  - Comprehensive documentation and examples 