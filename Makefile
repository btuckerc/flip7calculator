SHELL := /bin/bash

PROJECT ?= flip7calculator.xcodeproj
SCHEME ?= flip7calculator
CONFIGURATION ?= Debug
SIMULATOR_NAME ?= iPhone 16
SIMULATOR_OS ?= latest
CACHE_ROOT ?= $(HOME)/Library/Caches/FlippingSevenCalculator
DERIVED_DATA ?= $(CACHE_ROOT)/DerivedData
RESULTS_DIR ?= $(CACHE_ROOT)/Results
BUNDLE_ID ?= com.tcraig.flip7calculator.ios

.DEFAULT_GOAL := help

.PHONY: help build test test-one ui-test build-settings destinations boot-sim launch clean

help: ## Show local build, test, and simulator workflows
	@echo "Flipping Seven Calculator local workflow"
	@echo
	@grep -E '^[a-zA-Z0-9_.-]+:.*## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "  %-14s %s\n", $$1, $$2}'
	@echo
	@echo "Overrides:"
	@echo "  SIMULATOR_NAME=<device>  default: $(SIMULATOR_NAME)"
	@echo "  SIMULATOR_OS=<version|latest>  default: $(SIMULATOR_OS)"
	@echo "  CACHE_ROOT=<path>        default: $(CACHE_ROOT)"
	@echo "  TEST=<Target/Suite[/testName]> for test-one"

build: ## Build the app for the configured simulator
	@PROJECT="$(PROJECT)" SCHEME="$(SCHEME)" CONFIGURATION="$(CONFIGURATION)" SIMULATOR_NAME="$(SIMULATOR_NAME)" SIMULATOR_OS="$(SIMULATOR_OS)" DERIVED_DATA="$(DERIVED_DATA)" scripts/xcode-task.sh build

test: ## Run the full test suite with simulator signing disabled
	@PROJECT="$(PROJECT)" SCHEME="$(SCHEME)" CONFIGURATION="$(CONFIGURATION)" SIMULATOR_NAME="$(SIMULATOR_NAME)" SIMULATOR_OS="$(SIMULATOR_OS)" DERIVED_DATA="$(DERIVED_DATA)" RESULT_BUNDLE="$(RESULTS_DIR)/$(SCHEME)-tests.xcresult" scripts/xcode-task.sh test

test-one: ## Run one suite or test, e.g. make test-one TEST=flip7calculatorTests/PlayerPaletteTests
	@test -n "$(TEST)" || (echo "Set TEST=Target/Suite or TEST=Target/Suite/testName" >&2; exit 1)
	@PROJECT="$(PROJECT)" SCHEME="$(SCHEME)" CONFIGURATION="$(CONFIGURATION)" SIMULATOR_NAME="$(SIMULATOR_NAME)" SIMULATOR_OS="$(SIMULATOR_OS)" DERIVED_DATA="$(DERIVED_DATA)" RESULT_BUNDLE="$(RESULTS_DIR)/$(subst /,-,$(TEST)).xcresult" scripts/xcode-task.sh test -only-testing:$(TEST)

ui-test: ## Run only the UI test target
	@PROJECT="$(PROJECT)" SCHEME="$(SCHEME)" CONFIGURATION="$(CONFIGURATION)" SIMULATOR_NAME="$(SIMULATOR_NAME)" SIMULATOR_OS="$(SIMULATOR_OS)" DERIVED_DATA="$(DERIVED_DATA)" RESULT_BUNDLE="$(RESULTS_DIR)/ui-tests.xcresult" scripts/xcode-task.sh test -only-testing:flip7calculatorUITests

build-settings: ## Print key Xcode build settings for the chosen simulator
	@DESTINATION="$$(scripts/find-simulator.sh "$(SIMULATOR_NAME)" "$(SIMULATOR_OS)" destination)" && \
	xcodebuild -showBuildSettings -project "$(PROJECT)" -scheme "$(SCHEME)" -destination "$$DESTINATION" | rg 'PRODUCT_BUNDLE_IDENTIFIER|MARKETING_VERSION|CURRENT_PROJECT_VERSION|INFOPLIST_KEY_CFBundleDisplayName'

destinations: ## List available iOS simulators
	@xcrun simctl list devices available | sed -n '/-- iOS /,/^$$/p'

boot-sim: ## Boot the configured simulator and wait for it
	@UDID="$$(scripts/find-simulator.sh "$(SIMULATOR_NAME)" "$(SIMULATOR_OS)" udid)" && \
	open -a Simulator && \
	xcrun simctl boot "$$UDID" >/dev/null 2>&1 || true && \
	xcrun simctl bootstatus "$$UDID" -b

launch: build boot-sim ## Build, install, and launch the app on the configured simulator
	@UDID="$$(scripts/find-simulator.sh "$(SIMULATOR_NAME)" "$(SIMULATOR_OS)" udid)" && \
	APP_PATH="$(DERIVED_DATA)/Build/Products/$(CONFIGURATION)-iphonesimulator/flip7calculator.app" && \
	test -d "$$APP_PATH" || (echo "Built app not found at $$APP_PATH" >&2; exit 1) && \
	xcrun simctl install "$$UDID" "$$APP_PATH" && \
	xcrun simctl launch "$$UDID" "$(BUNDLE_ID)"

clean: ## Remove local build artifacts
	@rm -rf .build "$(DERIVED_DATA)" "$(RESULTS_DIR)"
