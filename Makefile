# Makefile for PatalInputMethod

# Variables
SCRIPT_DIR = ./script
SRC_DIR = ./macOS
DIST_DIR = ./dist
PKG = PatalInputMethod.pkg
APP_ROOT = /Library/Input\ Methods/Patal.app
APP_USER = /Users/$(USER)/Library/Input\ Methods/Patal.app
SCHEME = Patal

# Default target
.DEFAULT_GOAL := help

.PHONY: all format install install-debug package distribute clean build debug log perf-log kill remove remove-root remove-user unquarantine list help test test-only test-verbose

all: format install package distribute

test:
	@echo "Running tests..."
	@cd $(SRC_DIR) && xcodebuild test \
		-scheme $(SCHEME) \
		-destination 'platform=macOS' \
		| xcbeautify

test-only:
	@echo "Running single test..."
	@cd $(SRC_DIR) && xcodebuild test \
		-scheme $(SCHEME) \
		-destination 'platform=macOS' \
		-only-testing:PatalTests/$(CLASS) \
		| xcbeautify

test-verbose:
	@echo "Running tests with verbose output..."
	@cd $(SRC_DIR) && xcodebuild test \
		-scheme $(SCHEME) \
		-destination 'platform=macOS' \
		-verbose

format:
	@echo "Running format script..."
	@cd $(SCRIPT_DIR) && sh format.sh

build-verbose:
	@echo "Building the project..."
	@cd $(SRC_DIR) && xcodebuild -verbose -scheme Patal -configuration Release build

build:
	@echo "Building the project..."
	@cd $(SRC_DIR) && xcodebuild -verbose -scheme Patal -configuration Release build | xcpretty

debug:
	@echo "Building Debug version..."
	@cd $(SRC_DIR) && xcodebuild -scheme $(SCHEME) -configuration Debug build CONFIGURATION_BUILD_DIR=$(CURDIR)/$(SRC_DIR)/build/Debug
	@echo "Debug build completed. Start log monitoring with: make log"

log:
	@echo "Monitoring Patal logs..."
	@log stream --predicate 'process == "Patal"' --level debug

perf-log:
	@echo "Monitoring performance logs..."
	@log stream --predicate 'process == "Patal"' --level debug AND category == "Performance"' --level info


install:
	@echo "Running install script..."
	@cd $(SCRIPT_DIR) && sh install.sh
	@killall Patal 2>/dev/null || true
	@echo "Patal process restarted."

install-debug: debug
	@echo "Installing Debug build..."
	@rm -rf $(APP_USER)
	@cp -R $(SRC_DIR)/build/Debug/Patal.app $(APP_USER)
	@killall Patal 2>/dev/null || true
	@echo "Debug build installed. Start log monitoring with: make log"

package:
	@echo "Running packaging script..."
	@cd $(SCRIPT_DIR) && sh packaging.sh

distribute:
	@echo "Running distribute script..."
	@cd $(SCRIPT_DIR) && sh distribute.sh

clean:
	@echo "Cleaning up..."
	@rm -rf $(DIST_DIR)/*.zip
	@rm -rf $(DIST_DIR)/*.pkg
	@rm -rf $(DIST_DIR)/Distribution.xml
	@echo "Cleaned up."

kill:
	@echo "Killing Patal process..."
	@killall Patal || true

remove: remove-user remove-root

remove-root:
	@echo "Removing root Patal app with root permissions..."
	@sudo rm -rf $(APP_ROOT)
	@echo "Removed root Patal app."

remove-user:
	@echo "Removing user Patal app..."
	@rm -rf $(APP_USER)
	@echo "Removed user Patal app."

unquarantine:
	@echo "Removing quarantine attribute..."
	@sudo xattr -rd com.apple.quarantine /Library/Input\ Methods/Patal.app
	@echo "Quarantine attribute removed."

list:
	@echo "Listing dist directory..."
	@ls -l $(DIST_DIR)

help:
	@echo "Available targets:"
	@echo "  all         - Run format, install, package, and distribute"
	@echo "  format      - Run the format script"
	@echo "  build       - Build the project using xcodebuild"
	@echo "  debug       - Build Debug version (with debug logging enabled)"
	@echo "  log         - Monitor all Patal logs in real-time"
	@echo "  perf-log    - Monitor performance logs only"
	@echo "  install     - Run the install script"
	@echo "  install-debug - Build and install Debug version"
	@echo "  package     - Run the packaging script"
	@echo "  distribute  - Run the distribute script"
	@echo "  clean       - Clean up the dist directory"
	@echo "  kill        - Kill the Patal process"
	@echo "  remove      - Remove both root and user Patal apps"
	@echo "  remove-root - Remove the root Patal app"
	@echo "  remove-user - Remove the user Patal app"
	@echo "  unquarantine- Remove quarantine attribute from Patal app"
	@echo "  list        - List the contents of the dist directory"
	@echo "  test        - Run tests with pretty formatting"
	@echo "  test-only   - Run a single test (Usage: make test-only CLASS=AClass)"
	@echo "  test-verbose- Run tests with verbose output"
	@echo "  help        - Show this help message"
