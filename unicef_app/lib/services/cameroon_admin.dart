/// Cameroon administrative hierarchy:
/// Région → Département → Arrondissement
class CameroonAdmin {
  // Full hierarchy map: region → department → [arrondissements]
  static const Map<String, Map<String, List<String>>> hierarchy = {
    'Adamaoua': {
      'Djérem': ['Tibati', 'Ngaoundal', 'Mbakaou'],
      'Faro-et-Déo': ['Tignère', 'Galim-Tignère', 'Kontcha'],
      'Mayo-Banyo': ['Banyo', 'Bankim', 'Mayo-Darlé'],
      'Mbéré': ['Meiganga', 'Djohong', 'Ngaoui'],
      'Vina': ['Ngaoundéré 1er', 'Ngaoundéré 2ème', 'Ngaoundéré 3ème', 'Belel', 'Martap'],
    },
    'Centre': {
      'Haute-Sanaga': ['Nanga-Eboko', 'Lembe-Yezoum', 'Minta'],
      'Lékié': ['Monatélé', 'Elig-Mfomo', 'Sa\'a', 'Obala', 'Evodoula'],
      'Mbam-et-Inoubou': ['Bafia', 'Makénéné', 'Ngambé-Tikar', 'Nitoukou'],
      'Mbam-et-Kim': ['Ntui', 'Mbangassina', 'Ngoro', 'Yoko'],
      'Méfou-et-Afamba': ['Mfou', 'Awae', 'Esse', 'Nkolafamba'],
      'Méfou-et-Akono': ['Akonolinga', 'Ayos', 'Endom'],
      'Mfoundi': ['Yaoundé 1er', 'Yaoundé 2ème', 'Yaoundé 3ème', 'Yaoundé 4ème', 'Yaoundé 5ème', 'Yaoundé 6ème', 'Yaoundé 7ème'],
      'Nyong-et-Foumou': ['Sangmélima', 'Bengbis', 'Djoum'],
      'Nyong-et-Kellé': ['Eséka', 'Makak', 'Matomb'],
      'Nyong-et-Mfoumou': ['Akonolinga', 'Mengueme'],
    },
    'Est': {
      'Boumba-et-Ngoko': ['Moloundou', 'Salapoumbé', 'Yokadouma'],
      'Haut-Nyong': ['Abong-Mbang', 'Doumé', 'Lomié', 'Mboma'],
      'Kadey': ['Batouri', 'Kette', 'Ndelele'],
      'Lom-et-Djerem': ['Bertoua 1er', 'Bertoua 2ème', 'Bélabo', 'Diang'],
    },
    'Extrême-Nord': {
      'Diamaré': ['Maroua 1er', 'Maroua 2ème', 'Maroua 3ème', 'Bogo', 'Gazawa', 'Katoual', 'Méri', 'Moutourwa'],
      'Logone-et-Chari': ['Kousseri', 'Blangoua', 'Fotokol', 'Goulfey', 'Makary', 'Waza', 'Zina'],
      'Mayo-Danay': ['Yagoua', 'Datchéka', 'Guémé', 'Kai-Kai', 'Kaï-Kaï', 'Maga', 'Vélé', 'Wina'],
      'Mayo-Kani': ['Kaélé', 'Gazawa', 'Mindif', 'Moulvoudaye'],
      'Mayo-Mosogo': ['Hina', 'Koza', 'Tokombéré', 'Roua'],
      'Mayo-Sava': ['Mora', 'Kolofata', 'Méri'],
      'Mayo-Tsanaga': ['Mokolo', 'Bourha', 'Koza', 'Mogodé', 'Mozogo', 'Touloum'],
    },
    'Littoral': {
      'Moungo': ['Nkongsamba 1er', 'Nkongsamba 2ème', 'Nkongsamba 3ème', 'Loum', 'Mbanga', 'Mombo', 'Melong'],
      'Nkam': ['Yabassi', 'Ebo', 'Ndom', 'Yingui'],
      'Sanaga-Maritime': ['Edéa 1er', 'Edéa 2ème', 'Dizangue', 'Mouanko', 'Ngwei', 'Pouma'],
      'Wouri': ['Douala 1er', 'Douala 2ème', 'Douala 3ème', 'Douala 4ème', 'Douala 5ème'],
    },
    'Nord': {
      'Bénoué': ['Ngaoundéré 1er', 'Garoua 1er', 'Garoua 2ème', 'Garoua 3ème', 'Bibemi', 'Lagdo', 'Mayo-Hourna'],
      'Faro': ['Poli', 'Beka'],
      'Mayo-Louti': ['Guider', 'Figuil', 'Mayo-Oulo'],
      'Mayo-Rey': ['Rey-Bouba', 'Madingring', 'Tcholliré', 'Touboro'],
    },
    'Nord-Ouest': {
      'Boyo': ['Fundong', 'Belo', 'Noni'],
      'Bui': ['Kumbo', 'Jakiri', 'Nkor', 'Nkum'],
      'Donga-Mantung': ['Nkambe', 'Ako', 'Nwa', 'Misaje'],
      'Menchum': ['Wum', 'Fungom', 'Menchum Valley'],
      'Mezam': ['Bamenda 1er', 'Bamenda 2ème', 'Bamenda 3ème'],
      'Momo': ['Mbengwi', 'Batibo', 'Njikwa'],
      'Ngokentunjia': ['Ndop', 'Babessi', 'Balikumbat'],
    },
    'Ouest': {
      'Bamboutos': ['Mbouda', 'Babadjou', 'Galim', 'Batcham'],
      'Hauts-Plateaux': ['Baham', 'Bana', 'Bangou'],
      'Haut-Nkam': ['Bafang', 'Banka', 'Bandja', 'Bakou'],
      'Koupé-Manengouba': ['Bangem', 'Nguti', 'Tombel'],
      'Menoua': ['Dschang', 'Fokoué', 'Nkong-Ni', 'Santchou'],
      'Mifi': ['Bafoussam 1er', 'Bafoussam 2ème', 'Bafoussam 3ème'],
      'Nde': ['Bangangté', 'Bassamba', 'Djebem', 'Ndé'],
      'Noun': ['Foumban', 'Foumbot', 'Koutaba', 'Magba', 'Massangam'],
    },
    'Sud': {
      'Dja-et-Lobo': ['Sangmélima', 'Bengbis', 'Djoum', 'Meyomessala'],
      'Mvila': ['Ebolowa 1er', 'Ebolowa 2ème', 'Biwong-Bulu', 'Mvangan', 'Ngoulemakong'],
      'Océan': ['Kribi 1er', 'Kribi 2ème', 'Campo', 'Akom II', 'Bipindi'],
      'Vallée-du-Ntem': ['Ambam', 'Ma\'an', 'Mvangan'],
    },
    'Sud-Ouest': {
      'Fako': ['Buea', 'Limbe 1er', 'Limbe 2ème', 'Limbe 3ème', 'Muyuka', 'Tiko', 'West Coast'],
      'Koupé-Manengouba': ['Bangem', 'Nguti', 'Tombel'],
      'Lebialem': ['Menji', 'Alou', 'Fontem'],
      'Manyu': ['Mamfe', 'Akwaya', 'Eyumojock', 'Tinto'],
      'Meme': ['Kumba 1er', 'Kumba 2ème', 'Kumba 3ème', 'Konye', 'Mbonge'],
      'Ndian': ['Mundemba', 'Ekondo-Titi', 'Idabato', 'Isangele'],
    },
  };

  static List<String> get regions => hierarchy.keys.toList()..sort();

  static List<String> departmentsFor(String region) =>
      (hierarchy[region]?.keys.toList() ?? [])..sort();

  static List<String> arrondissementsFor(String region, String department) =>
      ([...?hierarchy[region]?[department]])..sort();
}
