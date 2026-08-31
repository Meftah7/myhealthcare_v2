"""Synthetic appointment history with a learnable no-show signal (P4-02).

Mirrors the Dart seeder's hidden no-show logic (lib/data/seed/seeder.dart):

    p = noShowTendency
        + clamp(leadDays, 0, 45) / 45 * 0.35
        + (0.06 if age < 25 else 0)
        + (-0.05 if has_chronic else 0)
    p = clamp(p, 0.02, 0.92)
    realised no-show  when  rand < p * 0.85
    cancelled         when  rand < p * 0.85 + 0.05
    else completed

    noShowTendency: 24% of patients ~ U(0.45, 0.85), the rest ~ U(0.02, 0.11)

`noShowTendency` is hidden; the model must learn to infer it from the
observable `prior_no_show_rate` plus lead time and age. A little Gaussian
noise on the features keeps accuracy realistic (not a perfect recovery).

Writes tools/ml/dataset.csv.
"""

from __future__ import annotations

import csv
import random
from pathlib import Path

from features import FEATURE_NAMES, AppointmentFeatures

SEED = 20260101
N_PATIENTS = 450
HISTORY_DAYS = 1100
OUT = Path(__file__).parent / "dataset.csv"

VISIT_TYPES = [
    "newPatient", "followUp", "routineCheckup", "chronicCareReview",
    "urgentCare", "procedure", "vaccination", "labOnly",
]


def hidden_probability(tendency, lead_days, age, has_chronic):
    p = tendency
    p += min(max(lead_days, 0), 45) / 45 * 0.35
    p += 0.06 if age < 25 else 0.0
    p += -0.05 if has_chronic else 0.0
    return min(max(p, 0.02), 0.92)


def main():
    rng = random.Random(SEED)
    rows = []

    for _ in range(N_PATIENTS):
        age = rng.randint(8, 82)
        cond_count = (
            _weighted(rng, [0.85, 0.13, 0.02]) if age < 30
            else _weighted(rng, [0.45, 0.35, 0.15, 0.05]) if age < 55
            else _weighted(rng, [0.15, 0.30, 0.30, 0.20, 0.05])
        )
        has_chronic = cond_count > 0
        tendency = (
            0.45 + rng.random() * 0.40 if rng.random() < 0.24
            else 0.02 + rng.random() * 0.09
        )
        interval = (24 + rng.randint(0, 34)) if has_chronic else (75 + rng.randint(0, 120))

        past_total = 0
        past_no_show = 0
        day = rng.randint(0, interval)
        first = True

        while day < HISTORY_DAYS:
            lead_days = 3 + rng.randint(0, 20)
            hour = 8 + rng.randint(0, 5)
            weekday = ((day % 5)) + 1  # clinics run Mon–Fri here
            visit = "chronicCareReview" if has_chronic and rng.random() < 0.6 \
                else rng.choice(VISIT_TYPES)
            reminders_ack = 0 if first else rng.randint(0, 2)

            prior_rate = (past_no_show / past_total) if past_total else 0.0

            p = hidden_probability(tendency, lead_days, age, has_chronic)
            r = rng.random()
            if r < p * 0.85:
                label = 1  # no-show
            elif r < p * 0.85 + 0.05:
                label = None  # cancelled — excluded from training
            else:
                label = 0  # completed

            if label is not None:
                feats = AppointmentFeatures(
                    lead_time_days=lead_days + rng.gauss(0, 0.8),
                    prior_no_show_rate=min(1.0, max(0.0, prior_rate + rng.gauss(0, 0.02))),
                    prior_appointment_count=past_total,
                    age_years=age,
                    visit_type=visit,
                    day_of_week=weekday,
                    hour_of_day=hour,
                    has_chronic_condition=has_chronic,
                    reminders_acknowledged=reminders_ack,
                )
                rows.append(feats.to_vector() + [label])

            past_total += 1
            if label == 1:
                past_no_show += 1
            first = False
            day += interval + rng.randint(-10, 10)

    with OUT.open("w", newline="") as f:
        w = csv.writer(f)
        w.writerow(FEATURE_NAMES + ["no_show"])
        w.writerows(rows)

    n = len(rows)
    pos = sum(row[-1] for row in rows)
    print(f"wrote {OUT}  rows={n}  no_show={pos} ({pos / n:.1%})")


def _weighted(rng, weights):
    r = rng.random()
    acc = 0.0
    for i, wt in enumerate(weights):
        acc += wt
        if r < acc:
            return i
    return len(weights) - 1


if __name__ == "__main__":
    main()
