OODA_COMPILER ?= /Projects/openOODA-core/oodac/bin/oodac
OODA_READDIR ?= /Projects
OODA_WRITEDIR ?= $(CURDIR):/tmp
OO_LIST_AMBIENT_QUOTA ?= 8589934592
BIN := bin/oodream
REPO_NAME := oodream
VER := 0.4.1
SRC := $(shell find anchor.oo cli core tests -name '*.oo')
ENV := OO_LIST_AMBIENT_QUOTA=$(OO_LIST_AMBIENT_QUOTA) OODA_FS_READDIR=$(OODA_READDIR):/tmp OODA_FS_WRITEDIR=$(OODA_WRITEDIR) OODA_NO_JAIL=1
export OODA_COMPILER OODA_FS_READDIR OODA_FS_WRITEDIR OODA_NO_JAIL OO_LIST_AMBIENT_QUOTA

.PHONY: all build verify test det check line-cap file-law academy density vocab clean link-law

all: build verify test det

build: $(BIN)

$(BIN): $(SRC)
	@mkdir -p bin .ooda-cache
	$(ENV) $(OODA_COMPILER) build cli/main.oo -o $(BIN)
	@chmod +x $(BIN)
	@echo "built $(BIN)"

line-cap:
	@violations=0; \
	for f in $$(find . -name "*.oo" -o -name "*.oot" | grep -v "/.git/" | grep -v "/bin/" | grep -v "/dist/" | grep -v "/.ooda-cache/" | grep -v "/.blackbox/"); do \
		n=$$(wc -l < "$$f"); \
		if [ $$n -gt 256 ]; then \
			echo "VIOLATION: $$f = $$n lines (exceeds 256)"; violations=$$((violations+1)); \
		fi; \
		code=$$(grep -vE '^[[:space:]]*(//.*)?$$' "$$f" | grep -cvE '^[[:space:]]*import[[:space:]]+"'); \
		if [ "$$code" = "0" ]; then continue; fi; \
		if [ $$n -lt 16 ]; then \
			echo "VIOLATION: $$f = $$n lines (under 16-line floor, not a shim)"; violations=$$((violations+1)); \
		fi; \
	done; \
	if [ $$violations -gt 0 ]; then echo "FAIL: $$violations files violate the Page Rule"; exit 1; fi; \
	echo "PASS: Page Rule sizing (16-256 lines, shims exempt from floor) holds"

file-law:
	@forbidden="py js ts rb pl json yaml toml"; \
	violations=0; \
	for ext in $$forbidden; do \
		found=$$(find . -name "*.$$ext" -not -path "./.git/*" -not -path "./bin/*" -not -path "./dist/*" -not -path "./.ooda-cache/*" -not -path "./.blackbox/*" 2>/dev/null | head -3); \
		if [ -n "$$found" ]; then \
			echo "VIOLATION: .$$ext forbidden:"; echo "$$found"; violations=$$((violations+1)); \
		fi; \
	done; \
	if [ $$violations -gt 0 ]; then echo "FAIL: file-law violations"; exit 1; fi; \
	echo "PASS: file law holds"

academy:
	@failures=0; \
	for f in $$(find . -name "*.oo" -not -path "./.git/*" -not -path "./bin/*" -not -path "./dist/*" -not -path "./.ooda-cache/*" -not -path "./.blackbox/*"); do \
		header=$$(head -7 "$$f"); \
		missing=""; \
		echo "$$header" | grep -q "^// # "        || missing="$$missing title"; \
		echo "$$header" | grep -q "^// Logline:"  || missing="$$missing logline"; \
		echo "$$header" | grep -q "^// Setup:"    || missing="$$missing setup"; \
		echo "$$header" | grep -q "^// Beats:"    || missing="$$missing beats"; \
		if [ -n "$$missing" ]; then \
			echo "FAIL: $$f missing Academy element(s):$$missing"; failures=$$((failures+1)); \
		fi; \
	done; \
	if [ $$failures -gt 0 ]; then echo "FAIL: $$failures academy header violations"; exit 1; fi; \
	echo "PASS: academy headers hold"

density:
	@violations=0; \
	for d in $$(find . -type d -not -path "./.git*" -not -path "./bin*" -not -path "./dist*" -not -path "./.ooda-cache*" -not -path "./.blackbox*"); do \
		n=$$(ls "$$d"/*.oo "$$d"/*.oot 2>/dev/null | grep -v '\*' | wc -l); \
		if [ $$n -gt 8 ]; then \
			echo "VIOLATION: $$d holds $$n pages (exceeds 8)"; violations=$$((violations+1)); \
		fi; \
	done; \
	if [ $$violations -gt 0 ]; then echo "FAIL: $$violations directories exceed density bound"; exit 1; fi; \
	echo "PASS: directory density (<= 8 pages per directory) holds"

vocab:
	@if grep -riE "sovereign|Pillar [0-9]|moonshot|dogfight|bootstrap|Stage [0-9]" --include="*.oo" --include="*.oot" . ; then \
		echo "FAIL: banned vocabulary found"; exit 1; \
	fi; \
	echo "PASS: vocabulary check holds"

check:
	@for f in $$(find . -name "*.oo" -not -path "./.git/*" -not -path "./bin/*" -not -path "./dist/*" -not -path "./.ooda-cache/*" -not -path "./.blackbox/*"); do \
		$(ENV) $(OODA_COMPILER) check "$$f" > /dev/null || exit 1; \
	done; \
	echo "PASS: oodac check holds on all .oo files"

verify: line-cap file-law academy density vocab check link-law

test: $(BIN)
	@mkdir -p .ooda-cache
	@$(ENV) $(OODA_COMPILER) build tests/test_functional.oo -o bin/test_functional > /dev/null
	@OODA_FS_READ=/Projects:/tmp OODA_FS_WRITE=/tmp $(ENV) ./bin/test_functional
	@$(ENV) $(OODA_COMPILER) build tests/test_refusal.oo -o bin/test_refusal > /dev/null
	@$(ENV) ./bin/test_refusal
	@rm -rf bin/test_functional bin/test_refusal /tmp/oodream_fn*
	@rc=0; ./$(BIN) --persona oodream status > /dev/null 2>&1 || rc=$$?; [ "$$rc" = "2" ] && echo "PASS: --persona flag refused with exit 2"
	@rc=0; ./$(BIN) --list-personas > /dev/null 2>&1 || rc=$$?; [ "$$rc" = "2" ] && echo "PASS: --list-personas refused with exit 2"
	@rc=0; ./$(BIN) ooagent-memory status > /dev/null 2>&1 || rc=$$?; [ "$$rc" = "2" ] && echo "PASS: operand persona refused with exit 2"
	@rc=0; ./$(BIN) --persona bogus status > /dev/null 2>&1 || rc=$$?; [ "$$rc" = "2" ] && echo "PASS: unknown persona refuses with exit 2"
	@./$(BIN) --help | grep -q "$(REPO_NAME) $(VER)" && echo "PASS: --help"
	@./$(BIN) --version | grep -q "$(VER)" && echo "PASS: --version"
	@./$(BIN) status | grep -q "PASS" && echo "PASS: status"
	@./$(BIN) about | grep -q "Binary       :" && echo "PASS: about"
	@./$(BIN) about | grep -q "Organization : openOODA-agents" && echo "PASS: about org"
	@./$(BIN) about | grep -q "Capabilities : FsRead,FsWrite,Env,Tcp" && echo "PASS: about caps"
	@./$(BIN) about --json | grep -q '"component":"oodream"' && echo "PASS: about --json"
	@./$(BIN) about nosuchtarget >/dev/null 2>&1; test $$? -eq 2 && echo "PASS: about unknown target (exit 2)"
	@./$(BIN) theme ooda-dark --json | grep -q '"theme":"ooda-dark"' && echo "PASS: theme ooda-dark --json"
	@./$(BIN) verify | grep -q "verify OK" && echo "PASS: verify"
	@./$(BIN) inspect | grep -q '"status":"pass"' && echo "PASS: inspect"
	@./$(BIN) --self-test | grep -q "PASS" && echo "PASS: --self-test"
	@./$(BIN) --json | grep -q '"status":"pass"' && echo "PASS: --json"
	@$(ENV) ./$(BIN) scan . | grep -q "verdict=pass" && echo "PASS: live scan verdict"
	@./$(BIN) --zzz-9 > /dev/null 2>&1; test $$? -eq 2 && echo "PASS: fail-closed --zzz-9 (exit 2)"
	@./$(BIN) -x9 > /dev/null 2>&1; test $$? -eq 2 && echo "PASS: fail-closed -x9 (exit 2)"
	@./$(BIN) --version=0 > /dev/null 2>&1; test $$? -eq 2 && echo "PASS: fail-closed --version=0 (exit 2)"
	@./$(BIN) --json > .ooda-cache/r1.txt && ./$(BIN) --json > .ooda-cache/r2.txt && cmp -s .ooda-cache/r1.txt .ooda-cache/r2.txt && echo "PASS: double-run output determinism"
	@rc=0; ./$(BIN) dream ../oodream_evil > /dev/null 2>&1 || rc=$$?; [ "$$rc" = "2" ] && echo "PASS: refuses a parent-directory path (CWE-22)"
	@echo "ALL TESTS PASSED"

det: $(BIN)
	@$(ENV) $(OODA_COMPILER) build cli/main.oo -o .ooda-cache/det_a > /dev/null
	@$(ENV) $(OODA_COMPILER) build cli/main.oo -o .ooda-cache/det_b > /dev/null
	@cmp -s .ooda-cache/det_a .ooda-cache/det_b && sha256sum .ooda-cache/det_a && echo "PASS: deterministic build (byte-identical)" || (echo "FAIL: nondeterministic build"; exit 1)

clean:
	@rm -rf bin dist .ooda-cache

link-law:
	@test $$(find . -not -path "./.git*" -type l | wc -l) -eq 0 && echo "PASS: link-law holds"
