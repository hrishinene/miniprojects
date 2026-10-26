const List<String> defaultRuleTexts = [
  'Drink 2 litres of water daily. Avoid second servings unless genuinely hungry.',
  'Finish dinner by 7:30 pm on at least 5 days per week.',
  'Eat only during 3 planned eating blocks per day.',
  'No sweets, desserts or sugar-sweetened drinks.',
  'No unplanned snacks. Eat three planned, balanced meals with appropriate portions.',
];

const List<String> ruleTitles = [
  'Foundation',
  'Meal timing',
  'Eating structure',
  'Sweets',
  'Planned meals',
];

/// Rules 1 through [level], inclusive. The level is the latest crossed line.
List<String> rulesForLevel(int level, List<String> rules) {
  if (level < 1 || level > rules.length) {
    throw ArgumentError.value(level, 'level');
  }
  return rules.sublist(0, level);
}
