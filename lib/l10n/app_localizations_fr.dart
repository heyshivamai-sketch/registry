// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get onboardingSkip => 'Ignorer';

  @override
  String get onboardingContinue => 'Continuer';

  @override
  String get onboardingGetStarted => 'Commencer';

  @override
  String get onboardingPage1Title => 'Ne manquez plus une date importante';

  @override
  String get onboardingPage1Subtitle =>
      'Suivez les dates d’expiration de vos documents et sachez quand commencer le renouvellement.';

  @override
  String get onboardingPage2Title => 'Anticipez chaque prélèvement';

  @override
  String get onboardingPage2Subtitle =>
      'Gardez vos abonnements organisés et décidez avant le prochain paiement.';

  @override
  String get onboardingPage3Title => 'Vos informations restent les vôtres';

  @override
  String get onboardingPage3Subtitle =>
      'Commencez sans compte. Vos dossiers restent privés sur votre appareil.';

  @override
  String get onboardingPage1IllustrationLabel =>
      'Rappel d’expiration d’un document';

  @override
  String get onboardingPage2IllustrationLabel =>
      'Prélèvement d’abonnement à venir';

  @override
  String get onboardingPage3IllustrationLabel =>
      'Dossiers privés enregistrés sur cet appareil';

  @override
  String get onboardingDocumentName => 'Passeport';

  @override
  String get onboardingDocumentExpiry => 'Expire le 12 juin';

  @override
  String get onboardingReminder => 'Rappel activé';

  @override
  String get onboardingSubscriptionName => 'Streaming';

  @override
  String get onboardingUpcomingCharge => 'Prélèvement dans 5 jours';

  @override
  String get onboardingDecisionDate => 'Décider avant vendredi';

  @override
  String get onboardingPrivacyLock => 'Sur l’appareil uniquement';

  @override
  String get navHome => 'Accueil';

  @override
  String get navDocuments => 'Documents';

  @override
  String get navSubscriptions => 'Abonnements';

  @override
  String get homeGreeting => 'Restez en avance sur l’essentiel';

  @override
  String get homeTitle => 'Votre registre';

  @override
  String get searchPlaceholder => 'Rechercher documents et abonnements';

  @override
  String get searchClear => 'Effacer la recherche';

  @override
  String get filterTooltip => 'Filtrer';

  @override
  String get filtersComingSoon =>
      'Les filtres arriveront dans une prochaine version.';

  @override
  String get reviewAction => 'Examiner';

  @override
  String get highImpactLabel => 'Impact élevé';

  @override
  String get summaryDocuments => 'Documents';

  @override
  String get summarySubscriptions => 'Abonnements';

  @override
  String get summaryNeedsAttention => 'À traiter';

  @override
  String get sectionNeedsAttention => 'Nécessite votre attention';

  @override
  String get sectionComingUp => 'À venir';

  @override
  String startByDate(String date) {
    return 'Commencer avant le $date';
  }

  @override
  String expiresDate(String date) {
    return 'Expire le $date';
  }

  @override
  String nextChargeDate(String date) {
    return 'Prochain prélèvement $date';
  }

  @override
  String decideByDate(String date) {
    return 'Décider avant le $date';
  }

  @override
  String get typeDocument => 'Document';

  @override
  String get typeSubscription => 'Abonnement';

  @override
  String get statusUrgent => 'Urgent';

  @override
  String get statusUpcoming => 'À venir';

  @override
  String get statusActive => 'Actif';

  @override
  String get itemCarInsurance => 'Assurance auto';

  @override
  String get heroCarInsurance => 'Commencer le renouvellement d’assurance';

  @override
  String get actionStartRenewalSoon => 'Commencer le renouvellement bientôt';

  @override
  String get itemPassport => 'Passeport';

  @override
  String get actionUpcomingExpiry => 'Expiration prochaine';

  @override
  String get itemStreaming => 'Abonnement streaming';

  @override
  String get actionDecideBeforeCharge =>
      'Décider avant le prochain prélèvement';

  @override
  String get itemDrivingLicence => 'Permis de conduire';

  @override
  String get actionPrepareRenewal => 'Préparer le renouvellement';

  @override
  String get itemGym => 'Abonnement salle de sport';

  @override
  String get actionReviewMembership => 'Vérifier avant le renouvellement';

  @override
  String get addDocument => 'Ajouter un document';

  @override
  String get addSubscription => 'Ajouter un abonnement';

  @override
  String get addSheetTitle => 'Ajouter au registre';

  @override
  String get addSheetSubtitle => 'Choisissez ce que vous souhaitez suivre.';

  @override
  String get addFabTooltip => 'Ajouter';

  @override
  String get documentsTitle => 'Documents';

  @override
  String get documentsEmptyTitle => 'Aucun document pour le moment';

  @override
  String get documentsEmptyMessage =>
      'Ajoutez passeports, assurances et autres dossiers pour voir ici les dates de renouvellement.';

  @override
  String get subscriptionsTitle => 'Abonnements';

  @override
  String get subscriptionsEmptyTitle => 'Aucun abonnement pour le moment';

  @override
  String get subscriptionsEmptyMessage =>
      'Ajoutez streaming, sport et autres prélèvements pour anticiper les paiements.';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileMessage =>
      'Il n’y a pas de compte dans cette version. Registry conservera vos dossiers en privé sur cet appareil.';

  @override
  String get profileButton => 'Ouvrir le profil';

  @override
  String get addDocumentTitle => 'Ajouter un document';

  @override
  String get addDocumentMessage =>
      'Le formulaire document, l’analyse optionnelle et le stockage local seront construits ensuite. Vous pouvez revenir en arrière et continuer à explorer l’accueil.';

  @override
  String get addSubscriptionTitle => 'Ajouter un abonnement';

  @override
  String get addSubscriptionMessage =>
      'Le formulaire d’abonnement et les rappels de paiement seront construits ensuite. Vous pouvez revenir en arrière et continuer à explorer l’accueil.';

  @override
  String get searchNoResultsTitle => 'Aucun résultat';

  @override
  String get searchNoResultsMessage =>
      'Essayez un autre nom, ou effacez la recherche pour tout afficher.';

  @override
  String get addDocumentHeadline => 'Ajouter un document';

  @override
  String get addDocumentSubtitle =>
      'Scannez ou saisissez les informations manuellement.';

  @override
  String get attachmentSectionTitle => 'Pièce jointe';

  @override
  String get attachmentEmptyLabel => 'Ajoutez une photo de ce document';

  @override
  String get attachmentTakePhoto => 'Prendre une photo';

  @override
  String get attachmentChooseGallery => 'Choisir depuis la galerie';

  @override
  String get attachmentReplace => 'Remplacer';

  @override
  String get attachmentRemove => 'Retirer';

  @override
  String get attachmentPrivacy =>
      'Votre image reste sur cet appareil et n’est pas téléversée.';

  @override
  String get replaceAttachmentTitle => 'Remplacer la photo';

  @override
  String get attachmentPickerFailed =>
      'La photo n’a pas pu être ajoutée. Vérifiez l’autorisation de l’appareil photo ou de la bibliothèque, puis réessayez.';

  @override
  String get sectionBasicInfo => 'Informations de base';

  @override
  String get fieldDocumentName => 'Nom du document';

  @override
  String get fieldDocumentType => 'Type de document';

  @override
  String get fieldOwnerName => 'Nom du titulaire ou du profil';

  @override
  String get fieldIssuingAuthority => 'Pays ou autorité émettrice';

  @override
  String get fieldDocumentNumber => 'Numéro du document';

  @override
  String get showDocumentNumber => 'Afficher le numéro du document';

  @override
  String get hideDocumentNumber => 'Masquer le numéro du document';

  @override
  String get sectionImportantDates => 'Dates importantes';

  @override
  String get fieldIssueDate => 'Date d’émission';

  @override
  String get fieldExpiryDate => 'Date d’expiration';

  @override
  String get fieldActionDate => 'Date de début de renouvellement';

  @override
  String get actionDateHelper =>
      'La date à laquelle vous devriez commencer à agir, éventuellement avant l’expiration.';

  @override
  String get sectionPriorityRenewal => 'Priorité et renouvellement';

  @override
  String get fieldImpact => 'Impact en cas de péremption';

  @override
  String get fieldRenewalEffort => 'Effort de renouvellement';

  @override
  String get fieldCostOfLapsing => 'Coût de la péremption';

  @override
  String get fieldCostHelper =>
      'Montant ou courte description. Aucune devise n’est exigée.';

  @override
  String get fieldDependency => 'Dépendance';

  @override
  String get fieldDependencyHelper =>
      'Qu’est-ce qui dépend de la validité de ce document ?';

  @override
  String get fieldExpectedChanges => 'Changements attendus au renouvellement';

  @override
  String get fieldNotes => 'Notes';

  @override
  String get sectionReminders => 'Préférence de rappel';

  @override
  String get remindersHelper =>
      'Ces options sont enregistrées avec le document. Les notifications ne sont pas encore planifiées.';

  @override
  String get reminderOnActionDate => 'Le jour de l’action';

  @override
  String get reminder7Days => '7 jours avant';

  @override
  String get reminder30Days => '30 jours avant';

  @override
  String get saveDocument => 'Enregistrer le document';

  @override
  String get documentSaved => 'Document enregistré pour cette session.';

  @override
  String get discardDraftTitle => 'Abandonner ce brouillon ?';

  @override
  String get discardDraftMessage =>
      'Les informations saisies et l’image sélectionnée ne seront pas conservées.';

  @override
  String get discardDraftConfirm => 'Abandonner';

  @override
  String get discardDraftKeep => 'Continuer';

  @override
  String get errorRequired => 'Ce champ est obligatoire.';

  @override
  String get errorIssueAfterExpiry =>
      'La date d’émission ne peut pas être postérieure à la date d’expiration.';

  @override
  String get errorActionAfterExpiry =>
      'La date de début de renouvellement ne peut pas être postérieure à la date d’expiration.';

  @override
  String get categoryPassport => 'Passeport';

  @override
  String get categoryIdCard => 'Carte d’identité';

  @override
  String get categoryDrivingLicence => 'Permis de conduire';

  @override
  String get categoryInsurance => 'Assurance';

  @override
  String get categoryVisa => 'Visa / titre de séjour';

  @override
  String get categoryCertificate => 'Certificat';

  @override
  String get categoryWarranty => 'Garantie';

  @override
  String get categoryOther => 'Autre';

  @override
  String get impactLow => 'Faible';

  @override
  String get impactMedium => 'Moyen';

  @override
  String get impactHigh => 'Élevé';

  @override
  String get impactCritical => 'Critique';

  @override
  String get effortEasy => 'Facile';

  @override
  String get effortModerate => 'Modéré';

  @override
  String get effortDifficult => 'Difficile';

  @override
  String get requiredMarker => 'Obligatoire';

  @override
  String get optionalMarker => 'Facultatif';

  @override
  String get hasAttachment => 'Pièce jointe';

  @override
  String get selectDate => 'Choisir une date';
}
