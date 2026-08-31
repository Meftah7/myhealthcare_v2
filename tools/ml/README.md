# No-show model (RQ2)

Offline training for the appointment no-show predictor. The app does **pure-Dart
inference** at runtime (`lib/services/ml/`) — Python is never shipped.

## Pipeline

```bash
python -m venv venv
venv\Scripts\pip install -r requirements.txt

venv\Scripts\python generate_dataset.py   # -> dataset.csv (mirrors the Dart seeder)
venv\Scripts\python train_no_show.py      # -> assets/models/no_show_model.json, _split.npz
venv\Scripts\python evaluate.py           # -> docs/ml_results.md, docs/roc_curve.png
venv\Scripts\python export_parity.py      # -> test/support/parity_cases.json
```

Then run the Dart parity check:

```bash
flutter test test/services/no_show_parity_test.dart
```

## Files

| File | Role |
|---|---|
| `features.py` | The 11 features + encoding. **Must stay in sync with `lib/services/ml/feature_extractor.dart`** — the parity test enforces it. |
| `generate_dataset.py` | Synthetic history; `hidden_probability()` mirrors `Seeder._noShowProbability` so the model works on the app's seeded data. |
| `train_no_show.py` | Stratified split, `StandardScaler`, class-balanced `LogisticRegression`. Exports coef + intercept + scaler params + risk-band thresholds. |
| `evaluate.py` | Accuracy / precision / recall / F1 / ROC-AUC / confusion matrix vs a majority-class and a heuristic baseline. |
| `export_parity.py` | Freezes `(features -> probability)` cases for the 1e-6 Python↔Dart parity test (P4-11). |

## Committed vs regenerable

- **Committed:** `assets/models/no_show_model.json`, `test/support/parity_cases.json`,
  `docs/ml_results.md`, `docs/roc_curve.png`.
- **Git-ignored (regenerable):** `venv/`, `dataset.csv`, `_split.npz`.

## Current results

Logistic regression on a 2,145-appointment held-out set (25% no-show rate):
**accuracy 0.73 · precision 0.48 · recall 0.62 · F1 0.54 · ROC-AUC 0.75** —
clearly above the heuristic baseline (AUC 0.68) and the only model with non-zero
recall. `prior_no_show_rate` and `lead_time_days` are the dominant features.
