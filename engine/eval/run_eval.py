"""Eval harness (validation gate — NOT a unit test).

Run manually against the real API:
    ANTHROPIC_API_KEY=... python -m engine.eval.run_eval

Per brief it reports: extraction (did it find the human-marked fields + category),
adaptive question count (0 for complete, 1-3 for vague), and whether the brief compiles
cleanly through the real FlyerPromptBuilder. The mock-backed test_eval_smoke proves the
harness runs without burning API calls.
"""
import json
import os

from engine.extract import extract_brief
from engine.gaps import missing_critical_fields, build_questions
from engine.schema import to_flyer_project
from prompt_builder import FlyerPromptBuilder


def load_briefs(path=None):
    path = path or os.path.join(os.path.dirname(__file__), "briefs.jsonl")
    briefs = []
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line:
                briefs.append(json.loads(line))
    return briefs


def _count_found(brief, expect_fields):
    return sum(1 for f in expect_fields if getattr(brief, f, None))


def run_eval(briefs=None, client=None, extract=None, generate=False, generator=None):
    """Returns a summary dict. `extract` is injectable so the smoke test can avoid the API."""
    briefs = briefs if briefs is not None else load_briefs()
    extract = extract or extract_brief
    results = []

    for item in briefs:
        text = item.get("text", "")
        kind = item.get("kind", "")
        expect_category = item.get("expect_category")
        expect_fields = item.get("expect_fields", [])
        row = {"text": text, "kind": kind, "error": None}
        try:
            brief = extract(text, client=client)
            row["category"] = brief.category
            row["category_ok"] = (expect_category is None) or (brief.category == expect_category)
            row["fields_found"] = _count_found(brief, expect_fields)
            row["fields_expected"] = len(expect_fields)

            qs = build_questions(brief)
            row["question_count"] = len(qs.questions)
            row["missing"] = missing_critical_fields(brief)
            if kind == "complete":
                row["question_count_ok"] = (len(qs.questions) == 0)
            elif kind == "vague":
                row["question_count_ok"] = (1 <= len(qs.questions) <= 3)
            else:
                row["question_count_ok"] = (len(qs.questions) <= 3)

            project = to_flyer_project(brief)
            package = FlyerPromptBuilder(project).build()
            row["compiled"] = bool(package.get("main_prompt"))

            if generate and generator is not None:
                from engine.tools import generate_concepts
                concepts = generate_concepts(project, generator=generator, n=1)
                row["generated"] = bool(concepts and concepts[0].image_base64)
        except Exception as e:  # pragma: no cover - exercised via the error path in smoke test
            row["error"] = str(e)
            row["category_ok"] = False
            row["question_count_ok"] = False
            row["fields_found"] = 0
            row["fields_expected"] = len(expect_fields)
            row["compiled"] = False
        results.append(row)

    n = len(results)
    return {
        "n": n,
        "compiled": sum(1 for r in results if r.get("compiled")),
        "category_ok": sum(1 for r in results if r.get("category_ok")),
        "question_count_ok": sum(1 for r in results if r.get("question_count_ok")),
        "fields_found": sum(r.get("fields_found", 0) for r in results),
        "fields_expected": sum(r.get("fields_expected", 0) for r in results),
        "errors": [r for r in results if r.get("error")],
        "results": results,
    }


if __name__ == "__main__":  # pragma: no cover - manual real-API run
    from engine.llm import get_client

    summary = run_eval(client=get_client())
    print(f"briefs:            {summary['n']}")
    print(f"compiled cleanly:  {summary['compiled']}/{summary['n']}")
    print(f"category correct:  {summary['category_ok']}/{summary['n']}")
    print(f"adaptive q-count:  {summary['question_count_ok']}/{summary['n']}")
    print(f"fields extracted:  {summary['fields_found']}/{summary['fields_expected']}")
    for r in summary["errors"]:
        print("  ERROR:", r["text"][:60], "->", r["error"])
