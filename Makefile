REPO_ROOT ?= $(shell git rev-parse --show-toplevel)
BUILD_DIR ?= $(dir $(realpath -s $(firstword $(MAKEFILE_LIST))))/build
VERSION ?= $(shell git describe --tags --always --dirty)

$(shell mkdir -p ${BUILD_DIR})

all: verify test build

build:
	@echo "build"

verify:
	${REPO_ROOT}/scripts/validate-charts.sh
	${REPO_ROOT}/scripts/validate-chart-versions.sh
	${REPO_ROOT}/scripts/lint-charts.sh

draft-release:
	${REPO_ROOT}/scripts/draft-release.sh

package:
	${REPO_ROOT}/scripts/package-charts.sh

publish: package
	${REPO_ROOT}/scripts/publish-charts.sh

version:
	@echo ${VERSION}

install-toolchain:
	${REPO_ROOT}/scripts/install-toolchain.sh

clean:
	rm -rf ${REPO_ROOT}/build/

help:
	@grep -E '^[a-zA-Z_-]+:.*$$' $(MAKEFILE_LIST) | sort

.PHONY: all build test verify package publish draft-release help
