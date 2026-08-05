.PHONY: install run clean

install:
	python -m pip install -r requirements.txt

run:
	python main.py

clean:
	rm -f analysis_executed_latest.ipynb
	rm -rf data/processed/* outputs/tables/* outputs/model_results/* outputs/charts/*
