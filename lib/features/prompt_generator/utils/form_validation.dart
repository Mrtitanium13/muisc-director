import 'package:music_director/core/utils/duration_format.dart';
import 'package:music_director/data/models/track_duration_config.dart';
import 'package:music_director/data/models/user_input_model.dart';

enum ValidationError {
  missingGenre,
  missingVibe,
  invalidCustomDuration,
}

extension ValidationErrorX on ValidationError {
  String get message {
    switch (this) {
      case ValidationError.missingGenre:
        return 'Select a primary sub-genre.';
      case ValidationError.missingVibe:
        return 'Pick a mood and/or describe your vibe / idea.';
      case ValidationError.invalidCustomDuration:
        return 'Enter a valid custom duration (e.g. 3:45, 4 min, 180 for seconds).';
    }
  }
}

class FormValidation {
  const FormValidation._();

  static List<ValidationError> validate(UserInputModel form) {
    final errors = <ValidationError>[];
    if (form.primaryGenre.isEmpty) errors.add(ValidationError.missingGenre);
    if (form.vibe.isEmpty) errors.add(ValidationError.missingVibe);
    if (form.trackDuration == TrackDuration.custom) {
      if (parseFlexibleDurationMinutes(form.trackDurationLabel) == null) {
        errors.add(ValidationError.invalidCustomDuration);
      }
    }
    return errors;
  }
}
