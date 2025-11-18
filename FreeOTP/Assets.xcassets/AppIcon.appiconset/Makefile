# The source image must be present in the same directory
SOURCE_IMAGE = store_ticks_enhanced.png

# List all generated icon files
TARGETS = \
    40-2.png 60.png icon58.png 87.png icon80.png 120.png icon120.png icon180.png \
    20.png 40.png 29.png 58.png 40-1.png 80.png icon76.png 152.png 167.png

# --- Default Target ---
.PHONY: all
all: $(TARGETS)
	@echo "All iOS icons created/updated successfully from $(SOURCE_IMAGE)"

# --- Individual Rules for App Icon Sizes ---
# Use the automatic variables:
# $< is the first prerequisite (SOURCE_IMAGE)
# $@ is the target name (e.g., 40-2.png)
CONVERT_CMD = convert $< -filter Lanczos -resize 

# iPhone App Icons
40-2.png: $(SOURCE_IMAGE)
	@echo "Creating iPhone 20pt @2x ($@)"
	$(CONVERT_CMD) 40x40 $@

60.png: $(SOURCE_IMAGE)
	@echo "Creating iPhone 20pt @3x ($@)"
	$(CONVERT_CMD) 60x60 $@

icon58.png: $(SOURCE_IMAGE)
	@echo "Creating iPhone 29pt @2x ($@)"
	$(CONVERT_CMD) 58x58 $@

87.png: $(SOURCE_IMAGE)
	@echo "Creating iPhone 29pt @3x ($@)"
	$(CONVERT_CMD) 87x87 $@

icon80.png: $(SOURCE_IMAGE)
	@echo "Creating iPhone 40pt @2x ($@)"
	$(CONVERT_CMD) 80x80 $@

120.png: $(SOURCE_IMAGE)
	@echo "Creating iPhone 40pt @3x ($@)"
	$(CONVERT_CMD) 120x120 $@

icon120.png: $(SOURCE_IMAGE)
	@echo "Creating iPhone 60pt @2x ($@)"
	$(CONVERT_CMD) 120x120 $@

icon180.png: $(SOURCE_IMAGE)
	@echo "Creating iPhone 60pt @3x ($@)"
	$(CONVERT_CMD) 180x180 $@

# iPad App Icons
20.png: $(SOURCE_IMAGE)
	@echo "Creating iPad 20pt @1x ($@)"
	$(CONVERT_CMD) 20x20 $@

40.png: $(SOURCE_IMAGE)
	@echo "Creating iPad 20pt @2x ($@)"
	$(CONVERT_CMD) 40x40 $@

29.png: $(SOURCE_IMAGE)
	@echo "Creating iPad 29pt @1x ($@)"
	$(CONVERT_CMD) 29x29 $@

58.png: $(SOURCE_IMAGE)
	@echo "Creating iPad 29pt @2x ($@)"
	$(CONVERT_CMD) 58x58 $@

40-1.png: $(SOURCE_IMAGE)
	@echo "Creating iPad 40pt @1x ($@)"
	$(CONVERT_CMD) 40x40 $@

80.png: $(SOURCE_IMAGE)
	@echo "Creating iPad 40pt @2x ($@)"
	$(CONVERT_CMD) 80x80 $@

icon76.png: $(SOURCE_IMAGE)
	@echo "Creating iPad 76pt @1x ($@)"
	$(CONVERT_CMD) 76x76 $@

152.png: $(SOURCE_IMAGE)
	@echo "Creating iPad 76pt @2x ($@)"
	$(CONVERT_CMD) 152x152 $@

167.png: $(SOURCE_IMAGE)
	@echo "Creating iPad 83.5pt @2x ($@)"
	$(CONVERT_CMD) 167x167 $@

# iOS Marketing Icon (optional/manual)
# Note: You would typically run this separately if your source isn't 1024x1024 already.
# store.png: $(SOURCE_IMAGE)
# 	@echo "Creating 1024x1024 App Store Icon (store.png)"
# 	$(CONVERT_CMD) 1024x1024 $@

# --- Cleanup Target ---
.PHONY: clean
clean:
	@echo "Cleaning up generated icon files..."
	-rm -f $(TARGETS)
