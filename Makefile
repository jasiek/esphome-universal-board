# Makefile for generating schematic and PCB PDF and PNG plots
KICAD_CLI=/Applications/KiCad/KiCad.app/Contents/MacOS/kicad-cli

# KiCad files
SCHEMATIC := universal-board.kicad_sch
SCHEMATIC_DEPS := $(wildcard *.kicad_sch)
PCB := universal-board.kicad_pcb
OUTPUT_DIR := plots
PDF_FILE := $(OUTPUT_DIR)/universal-board-complete.pdf
SCHEMATIC_PDF := $(OUTPUT_DIR)/schematic.pdf
PNG_DIR := $(OUTPUT_DIR)/png
PNG_FILES := $(PNG_DIR)/.png_generated
DPI := 300

# PCB layers to export
PCB_LAYERS := F.Cu B.Cu F.Silkscreen B.Silkscreen Edge.Cuts
PCB_TEMP_DIR := $(OUTPUT_DIR)/temp-pcb
PCB_LAYER_SVGS := $(foreach layer,$(PCB_LAYERS),$(PCB_TEMP_DIR)/$(layer).svg)
PCB_LAYER_PDFS := $(foreach layer,$(PCB_LAYERS),$(PCB_TEMP_DIR)/$(layer).pdf)
BACKGROUND_COLOR := \#1a1a1a

# Default target
.PHONY: all
all: $(PDF_FILE) $(PNG_FILES) Makefile

# Create output directories
$(OUTPUT_DIR):
	mkdir -p $(OUTPUT_DIR)

$(PNG_DIR):
	mkdir -p $(PNG_DIR)

$(PCB_TEMP_DIR):
	mkdir -p $(PCB_TEMP_DIR)

# Generate PDF of the schematic (depends on all .kicad_sch files)
$(SCHEMATIC_PDF): $(SCHEMATIC_DEPS) | $(OUTPUT_DIR)
	$(KICAD_CLI) sch export pdf \
		--output $(SCHEMATIC_PDF) \
		$(SCHEMATIC)
	@echo "Schematic PDF generated: $(SCHEMATIC_PDF)"

# Generate individual PCB layer SVGs
$(PCB_TEMP_DIR)/%.svg: $(PCB) | $(PCB_TEMP_DIR)
	$(eval LAYER := $(notdir $(basename $@)))
	@echo "Generating $(LAYER) layer SVG..."
	$(KICAD_CLI) pcb export svg \
		--output $@ \
		--layers $(LAYER) \
		--theme _builtin_default \
		--drill-shape-opt 2 \
		--page-size-mode 2 \
		$(PCB)

# Convert SVG to PDF with dark background
$(PCB_TEMP_DIR)/%.pdf: $(PCB_TEMP_DIR)/%.svg
	$(eval LAYER := $(notdir $(basename $@)))
	@echo "Converting $(LAYER) SVG to PDF with dark background..."
	@rsvg-convert -f pdf --background-color=$(BACKGROUND_COLOR) $< -o $@

# Merge schematic and PCB layer PDFs into one multi-page PDF
$(PDF_FILE): $(SCHEMATIC_PDF) $(PCB_LAYER_PDFS) | $(OUTPUT_DIR)
	@echo "Merging schematic and PCB layer PDFs..."
	@gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile=$(PDF_FILE) \
		$(SCHEMATIC_PDF) $(PCB_LAYER_PDFS)
	@echo "Complete PDF generated: $(PDF_FILE)"

# Generate PNG images for schematic pages and PCB layers
$(PNG_FILES): $(SCHEMATIC_PDF) $(PCB_LAYER_SVGS) | $(PNG_DIR)
	@echo "Converting schematic PDF pages to PNG at $(DPI) DPI..."
	@pdftoppm -png -r $(DPI) $(SCHEMATIC_PDF) $(PNG_DIR)/schematic-page
	@echo "Converting PCB layer SVGs to PNG with dark background at $(DPI) DPI..."
	@for layer_svg in $(PCB_LAYER_SVGS); do \
		layer_name=$$(basename $$layer_svg .svg); \
		rsvg-convert -f png --background-color=$(BACKGROUND_COLOR) -d $(DPI) -p $(DPI) $$layer_svg -o $(PNG_DIR)/$$layer_name.png; \
		echo "  Generated $(PNG_DIR)/$${layer_name}.png"; \
	done
	@touch $(PNG_FILES)
	@echo "All PNG files generated in $(PNG_DIR)/"

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
	@echo "  pdf   - Generate multi-page PDF with schematic and PCB layers"
	@echo "  png   - Generate PNG images for schematic pages and PCB layers at $(DPI) DPI"
	@echo "  clean - Remove all generated files"
	@echo "  help  - Show this help message"
	@echo ""
	@echo "PCB layers included: $(PCB_LAYERS)"
