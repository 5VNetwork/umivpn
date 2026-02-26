import 'dart:math';

String generateRealisticDomain() {
  final random = Random();

  // Common domain prefixes
  final prefixes = [
    'my',
    'the',
    'get',
    'go',
    'find',
    'search',
    'buy',
    'shop',
    'best',
    'top',
    'new',
    'free',
    'pro',
    'online',
    'web',
    'net',
    'tech',
    'info',
    'data',
    'cloud',
    'app',
    'dev',
    'code',
    'soft'
  ];

  // Common domain suffixes
  final suffixes = [
    'hub',
    'zone',
    'spot',
    'place',
    'space',
    'site',
    'store',
    'shop',
    'market',
    'center',
    'point',
    'base',
    'lab',
    'pro',
    'plus',
    'max',
    'prime',
    'premium',
    'elite',
    'pro',
    'expert'
  ];

  // Randomly decide the structure
  final structure = random.nextInt(3);

  switch (structure) {
    case 0:
      // prefix-suffix.com
      return '${prefixes[random.nextInt(prefixes.length)]}-${suffixes[random.nextInt(suffixes.length)]}.com';
    case 1:
      // prefixsuffix.com
      return '${prefixes[random.nextInt(prefixes.length)]}${suffixes[random.nextInt(suffixes.length)]}.com';
    case 2:
      // prefix123.com
      return '${prefixes[random.nextInt(prefixes.length)]}${random.nextInt(999)}.com';
    default:
      return 'example.com';
  }
}
