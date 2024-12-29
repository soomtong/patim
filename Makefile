# Makefile for PatalInputMethod

# Variables
SCRIPT_DIR = ./script
SRC_DIR = ./macOS
DIST_DIR = ./dist
PKG = PatalInputMethod.pkg
APP_ROOT = /Library/Input\ Methods/Patal.app
APP_USER = /Users/$(USER)/Library/Input\ Methods/Patal.app

# Default target
.DEFAULT_GOAL := help

.PHONY: all format install package distribute clean build kill remove remove-root remove-user list help

all: format install package distribute

format:
	@echo "Running format script..."
	@cd $(SCRIPT_DIR) && sh format.sh

build:
	@echo "Building the project..."
	@cd $(SRC_DIR) && xcodebuild -verbose -scheme Patal -configuration Release build

install:
	@echo "Running install script..."
	@cd $(SCRIPT_DIR) && sh install.sh

package:
	@echo "Running packaging script..."
	@cd $(SCRIPT_DIR) && sh packaging.sh

distribute:
	@echo "Running distribute script..."
	@cd $(SCRIPT_DIR) && sh distribute.sh

clean:
	@echo "Cleaning up..."
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

list:
	@echo "Listing dist directory..."
	@ls -l $(DIST_DIR)

help:
	@echo "Available targets:"
	@echo "  all         - Run format, install, package, and distribute"
	@echo "  format      - Run the format script"
	@echo "  build       - Build the project using xcodebuild"
	@echo "  install     - Run the install script"
	@echo "  package     - Run the packaging script"
	@echo "  distribute  - Run the distribute script"
	@echo "  clean       - Clean up the dist directory"
	@echo "  kill        - Kill the Patal process"
	@echo "  remove      - Remove both root and user Patal apps"
	@echo "  remove-root - Remove the root Patal app"
	@echo "  remove-user - Remove the user Patal app"
	@echo "  list        - List the contents of the dist directory"
	@echo "  help        - Show this help message"
