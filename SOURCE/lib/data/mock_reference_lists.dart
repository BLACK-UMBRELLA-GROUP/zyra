// Static reference lists standing in for real searchable country/
// language/ethnicity datasets, which need a real backend/API to back
// properly. Good enough for today's testable build — swap for a real
// data source (e.g. a countries package or Supabase table) later.

const List<String> mockCountries = [
  'United Kingdom', 'Pakistan', 'India', 'Bangladesh', 'Somalia', 'Nigeria', 'Egypt', 'Morocco',
  'Turkey', 'Saudi Arabia', 'United Arab Emirates', 'Indonesia', 'Malaysia', 'United States',
  'Canada', 'France', 'Germany', 'Algeria', 'Tunisia', 'Jordan', 'Lebanon', 'Syria', 'Iraq',
  'Yemen', 'Sudan', 'Afghanistan', 'Iran', 'Albania', 'Bosnia and Herzegovina', 'South Africa',
];

const List<String> mockLanguages = [
  'English', 'Urdu', 'Arabic', 'Bengali', 'Somali', 'Hausa', 'Turkish', 'Punjabi', 'Gujarati',
  'Malay', 'Indonesian', 'French', 'Farsi/Persian', 'Pashto', 'Albanian', 'Bosnian', 'Hindi',
  'Swahili', 'Kurdish', 'Rohingya',
];

const List<String> mockEthnicities = [
  'South Asian', 'Arab', 'Black African', 'Black Caribbean', 'East Asian', 'Southeast Asian',
  'White / Caucasian', 'North African', 'Turkish', 'Mixed Ethnicity', 'Central Asian',
  'Other',
];
