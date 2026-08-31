/// Clinical vocab for the synthetic seeder (P1-19): departments, specialties,
/// chronic conditions, medications, and lab analytes with real reference
/// ranges (adult, generic units).
library;

class DepartmentSeed {
  const DepartmentSeed(this.name, this.description, this.specialties);
  final String name;
  final String description;
  final List<String> specialties;
}

const departments = [
  DepartmentSeed(
    'Family Medicine',
    'Primary care and chronic disease follow-up',
    ['Family Physician', 'General Practitioner'],
  ),
  DepartmentSeed(
    'Internal Medicine',
    'General adult medicine and diagnostics',
    ['Internist', 'Endocrinologist'],
  ),
  DepartmentSeed('Cardiology', 'Heart and vascular care', ['Cardiologist']),
  DepartmentSeed('Paediatrics', 'Care for children and adolescents', [
    'Paediatrician',
  ]),
  DepartmentSeed('Obstetrics & Gynaecology', "Women's health and maternity", [
    'Obstetrician',
    'Gynaecologist',
  ]),
];

/// A chronic condition and the analytes / vitals it tends to disturb.
class ConditionSeed {
  const ConditionSeed(
    this.name, {
    this.raises = const [],
    this.lowers = const [],
  });
  final String name;
  final List<String> raises;
  final List<String> lowers;
}

const chronicConditions = [
  ConditionSeed('Type 2 Diabetes', raises: ['HbA1c', 'Fasting Glucose']),
  ConditionSeed('Hypertension', raises: ['Systolic BP', 'Diastolic BP']),
  ConditionSeed(
    'Hyperlipidaemia',
    raises: ['LDL Cholesterol', 'Total Cholesterol'],
  ),
  ConditionSeed('Asthma', lowers: ['SpO2']),
  ConditionSeed('Chronic Kidney Disease', raises: ['Creatinine', 'Potassium']),
  ConditionSeed('Hypothyroidism', raises: ['TSH']),
  ConditionSeed('Anaemia', lowers: ['Haemoglobin']),
  ConditionSeed('Obesity', raises: ['HbA1c', 'LDL Cholesterol']),
];

const medicationsByCondition = <String, List<String>>{
  'Type 2 Diabetes': [
    'Metformin 500mg',
    'Metformin 1g',
    'Gliclazide 80mg',
    'Empagliflozin 10mg',
  ],
  'Hypertension': [
    'Amlodipine 5mg',
    'Lisinopril 10mg',
    'Losartan 50mg',
    'Bisoprolol 5mg',
  ],
  'Hyperlipidaemia': [
    'Atorvastatin 20mg',
    'Rosuvastatin 10mg',
    'Simvastatin 40mg',
  ],
  'Asthma': ['Salbutamol inhaler', 'Budesonide/Formoterol inhaler'],
  'Chronic Kidney Disease': ['Sevelamer 800mg', 'Furosemide 40mg'],
  'Hypothyroidism': ['Levothyroxine 50mcg', 'Levothyroxine 100mcg'],
  'Anaemia': ['Ferrous sulfate 200mg', 'Folic acid 5mg'],
  'Obesity': ['Orlistat 120mg'],
};

const generalMedications = [
  'Paracetamol 500mg',
  'Ibuprofen 400mg',
  'Omeprazole 20mg',
  'Amoxicillin 500mg',
  'Cetirizine 10mg',
  'Vitamin D 1000IU',
];

/// A lab analyte with an adult reference range.
class AnalyteSeed {
  const AnalyteSeed(
    this.name,
    this.unit,
    this.low,
    this.high,
    this.healthyMean,
  );
  final String name;
  final String unit;
  final double low;
  final double high;
  final double healthyMean;
}

const analytes = [
  AnalyteSeed('Haemoglobin', 'g/dL', 13.0, 17.0, 14.5),
  AnalyteSeed('HbA1c', '%', 4.0, 5.6, 5.2),
  AnalyteSeed('Fasting Glucose', 'mmol/L', 3.9, 5.5, 4.8),
  AnalyteSeed('Creatinine', 'umol/L', 60, 110, 82),
  AnalyteSeed('Potassium', 'mmol/L', 3.5, 5.1, 4.2),
  AnalyteSeed('Sodium', 'mmol/L', 135, 145, 140),
  AnalyteSeed('Total Cholesterol', 'mmol/L', 3.0, 5.2, 4.4),
  AnalyteSeed('LDL Cholesterol', 'mmol/L', 1.5, 3.4, 2.6),
  AnalyteSeed('HDL Cholesterol', 'mmol/L', 1.0, 2.2, 1.4),
  AnalyteSeed('TSH', 'mIU/L', 0.4, 4.0, 1.8),
  AnalyteSeed('ALT', 'U/L', 7, 55, 25),
  AnalyteSeed('Vitamin D', 'ng/mL', 20, 50, 32),
];

const visitReasons = [
  'Routine follow-up',
  'Medication review',
  'Blood pressure check',
  'Diabetes review',
  'Cough and cold',
  'Fatigue',
  'Abdominal pain',
  'Headache',
  'Annual check-up',
  'Lab results review',
  'Prescription renewal',
  'Chest discomfort',
];

const facilities = [
  'Salmaniya Medical Complex',
  'King Hamad University Hospital',
  'BDF Hospital',
  'Bahrain Specialist Hospital',
  'Al Kindi Specialised Hospital',
  'Ibn Al-Nafees Hospital',
];
