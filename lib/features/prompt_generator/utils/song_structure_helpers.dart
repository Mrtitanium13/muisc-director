import 'package:music_director/core/constants/song_structure_data.dart';

String presetIdOrFlexible(String id) {
  return SongStructureData.presetById(id) != null
      ? id
      : SongStructureData.flexibleId;
}
