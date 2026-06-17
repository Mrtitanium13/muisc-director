/// Optional Power Codes — production density, gear detail, max energy.
class PowerCodeData {
  PowerCodeData._();

  static const List<String> codes = [
    '/L99',
    '/UDA',
    '/BEASTMODE',
  ];

  static String labelFor(String code) {
    switch (code) {
      case '/L99':
        return 'L99';
      case '/UDA':
        return 'UDA';
      case '/BEASTMODE':
        return 'Beastmode';
      default:
        return code.replaceFirst('/', '');
    }
  }

  static String hintFor(String code) {
    switch (code) {
      case '/L99':
        return 'Boutique gear & audiophile chain detail';
      case '/UDA':
        return 'Ultra-detailed arrangement & theory';
      case '/BEASTMODE':
        return 'Max energy & impact';
      default:
        return '';
    }
  }
}
