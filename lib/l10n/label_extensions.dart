import '../models/passage.dart';
import '../models/reader_sign_in_display.dart';
import '../models/reading_settings.dart';
import '../theme/reading_surface.dart';
import 'app_language.dart';
import 'app_strings.dart';

/// Localised names for the enums that are shown to a reader.
///
/// [PassageDifficulty] and [ReadingSurface] already carried a `labelBn`
/// alongside the English one and nothing had ever read it — the Library showed
/// "Easy" to every participant while the Bangla sat unused in the model.
/// [ReadingProfile] had no Bangla at all, so its wording comes from the string
/// table like everything else.
extension LocalisedDifficulty on PassageDifficulty {
  String localisedLabel(AppStrings t) =>
      t.language == AppLanguage.bangla ? labelBn : label;
}

extension LocalisedSurface on ReadingSurface {
  String localisedLabel(AppStrings t) =>
      t.language == AppLanguage.bangla ? labelBn : label;
}

extension LocalisedProfile on ReadingProfile {
  String localisedLabel(AppStrings t) => switch (this) {
        ReadingProfile.standard => t.profileDefault,
        ReadingProfile.recommended => t.profileRecommended,
        ReadingProfile.custom => t.profileCustom,
      };
}

extension LocalisedSignInDisplay on ReaderSignInDisplay {
  String localisedLabel(AppStrings t) => switch (this) {
        ReaderSignInDisplay.names => t.readerSignInNames,
        ReaderSignInDisplay.participantIdsOnly => t.readerSignInIds,
        ReaderSignInDisplay.off => t.readerSignInOff,
      };
}

extension SignInDisplayCaption on ReaderSignInDisplay {
  String localisedCaption(AppStrings t) => switch (this) {
        ReaderSignInDisplay.names => t.signInCaptionNames,
        ReaderSignInDisplay.participantIdsOnly => t.signInCaptionIds,
        ReaderSignInDisplay.off => t.signInCaptionOff,
      };
}
