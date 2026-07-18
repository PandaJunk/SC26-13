SWIFT ?= swift

APP_TARGET := TypingFarmerMac
SELFTEST_TARGET := TypingFarmerCoreSelfTest
MAC_SUPPORT_SELFTEST_TARGET := TypingFarmerMacSupportSelfTest

.PHONY: help build release test selftest run clean

help:
	@printf "Typing Farmer Mac\n"
	@printf "\n"
	@printf "Targets:\n"
	@printf "  make build     Build debug binaries\n"
	@printf "  make release   Build release binaries\n"
	@printf "  make test      Run Swift tests\n"
	@printf "  make selftest  Run the core self-test executable\n"
	@printf "  make run       Run the macOS menu bar app\n"
	@printf "  make clean     Remove SwiftPM build artifacts\n"

build:
	$(SWIFT) build

release:
	$(SWIFT) build -c release

test:
	$(SWIFT) test

selftest:
	$(SWIFT) run $(SELFTEST_TARGET)
	$(SWIFT) run $(MAC_SUPPORT_SELFTEST_TARGET)

run:
	$(SWIFT) run $(APP_TARGET)

clean:
	$(SWIFT) package clean
