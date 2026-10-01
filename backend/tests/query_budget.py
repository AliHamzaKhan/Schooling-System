"""O03 query-budget and latency measurement helpers for isolated tests.

``count_queries`` attaches a SQLAlchemy cursor listener to every engine for the
duration of a block and counts the SQL statements a request issues.  Tests are
run sequentially by the isolated runner, so a module-level recorder is enough.

``measure_endpoint`` repeats a request and returns statement counts plus
wall-clock latency percentiles.  Latency is reported, never asserted: it
depends on the host, so only statement counts are release-blocking budgets.
Set ``O03_MEASUREMENT_REPORT`` to a file path to write the collected
measurements as JSON evidence for the progress log.
"""
from __future__ import annotations

import json
import os
import statistics
import time
from contextlib import contextmanager
from dataclasses import asdict, dataclass, field
from typing import Any, Iterator

from sqlalchemy import event
from sqlalchemy.engine import Engine


class QueryRecorder:
    def __init__(self) -> None:
        self.statements: list[str] = []

    @property
    def count(self) -> int:
        return len(self.statements)


@contextmanager
def count_queries() -> Iterator[QueryRecorder]:
    recorder = QueryRecorder()

    def _before(conn, cursor, statement, parameters, context, executemany):  # noqa: ANN001
        recorder.statements.append(statement)

    event.listen(Engine, "before_cursor_execute", _before)
    try:
        yield recorder
    finally:
        event.remove(Engine, "before_cursor_execute", _before)


@dataclass
class EndpointMeasurement:
    name: str
    params: dict[str, Any]
    rows: int
    queries: int
    repetitions: int
    p50_ms: float
    p95_ms: float
    max_ms: float


@dataclass
class MeasurementReport:
    measurements: list[EndpointMeasurement] = field(default_factory=list)

    def add(self, measurement: EndpointMeasurement) -> None:
        self.measurements.append(measurement)

    def write_if_requested(self) -> None:
        path = os.environ.get("O03_MEASUREMENT_REPORT")
        if not path:
            return
        existing: list[dict[str, Any]] = []
        if os.path.exists(path):
            with open(path, encoding="utf-8") as handle:
                existing = json.load(handle)
        existing.extend(asdict(item) for item in self.measurements)
        with open(path, "w", encoding="utf-8") as handle:
            json.dump(existing, handle, indent=2)


def _percentile(samples: list[float], fraction: float) -> float:
    ordered = sorted(samples)
    index = min(len(ordered) - 1, max(0, round(fraction * (len(ordered) - 1))))
    return ordered[index]


async def measure_endpoint(
    client,
    name: str,
    url: str,
    headers: dict[str, str],
    params: dict[str, Any],
    *,
    repetitions: int = 15,
) -> EndpointMeasurement:
    """Warm once, then record statement counts and latency for ``repetitions``."""
    warm = await client.get(url, headers=headers, params=params)
    assert warm.status_code == 200, warm.text
    counts: set[int] = set()
    durations: list[float] = []
    rows = 0
    for _ in range(repetitions):
        with count_queries() as recorder:
            started = time.perf_counter()
            response = await client.get(url, headers=headers, params=params)
            durations.append((time.perf_counter() - started) * 1000)
        assert response.status_code == 200, response.text
        body = response.json()
        rows = len(body) if isinstance(body, list) else len(body.get("items", []))
        counts.add(recorder.count)
    # A cached read path must not change its statement count between calls.
    assert len(counts) == 1, f"{name} issued a varying statement count: {sorted(counts)}"
    return EndpointMeasurement(
        name=name,
        params=params,
        rows=rows,
        queries=counts.pop(),
        repetitions=repetitions,
        p50_ms=round(statistics.median(durations), 2),
        p95_ms=round(_percentile(durations, 0.95), 2),
        max_ms=round(max(durations), 2),
    )
