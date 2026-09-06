/// How each kind of ID is written for a person to read.
///
/// Shared rather than kept beside the picker that first needed it: the tenant
/// chooses "Driving licence" from a list, and their landlord must not then be
/// shown "DRIVERS_LICENSE" for the same document. Two copies of this map would
/// drift the first time one gained an entry.
const idTypeLabels = {
  'PHILSYS': 'PhilSys (National ID)',
  'UMID': 'UMID',
  'SSS': 'SSS',
  'GSIS': 'GSIS',
  'DRIVERS_LICENSE': 'Driving licence',
  'PASSPORT': 'Passport',
  'PHILHEALTH': 'PhilHealth',
  'POSTAL': 'Postal ID',
  'VOTERS': 'Voter ID',
  'TIN': 'TIN',
  'PRC': 'PRC',
  'OTHER': 'Other',
};

/// The label for a raw enum value, falling back to the value itself.
///
/// A new ID type added to the backend shows as its own name rather than as
/// nothing at all — ugly, and better than a blank where a document should be.
String idTypeLabel(String? raw) =>
    raw == null ? '' : (idTypeLabels[raw] ?? raw);

/// What a photograph is of.
const docTypeLabels = {
  'VALID_ID': 'Valid ID',
  'TENANT_PHOTO': 'Photo',
};

String docTypeLabel(String? raw) =>
    raw == null ? '' : (docTypeLabels[raw] ?? raw);
