import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]

def test_dvc_pipeline_declares_materialized_outputs():
    pipeline=(ROOT/"dvc.yaml").read_text()
    assert "outs:" in pipeline
    assert any(token in pipeline for token in ("download","brick"))

def test_reference_profile_does_not_claim_tabular_coverage():
    coverage=json.loads((ROOT/"health/source-coverage.json").read_text())
    policy=json.loads((ROOT/"health/ontology-policy.json").read_text())
    status=json.loads((ROOT/"health/build-status.json").read_text())
    assert coverage["profile"]=="reference-ontology-import"
    assert coverage["tabular_conversion_coverage"]=="not-applicable"
    assert "source_checksum" in coverage["integrity_metrics"]
    assert policy["schema_ownership"]=="upstream"
    assert status["profile"]=="reference-ontology-import"

def test_validated_import_has_integrity_evidence():
    report=json.loads((ROOT/"reports/reference-integrity.json").read_text())
    status=json.loads((ROOT/"health/build-status.json").read_text())
    assert status["status"]=="validated-reference-import"
    assert report["rdf_parquet_integrity"]["statement_rows"]==status["rdf_statement_rows"]
    assert report["rdf_parquet_integrity"]["null_spo_cells"]==0
    assert report["deterministic_complete_subject_sample"]["statements"]>0
