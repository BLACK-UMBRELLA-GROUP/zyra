// ZYRA reference data — countries, nationalities, languages, ethnicities.
//
// GENERATED 2026-08-01. Replaces data/mock_reference_lists.dart, whose own
// header admitted it was a stand-in: 30 countries, 20 languages, 12
// ethnicities. A Seeker born in Kenya, Kosovo, Uzbekistan or the
// Philippines could not answer "which country were you born in" — there was
// no Other and no free-text fallback.
//
// THE RULE THAT MATTERS MOST HERE:
//
//   STORE THE CODE. NEVER STORE THE LABEL.
//
// Every entry has a stable machine code and a human label. `code` is what
// goes in the database; `name` is only ever for display. This is not
// tidiness — it is what stops the Founder's stated fear ("I'd rather solve
// this once than migrate user data later") from ever happening. Relabel
// "Turkey" to "Türkiye" and no user row changes, because the row says 'TR'.
//
// It is also already load-bearing. ISO 639-1 names two of this audience's
// most-spoken languages "Panjabi" and "Pushto" — spellings nobody would
// search for — and suffixes others "(macrolanguage)". Those are corrected in
// the labels below while the codes stay canonical. Had the labels been the
// stored value, correcting them would have orphaned every affected user.
//
// SOURCES
//   Countries    ISO 3166-1 alpha-2, via pycountry. 197 = UN member states
//                and observers, plus Taiwan and Kosovo (XK, user-assigned).
//                Uninhabited territories deliberately excluded.
//   Nationality  Demonyms, hand-written and asserted to cover all 197.
//                A nationality is "Pakistani", not "Pakistan" — the old
//                list used the country names for both, which typed the
//                data wrong at source.
//   Languages    ISO 639-1, via pycountry. All 184.
//   Ethnicity    No ISO standard exists. ZYRA's own codes, below.
//
// Do not hand-edit country or language entries. Correct labels via the
// override map in the generator and regenerate, so codes cannot drift.

class ZyraRefItem {
  /// Stored in the database. Stable forever.
  final String code;

  /// Shown to the user. Safe to change at any time.
  final String name;

  const ZyraRefItem(this.code, this.name);
}

class ZyraCountryItem {
  final String code;
  final String name;

  /// Demonym — "Pakistani" for PK. Same country list backs both the
  /// country-of-birth and nationality questions; only the label differs.
  final String nationality;

  const ZyraCountryItem(this.code, this.name, this.nationality);
}

/// 197 countries, ISO 3166-1 alpha-2.
const List<ZyraCountryItem> zyraCountries = [
  ZyraCountryItem('AF', 'Afghanistan', 'Afghan'),
  ZyraCountryItem('AL', 'Albania', 'Albanian'),
  ZyraCountryItem('DZ', 'Algeria', 'Algerian'),
  ZyraCountryItem('AD', 'Andorra', 'Andorran'),
  ZyraCountryItem('AO', 'Angola', 'Angolan'),
  ZyraCountryItem('AG', 'Antigua and Barbuda', 'Antiguan and Barbudan'),
  ZyraCountryItem('AR', 'Argentina', 'Argentine'),
  ZyraCountryItem('AM', 'Armenia', 'Armenian'),
  ZyraCountryItem('AU', 'Australia', 'Australian'),
  ZyraCountryItem('AT', 'Austria', 'Austrian'),
  ZyraCountryItem('AZ', 'Azerbaijan', 'Azerbaijani'),
  ZyraCountryItem('BS', 'Bahamas', 'Bahamian'),
  ZyraCountryItem('BH', 'Bahrain', 'Bahraini'),
  ZyraCountryItem('BD', 'Bangladesh', 'Bangladeshi'),
  ZyraCountryItem('BB', 'Barbados', 'Barbadian'),
  ZyraCountryItem('BY', 'Belarus', 'Belarusian'),
  ZyraCountryItem('BE', 'Belgium', 'Belgian'),
  ZyraCountryItem('BZ', 'Belize', 'Belizean'),
  ZyraCountryItem('BJ', 'Benin', 'Beninese'),
  ZyraCountryItem('BT', 'Bhutan', 'Bhutanese'),
  ZyraCountryItem('BO', 'Bolivia', 'Bolivian'),
  ZyraCountryItem('BA', 'Bosnia and Herzegovina', 'Bosnian'),
  ZyraCountryItem('BW', 'Botswana', 'Botswanan'),
  ZyraCountryItem('BR', 'Brazil', 'Brazilian'),
  ZyraCountryItem('BN', 'Brunei', 'Bruneian'),
  ZyraCountryItem('BG', 'Bulgaria', 'Bulgarian'),
  ZyraCountryItem('BF', 'Burkina Faso', 'Burkinabè'),
  ZyraCountryItem('BI', 'Burundi', 'Burundian'),
  ZyraCountryItem('CV', 'Cabo Verde', 'Cabo Verdean'),
  ZyraCountryItem('KH', 'Cambodia', 'Cambodian'),
  ZyraCountryItem('CM', 'Cameroon', 'Cameroonian'),
  ZyraCountryItem('CA', 'Canada', 'Canadian'),
  ZyraCountryItem('CF', 'Central African Republic', 'Central African'),
  ZyraCountryItem('TD', 'Chad', 'Chadian'),
  ZyraCountryItem('CL', 'Chile', 'Chilean'),
  ZyraCountryItem('CN', 'China', 'Chinese'),
  ZyraCountryItem('CO', 'Colombia', 'Colombian'),
  ZyraCountryItem('KM', 'Comoros', 'Comoran'),
  ZyraCountryItem('CR', 'Costa Rica', 'Costa Rican'),
  ZyraCountryItem('HR', 'Croatia', 'Croatian'),
  ZyraCountryItem('CU', 'Cuba', 'Cuban'),
  ZyraCountryItem('CY', 'Cyprus', 'Cypriot'),
  ZyraCountryItem('CZ', 'Czechia', 'Czech'),
  ZyraCountryItem('CI', 'Côte d\'Ivoire', 'Ivorian'),
  ZyraCountryItem('CD', 'Democratic Republic of the Congo', 'Congolese (DRC)'),
  ZyraCountryItem('DK', 'Denmark', 'Danish'),
  ZyraCountryItem('DJ', 'Djibouti', 'Djiboutian'),
  ZyraCountryItem('DM', 'Dominica', 'Dominican'),
  ZyraCountryItem('DO', 'Dominican Republic', 'Dominican'),
  ZyraCountryItem('EC', 'Ecuador', 'Ecuadorian'),
  ZyraCountryItem('EG', 'Egypt', 'Egyptian'),
  ZyraCountryItem('SV', 'El Salvador', 'Salvadoran'),
  ZyraCountryItem('GQ', 'Equatorial Guinea', 'Equatorial Guinean'),
  ZyraCountryItem('ER', 'Eritrea', 'Eritrean'),
  ZyraCountryItem('EE', 'Estonia', 'Estonian'),
  ZyraCountryItem('SZ', 'Eswatini', 'Swazi'),
  ZyraCountryItem('ET', 'Ethiopia', 'Ethiopian'),
  ZyraCountryItem('FJ', 'Fiji', 'Fijian'),
  ZyraCountryItem('FI', 'Finland', 'Finnish'),
  ZyraCountryItem('FR', 'France', 'French'),
  ZyraCountryItem('GA', 'Gabon', 'Gabonese'),
  ZyraCountryItem('GM', 'Gambia', 'Gambian'),
  ZyraCountryItem('GE', 'Georgia', 'Georgian'),
  ZyraCountryItem('DE', 'Germany', 'German'),
  ZyraCountryItem('GH', 'Ghana', 'Ghanaian'),
  ZyraCountryItem('GR', 'Greece', 'Greek'),
  ZyraCountryItem('GD', 'Grenada', 'Grenadian'),
  ZyraCountryItem('GT', 'Guatemala', 'Guatemalan'),
  ZyraCountryItem('GN', 'Guinea', 'Guinean'),
  ZyraCountryItem('GW', 'Guinea-Bissau', 'Bissau-Guinean'),
  ZyraCountryItem('GY', 'Guyana', 'Guyanese'),
  ZyraCountryItem('HT', 'Haiti', 'Haitian'),
  ZyraCountryItem('HN', 'Honduras', 'Honduran'),
  ZyraCountryItem('HU', 'Hungary', 'Hungarian'),
  ZyraCountryItem('IS', 'Iceland', 'Icelandic'),
  ZyraCountryItem('IN', 'India', 'Indian'),
  ZyraCountryItem('ID', 'Indonesia', 'Indonesian'),
  ZyraCountryItem('IR', 'Iran', 'Iranian'),
  ZyraCountryItem('IQ', 'Iraq', 'Iraqi'),
  ZyraCountryItem('IE', 'Ireland', 'Irish'),
  ZyraCountryItem('IL', 'Israel', 'Israeli'),
  ZyraCountryItem('IT', 'Italy', 'Italian'),
  ZyraCountryItem('JM', 'Jamaica', 'Jamaican'),
  ZyraCountryItem('JP', 'Japan', 'Japanese'),
  ZyraCountryItem('JO', 'Jordan', 'Jordanian'),
  ZyraCountryItem('KZ', 'Kazakhstan', 'Kazakhstani'),
  ZyraCountryItem('KE', 'Kenya', 'Kenyan'),
  ZyraCountryItem('KI', 'Kiribati', 'I-Kiribati'),
  ZyraCountryItem('XK', 'Kosovo', 'Kosovan'),
  ZyraCountryItem('KW', 'Kuwait', 'Kuwaiti'),
  ZyraCountryItem('KG', 'Kyrgyzstan', 'Kyrgyzstani'),
  ZyraCountryItem('LA', 'Laos', 'Lao'),
  ZyraCountryItem('LV', 'Latvia', 'Latvian'),
  ZyraCountryItem('LB', 'Lebanon', 'Lebanese'),
  ZyraCountryItem('LS', 'Lesotho', 'Basotho'),
  ZyraCountryItem('LR', 'Liberia', 'Liberian'),
  ZyraCountryItem('LY', 'Libya', 'Libyan'),
  ZyraCountryItem('LI', 'Liechtenstein', 'Liechtensteiner'),
  ZyraCountryItem('LT', 'Lithuania', 'Lithuanian'),
  ZyraCountryItem('LU', 'Luxembourg', 'Luxembourgish'),
  ZyraCountryItem('MG', 'Madagascar', 'Malagasy'),
  ZyraCountryItem('MW', 'Malawi', 'Malawian'),
  ZyraCountryItem('MY', 'Malaysia', 'Malaysian'),
  ZyraCountryItem('MV', 'Maldives', 'Maldivian'),
  ZyraCountryItem('ML', 'Mali', 'Malian'),
  ZyraCountryItem('MT', 'Malta', 'Maltese'),
  ZyraCountryItem('MH', 'Marshall Islands', 'Marshallese'),
  ZyraCountryItem('MR', 'Mauritania', 'Mauritanian'),
  ZyraCountryItem('MU', 'Mauritius', 'Mauritian'),
  ZyraCountryItem('MX', 'Mexico', 'Mexican'),
  ZyraCountryItem('FM', 'Micronesia, Federated States of', 'Micronesian'),
  ZyraCountryItem('MD', 'Moldova', 'Moldovan'),
  ZyraCountryItem('MC', 'Monaco', 'Monégasque'),
  ZyraCountryItem('MN', 'Mongolia', 'Mongolian'),
  ZyraCountryItem('ME', 'Montenegro', 'Montenegrin'),
  ZyraCountryItem('MA', 'Morocco', 'Moroccan'),
  ZyraCountryItem('MZ', 'Mozambique', 'Mozambican'),
  ZyraCountryItem('MM', 'Myanmar', 'Burmese'),
  ZyraCountryItem('NA', 'Namibia', 'Namibian'),
  ZyraCountryItem('NR', 'Nauru', 'Nauruan'),
  ZyraCountryItem('NP', 'Nepal', 'Nepali'),
  ZyraCountryItem('NL', 'Netherlands', 'Dutch'),
  ZyraCountryItem('NZ', 'New Zealand', 'New Zealander'),
  ZyraCountryItem('NI', 'Nicaragua', 'Nicaraguan'),
  ZyraCountryItem('NE', 'Niger', 'Nigerien'),
  ZyraCountryItem('NG', 'Nigeria', 'Nigerian'),
  ZyraCountryItem('KP', 'North Korea', 'North Korean'),
  ZyraCountryItem('MK', 'North Macedonia', 'North Macedonian'),
  ZyraCountryItem('NO', 'Norway', 'Norwegian'),
  ZyraCountryItem('OM', 'Oman', 'Omani'),
  ZyraCountryItem('PK', 'Pakistan', 'Pakistani'),
  ZyraCountryItem('PW', 'Palau', 'Palauan'),
  ZyraCountryItem('PS', 'Palestine', 'Palestinian'),
  ZyraCountryItem('PA', 'Panama', 'Panamanian'),
  ZyraCountryItem('PG', 'Papua New Guinea', 'Papua New Guinean'),
  ZyraCountryItem('PY', 'Paraguay', 'Paraguayan'),
  ZyraCountryItem('PE', 'Peru', 'Peruvian'),
  ZyraCountryItem('PH', 'Philippines', 'Filipino'),
  ZyraCountryItem('PL', 'Poland', 'Polish'),
  ZyraCountryItem('PT', 'Portugal', 'Portuguese'),
  ZyraCountryItem('QA', 'Qatar', 'Qatari'),
  ZyraCountryItem('CG', 'Republic of the Congo', 'Congolese'),
  ZyraCountryItem('RO', 'Romania', 'Romanian'),
  ZyraCountryItem('RU', 'Russia', 'Russian'),
  ZyraCountryItem('RW', 'Rwanda', 'Rwandan'),
  ZyraCountryItem('KN', 'Saint Kitts and Nevis', 'Kittitian and Nevisian'),
  ZyraCountryItem('LC', 'Saint Lucia', 'Saint Lucian'),
  ZyraCountryItem('VC', 'Saint Vincent and the Grenadines', 'Vincentian'),
  ZyraCountryItem('WS', 'Samoa', 'Samoan'),
  ZyraCountryItem('SM', 'San Marino', 'Sammarinese'),
  ZyraCountryItem('ST', 'Sao Tome and Principe', 'São Toméan'),
  ZyraCountryItem('SA', 'Saudi Arabia', 'Saudi'),
  ZyraCountryItem('SN', 'Senegal', 'Senegalese'),
  ZyraCountryItem('RS', 'Serbia', 'Serbian'),
  ZyraCountryItem('SC', 'Seychelles', 'Seychellois'),
  ZyraCountryItem('SL', 'Sierra Leone', 'Sierra Leonean'),
  ZyraCountryItem('SG', 'Singapore', 'Singaporean'),
  ZyraCountryItem('SK', 'Slovakia', 'Slovak'),
  ZyraCountryItem('SI', 'Slovenia', 'Slovenian'),
  ZyraCountryItem('SB', 'Solomon Islands', 'Solomon Islander'),
  ZyraCountryItem('SO', 'Somalia', 'Somali'),
  ZyraCountryItem('ZA', 'South Africa', 'South African'),
  ZyraCountryItem('KR', 'South Korea', 'South Korean'),
  ZyraCountryItem('SS', 'South Sudan', 'South Sudanese'),
  ZyraCountryItem('ES', 'Spain', 'Spanish'),
  ZyraCountryItem('LK', 'Sri Lanka', 'Sri Lankan'),
  ZyraCountryItem('SD', 'Sudan', 'Sudanese'),
  ZyraCountryItem('SR', 'Suriname', 'Surinamese'),
  ZyraCountryItem('SE', 'Sweden', 'Swedish'),
  ZyraCountryItem('CH', 'Switzerland', 'Swiss'),
  ZyraCountryItem('SY', 'Syria', 'Syrian'),
  ZyraCountryItem('TW', 'Taiwan', 'Taiwanese'),
  ZyraCountryItem('TJ', 'Tajikistan', 'Tajikistani'),
  ZyraCountryItem('TZ', 'Tanzania', 'Tanzanian'),
  ZyraCountryItem('TH', 'Thailand', 'Thai'),
  ZyraCountryItem('TL', 'Timor-Leste', 'Timorese'),
  ZyraCountryItem('TG', 'Togo', 'Togolese'),
  ZyraCountryItem('TO', 'Tonga', 'Tongan'),
  ZyraCountryItem('TT', 'Trinidad and Tobago', 'Trinidadian and Tobagonian'),
  ZyraCountryItem('TN', 'Tunisia', 'Tunisian'),
  ZyraCountryItem('TM', 'Turkmenistan', 'Turkmen'),
  ZyraCountryItem('TV', 'Tuvalu', 'Tuvaluan'),
  ZyraCountryItem('TR', 'Türkiye', 'Turkish'),
  ZyraCountryItem('UG', 'Uganda', 'Ugandan'),
  ZyraCountryItem('UA', 'Ukraine', 'Ukrainian'),
  ZyraCountryItem('AE', 'United Arab Emirates', 'Emirati'),
  ZyraCountryItem('GB', 'United Kingdom', 'British'),
  ZyraCountryItem('US', 'United States', 'American'),
  ZyraCountryItem('UY', 'Uruguay', 'Uruguayan'),
  ZyraCountryItem('UZ', 'Uzbekistan', 'Uzbekistani'),
  ZyraCountryItem('VU', 'Vanuatu', 'Ni-Vanuatu'),
  ZyraCountryItem('VA', 'Vatican City', 'Vatican'),
  ZyraCountryItem('VE', 'Venezuela', 'Venezuelan'),
  ZyraCountryItem('VN', 'Vietnam', 'Vietnamese'),
  ZyraCountryItem('YE', 'Yemen', 'Yemeni'),
  ZyraCountryItem('ZM', 'Zambia', 'Zambian'),
  ZyraCountryItem('ZW', 'Zimbabwe', 'Zimbabwean'),
];

/// Display names for the country-of-birth picker.
List<String> get zyraCountryNames => [for (final c in zyraCountries) c.name];

/// Display names for the nationality picker.
List<String> get zyraNationalityNames => [
  for (final c in zyraCountries) c.nationality,
];

/// 184 languages, ISO 639-1.
const List<ZyraRefItem> zyraLanguages = [
  ZyraRefItem('ab', 'Abkhazian'),
  ZyraRefItem('aa', 'Afar'),
  ZyraRefItem('af', 'Afrikaans'),
  ZyraRefItem('ak', 'Akan'),
  ZyraRefItem('sq', 'Albanian'),
  ZyraRefItem('am', 'Amharic'),
  ZyraRefItem('ar', 'Arabic'),
  ZyraRefItem('an', 'Aragonese'),
  ZyraRefItem('hy', 'Armenian'),
  ZyraRefItem('as', 'Assamese'),
  ZyraRefItem('av', 'Avaric'),
  ZyraRefItem('ae', 'Avestan'),
  ZyraRefItem('ay', 'Aymara'),
  ZyraRefItem('az', 'Azerbaijani'),
  ZyraRefItem('bm', 'Bambara'),
  ZyraRefItem('ba', 'Bashkir'),
  ZyraRefItem('eu', 'Basque'),
  ZyraRefItem('be', 'Belarusian'),
  ZyraRefItem('bn', 'Bengali'),
  ZyraRefItem('bi', 'Bislama'),
  ZyraRefItem('bs', 'Bosnian'),
  ZyraRefItem('br', 'Breton'),
  ZyraRefItem('bg', 'Bulgarian'),
  ZyraRefItem('my', 'Burmese'),
  ZyraRefItem('ca', 'Catalan'),
  ZyraRefItem('ch', 'Chamorro'),
  ZyraRefItem('ce', 'Chechen'),
  ZyraRefItem('ny', 'Chichewa'),
  ZyraRefItem('zh', 'Chinese (Mandarin)'),
  ZyraRefItem('cu', 'Church Slavic'),
  ZyraRefItem('cv', 'Chuvash'),
  ZyraRefItem('kw', 'Cornish'),
  ZyraRefItem('co', 'Corsican'),
  ZyraRefItem('cr', 'Cree'),
  ZyraRefItem('hr', 'Croatian'),
  ZyraRefItem('cs', 'Czech'),
  ZyraRefItem('da', 'Danish'),
  ZyraRefItem('dv', 'Divehi'),
  ZyraRefItem('nl', 'Dutch'),
  ZyraRefItem('dz', 'Dzongkha'),
  ZyraRefItem('en', 'English'),
  ZyraRefItem('eo', 'Esperanto'),
  ZyraRefItem('et', 'Estonian'),
  ZyraRefItem('ee', 'Ewe'),
  ZyraRefItem('fo', 'Faroese'),
  ZyraRefItem('fj', 'Fijian'),
  ZyraRefItem('fi', 'Finnish'),
  ZyraRefItem('fr', 'French'),
  ZyraRefItem('ff', 'Fulah'),
  ZyraRefItem('gl', 'Galician'),
  ZyraRefItem('lg', 'Ganda'),
  ZyraRefItem('ka', 'Georgian'),
  ZyraRefItem('de', 'German'),
  ZyraRefItem('gn', 'Guarani'),
  ZyraRefItem('gu', 'Gujarati'),
  ZyraRefItem('ht', 'Haitian Creole'),
  ZyraRefItem('ha', 'Hausa'),
  ZyraRefItem('he', 'Hebrew'),
  ZyraRefItem('hz', 'Herero'),
  ZyraRefItem('hi', 'Hindi'),
  ZyraRefItem('ho', 'Hiri Motu'),
  ZyraRefItem('hu', 'Hungarian'),
  ZyraRefItem('is', 'Icelandic'),
  ZyraRefItem('io', 'Ido'),
  ZyraRefItem('ig', 'Igbo'),
  ZyraRefItem('id', 'Indonesian'),
  ZyraRefItem(
    'ia',
    'Interlingua (International Auxiliary Language Association)',
  ),
  ZyraRefItem('ie', 'Interlingue'),
  ZyraRefItem('iu', 'Inuktitut'),
  ZyraRefItem('ik', 'Inupiaq'),
  ZyraRefItem('ga', 'Irish'),
  ZyraRefItem('it', 'Italian'),
  ZyraRefItem('ja', 'Japanese'),
  ZyraRefItem('jv', 'Javanese'),
  ZyraRefItem('kl', 'Kalaallisut'),
  ZyraRefItem('kn', 'Kannada'),
  ZyraRefItem('kr', 'Kanuri'),
  ZyraRefItem('ks', 'Kashmiri'),
  ZyraRefItem('kk', 'Kazakh'),
  ZyraRefItem('km', 'Khmer'),
  ZyraRefItem('ki', 'Kikuyu'),
  ZyraRefItem('rw', 'Kinyarwanda'),
  ZyraRefItem('ky', 'Kirghiz'),
  ZyraRefItem('kv', 'Komi'),
  ZyraRefItem('kg', 'Kongo'),
  ZyraRefItem('ko', 'Korean'),
  ZyraRefItem('kj', 'Kuanyama'),
  ZyraRefItem('ku', 'Kurdish'),
  ZyraRefItem('lo', 'Lao'),
  ZyraRefItem('la', 'Latin'),
  ZyraRefItem('lv', 'Latvian'),
  ZyraRefItem('li', 'Limburgan'),
  ZyraRefItem('ln', 'Lingala'),
  ZyraRefItem('lt', 'Lithuanian'),
  ZyraRefItem('lu', 'Luba-Katanga'),
  ZyraRefItem('lb', 'Luxembourgish'),
  ZyraRefItem('mk', 'Macedonian'),
  ZyraRefItem('mg', 'Malagasy'),
  ZyraRefItem('ms', 'Malay'),
  ZyraRefItem('ml', 'Malayalam'),
  ZyraRefItem('mt', 'Maltese'),
  ZyraRefItem('gv', 'Manx'),
  ZyraRefItem('mi', 'Maori'),
  ZyraRefItem('mr', 'Marathi'),
  ZyraRefItem('mh', 'Marshallese'),
  ZyraRefItem('el', 'Modern Greek (1453-)'),
  ZyraRefItem('mn', 'Mongolian'),
  ZyraRefItem('na', 'Nauru'),
  ZyraRefItem('nv', 'Navajo'),
  ZyraRefItem('ng', 'Ndonga'),
  ZyraRefItem('ne', 'Nepali'),
  ZyraRefItem('nd', 'North Ndebele'),
  ZyraRefItem('se', 'Northern Sami'),
  ZyraRefItem('no', 'Norwegian'),
  ZyraRefItem('nb', 'Norwegian (Bokmål)'),
  ZyraRefItem('nn', 'Norwegian (Nynorsk)'),
  ZyraRefItem('oc', 'Occitan'),
  ZyraRefItem('oj', 'Ojibwa'),
  ZyraRefItem('or', 'Oriya'),
  ZyraRefItem('om', 'Oromo'),
  ZyraRefItem('os', 'Ossetian'),
  ZyraRefItem('pi', 'Pali'),
  ZyraRefItem('ps', 'Pashto'),
  ZyraRefItem('fa', 'Persian (Farsi)'),
  ZyraRefItem('pl', 'Polish'),
  ZyraRefItem('pt', 'Portuguese'),
  ZyraRefItem('pa', 'Punjabi'),
  ZyraRefItem('qu', 'Quechua'),
  ZyraRefItem('ro', 'Romanian'),
  ZyraRefItem('rm', 'Romansh'),
  ZyraRefItem('rn', 'Rundi'),
  ZyraRefItem('ru', 'Russian'),
  ZyraRefItem('sm', 'Samoan'),
  ZyraRefItem('sg', 'Sango'),
  ZyraRefItem('sa', 'Sanskrit'),
  ZyraRefItem('sc', 'Sardinian'),
  ZyraRefItem('gd', 'Scottish Gaelic'),
  ZyraRefItem('sr', 'Serbian'),
  ZyraRefItem('sh', 'Serbo-Croatian'),
  ZyraRefItem('sn', 'Shona'),
  ZyraRefItem('sd', 'Sindhi'),
  ZyraRefItem('si', 'Sinhala'),
  ZyraRefItem('sk', 'Slovak'),
  ZyraRefItem('sl', 'Slovenian'),
  ZyraRefItem('so', 'Somali'),
  ZyraRefItem('nr', 'South Ndebele'),
  ZyraRefItem('st', 'Southern Sotho'),
  ZyraRefItem('es', 'Spanish'),
  ZyraRefItem('su', 'Sundanese'),
  ZyraRefItem('sw', 'Swahili'),
  ZyraRefItem('ss', 'Swati'),
  ZyraRefItem('sv', 'Swedish'),
  ZyraRefItem('tl', 'Tagalog'),
  ZyraRefItem('ty', 'Tahitian'),
  ZyraRefItem('tg', 'Tajik'),
  ZyraRefItem('ta', 'Tamil'),
  ZyraRefItem('tt', 'Tatar'),
  ZyraRefItem('te', 'Telugu'),
  ZyraRefItem('th', 'Thai'),
  ZyraRefItem('bo', 'Tibetan'),
  ZyraRefItem('ti', 'Tigrinya'),
  ZyraRefItem('to', 'Tonga (Tonga Islands)'),
  ZyraRefItem('ts', 'Tsonga'),
  ZyraRefItem('tn', 'Tswana'),
  ZyraRefItem('tr', 'Turkish'),
  ZyraRefItem('tk', 'Turkmen'),
  ZyraRefItem('tw', 'Twi'),
  ZyraRefItem('ug', 'Uighur'),
  ZyraRefItem('uk', 'Ukrainian'),
  ZyraRefItem('ur', 'Urdu'),
  ZyraRefItem('uz', 'Uzbek'),
  ZyraRefItem('ve', 'Venda'),
  ZyraRefItem('vi', 'Vietnamese'),
  ZyraRefItem('vo', 'Volapük'),
  ZyraRefItem('wa', 'Walloon'),
  ZyraRefItem('cy', 'Welsh'),
  ZyraRefItem('fy', 'Western Frisian'),
  ZyraRefItem('wo', 'Wolof'),
  ZyraRefItem('xh', 'Xhosa'),
  ZyraRefItem('ii', 'Yi'),
  ZyraRefItem('yi', 'Yiddish'),
  ZyraRefItem('yo', 'Yoruba'),
  ZyraRefItem('za', 'Zhuang'),
  ZyraRefItem('zu', 'Zulu'),
];

List<String> get zyraLanguageNames => [for (final l in zyraLanguages) l.name];

/// 29 ethnicities. ZYRA codes — no ISO standard exists.
///
/// Granularity is deliberately mixed. "Pakistani" and "South Asian"
/// sit in one list because that is how people describe themselves, and
/// for this audience the specific answer is the meaningful one. Raised
/// with the Founder rather than decided here.
const List<ZyraRefItem> zyraEthnicities = [
  ZyraRefItem('pakistani', 'Pakistani'),
  ZyraRefItem('indian', 'Indian'),
  ZyraRefItem('bangladeshi', 'Bangladeshi'),
  ZyraRefItem('sri_lankan', 'Sri Lankan'),
  ZyraRefItem('south_asian_other', 'South Asian (other)'),
  ZyraRefItem('arab', 'Arab'),
  ZyraRefItem('north_african', 'North African'),
  ZyraRefItem('berber', 'Berber / Amazigh'),
  ZyraRefItem('somali', 'Somali'),
  ZyraRefItem('black_african', 'Black African'),
  ZyraRefItem('black_caribbean', 'Black Caribbean'),
  ZyraRefItem('turkish', 'Turkish'),
  ZyraRefItem('kurdish', 'Kurdish'),
  ZyraRefItem('persian', 'Persian / Iranian'),
  ZyraRefItem('afghan', 'Afghan'),
  ZyraRefItem('central_asian', 'Central Asian'),
  ZyraRefItem('malay', 'Malay'),
  ZyraRefItem('indonesian', 'Indonesian'),
  ZyraRefItem('southeast_asian_other', 'Southeast Asian (other)'),
  ZyraRefItem('east_asian', 'East Asian'),
  ZyraRefItem('uyghur', 'Uyghur'),
  ZyraRefItem('bosnian', 'Bosnian'),
  ZyraRefItem('albanian', 'Albanian'),
  ZyraRefItem('balkan_other', 'Balkan (other)'),
  ZyraRefItem('white_european', 'White / European'),
  ZyraRefItem('latin_american', 'Latin American'),
  ZyraRefItem('mixed', 'Mixed heritage'),
  ZyraRefItem('other', 'Other'),
  ZyraRefItem('prefer_not_to_say', 'Prefer not to say'),
];

List<String> get zyraEthnicityNames => [
  for (final e in zyraEthnicities) e.name,
];

/// Location preference — Founder decision 2026-08-01, replacing mileage
/// bands (10/25/50/100 miles).
///
/// The old question could never be answered: `location_text` is free text
/// with no coordinates, so no distance in miles was ever computable. These
/// buckets need no geocoding.
const List<ZyraRefItem> zyraLocationPreferences = [
  ZyraRefItem('same_city', 'Same city'),
  ZyraRefItem('same_region', 'Same region or county'),
  ZyraRefItem('same_country', 'Same country'),
  ZyraRefItem('anywhere', 'Anywhere'),
];

List<String> get zyraLocationPreferenceNames => [
  for (final l in zyraLocationPreferences) l.name,
];

/// Code for a label, for the pickers that still hand back display strings.
/// Returns null if the label is unknown — callers must treat that as a bug,
/// never as a value to store.
String? zyraCodeFor(List<ZyraRefItem> list, String? name) {
  if (name == null) return null;
  for (final i in list) {
    if (i.name == name) return i.code;
  }
  return null;
}

String? zyraCountryCodeFor(String? name) {
  if (name == null) return null;
  for (final c in zyraCountries) {
    if (c.name == name) return c.code;
  }
  return null;
}

String? zyraNationalityCodeFor(String? nationality) {
  if (nationality == null) return null;
  for (final c in zyraCountries) {
    if (c.nationality == nationality) return c.code;
  }
  return null;
}

/// Label for a stored code — the reverse of [zyraCodeFor], and the direction
/// every display surface needs. Returns null for an unknown code rather than
/// echoing it back: rendering a raw code to a user is a bug that should look
/// like one, not a slightly-odd-looking word they learn to ignore.
String? zyraNameFor(List<ZyraRefItem> list, String? code) {
  if (code == null) return null;
  for (final i in list) {
    if (i.code == code) return i.name;
  }
  return null;
}

/// How a Guardian is related to their Seeker. Stored on `wali_links`, per
/// link rather than per Guardian — the same person is father to a daughter
/// and paternal uncle to a niece, and one value on their profile cannot say
/// both.
///
/// Founder-approved 2026-08-06, deliberately narrow. Widening an enum is an
/// additive migration; removing a value is a breaking one that orphans live
/// rows. Starting narrow keeps the product decision open instead of encoding
/// one nobody has made.
///
/// NOTE THE FOURTH ENTRY. The code is `uncle`; the label is "Paternal
/// Uncle". That is not an inconsistency, it is the whole point of the rule
/// at the top of this file — WALI_ARCHITECTURE V6 and Guardian onboarding
/// both say *Paternal* Uncle, and if the product ever admits maternal
/// uncles the label changes and not one stored row moves.
const List<ZyraRefItem> zyraGuardianRelationships = [
  ZyraRefItem('father', 'Father'),
  ZyraRefItem('grandfather', 'Grandfather'),
  ZyraRefItem('brother', 'Brother'),
  ZyraRefItem('uncle', 'Paternal Uncle'),
  ZyraRefItem('legal_guardian', 'Legal Guardian'),
  ZyraRefItem('family_representative', 'Family Representative'),
  ZyraRefItem('other', 'Other'),
];

List<String> get zyraGuardianRelationshipNames => [
  for (final r in zyraGuardianRelationships) r.name,
];

/// The FULL proposed list, grouped — Founder + ChatGPT, 2026-08-07.
///
/// ⚠️ PREVIEW ONLY. `wali_links.relationship` still has a CHECK constraint
/// allowing seven values. Anything below outside that set CANNOT be saved,
/// and the only screen using this list writes nothing.
///
/// It exists so the grouped-chip layout can be judged at full size while the
/// Guardian governance review runs. Three things gate promotion to the real
/// enum, recorded in ZYRA_GUARDIAN_RELATIONSHIP_LIST_REVIEW:
///
///   1. GUARDIAN GENDER. Eight female values below (Mother, Sister, Aunt,
///      Daughter, Niece, Mother-in-law, Sister-in-law, Wife) would settle a
///      question the Founder ordered a separate review for on 2026-08-06,
///      by implication rather than decision.
///   2. ISLAMIC VALIDITY. The Guardian is the wali. Imam and Legal Guardian
///      have standing; Family Friend and Trusted Friend need a scholar's
///      view, not a product one.
///   3. PATERNAL DISTINCTIONS. "Uncle" and "Cousin" drop the paternal
///      qualifier we deliberately kept on 2026-08-06.
///
/// EVERY VALUE READS AS "I AM HER ___". The Guardian states it (ratified
/// 2026-08-07), which is why Father and Son can both appear — a son acting
/// as wali for his widowed mother is a real case. Add nothing here from the
/// Seeker's point of view.
const List<({String title, List<ZyraRefItem> items})>
zyraGuardianRelationshipGroups = [
  (
    title: 'Immediate Family',
    items: [
      ZyraRefItem('father', 'Father'),
      ZyraRefItem('mother', 'Mother'),
      ZyraRefItem('brother', 'Brother'),
      ZyraRefItem('sister', 'Sister'),
      ZyraRefItem('son', 'Son'),
      ZyraRefItem('daughter', 'Daughter'),
    ],
  ),
  (
    title: 'Grandparents',
    items: [
      ZyraRefItem('grandfather', 'Grandfather'),
      ZyraRefItem('grandmother', 'Grandmother'),
    ],
  ),
  (
    title: 'Extended Family',
    items: [
      // NOTE: 'uncle' currently displays as "Paternal Uncle" in the live
      // seven. Shown here as the proposal words it; the conflict is real and
      // must be settled before promotion, not silently resolved.
      ZyraRefItem('uncle', 'Uncle'),
      ZyraRefItem('aunt', 'Aunt'),
      ZyraRefItem('cousin', 'Cousin'),
      ZyraRefItem('nephew', 'Nephew'),
      ZyraRefItem('niece', 'Niece'),
    ],
  ),
  (
    title: 'Marriage',
    items: [
      // Husband and Wife are DELIBERATELY ABSENT from this group.
      //
      // A Seeker looking for marriage does not have a spouse — the value
      // could never be true of anyone who could select it. Left out rather
      // than shown, because a chip nobody can honestly pick is worse than a
      // missing one.
      ZyraRefItem('father_in_law', 'Father-in-law'),
      ZyraRefItem('mother_in_law', 'Mother-in-law'),
      ZyraRefItem('brother_in_law', 'Brother-in-law'),
      ZyraRefItem('sister_in_law', 'Sister-in-law'),
    ],
  ),
  (
    title: 'Trusted People',
    items: [
      ZyraRefItem('family_friend', 'Family Friend'),
      ZyraRefItem('trusted_friend', 'Trusted Friend'),
      ZyraRefItem('imam', 'Imam'),
      ZyraRefItem('legal_guardian', 'Legal Guardian'),
      // No description field, by decision. "Other" stays "Other".
      ZyraRefItem('other', 'Other'),
    ],
  ),
];

/// True where a code is in the LIVE enum and can actually be stored.
/// Everything else in the grouped list above is preview.
bool zyraRelationshipIsLive(String code) =>
    zyraGuardianRelationships.any((r) => r.code == code);

/// "uncle" -> "Paternal Uncle". Null for null or unknown.
String? zyraRelationshipLabel(String? code) =>
    zyraNameFor(zyraGuardianRelationships, code);

/// "Paternal Uncle" -> "uncle". Null for null or unknown.
String? zyraRelationshipCode(String? label) =>
    zyraCodeFor(zyraGuardianRelationships, label);
