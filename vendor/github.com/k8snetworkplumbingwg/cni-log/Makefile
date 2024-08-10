.PHONY: test
test: ## Run unit tests
	go test -v .

GOLANGCILINT = $(GOBIN)/golangci-lint
$(GOLANGCILINT): | $(BASE) ; $(info  Installing golangci-lint...)
	$Q go install github.com/golangci/golangci-lint/cmd/golangci-lint@v1.52.2

.PHONY: lint
lint: | $(BASE) $(GOLANGCILINT) ; $(info  Running golangci-lint...) @ ## Run golint on all source files
	$Q $(GOLANGCILINT) run ./...

.PHONY: test-coverage
test-coverage: ## Get test coverage
	go test -count 1 -coverprofile=coverage.out  .
	go tool cover -html=coverage.out

.PHONY: help
help: ; @ ## Display this help message
	@grep -E '^[ a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'
