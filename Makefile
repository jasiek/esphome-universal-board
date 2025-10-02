# Makefile for generating schematic PDF and PNG plots
KICAD_CLI=/Applications/KiCad/KiCad.app/Contents/MacOS/kicad-cli

# KiCad schematic files
SCHEMATIC := universal-board.kicad_sch
SCHEMATIC_DEPS := $(wildcard *.kicad_sch)
OUTPUT_DIR := plots
PDF_FILE := $(OUTPUT_DIR)/universal-board-schematic.pdf
PNG_DIR := $(OUTPUT_DIR)/png
PNG_FILES := $(PNG_DIR)/.png_generated
DPI := 200

# Default target
.PHONY: all
all: $(PDF_FILE) $(PNG_FILES)

# Create output directories
$(OUTPUT_DIR):
	mkdir -p $(OUTPUT_DIR)

$(PNG_DIR):
	mkdir -p $(PNG_DIR)

# Generate PDF of the schematic (depends on all .kicad_sch files)
$(PDF_FILE): $(SCHEMATIC_DEPS) | $(OUTPUT_DIR)
	$(KICAD_CLI) sch export pdf \
		--output $(PDF_FILE) \
		$(SCHEMATIC)
	@echo "PDF generated: $(PDF_FILE)"

# Generate PNG images for each page of the PDF
$(PNG_FILES): $(PDF_FILE) | $(PNG_DIR)
	@echo "Converting PDF pages to PNG at $(DPI) DPI..."
	@pdftoppm -png -r $(DPI) $(PDF_FILE) $(PNG_DIR)/page
	@touch $(PNG_FILES)
	@echo "PNG files generated in $(PNG_DIR)/"

# Convenience targets
.PHONY: pdf png
pdf: $(PDF_FILE)
png: $(PNG_FILES)

# Clean generated files
.PHONY: clean
clean:
	rm -rf $(OUTPUT_DIR)
	@echo "Cleaned all generated plots"

# Help target
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  all   - Generate PDF and PNG plots (default)"
	@echo "  pdf   - Generate PDF plot of schematic"
	@echo "  png   - Generate PNG images from PDF pages at $(DPI) DPI"
	@echo "  clean - Remove all generated files"
	@echo "  help  - Show this help message"
