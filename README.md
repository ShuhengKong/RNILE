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

### Advanced Information Extraction (NEW)
- `get_offset_start(semantic_obj)`: Get start character position
- `get_offset_end(semantic_obj)`: Get end character position
- `get_sentence(semantic_obj)`: Get parent sentence object
- `get_tokens(sentence)`: Get tokenized words from sentence
- `get_dictionary(nlp)`: Get dictionary object from NLP processor

### Object Modification (NEW)
- `set_offsets(semantic_obj, start, end)`: Set character positions
- `set_certainty(semantic_obj, certainty)`: Set certainty level
- `set_family_history(semantic_obj, flag)`: Set family history flag
- `set_sentence(semantic_obj, sentence)`: Set parent sentence

### Advanced Analysis (NEW)
- `analyze_sentence(nlp, text)`: Detailed sentence analysis with tokens
- `extract_hierarchical_semantics(nlp, text)`: Hierarchical semantic extraction
- `batch_process_texts(nlp, texts)`: Process multiple texts efficiently
- `get_available_semantic_roles()`: List all available semantic roles
- `get_available_certainty_levels()`: List all certainty levels

### Utilities
- `print_semantic_object(obj)`: Print detailed object information
- `to_short_string(sentence)`: Get sentence summary
- `inspect_nile_classes()`: Inspect available Java classes

## Semantic Roles

NILE recognizes many semantic roles for comprehensive medical text analysis:

### Primary Roles
1. **OBSERVATION**: Medical findings, conditions, procedures
   - Examples: "pulmonary embolism", "filling defects", "pneumonia"

2. **LOCATION**: Anatomical locations and structures
   - Examples: "right upper lobe", "pulmonary arteries", "left ventricle"

3. **MODIFIER**: Descriptive terms that modify observations
   - Examples: "acute", "bilateral", "segmental", "chronic"

### Extended Roles (Available in NILE)
- **NEGATOR**: Negation terms ("no", "absent", "negative")
- **SPECULATION**: Uncertainty terms ("possible", "likely", "rule out")
- **CONFIRMER**: Confirmation terms ("positive", "present", "evident")
- **CHANGE**: Change indicators ("increased", "decreased", "stable")
- **HISTORY**: Historical references ("prior", "previous", "old")
- **FAMILYHIST**: Family history indicators
- **CONJUNCTION**: Connecting words ("and", "or", "but")
- **COMPARISON**: Comparative terms ("compared to", "versus")

Use `get_available_semantic_roles()` to see all available roles.

## Certainty Levels

NILE recognizes three certainty levels:
- **YES**: Certain/definite findings
- **NO**: Negated/absent findings  
- **UNCLEAR**: Uncertain/speculative findings

Use `get_available_certainty_levels()` to retrieve these programmatically.

## Example Outputs

### Simple Processing
```r
nlp <- init_nile()
result <- process_text(nlp, "Patient has acute pulmonary embolism in right upper lobe.")

# Result data frame:
#   sentence_id     entity_text    codes semantic_role certainty family_history offset_start offset_end
# 1           1           acute    ACUTE      MODIFIER       YES          FALSE           12         17
# 2           1 pulmonary embolism C0034065   OBSERVATION       YES          FALSE           18         36  
# 3           1   right upper lobe      RUL      LOCATION       YES          FALSE           40         56
```

### Advanced Analysis
```r
# Detailed sentence analysis
analysis <- analyze_sentence(nlp, "Complex medical text here")
for (sentence in analysis) {
  cat("Tokens:", paste(sentence$tokens, collapse = ", "), "\n")
  cat("Semantic objects:", length(sentence$semantic_objects), "\n")
}

# Hierarchical semantic extraction with modifiers
hierarchical <- extract_hierarchical_semantics(nlp, text)
for (sentence in hierarchical) {
  for (semantic in sentence$semantics) {
    cat("Entity:", semantic$text, "\n")
    if (length(semantic$modifiers) > 0) {
      cat("  Modifiers:", sapply(semantic$modifiers, function(m) m$text), "\n")
    }
  }
}
```

### Batch Processing
```r
# Process multiple texts efficiently
texts <- c("Text 1...", "Text 2...", "Text 3...")
batch_result <- batch_process_texts(nlp, texts)

# Results include text_id for tracking
print(batch_result[, c("text_id", "entity_text", "semantic_role")])
```

### Working with Positions and Details
```r
sentences <- dig_text_line(nlp, text)
objects <- get_semantic_objects(sentences[[1]])
obj <- objects[[1]]

# Get detailed position information
start_pos <- get_offset_start(obj)
end_pos <- get_offset_end(obj)
entity_text <- get_text(obj)

cat("Entity '", entity_text, "' found at positions ", start_pos, "-", end_pos, "\n")

# Get sentence tokens
tokens <- get_tokens(sentences[[1]])
cat("Sentence tokens:", paste(tokens, collapse = ", "), "\n")

# Modify object properties
set_family_history(obj, TRUE)
set_certainty(obj, "UNCLEAR")
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

## Python Interface

RNILE can be used from Python through the rpy2 interface. See `Example.py` for a complete Python wrapper.

### Prerequisites
```bash
pip install rpy2 pandas
```

### Basic Python Usage
```python
from rnile_interface import RNILEInterface

# Initialize RNILE
rnile = RNILEInterface()

# Process medical text
text = "Patient has pneumonia in the right lung."
result = rnile.process_text(text)
print(result)

# Batch processing
texts = ["Text 1...", "Text 2...", "Text 3..."]
batch_result = rnile.batch_process(texts)
print(batch_result)

# Detailed analysis
analysis = rnile.analyze_sentence(text)
print(analysis)
```

### Python Interface Features
- Seamless R-Python integration via rpy2
- Pandas DataFrame output for easy analysis
- Batch processing capabilities
- Error handling and validation
- Comprehensive examples and documentation

## Complete Functionality Coverage

This R package provides **complete coverage** of all NILE Java library functions:

### Core NLP Functions ✓
- `NaturalLanguageProcessor()` → `new_nlp()`
- `addVocabulary()` → `add_vocabulary()`
- `addPhrase()` → `add_phrase()`
- `digTextLine()` → `dig_text_line()`
- `getDictionary()` → `get_dictionary()`

### Semantic Object Functions ✓
- `getText()` → `get_text()`
- `getCode()` → `get_codes()`
- `getSemanticRole()` → `get_semantic_role()`
- `getCertainty()` → `get_certainty()`
- `isFamilyHistory()` → `is_family_history()`
- `getModifiers()` → `get_modifiers()`
- `getOffsetStart()` → `get_offset_start()`
- `getOffsetEnd()` → `get_offset_end()`
- `setOffsets()` → `set_offsets()`
- `setCertainty()` → `set_certainty()`
- `setFamilyHistory()` → `set_family_history()`
- `getSentence()` → `get_sentence()`
- `setSentence()` → `set_sentence()`
- `toString()` → `sentence_to_string()` / `to_short_string()`

### Sentence Functions ✓
- `getText()` → accessible via sentence object
- `getTokens()` → `get_tokens()`
- `getSemanticObjs()` → `get_semantic_objects()`
- `toString()` → `sentence_to_string()`
- `toShortString()` → `to_short_string()`

### Enum Access ✓
- `SemanticRole` values → `get_available_semantic_roles()`
- `Certainty` values → `get_available_certainty_levels()`

### Enhanced R-Specific Functions
- `init_nile()`: Convenient initialization with default dictionaries
- `process_text()`: Returns R data.frame for easy analysis
- `analyze_sentence()`: Detailed sentence analysis
- `extract_hierarchical_semantics()`: Preserves modifier relationships
- `batch_process_texts()`: Efficient multi-text processing
- `print_semantic_object()`: Recursive object printing
- Python interface via rpy2

## Version History

- **1.0.0**: Initial R wrapper implementation
  - Core functionality wrapper
  - Default dictionary integration
  - Helper functions for R users
  - Comprehensive documentation and examples

- **1.1.0**: Complete NILE functionality coverage
  - All NILE Java methods now wrapped in R
  - Position offset functions (`get_offset_start`, `get_offset_end`, `set_offsets`)
  - Object modification functions (`set_certainty`, `set_family_history`)
  - Sentence relationship functions (`get_sentence`, `set_sentence`)
  - Token extraction (`get_tokens`)
  - Dictionary access (`get_dictionary`)
  - Enum value access (`get_available_semantic_roles`, `get_available_certainty_levels`)
  - Advanced analysis functions (`analyze_sentence`, `extract_hierarchical_semantics`)
  - Batch processing (`batch_process_texts`)
  - Python interface via rpy2 (`Example.py`)
  - Enhanced documentation and examples
  - Complete test coverage in `Example.R`

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