.PHONY: all engine app bundle clean test run

BUILD_DIR := build
APP_BUNDLE := $(BUILD_DIR)/ChoosePaste.app
ENGINE_BINARY := $(BUILD_DIR)/choosepaste-engine

# Default: build everything
all: bundle

# Build Go engine (universal binary: arm64 + amd64)
engine:
	@echo "Building Go engine..."
	@mkdir -p $(BUILD_DIR)
	cd engine && CGO_ENABLED=0 GOOS=darwin GOARCH=arm64 go build -o ../$(BUILD_DIR)/choosepaste-engine-arm64 ./cmd/choosepaste-engine/
	cd engine && CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 go build -o ../$(BUILD_DIR)/choosepaste-engine-amd64 ./cmd/choosepaste-engine/
	lipo -create -output $(ENGINE_BINARY) $(BUILD_DIR)/choosepaste-engine-arm64 $(BUILD_DIR)/choosepaste-engine-amd64
	rm $(BUILD_DIR)/choosepaste-engine-arm64 $(BUILD_DIR)/choosepaste-engine-amd64
	@echo "Engine built: $(ENGINE_BINARY)"

# Build Swift app
app:
	@echo "Building Swift app..."
	swift build -c release --package-path .
	@echo "Swift app built."

# Assemble .app bundle
bundle: engine app
	@echo "Assembling app bundle..."
	@mkdir -p $(APP_BUNDLE)/Contents/MacOS
	@mkdir -p $(APP_BUNDLE)/Contents/Resources
	cp .build/release/ChoosePaste $(APP_BUNDLE)/Contents/MacOS/ChoosePaste
	cp $(ENGINE_BINARY) $(APP_BUNDLE)/Contents/MacOS/choosepaste-engine
	cp ChoosePaste/Resources/Info.plist $(APP_BUNDLE)/Contents/Info.plist
	@echo "App bundle ready: $(APP_BUNDLE)"

# Run the app
run: bundle
	@echo "Launching ChoosePaste..."
	open $(APP_BUNDLE)

# Run Go engine tests
test:
	@echo "Running Go engine tests..."
	cd engine && go test ./... -v

# Clean build artifacts
clean:
	rm -rf $(BUILD_DIR)
	swift package clean 2>/dev/null || true
	rm -rf .build
