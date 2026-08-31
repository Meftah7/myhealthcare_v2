"""The 11 no-show features and their encoding (P4-03).

This encoding is the CONTRACT: `lib/services/ml/feature_extractor.dart` must
produce a byte-identical vector for the same appointment, and the Python/Dart
parity test (P4-11) asserts agreement within 1e-6.

Order matters — it is the column order of the exported model JSON.
"""

from __future__ import annotations

from dataclasses import dataclass

FEATURE_NAMES = [
    "lead_time_days",          # days between booking and the slot
    "prior_no_show_rate",      # historical no-show rate for this patient [0,1]
    "prior_appointment_count", # completed/no-show/cancelled appts before this
    "age_years",
    "visit_type_urgent",       # 1 if urgentCare
    "visit_type_routine",      # 1 if routineCheckup or chronicCareReview
    "day_of_week",             # 1 = Monday .. 7 = Sunday
    "hour_of_day",             # 24h
    "is_first_visit",          # 1 if prior_appointment_count == 0
    "has_chronic_condition",
    "reminders_acknowledged",  # count [0,3]
]

# Clamp ranges applied before scaling (keeps outliers from dominating).
CLAMP = {
    "lead_time_days": (0.0, 60.0),
    "prior_no_show_rate": (0.0, 1.0),
    "prior_appointment_count": (0.0, 40.0),
    "age_years": (0.0, 100.0),
    "day_of_week": (1.0, 7.0),
    "hour_of_day": (0.0, 23.0),
    "reminders_acknowledged": (0.0, 3.0),
}

VISIT_URGENT = {"urgentCare"}
VISIT_ROUTINE = {"routineCheckup", "chronicCareReview"}


@dataclass
class AppointmentFeatures:
    lead_time_days: float
    prior_no_show_rate: float
    prior_appointment_count: int
    age_years: int
    visit_type: str
    day_of_week: int
    hour_of_day: int
    has_chronic_condition: bool
    reminders_acknowledged: int

    def to_vector(self) -> list[float]:
        first_visit = 1.0 if self.prior_appointment_count == 0 else 0.0
        raw = {
            "lead_time_days": float(self.lead_time_days),
            "prior_no_show_rate": float(self.prior_no_show_rate),
            "prior_appointment_count": float(self.prior_appointment_count),
            "age_years": float(self.age_years),
            "visit_type_urgent": 1.0 if self.visit_type in VISIT_URGENT else 0.0,
            "visit_type_routine": 1.0 if self.visit_type in VISIT_ROUTINE else 0.0,
            "day_of_week": float(self.day_of_week),
            "hour_of_day": float(self.hour_of_day),
            "is_first_visit": first_visit,
            "has_chronic_condition": 1.0 if self.has_chronic_condition else 0.0,
            "reminders_acknowledged": float(self.reminders_acknowledged),
        }
        out = []
        for name in FEATURE_NAMES:
            v = raw[name]
            if name in CLAMP:
                lo, hi = CLAMP[name]
                v = max(lo, min(hi, v))
            out.append(v)
        return out
