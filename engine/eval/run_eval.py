"""Eval harness (validation gate, NOT a unit test) for the one-brain interpreter.

Run manually against the real API:
    OPENROUTER_API_KEY=... .venv/bin/python -m engine.eval.run_eval

Per brief it reports status, the questions asked, the design decision keys (and any flagged
unsupported), and the proposed creative_elements with sensitivity - a table for human judgment
against each row's `expect`. The mock-backed test_eval_smoke proves the harness runs without API.
"""
import json
import os
from engine.interpret import interpret as _interpret
from engine.llm import get_client


def load_briefs(path=None):
    path = path or os.path.join(os.path.dirname(__file__), "briefs.jsonl")
    with open(path, encoding="utf-8") as f:
        return [json.loads(line) for line in f if line.strip()]


def _row_result(row, turn):
    return {
        "id": row.get("id", ""),
        "expect": row.get("expect", ""),
        "status": turn.status,
        "questions": [q.field for q in turn.questions],
        "decisions": [d.key for d in turn.decisions],
        "unsupported": [d.key for d in turn.decisions if not d.supported],
        "creative_elements": [(e.what, e.sensitivity) for e in turn.creative_elements],
    }


def run_eval(briefs=None, client=None, interpret=None):
    """Run the corpus through interpret and return a summary dict. `interpret` is injectable
    so the smoke test can avoid the API."""
    briefs = briefs if briefs is not None else load_briefs()
    interpret = interpret or _interpret
    if client is None and interpret is _interpret:
        client = get_client()
    results = [_row_result(row, interpret(None, row["text"], None, client=client)) for row in briefs]
    return {"n": len(results), "results": results}


def _print_table(summary):
    """Print a human-readable table for manual judgment against each row's expect."""
    col_w = {"id": 24, "status": 11, "questions": 30, "decisions": 36, "creative": 40, "expect": 50}
    header = (
        f"{'ID':<{col_w['id']}}  "
        f"{'STATUS':<{col_w['status']}}  "
        f"{'QUESTIONS':<{col_w['questions']}}  "
        f"{'DECISIONS (unsupported=*)':<{col_w['decisions']}}  "
        f"{'CREATIVE ELEMENTS':<{col_w['creative']}}  "
        f"EXPECT"
    )
    print(header)
    print("-" * len(header))
    for r in summary["results"]:
        questions_str = ", ".join(r["questions"]) if r["questions"] else "-"
        decision_parts = []
        for key in r["decisions"]:
            marker = "*" if key in r["unsupported"] else ""
            decision_parts.append(f"{key}{marker}")
        decisions_str = ", ".join(decision_parts) if decision_parts else "-"
        creative_parts = []
        for (what, sensitivity) in r["creative_elements"]:
            label = "[sensitive]" if sensitivity == "sensitive" else "[safe]"
            short = what[:22] + ".." if len(what) > 24 else what
            creative_parts.append(f"{short}{label}")
        creative_str = "; ".join(creative_parts) if creative_parts else "-"

        # Truncate long values for column alignment
        questions_str = questions_str[:col_w["questions"] - 2] if len(questions_str) > col_w["questions"] else questions_str
        decisions_str = decisions_str[:col_w["decisions"] - 2] if len(decisions_str) > col_w["decisions"] else decisions_str
        creative_str = creative_str[:col_w["creative"] - 2] if len(creative_str) > col_w["creative"] else creative_str

        print(
            f"{r['id']:<{col_w['id']}}  "
            f"{r['status']:<{col_w['status']}}  "
            f"{questions_str:<{col_w['questions']}}  "
            f"{decisions_str:<{col_w['decisions']}}  "
            f"{creative_str:<{col_w['creative']}}  "
            f"{r['expect']}"
        )


if __name__ == "__main__":   # manual, real API
    _print_table(run_eval())
