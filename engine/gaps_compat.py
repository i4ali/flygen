"""Wire-shape dataclasses (Question, QuestionSet) preserved out of gaps.py so the
SSE `questions` payload survives gaps.py's deletion. Copied verbatim - do not change shapes."""
from dataclasses import dataclass, field
from typing import List, Optional


@dataclass
class Question:
    field: str
    text: str
    options: Optional[List[dict]] = None   # when set, rendered as a labeled picker (e.g. size)


@dataclass
class QuestionSet:
    questions: List[Question] = field(default_factory=list)
    stage: str = "gaps"   # "gaps" (up-front intake) | "design" (must-fixes after the design brief)
