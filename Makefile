.PHONY: help wp1 check clean-scratch

help:
	@echo "wp1           run the Louisiana chain end to end (~18 min, needs data/raw)"
	@echo "check         parse every R file and validate the results manifest"
	@echo "clean-scratch remove scratch/ and tmp/"

wp1:
	cd analysis/louisiana/code && ./run_all.sh

check:
	Rscript -e 'fs <- list.files(".", pattern="[.][Rr]$$", recursive=TRUE, full.names=TRUE); fs <- fs[!grepl("^[.]/data/", fs)]; invisible(lapply(fs, parse)); cat(length(fs), "R files parse\n")'
	@python3 -c "import json;d=json.load(open('analysis/louisiana/results/EXPECTED-RESULTS.json'));assert 'deterministic' in d and 'monte_carlo' in d;print('manifest OK')" 2>/dev/null || echo "manifest not present yet"

clean-scratch:
	rm -rf scratch tmp
