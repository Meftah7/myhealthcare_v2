"""Train the no-show predictor and export portable weights (P4-04, P4-06).

Stratified train/test split, StandardScaler, class-balanced logistic
regression. Exports:

  assets/models/no_show_model.json   coef / intercept / scaler / schema
  tools/ml/_split.npz                held-out test set (for evaluate.py)
"""

from __future__ import annotations

import json
from pathlib import Path

import numpy as np
import pandas as pd
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler

from features import FEATURE_NAMES

ROOT = Path(__file__).resolve().parents[2]
DATASET = Path(__file__).parent / "dataset.csv"
MODEL_JSON = ROOT / "assets" / "models" / "no_show_model.json"
SPLIT = Path(__file__).parent / "_split.npz"
MODEL_VERSION = "no-show-v1"
SEED = 42


def main():
    df = pd.read_csv(DATASET)
    X = df[FEATURE_NAMES].to_numpy(dtype=float)
    y = df["no_show"].to_numpy(dtype=int)

    X_tr, X_te, y_tr, y_te = train_test_split(
        X, y, test_size=0.25, random_state=SEED, stratify=y
    )

    scaler = StandardScaler().fit(X_tr)
    clf = LogisticRegression(
        class_weight="balanced", max_iter=2000, random_state=SEED
    )
    clf.fit(scaler.transform(X_tr), y_tr)

    MODEL_JSON.parent.mkdir(parents=True, exist_ok=True)
    MODEL_JSON.write_text(
        json.dumps(
            {
                "modelVersion": MODEL_VERSION,
                "featureNames": FEATURE_NAMES,
                "coef": clf.coef_[0].tolist(),
                "intercept": float(clf.intercept_[0]),
                "scalerMean": scaler.mean_.tolist(),
                "scalerScale": scaler.scale_.tolist(),
                "riskBands": {"low": 0.33, "medium": 0.66},
                "trainedOn": {
                    "rows": int(len(df)),
                    "trainRows": int(len(X_tr)),
                    "testRows": int(len(X_te)),
                    "noShowRate": float(y.mean()),
                },
            },
            indent=2,
        )
    )
    np.savez(SPLIT, X_test=X_te, y_test=y_te)

    train_acc = clf.score(scaler.transform(X_tr), y_tr)
    test_acc = clf.score(scaler.transform(X_te), y_te)
    print(f"exported {MODEL_JSON.relative_to(ROOT)}")
    print(f"train acc {train_acc:.3f}  test acc {test_acc:.3f}")
    for name, c in zip(FEATURE_NAMES, clf.coef_[0]):
        print(f"  {name:24s} {c:+.3f}")


if __name__ == "__main__":
    main()
