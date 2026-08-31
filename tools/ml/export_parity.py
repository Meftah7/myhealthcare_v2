"""Freeze a set of (features -> probability) cases for the Dart parity test
(P4-11). Writes test/support/parity_cases.json.
"""

from __future__ import annotations

import json
from pathlib import Path

import numpy as np

from features import FEATURE_NAMES, AppointmentFeatures

ROOT = Path(__file__).resolve().parents[2]
MODEL = json.loads((ROOT / "assets" / "models" / "no_show_model.json").read_text())
OUT = ROOT / "test" / "support" / "parity_cases.json"

MEAN = np.array(MODEL["scalerMean"])
SCALE = np.array(MODEL["scalerScale"])
COEF = np.array(MODEL["coef"])


def proba(vec):
    x = np.array(vec)
    z = MODEL["intercept"] + (x - MEAN) / SCALE @ COEF
    return 1.0 / (1.0 + np.exp(-z))


CASES = [
    AppointmentFeatures(2, 0.0, 0, 45, "followUp", 2, 9, True, 2),
    AppointmentFeatures(30, 0.6, 12, 22, "urgentCare", 5, 15, False, 0),
    AppointmentFeatures(14, 0.2, 4, 68, "chronicCareReview", 3, 11, True, 1),
    AppointmentFeatures(0, 0.0, 1, 30, "vaccination", 1, 8, False, 2),
    AppointmentFeatures(45, 0.85, 20, 19, "newPatient", 4, 17, False, 0),
    AppointmentFeatures(7, 0.05, 8, 55, "routineCheckup", 2, 10, True, 3),
]


def main():
    OUT.parent.mkdir(parents=True, exist_ok=True)
    out = {
        "modelVersion": MODEL["modelVersion"],
        "featureNames": FEATURE_NAMES,
        "cases": [
            {"features": c.to_vector(), "probability": proba(c.to_vector())}
            for c in CASES
        ],
    }
    OUT.write_text(json.dumps(out, indent=2))
    print(f"wrote {OUT.relative_to(ROOT)} ({len(CASES)} cases)")
    for c in out["cases"]:
        print(f"  p={c['probability']:.6f}")


if __name__ == "__main__":
    main()
