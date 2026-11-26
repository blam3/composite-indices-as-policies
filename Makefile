.PHONY: help wp1 check clean-scratch

help:
	@echo "wp1           run the Louisiana chain end to end (needs staged inputs; see data/README.md)"
	@echo "check         parse every R file and validate the results manifest"
	@echo "clean-scratch remove scratch/ and tmp/"

wp1:
	bash analysis/louisiana/run_all.sh

check:
	Rscript -e 'fs <- list.files(".", pattern="[.][Rr]$$", recursive=TRUE, full.names=TRUE); fs <- fs[!grepl("^[.]/data/", fs)]; invisible(lapply(fs, parse)); cat(length(fs), "R files parse\n")'
	python3 -m unittest discover -s tests
	Rscript tests/check_pipeline.R
	python3 scripts/compare_results.py analysis/louisiana/results/EXPECTED-RESULTS.json analysis/louisiana/results/EXPECTED-RESULTS.json

clean-scratch:
	rm -rf scratch tmp
