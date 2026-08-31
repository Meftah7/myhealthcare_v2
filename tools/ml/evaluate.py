"""Evaluate the trained model + baselines, write the results chapter inputs
(P4-05, P4-07).

  docs/ml_results.md      metrics table + confusion matrix + baseline comparison
  docs/roc_curve.png      ROC curve
"""

from __future__ import annotations

import json
from pathlib import Path

import numpy as np

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
from sklearn.metrics import (  # noqa: E402
    accuracy_score,
    confusion_matrix,
    f1_score,
    precision_score,
    recall_score,
    roc_auc_score,
    roc_curve,
)

from features import FEATURE_NAMES  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
MODEL_JSON = ROOT / "assets" / "models" / "no_show_model.json"
SPLIT = Path(__file__).parent / "_split.npz"
RESULTS = ROOT / "docs" / "ml_results.md"
ROC_PNG = ROOT / "docs" / "roc_curve.png"


def _predict_proba(model, X):
    mean = np.array(model["scalerMean"])
    scale = np.array(model["scalerScale"])
    coef = np.array(model["coef"])
    z = model["intercept"] + (X - mean) / scale @ coef
    return 1.0 / (1.0 + np.exp(-z))


def _metrics(y, pred):
    return {
        "accuracy": accuracy_score(y, pred),
        "precision": precision_score(y, pred, zero_division=0),
        "recall": recall_score(y, pred, zero_division=0),
        "f1": f1_score(y, pred, zero_division=0),
    }


def main():
    model = json.loads(MODEL_JSON.read_text())
    data = np.load(SPLIT)
    X, y = data["X_test"], data["y_test"]

    proba = _predict_proba(model, X)
    pred = (proba >= 0.5).astype(int)

    model_m = _metrics(y, pred)
    model_m["roc_auc"] = roc_auc_score(y, proba)
    cm = confusion_matrix(y, pred)

    # Baselines.
    majority = np.zeros_like(y)  # always "will attend"
    base_majority = _metrics(y, majority)

    # Heuristic: flag as no-show if prior_no_show_rate > 0.25 or lead_time > 21.
    i_rate = FEATURE_NAMES.index("prior_no_show_rate")
    i_lead = FEATURE_NAMES.index("lead_time_days")
    heuristic = ((X[:, i_rate] > 0.25) | (X[:, i_lead] > 21)).astype(int)
    base_heuristic = _metrics(y, heuristic)
    base_heuristic["roc_auc"] = roc_auc_score(y, heuristic)

    # ROC curve.
    fpr, tpr, _ = roc_curve(y, proba)
    plt.figure(figsize=(5, 5))
    plt.plot(fpr, tpr, label=f"model (AUC = {model_m['roc_auc']:.3f})")
    plt.plot([0, 1], [0, 1], "k--", linewidth=1, label="chance")
    plt.xlabel("False positive rate")
    plt.ylabel("True positive rate")
    plt.title("No-show predictor - ROC")
    plt.legend()
    plt.tight_layout()
    ROC_PNG.parent.mkdir(parents=True, exist_ok=True)
    plt.savefig(ROC_PNG, dpi=150)

    def row(name, m):
        return (
            f"| {name} | {m['accuracy']:.3f} | {m.get('precision', 0):.3f} | "
            f"{m.get('recall', 0):.3f} | {m.get('f1', 0):.3f} | "
            f"{m.get('roc_auc', float('nan')):.3f} |"
        )

    RESULTS.write_text(
        "# No-show predictor - results (RQ2)\n\n"
        f"Model: `{model['modelVersion']}` - class-balanced logistic regression\n"
        f"Test set: {len(y)} appointments - "
        f"no-show rate {y.mean():.1%}\n\n"
        "## Metrics\n\n"
        "| Model | Accuracy | Precision | Recall | F1 | ROC-AUC |\n"
        "|---|---|---|---|---|---|\n"
        f"{row('Logistic regression', model_m)}\n"
        f"{row('Baseline: majority class', base_majority)}\n"
        f"{row('Baseline: simple heuristic', base_heuristic)}\n\n"
        "## Confusion matrix (model, threshold 0.5)\n\n"
        "| | pred attend | pred no-show |\n"
        "|---|---|---|\n"
        f"| **actual attend** | {cm[0, 0]} | {cm[0, 1]} |\n"
        f"| **actual no-show** | {cm[1, 0]} | {cm[1, 1]} |\n\n"
        "## Feature coefficients (scaled)\n\n"
        "| Feature | Coefficient |\n|---|---|\n"
        + "".join(
            f"| {n} | {c:+.3f} |\n"
            for n, c in sorted(
                zip(FEATURE_NAMES, model["coef"]),
                key=lambda kv: -abs(kv[1]),
            )
        )
        + f"\nIntercept: {model['intercept']:+.3f}\n\n"
        f"![ROC curve](roc_curve.png)\n"
    )

    print(f"wrote {RESULTS.relative_to(ROOT)} and {ROC_PNG.relative_to(ROOT)}")
    print(
        f"model  acc={model_m['accuracy']:.3f}  f1={model_m['f1']:.3f}  "
        f"auc={model_m['roc_auc']:.3f}"
    )
    print(f"heur   acc={base_heuristic['accuracy']:.3f}")
    print(f"major  acc={base_majority['accuracy']:.3f}")


if __name__ == "__main__":
    main()
