default: help

PROJECTNAME=$(shell basename "$(PWD)")

CLI_MAIN_FOLDER=./cmd
BIN_FOLDER=./bin
BIN_FOLDER_MACOS=${BIN_FOLDER}/amd64/darwin
BIN_FOLDER_WINDOWS=${BIN_FOLDER}/amd64/windows
BIN_FOLDER_LINUX=${BIN_FOLDER}/amd64/linux
BIN_FOLDER_SCRATCH=${BIN_FOLDER}/amd64/scratch
BIN_NAME=${PROJECTNAME}

# Make is verbose in Linux. Make it silent.
MAKEFLAGS += --silent
# LDFLAGS=-X main.buildDate=`date -u +%Y-%m-%dT%H:%M:%SZ` -X main.version=`scripts/version.sh`
LDFLAGS=

## setup: install all build dependencies for ci
setup: mod-download

## compile: compiles project in current system
compile: clean generate fmt vet test build

## watch: format, test and build project at go files modification
watch:
	@echo "\e[33m  >  Watching go files...\e[0m"
	@if [ -n "${RUN_ARGS}" ] ;then echo "Running app with \e[34m${RUN_ARGS}\e[0m";else echo "No extra arguments";fi
	@if ! which gow >/dev/null; then \
		echo "Installing gow";go install github.com/mitranim/gow@latest; fi
	@echo 
	@gow -c run ${CLI_MAIN_FOLDER} ${RUN_ARGS}

# ---------------------------------------------------------------------------

clean:
	@echo "  >  Cleaning build cache"
	@-rm -rf ${BIN_FOLDER}/amd64 ${BIN_FOLDER}/${BIN_NAME} \
		&& go clean ./...

build:
	@echo "\e[33m  >  Building binary\e[0m"
	@go build \
		-ldflags="${LDFLAGS}" \
		-o ${BIN_FOLDER}/${BIN_NAME} \
		"${CLI_MAIN_FOLDER}"

build-all: build-macos build-windows build-linux build-alpine-scratch

build-macos:
	@echo "\e[33m  >  Building binary for MacOS\e[0m"
	@GOOS=darwin GOARCH=amd64 \
		go build \
		-ldflags="${LDFLAGS}" \
		-o ${BIN_FOLDER_MACOS}/${BIN_NAME} \
		"${CLI_MAIN_FOLDER}"

build-windows:
	@echo "\e[33m  >  Building binary for Windows\e[0m"
	@GOOS=windows GOARCH=amd64 \
		go build \
		-ldflags="${LDFLAGS}" \
		-o ${BIN_FOLDER_WINDOWS}/${BIN_NAME}.exe \
		"${CLI_MAIN_FOLDER}"

build-linux:
	@echo "\e[33m  >  Building binary for Linux\e[0m"
	@GOOS=linux GOARCH=amd64 \
		go build \
		-ldflags="${LDFLAGS}" \
		-o ${BIN_FOLDER_LINUX}/${BIN_NAME} \
		"${CLI_MAIN_FOLDER}"

# Alpine & scratch base images use musl instead of gnu libc, thus we need to add additional parameters on the build
build-alpine-scratch:
	@echo "\e[33m  >  Building binary for Alpine/Scratch\e[0m"
	@CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
		go build \
		-ldflags="${LDFLAGS}" \
		-a -installsuffix cgo \
		-o ${BIN_FOLDER_SCRATCH}/${BIN_NAME} \
		"${CLI_MAIN_FOLDER}"

fmt:
	@echo "\e[33m  >  Formatting code\e[0m"
	@go fmt ./...

generate:
	@echo "\e[33m  >  Go generate\e[0m"
	@if !type "stringer" > /dev/null 2>&1; then \
		go install golang.org/x/tools/cmd/stringer@latest; \
	fi
	@go generate ./...

mod-download:
	@echo "\e[33m  >  Download dependencies...\e[0m"
	@go mod download && go mod tidy

test:
	@echo "\e[33m  >  Executing unit tests\e[0m"
	@go test -v -timeout 60s -race ./...

test-colorized:
	@echo "\e[33m  >  Executing unit tests\e[0m"
	@if ! type "richgo" > /dev/null 2>&1; then \
		go install github.com/kyoh86/richgo@latest; \
	fi
	@richgo test -v -timeout 60s -race ./...

vet:
	@echo "\e[33m  >  Checking code with vet\e[0m"
	@go vet ./...

.PHONY: help build
all: help
help: Makefile
	@echo
	@echo " Choose a command run in "$(PROJECTNAME)":"
	@echo
	@sed -n 's/^##//p' $< | column -t -s ':' |  sed -e 's/^/ /'
	@echo