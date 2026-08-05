
"""UrbanCart reusable pipeline.

One command:
    python main.py

The driver executes analysis.ipynb from the project root and regenerates
processed data, SQL result tables, NumPy model outputs, and charts.
"""

from __future__ import annotations

import sys
from pathlib import Path

import nbformat
from nbclient import NotebookClient


def run_pipeline(project_dir: Path) -> Path:
    notebook_path = project_dir / "analysis.ipynb"
    output_path = project_dir / "analysis_executed_latest.ipynb"

    if not notebook_path.exists():
        raise FileNotFoundError(f"Notebook not found: {notebook_path}")

    required_inputs = [
        project_dir / "data" / "raw" / "ecommerce.db",
        project_dir / "data" / "raw" / "legacy_customers_export.xlsx",
        project_dir / "data" / "raw" / "product_catalog_2024.xlsx",
        project_dir / "queries.sql",
    ]
    missing = [str(path) for path in required_inputs if not path.exists()]
    if missing:
        raise FileNotFoundError("Missing required input files:\n" + "\n".join(missing))

    notebook = nbformat.read(notebook_path, as_version=4)
    client = NotebookClient(
        notebook,
        timeout=600,
        kernel_name="python3",
        resources={"metadata": {"path": str(project_dir)}},
        allow_errors=False,
    )
    executed = client.execute()
    nbformat.write(executed, output_path)
    return output_path


def main() -> int:
    project_dir = Path(__file__).resolve().parents[1]
    print(f"Running UrbanCart pipeline in: {project_dir}")
    try:
        output = run_pipeline(project_dir)
    except Exception as exc:
        print(f"Pipeline failed: {exc}", file=sys.stderr)
        return 1

    print("UrbanCart pipeline completed successfully.")
    print(f"Executed notebook: {output}")
    print("Generated outputs:")
    print(f"  - {project_dir / 'data' / 'processed'}")
    print(f"  - {project_dir / 'outputs' / 'tables'}")
    print(f"  - {project_dir / 'outputs' / 'model_results'}")
    print(f"  - {project_dir / 'outputs' / 'charts'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
