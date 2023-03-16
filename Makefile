.PHONY: help check
.DEFAULT_GOAL := help

SUBPKGS=cpu disk docker host internal load mem net process
APP_NAME?=ddbimp

help:  ## Show help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

check:  ## Check
	errcheck -ignore="Close|Run|Write" ./...
	golint ./... | egrep -v 'underscores|HttpOnly|should have comment|comment on exported|CamelCase|VM|UID' && exit 1 || exit 0

BUILD_FAIL_PATTERN=grep -v "exec format error" | grep "build failed" && exit 1 || exit 0
build_test:  ## test only buildable
	# Supported operating systems
	GOOS=linux GOARCH=amd64 go test ./... | $(BUILD_FAIL_PATTERN)
	GOOS=linux GOARCH=386 go test ./... | $(BUILD_FAIL_PATTERN)
	GOOS=linux GOARCH=arm go test ./... | $(BUILD_FAIL_PATTERN)
	GOOS=linux GOARCH=arm64 go test ./... | $(BUILD_FAIL_PATTERN)
	GOOS=linux GOARCH=loong64 go test ./... | $(BUILD_FAIL_PATTERN)
	GOOS=linux GOARCH=riscv64 go test ./... | $(BUILD_FAIL_PATTERN)
	GOOS=linux GOARCH=s390x go test ./... | $(BUILD_FAIL_PATTERN)
	GOOS=freebsd GOARCH=amd64 go test ./... | $(BUILD_FAIL_PATTERN)
	GOOS=freebsd GOARCH=386 go test ./... | $(BUILD_FAIL_PATTERN)
	GOOS=freebsd GOARCH=arm go test ./... | $(BUILD_FAIL_PATTERN)
	GOOS=freebsd GOARCH=arm64 go test ./... | $(BUILD_FAIL_PATTERN)
	CGO_ENABLED=0 GOOS=darwin go test ./... | $(BUILD_FAIL_PATTERN)
	GOOS=windows go test ./... | $(BUILD_FAIL_PATTERN)
	# Operating systems supported for building only (not implemented error if used)
	GOOS=solaris go test ./... | $(BUILD_FAIL_PATTERN)
	GOOS=dragonfly go test ./... | $(BUILD_FAIL_PATTERN)
	GOOS=netbsd go test ./... | $(BUILD_FAIL_PATTERN)
	# cross build to OpenBSD not worked since process has "C"
#	GOOS=openbsd go test ./... | $(BUILD_FAIL_PATTERN)
#   GOOS=plan9 go test ./... | $(BUILD_FAIL_PATTERN)

ifeq ($(shell uname -s), Darwin)
	CGO_ENABLED=1 GOOS=darwin go test ./... | $(BUILD_FAIL_PATTERN)
endif
	@echo 'Successfully built on all known operating systems'

build:
	GOOS=linux GOARCH=amd64 go build -o bin/$(APP_NAME)-linux-amd64 .
	GOOS=linux GOARCH=386 go build -o bin/$(APP_NAME)-linux-i386 .
	GOOS=linux GOARCH=arm go build -o bin/$(APP_NAME)-linux-arm .
	GOOS=linux GOARCH=arm64 go build -o bin/$(APP_NAME)-linux-arm64 .
	GOOS=linux GOARCH=loong64 go build -o bin/$(APP_NAME)-linux-loong64 .
	GOOS=linux GOARCH=riscv64 go build -o bin/$(APP_NAME)-linux-riscv64 .
	GOOS=linux GOARCH=s390x go build -o bin/$(APP_NAME)-linux-s390x.
	GOOS=freebsd GOARCH=amd64 go build -o bin/$(APP_NAME)-freebsd-amd64 .
	GOOS=freebsd GOARCH=386 go build -o bin/$(APP_NAME)-freebsd-i386 .
	GOOS=freebsd GOARCH=arm go build -o bin/$(APP_NAME)-freebsd-arm .
	GOOS=freebsd GOARCH=arm64 go build -o bin/$(APP_NAME)-freebsd-arm64 .
	CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 go build -o bin/$(APP_NAME)-darwin-amd64 .
	GOOS=windows GOARCH=amd64 go build -o bin/$(APP_NAME)-windos-amd64.exe .
	GOOS=windows GOARCH=386 go build -o bin/$(APP_NAME)-windos-i386.exe .
	GOOS=solaris GOARCH=amd64 go build -o bin/$(APP_NAME)-solaris-amd64 .

vet:
	GOOS=darwin GOARCH=amd64 go vet ./...
	GOOS=darwin GOARCH=arm64 go vet ./....

	GOOS=freebsd GOARCH=amd64 go vet ./...
	GOOS=freebsd GOARCH=386 go vet ./...
	GOOS=freebsd GOARCH=arm go vet ./...

	GOOS=linux GOARCH=386 go vet ./...
	GOOS=linux GOARCH=amd64 go vet ./...
	GOOS=linux GOARCH=arm64 go vet ./...
	GOOS=linux GOARCH=arm go vet ./...
	GOOS=linux GOARCH=loong64 go vet ./...
	GOOS=linux GOARCH=mips64 go vet ./...
	GOOS=linux GOARCH=mips64le go vet ./...
	GOOS=linux GOARCH=mips go vet ./...
	GOOS=linux GOARCH=mipsle go vet ./...
	GOOS=linux GOARCH=ppc64le go vet ./...
	GOOS=linux GOARCH=ppc64 go vet ./...
	GOOS=linux GOARCH=riscv64 go vet ./...
	GOOS=linux GOARCH=s390x go vet ./...

	GOOS=netbsd GOARCH=amd64 go vet ./...

	GOOS=openbsd GOARCH=386 go vet ./...
	GOOS=openbsd GOARCH=amd64 go vet ./...

	GOOS=solaris GOARCH=amd64 go vet ./...

	GOOS=windows GOARCH=amd64 go vet ./...
	GOOS=windows GOARCH=386 go vet ./...

macos_test:
	CGO_ENABLED=0 GOOS=darwin go test ./... | $(BUILD_FAIL_PATTERN)
	CGO_ENABLED=1 GOOS=darwin go test ./... | $(BUILD_FAIL_PATTERN)

init_tools:
	go get github.com/golang/dep/cmd/dep

TAG=$(shell date +'v0.%y.%-m%d')

release:
	git tag $(TAG)
	git push origin $(TAG)