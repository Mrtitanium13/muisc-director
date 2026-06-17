import 'genre_hardware_profiles.dart';

/// Mandatory Block 1 mix/master/hardware user-block (Part E v2.1).
class Block1MixMasterDirective {
  Block1MixMasterDirective._();

  static String userBlockDirective({
    required String primaryGenre,
    String subGenreFusion = '',
    bool djIntro = false,
    bool djOutro = false,
  }) =>
      GenreHardwareProfiles.userBlockDirective(
        primaryGenre: primaryGenre,
        subGenreFusion: subGenreFusion,
        djIntro: djIntro,
        djOutro: djOutro,
      );
}
