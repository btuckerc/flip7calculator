SHELL := /bin/bash

PROJECT ?= flip7calculator.xcodeproj
SCHEME ?= flip7calculator
CONFIGURATION ?= Debug
SIMULATOR_NAME ?= iPhone 16
SIMULATOR_OS ?= latest
CACHE_ROOT ?= $(HOME)/Library/Caches/FlippingSevenCalculator
DERIVED_DATA ?= $(CACHE_ROOT)/DerivedData
RESULTS_DIR ?= $(CACHE_ROOT)/Results
RELEASE_DIR ?= $(HOME)/Library/Developer/Xcode/Archives/FlippingSevenCalculator
APP_STORE_ASSETS ?= AppStoreAssets/1.3
BUNDLE_ID ?= com.tcraig.flip7calculator.ios
ITERATIONS ?= 10
RESULT ?= $(RESULTS_DIR)/$(SCHEME)-tests.xcresult

.DEFAULT_GOAL := help

.PHONY: help doctor asc-auth xcode build build-timed list-tests test test-unit test-one test-repeat ui-test \
	test-summary open-results verify build-settings destinations boot-sim launch \
	release-assets release-preflight archive export validate-upload upload clean

help: ## Show local build, test, and simulator workflows
	@echo "Flipping Seven Calculator local workflow"
	@echo
	@grep -E '^[a-zA-Z0-9_.-]+:.*## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "  %-14s %s\n", $$1, $$2}'
	@echo
	@echo "Overrides:"
	@echo "  SIMULATOR_NAME=<device>  default: $(SIMULATOR_NAME)"
	@echo "  SIMULATOR_OS=<version|latest>  default: $(SIMULATOR_OS)"
	@echo "  CACHE_ROOT=<path>        default: $(CACHE_ROOT)"
	@echo "  PARALLEL_TESTING=YES     opt in to parallel test workers (default: NO)"
	@echo "  TEST=<Target/Suite[/testName]> for test-one"
	@echo "  ITERATIONS=<count>       default: $(ITERATIONS), for test-repeat"
	@echo "  RESULT=<xcresult path>   for test-summary/open-results"

doctor: ## Check the local Xcode, simulator, cache, and optional release setup
	@PROJECT="$(PROJECT)" SCHEME="$(SCHEME)" SIMULATOR_NAME="$(SIMULATOR_NAME)" SIMULATOR_OS="$(SIMULATOR_OS)" CACHE_ROOT="$(CACHE_ROOT)" scripts/doctor.sh

asc-auth: ## Verify secure local App Store Connect credentials without printing them
	@scripts/with-asc-credentials.sh --check

xcode: ## Open the project in Xcode
	@open "$(PROJECT)"

build: ## Build the app for the configured simulator
	@PROJECT="$(PROJECT)" SCHEME="$(SCHEME)" CONFIGURATION="$(CONFIGURATION)" SIMULATOR_NAME="$(SIMULATOR_NAME)" SIMULATOR_OS="$(SIMULATOR_OS)" DERIVED_DATA="$(DERIVED_DATA)" scripts/xcode-task.sh build

build-timed: ## Build and print Xcode's build timing summary
	@PROJECT="$(PROJECT)" SCHEME="$(SCHEME)" CONFIGURATION="$(CONFIGURATION)" SIMULATOR_NAME="$(SIMULATOR_NAME)" SIMULATOR_OS="$(SIMULATOR_OS)" DERIVED_DATA="$(DERIVED_DATA)" scripts/xcode-task.sh build -showBuildTimingSummary

list-tests: ## Print discovered tests; prefer Target/Suite filters with this Xcode version
	@mkdir -p "$(RESULTS_DIR)" && rm -f "$(RESULTS_DIR)/test-identifiers.txt"
	@PROJECT="$(PROJECT)" SCHEME="$(SCHEME)" CONFIGURATION="$(CONFIGURATION)" SIMULATOR_NAME="$(SIMULATOR_NAME)" SIMULATOR_OS="$(SIMULATOR_OS)" DERIVED_DATA="$(DERIVED_DATA)" REQUIRE_TESTS=NO scripts/xcode-task.sh test -enumerate-tests -test-enumeration-style flat -test-enumeration-format text -test-enumeration-output-path "$(RESULTS_DIR)/test-identifiers.txt" >/dev/null
	@cat "$(RESULTS_DIR)/test-identifiers.txt"

test: ## Run the full test suite with simulator signing disabled
	@PROJECT="$(PROJECT)" SCHEME="$(SCHEME)" CONFIGURATION="$(CONFIGURATION)" SIMULATOR_NAME="$(SIMULATOR_NAME)" SIMULATOR_OS="$(SIMULATOR_OS)" DERIVED_DATA="$(DERIVED_DATA)" RESULT_BUNDLE="$(RESULTS_DIR)/$(SCHEME)-tests.xcresult" scripts/xcode-task.sh test

test-unit: ## Run only the fast unit-test target
	@PROJECT="$(PROJECT)" SCHEME="$(SCHEME)" CONFIGURATION="$(CONFIGURATION)" SIMULATOR_NAME="$(SIMULATOR_NAME)" SIMULATOR_OS="$(SIMULATOR_OS)" DERIVED_DATA="$(DERIVED_DATA)" RESULT_BUNDLE="$(RESULTS_DIR)/unit-tests.xcresult" scripts/xcode-task.sh test -only-testing:flip7calculatorTests

test-one: ## Run one suite or test, e.g. make test-one TEST=flip7calculatorTests/PlayerPaletteTests
	@test -n "$(TEST)" || (echo "Set TEST=Target/Suite or TEST=Target/Suite/testName" >&2; exit 1)
	@PROJECT="$(PROJECT)" SCHEME="$(SCHEME)" CONFIGURATION="$(CONFIGURATION)" SIMULATOR_NAME="$(SIMULATOR_NAME)" SIMULATOR_OS="$(SIMULATOR_OS)" DERIVED_DATA="$(DERIVED_DATA)" RESULT_BUNDLE="$(RESULTS_DIR)/$(subst /,-,$(subst (),,$(TEST))).xcresult" scripts/xcode-task.sh test "-only-testing:$(TEST)"

test-repeat: ## Repeat one suite/test until failure, e.g. make test-repeat TEST=Target/Suite ITERATIONS=20
	@test -n "$(TEST)" || (echo "Set TEST=Target/Suite or a verified XCTest method identifier" >&2; exit 1)
	@test "$(ITERATIONS)" -gt 1 2>/dev/null || (echo "Set ITERATIONS to an integer greater than 1" >&2; exit 1)
	@PROJECT="$(PROJECT)" SCHEME="$(SCHEME)" CONFIGURATION="$(CONFIGURATION)" SIMULATOR_NAME="$(SIMULATOR_NAME)" SIMULATOR_OS="$(SIMULATOR_OS)" DERIVED_DATA="$(DERIVED_DATA)" RESULT_BUNDLE="$(RESULTS_DIR)/repeat-$(subst /,-,$(subst (),,$(TEST))).xcresult" scripts/xcode-task.sh test "-only-testing:$(TEST)" -run-tests-until-failure -test-iterations "$(ITERATIONS)" -test-repetition-relaunch-enabled YES

ui-test: ## Run only the UI test target
	@PROJECT="$(PROJECT)" SCHEME="$(SCHEME)" CONFIGURATION="$(CONFIGURATION)" SIMULATOR_NAME="$(SIMULATOR_NAME)" SIMULATOR_OS="$(SIMULATOR_OS)" DERIVED_DATA="$(DERIVED_DATA)" RESULT_BUNDLE="$(RESULTS_DIR)/ui-tests.xcresult" scripts/xcode-task.sh test -only-testing:flip7calculatorUITests

test-summary: ## Print a compact summary for RESULT=<path.xcresult>
	@scripts/xcresult-summary.sh "$(RESULT)"

open-results: ## Open RESULT=<path.xcresult> in Xcode
	@test -d "$(RESULT)" || (echo "Result bundle not found: $(RESULT)" >&2; exit 1)
	@open "$(RESULT)"

verify: test ## Run the complete test plan and a Release simulator build
	@$(MAKE) build CONFIGURATION=Release SIMULATOR_NAME="$(SIMULATOR_NAME)" SIMULATOR_OS="$(SIMULATOR_OS)" CACHE_ROOT="$(CACHE_ROOT)"

release-assets: ## Validate App Store metadata lengths, icons, and screenshot dimensions
	@ASSETS_DIR="$(APP_STORE_ASSETS)" scripts/validate-release-assets.sh

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

release-preflight: doctor release-assets ## Verify code, metadata, credentials, and release cleanliness without uploading
	@PROJECT="$(PROJECT)" SCHEME="$(SCHEME)" RELEASE_DIR="$(RELEASE_DIR)" scripts/release.sh preflight
	@$(MAKE) verify SIMULATOR_NAME="$(SIMULATOR_NAME)" SIMULATOR_OS="$(SIMULATOR_OS)" CACHE_ROOT="$(CACHE_ROOT)"

archive: ## Create a signed App Store archive (requires explicit clean release state)
	@PROJECT="$(PROJECT)" SCHEME="$(SCHEME)" RELEASE_DIR="$(RELEASE_DIR)" scripts/release.sh archive

export: ## Export the archive to an IPA using scripts/ExportOptions-AppStore.plist
	@PROJECT="$(PROJECT)" SCHEME="$(SCHEME)" RELEASE_DIR="$(RELEASE_DIR)" scripts/release.sh export

validate-upload: ## Ask App Store Connect to validate the exported IPA
	@PROJECT="$(PROJECT)" SCHEME="$(SCHEME)" RELEASE_DIR="$(RELEASE_DIR)" scripts/release.sh validate

upload: ## Upload the exported IPA; does not attach or submit it for review
	@PROJECT="$(PROJECT)" SCHEME="$(SCHEME)" RELEASE_DIR="$(RELEASE_DIR)" scripts/release.sh upload

clean: ## Remove local build artifacts
	@rm -rf .build "$(DERIVED_DATA)" "$(RESULTS_DIR)"
