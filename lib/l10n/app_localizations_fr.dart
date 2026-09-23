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
  String get navProfile => 'Profil';

  @override
  String get homeGreeting => 'Restez en avance sur l’essentiel';

  @override
  String get homeTitle => 'Votre registre';

  @override
  String get notificationsButton => 'Notifications';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsPlaceholderMessage =>
      'Les rappels ne sont pas planifiés dans cette version. Cet écran est un espace réservé.';

  @override
  String get searchPlaceholder => 'Rechercher dans votre registre';

  @override
  String get searchClear => 'Effacer la recherche';

  @override
  String get filterTooltip => 'Filtrer';

  @override
  String get filtersComingSoon =>
      'Les filtres arriveront dans une prochaine version.';

  @override
  String get reviewAction => 'Examiner maintenant';

  @override
  String get actionNeeded => 'Action requise';

  @override
  String get dueToday => 'Échéance aujourd’hui';

  @override
  String get oneDayRemaining => '1 jour restant';

  @override
  String daysRemaining(int count) {
    return '$count jours restants';
  }

  @override
  String get oneDayOverdue => '1 jour de retard';

  @override
  String daysOverdue(int count) {
    return '$count jours de retard';
  }

  @override
  String get highImpactLabel => 'Impact élevé';

  @override
  String get summaryDocuments => 'Documents';

  @override
  String get summarySubscriptions => 'Abonnements';

  @override
  String get summaryNeedsAttention => 'À traiter';

  @override
  String get summaryNext90Days => '90 prochains jours';

  @override
  String get snapshotDocumentsHint => 'Dossiers de votre registre';

  @override
  String get snapshotSubscriptionsHint => 'Abonnements suivis';

  @override
  String get snapshotNext90Hint => 'Dans tout votre registre';

  @override
  String snapshotDocumentsSupporting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count à traiter',
      one: '1 action due',
      zero: 'Aucune action',
    );
    return '$_temp0';
  }

  @override
  String snapshotSubscriptionsSupporting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count suivis',
      one: '1 suivi',
    );
    return '$_temp0';
  }

  @override
  String get pulseEyebrow => 'Prochaine meilleure action';

  @override
  String get pulseStartByEyebrow => 'Commencer avant';

  @override
  String get pulseExpiresEyebrow => 'Expire le';

  @override
  String get countdownDayUnit => 'jour';

  @override
  String get countdownDaysUnit => 'jours';

  @override
  String get countdownTodayUnit => 'aujourd’hui';

  @override
  String get countdownOverdueUnit => 'retard';

  @override
  String get addSheetDocumentSubtitle => 'Scannez ou saisissez un document';

  @override
  String get addSheetSubscriptionSubtitle =>
      'Suivre un prélèvement ou un renouvellement';

  @override
  String documentsSummary(int count) {
    return '$count enregistrés';
  }

  @override
  String documentsAttentionSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count à traiter',
      one: '$count à traiter',
    );
    return '$_temp0';
  }

  @override
  String get sectionNeedsAttention => 'À traiter';

  @override
  String get sectionComingUp => 'À venir';

  @override
  String get sectionRegistrySnapshot => 'Aperçu du registre';

  @override
  String sectionItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments',
      one: '$count élément',
    );
    return '$_temp0';
  }

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
  String get statusUrgent => 'Action requise';

  @override
  String get statusUpcoming => 'À venir';

  @override
  String get statusActive => 'Actif';

  @override
  String get statusNeutral => 'Info';

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
  String get addSheetTitle => 'Ajout rapide';

  @override
  String get addSheetSubtitle => 'Que souhaitez-vous suivre ?';

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
  String get fieldCategory => 'Catégorie';

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

  @override
  String get statusOverdue => 'En retard';

  @override
  String get documentDetailsTitle => 'Détails du document';

  @override
  String get editDocumentTitle => 'Modifier le document';

  @override
  String get editDocumentHeadline => 'Mettre à jour ce document';

  @override
  String get editDocumentSubtitle =>
      'Les modifications restent sur cet appareil pour cette session.';

  @override
  String get requiredFieldsHint =>
      'Les champs marqués d’un * sont obligatoires.';

  @override
  String get sectionEssential => 'Informations essentielles';

  @override
  String get sectionAdditional => 'Informations complémentaires';

  @override
  String get deleteDocument => 'Supprimer le document';

  @override
  String get deleteDocumentTitle => 'Supprimer ce document ?';

  @override
  String deleteDocumentMessage(String name) {
    return '$name sera retiré de cette session.';
  }

  @override
  String get deleteDocumentConfirm => 'Supprimer';

  @override
  String get deleteDocumentCancel => 'Annuler';

  @override
  String get documentUpdated => 'Document mis à jour pour cette session.';

  @override
  String get documentDeleted => 'Document supprimé de cette session.';

  @override
  String get deadlineHealth => 'État des échéances';

  @override
  String get deadlineRemaining => 'Temps restant';

  @override
  String get issuedBy => 'Délivré par';

  @override
  String get documentInformation => 'Informations du document';

  @override
  String get noRemindersSelected => 'Aucun rappel sélectionné';

  @override
  String get attachmentPreview => 'Aperçu de la pièce jointe';

  @override
  String get renewalHistory => 'Historique des renouvellements';

  @override
  String get noRenewalHistory =>
      'Aucun renouvellement enregistré pour le moment.';

  @override
  String get recordRenewal => 'Enregistrer un renouvellement';

  @override
  String get recordRenewalSubtitle =>
      'Ajoutez un renouvellement à cette session. Les autres informations restent inchangées, sauf si vous choisissez une nouvelle date de début.';

  @override
  String get previousExpiry => 'Expiration précédente';

  @override
  String get newExpiry => 'Nouvelle expiration';

  @override
  String get renewalDate => 'Date de renouvellement';

  @override
  String get renewalNoteOptional => 'Note (facultatif)';

  @override
  String get renewalRecorded => 'Renouvellement enregistré pour cette session.';

  @override
  String get errorNewExpiryNotAfterPrevious =>
      'La nouvelle date d’expiration doit être postérieure à la précédente.';

  @override
  String get errorNewExpiryRequired =>
      'La nouvelle date d’expiration est obligatoire.';

  @override
  String get errorActionAfterNewExpiry =>
      'La date de début de renouvellement ne peut pas être postérieure à la nouvelle date d’expiration.';

  @override
  String get documentUnavailableTitle => 'Document indisponible';

  @override
  String get documentUnavailableMessage =>
      'Ce document n’est plus dans cette session.';

  @override
  String get saveChanges => 'Enregistrer les modifications';

  @override
  String get discardChangesTitle => 'Abandonner les modifications ?';

  @override
  String get discardChangesMessage =>
      'Vos modifications ne seront pas conservées.';

  @override
  String get moreActions => 'Autres actions';

  @override
  String get editAction => 'Modifier';

  @override
  String get renewAction => 'Renouveler';

  @override
  String maskedDocumentNumberLabel(String number) {
    return 'Numéro de document masqué $number';
  }

  @override
  String get ownerLabel => 'Titulaire';

  @override
  String get optionalNewActionDate =>
      'Nouvelle date de début de renouvellement (facultatif)';

  @override
  String get saveRenewal => 'Enregistrer le renouvellement';

  @override
  String get viewAttachment => 'Voir la photo';

  @override
  String get noPhotoAttached => 'Aucune photo jointe';

  @override
  String get documentPassLabel => 'Résumé du document';

  @override
  String get documentsEyebrow => 'Portefeuille numérique';

  @override
  String get documentsSearchPlaceholder => 'Rechercher vos documents';

  @override
  String get documentsFilterAll => 'Tous';

  @override
  String get documentsSearchEmptyTitle => 'Aucun document correspondant';

  @override
  String get documentsSearchEmptyMessage =>
      'Essayez un autre nom, type ou titulaire, ou effacez la recherche pour voir votre portefeuille.';

  @override
  String get documentsFilterEmptyTitle => 'Rien dans ce filtre';

  @override
  String get documentsFilterEmptyMessage =>
      'Choisissez un autre statut, ou sélectionnez Tous pour voir chaque document enregistré.';

  @override
  String get documentsRemainingHeader => 'Tous les documents';

  @override
  String get documentPassTitle => 'Passe documentaire';

  @override
  String get documentPassEyebrow => 'Détails du document';

  @override
  String get viewScan => 'Voir le scan';

  @override
  String get remindersTitle => 'Rappels';

  @override
  String get reminderPreferencesTitle => 'Préférences de rappel';

  @override
  String get renewalHistoryEmptyTitle => 'Aucun renouvellement';

  @override
  String wizardStepOf(int current, int total) {
    return 'Étape $current sur $total';
  }

  @override
  String get wizardContinue => 'Continuer';

  @override
  String get wizardBack => 'Retour';

  @override
  String get stepSourceTitle => 'Scan ou saisie manuelle';

  @override
  String get stepIdentityTitle => 'Faites-le vôtre';

  @override
  String get stepDatesTitle => 'Dates importantes';

  @override
  String get stepRenewalTitle => 'Préparation du renouvellement';

  @override
  String get stepReviewTitle => 'Vérifier et enregistrer';

  @override
  String get howToAddTitle => 'Comment souhaitez-vous l’ajouter ?';

  @override
  String get scanDocumentTitle => 'Scanner le document';

  @override
  String get scanDocumentRecommended => 'Recommandé';

  @override
  String get scanDocumentSubtitle =>
      'Prenez une photo ou choisissez une image, puis vérifiez les informations extraites.';

  @override
  String get enterManuallyTitle => 'Saisir manuellement';

  @override
  String get enterManuallySubtitle =>
      'Saisissez les informations vous-même, étape par étape.';

  @override
  String get ocrPrivacy =>
      'Votre scan est traité sur cet appareil. Rien n’est enregistré avant votre confirmation.';

  @override
  String get ocrReviewPrivacy =>
      'Votre scan est traité sur cet appareil. Vérifiez toutes les informations extraites avant d’enregistrer.';

  @override
  String get scanAgain => 'Scanner à nouveau';

  @override
  String get ocrProcessingTitle => 'Lecture du document';

  @override
  String get ocrProcessingMessage =>
      'Le texte est reconnu sur cet appareil. Vous pouvez annuler et saisir les informations manuellement.';

  @override
  String get ocrCancel => 'Annuler le scan';

  @override
  String get ocrFailedTitle => 'Ce scan n’a pas pu être lu';

  @override
  String get ocrFailedMessage =>
      'Conservez la photo et saisissez les informations manuellement, ou essayez une autre image.';

  @override
  String get ocrRetry => 'Réessayer';

  @override
  String get ocrReviewTitle => 'Vérifiez votre scan';

  @override
  String ocrFieldsFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count champs trouvés',
      one: '1 champ trouvé',
      zero: 'Aucun champ trouvé',
    );
    return '$_temp0';
  }

  @override
  String get ocrConfidenceHigh => 'Confiance élevée';

  @override
  String get ocrConfidenceReview => 'À vérifier';

  @override
  String get ocrConfidenceMissing => 'Non détecté';

  @override
  String get ocrReviewField => 'Vérifier cette valeur';

  @override
  String get ocrSuggestedCountry => 'Pays suggéré';

  @override
  String get ocrSuggestedType => 'Type de document suggéré';

  @override
  String get ocrAddMissingField => 'Ajouter un champ manquant';

  @override
  String get ocrConfirmContinue => 'Confirmer les détails';

  @override
  String get ocrRetake => 'Reprendre le scan';

  @override
  String get fieldCountry => 'Pays ou région';

  @override
  String get schemaChangeTitle => 'Changer le type de document ?';

  @override
  String get schemaChangeMessage =>
      'Certaines informations saisies ne correspondent pas au nouveau type et seront retirées.';

  @override
  String get schemaChangeConfirm => 'Changer le type';

  @override
  String get schemaChangeCancel => 'Conserver le type actuel';

  @override
  String get addCustomField => 'Ajouter un champ personnalisé';

  @override
  String get customFieldLabel => 'Nom du champ';

  @override
  String get customFieldValue => 'Valeur';

  @override
  String get removeCustomField => 'Supprimer le champ';

  @override
  String get markFieldSensitive =>
      'Masquer cette valeur hors de la vérification';

  @override
  String get reviewJumpIdentity => 'Modifier l’identité';

  @override
  String get reviewJumpDates => 'Modifier les dates';

  @override
  String get reviewJumpRenewal => 'Modifier le plan de renouvellement';

  @override
  String get reviewJumpScan => 'Modifier le scan';

  @override
  String get reviewAttachmentYes => 'Photo jointe';

  @override
  String get reviewAttachmentNo => 'Aucune photo jointe';

  @override
  String reviewDynamicCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count champs supplémentaires',
      one: '1 champ supplémentaire',
      zero: 'Aucun champ supplémentaire',
    );
    return '$_temp0';
  }

  @override
  String suggestedActionDate(String date) {
    return 'Date de début suggérée : $date';
  }

  @override
  String get useSuggestedActionDate => 'Utiliser la date suggérée';

  @override
  String get countryGeneric => 'International';

  @override
  String get countryIndia => 'Inde';

  @override
  String get countryFrance => 'France';

  @override
  String get countryUae => 'Émirats arabes unis';

  @override
  String get countryOther => 'Autre';

  @override
  String get schemaGenericPassport => 'Passeport';

  @override
  String get schemaIndiaAadhaar => 'Aadhaar';

  @override
  String get schemaFranceNationalId => 'Carte nationale d’identité';

  @override
  String get schemaUaeEmiratesId => 'Emirates ID';

  @override
  String get schemaGenericOther => 'Autre document';

  @override
  String get fieldPassportNumber => 'Numéro de passeport';

  @override
  String get fieldFullName => 'Nom complet';

  @override
  String get fieldNationality => 'Nationalité';

  @override
  String get fieldDateOfBirth => 'Date de naissance';

  @override
  String get fieldGender => 'Genre';

  @override
  String get fieldAddress => 'Adresse';

  @override
  String get fieldSurname => 'Nom';

  @override
  String get fieldGivenNames => 'Prénoms';

  @override
  String get fieldAadhaarNumber => 'Numéro Aadhaar';

  @override
  String get fieldIdNumber => 'Numéro d’identité';

  @override
  String get navDocumentsShort => 'Docs';

  @override
  String get navSubscriptionsShort => 'Forfaits';

  @override
  String get navProfileShort => 'Moi';

  @override
  String get snapshotNinetyDayView => 'Vue 90 jours';

  @override
  String get profileMonogram => 'R';

  @override
  String get guidedSetup => 'Configuration guidée';

  @override
  String get ocrOnDeviceEyebrow => 'Extraction sur l’appareil';

  @override
  String get howToAddBody =>
      'Scannez pour gagner du temps, ou saisissez les détails vous-même.';

  @override
  String get identityIntro => 'Quelques détails pour organiser votre document.';

  @override
  String get datesIntro =>
      'Les dates incluent toujours le jour, le mois et l’année.';

  @override
  String get planningIntro =>
      'Les détails optionnels aident à décider ce qui mérite votre attention.';

  @override
  String get reviewIntro =>
      'Vérifiez les informations importantes. Vous pourrez tout modifier plus tard.';

  @override
  String get readyToSave => 'Prêt à enregistrer';

  @override
  String get scanToFill => 'Scanner pour remplir automatiquement';

  @override
  String get ocrDynamicTemplateTitle => 'Modèle de champs dynamique';

  @override
  String get ocrDynamicTemplateBody =>
      'Les champs changent selon le pays et le type de document. Les libellés inconnus deviennent des champs personnalisés.';

  @override
  String get ocrReviewHint =>
      'Vérifiez les valeurs mises en avant avant de continuer.';

  @override
  String get ocrProcessingHint => 'Le texte est reconnu sur cet appareil.';

  @override
  String get horizonOpenCalendar => 'Ouvrir le calendrier';

  @override
  String get horizon90EmptyTitle => 'Rien dans les 90 prochains jours';

  @override
  String get horizon90EmptyMessage =>
      'Les éléments avec une date d’action ou de renouvellement dans les 90 prochains jours apparaîtront ici, du plus proche au plus lointain.';

  @override
  String get catalogReviewEyebrow => 'Élément mis en avant';

  @override
  String get catalogReviewTitle => 'Examen';

  @override
  String get catalogNotInWalletTitle => 'Catalogue Accueil';

  @override
  String get catalogNotInWallet =>
      'Ceci est l’élément mis en avant sur l’Accueil. Il n’est pas enregistré dans Documents, donc la modification, la suppression et le renouvellement ne sont pas disponibles.';

  @override
  String get catalogActionLabel => 'Prochaine action';

  @override
  String get catalogRemainingLabel => 'Temps restant';

  @override
  String get catalogChargeDate => 'Date du prochain prélèvement';

  @override
  String get documentStatusLabel => 'Statut';

  @override
  String get homeEmptyTitle => 'Votre registre est vide';

  @override
  String get homeEmptyMessage =>
      'Ajoutez un document ou un abonnement pour suivre les dates importantes.';

  @override
  String get homeCalmTitle => 'Rien n’a besoin d’attention pour le moment';

  @override
  String get homeCalmMessage =>
      'Les éléments enregistrés sont à jour. Les dates à venir apparaissent dans À venir.';

  @override
  String homeEstimatedMonthly(String amount) {
    return '$amount / mois';
  }

  @override
  String get pulseDecideByEyebrow => 'Décider avant';

  @override
  String get pulseNextChargeEyebrow => 'Prochain prélèvement';

  @override
  String get subscriptionsEyebrow => 'Dépenser avec intention';

  @override
  String get subscriptionsSearchPlaceholder => 'Rechercher des abonnements';

  @override
  String subscriptionsSavedSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count enregistrés',
      one: '1 enregistré',
    );
    return '$_temp0';
  }

  @override
  String subscriptionsActiveSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count abonnements actifs',
      one: '1 abonnement actif',
    );
    return '$_temp0';
  }

  @override
  String subscriptionsAttentionSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count décisions à prendre',
      one: '1 décision à prendre',
      zero: 'Aucune décision à prendre',
    );
    return '$_temp0';
  }

  @override
  String get subscriptionsListHeader => 'Abonnements';

  @override
  String get addSubscriptionShort => 'Ajouter';

  @override
  String get subscriptionsSearchEmptyTitle => 'Aucun abonnement correspondant';

  @override
  String get subscriptionsSearchEmptyMessage =>
      'Essayez un autre nom ou une autre catégorie, ou effacez la recherche.';

  @override
  String get subscriptionsFilterEmptyTitle => 'Rien dans ce filtre';

  @override
  String get subscriptionsFilterEmptyMessage =>
      'Choisissez un autre statut, ou Tous pour voir chaque abonnement.';

  @override
  String get monthlySnapshotEyebrow => 'Aperçu mensuel';

  @override
  String get estimatedMonthlyCost => 'Coût mensuel estimé';

  @override
  String get estimatedMonthlyDisclaimer =>
      'Estimation normalisée des abonnements actifs. Ce n’est pas une dépense réelle ni un historique de paiements.';

  @override
  String estimatedMonthlyMultiple(int count) {
    return '$count devises';
  }

  @override
  String get fieldServiceName => 'Nom du service';

  @override
  String get fieldPlanName => 'Nom de l’offre';

  @override
  String get fieldAmount => 'Montant';

  @override
  String get fieldCurrency => 'Devise';

  @override
  String get fieldBillingCycle => 'Cycle de facturation';

  @override
  String get fieldNextPayment => 'Prochaine date de paiement';

  @override
  String get fieldDecideBy => 'Date de décision';

  @override
  String get fieldAutoRenew => 'Renouvellement automatique';

  @override
  String get billingWeekly => 'Hebdomadaire';

  @override
  String get billingMonthly => 'Mensuel';

  @override
  String get billingQuarterly => 'Trimestriel';

  @override
  String get billingYearly => 'Annuel';

  @override
  String get billingPerWeek => '/ semaine';

  @override
  String get billingPerMonth => '/ mois';

  @override
  String get billingPerQuarter => '/ trimestre';

  @override
  String get billingPerYear => '/ an';

  @override
  String get subscriptionCategoryEntertainment => 'Divertissement';

  @override
  String get subscriptionCategoryHealth => 'Santé';

  @override
  String get subscriptionCategoryProductivity => 'Productivité';

  @override
  String get subscriptionCategoryUtilities => 'Services';

  @override
  String get subscriptionCategoryFinance => 'Finance';

  @override
  String get subscriptionCategoryEducation => 'Éducation';

  @override
  String get subscriptionCategoryOther => 'Autre';

  @override
  String get subscriptionServiceIntroTitle => 'Que suivez-vous ?';

  @override
  String get subscriptionServiceIntro =>
      'Commencez par le service et la catégorie.';

  @override
  String get subscriptionBillingIntroTitle => 'Définissez la facturation';

  @override
  String get subscriptionBillingIntro =>
      'Suivez les détails de votre abonnement.';

  @override
  String get subscriptionPreferencesIntroTitle => 'Anticipez le prélèvement';

  @override
  String get subscriptionPreferencesIntro =>
      'Choisissez quand vous voulez décider.';

  @override
  String get subscriptionReviewIntroTitle => 'Prêt à suivre';

  @override
  String get subscriptionReviewIntro =>
      'Confirmez l’abonnement avant de l’ajouter à votre registre.';

  @override
  String get saveSubscription => 'Enregistrer l’abonnement';

  @override
  String get subscriptionSaved => 'Abonnement enregistré pour cette session.';

  @override
  String get subscriptionUpdated => 'Abonnement mis à jour pour cette session.';

  @override
  String get subscriptionDeleted => 'Abonnement supprimé de cette session.';

  @override
  String get subscriptionSaveFailed =>
      'L’abonnement n’a pas pu être enregistré. Votre brouillon est toujours là. Réessayez.';

  @override
  String get editSubscriptionTitle => 'Modifier l’abonnement';

  @override
  String get subscriptionDetailsTitle => 'Abonnement';

  @override
  String get planDetailsEyebrow => 'Détails de l’offre';

  @override
  String get planInformation => 'Informations sur l’offre';

  @override
  String get nextDecision => 'Prochaine décision';

  @override
  String get subscriptionUnavailableTitle => 'Abonnement indisponible';

  @override
  String get subscriptionUnavailableMessage =>
      'Cet abonnement n’est plus dans cette session.';

  @override
  String get nextPaymentHelper =>
      'Les dates passées restent un suivi non résolu. Les dates ne sont pas avancées automatiquement.';

  @override
  String get decideByHelper => 'Doit être le jour du paiement ou avant.';

  @override
  String get clearDecideBy => 'Effacer la date de décision';

  @override
  String get autoRenewHelper =>
      'Une préférence suivie dans cette application. Elle ne change rien chez le fournisseur.';

  @override
  String get autoRenewOn => 'Activé';

  @override
  String get autoRenewOff => 'Désactivé';

  @override
  String get subscriptionRemindersHelper =>
      'Ces options sont enregistrées avec l’abonnement. Les notifications ne sont pas planifiées.';

  @override
  String get subscriptionReminder7Days => '7 jours avant';

  @override
  String get subscriptionReminder1Day => '1 jour avant';

  @override
  String get subscriptionReminderOnCharge => 'Le jour du prélèvement';

  @override
  String get decideByWhyTitle => 'Pourquoi une date de décision ?';

  @override
  String get decideByWhyMessage =>
      'Elle vous laisse le temps de revoir ou d’annuler avant le paiement.';

  @override
  String get reviewJumpService => 'Modifier le service';

  @override
  String get reviewJumpBilling => 'Modifier la facturation';

  @override
  String get reviewJumpPreferences => 'Modifier les préférences';

  @override
  String get subscriptionSessionNote =>
      'Les abonnements restent sur cet appareil pour cette session. Il n’y a ni connexion bancaire ni paiement.';

  @override
  String get errorDecideByAfterPayment =>
      'La date de décision doit être le jour du paiement ou avant.';

  @override
  String get errorAmountNegative => 'Le montant ne peut pas être négatif.';

  @override
  String get errorAmountInvalid =>
      'Saisissez un montant valide pour cette devise.';

  @override
  String get errorAmountPrecision =>
      'Cette devise n’autorise pas autant de décimales.';

  @override
  String get subscriptionCancelled => 'Annulé';

  @override
  String get subscriptionActive => 'Actif';

  @override
  String get lifecycleLabel => 'Statut de suivi';

  @override
  String get markCancelled => 'Marquer comme annulé';

  @override
  String get cancelPlanTitle => 'Arrêter le suivi de cet abonnement ?';

  @override
  String cancelPlanMessage(String name) {
    return 'Cela met à jour uniquement le suivi de $name dans cette application. Cela n’annule pas l’abonnement chez le fournisseur.';
  }

  @override
  String get planMarkedCancelled =>
      'Abonnement marqué comme annulé pour cette session.';

  @override
  String get reactivatePlan => 'Réactiver';

  @override
  String get reactivatePlanTitle => 'Réactiver cet abonnement ?';

  @override
  String reactivatePlanMessage(String name) {
    return 'Confirmez la prochaine date de paiement pour $name. Cela reprend uniquement le suivi dans cette application.';
  }

  @override
  String get planReactivated => 'Abonnement réactivé pour cette session.';

  @override
  String get deleteSubscription => 'Supprimer l’abonnement';

  @override
  String get deleteSubscriptionTitle => 'Supprimer cet abonnement ?';

  @override
  String deleteSubscriptionMessage(String name) {
    return '$name sera retiré de cette session.';
  }

  @override
  String get subscriptionTrackingDisclaimer =>
      'Le registre suit cet abonnement mais ne l’annule pas et ne le facture pas automatiquement.';

  @override
  String homeHeroReview(String title) {
    return 'Examiner $title';
  }

  @override
  String get homeHeroRenewalToday => 'Le renouvellement commence aujourd’hui';

  @override
  String homeHeroRenewalOn(String date) {
    return 'Le renouvellement commence le $date';
  }

  @override
  String get homeHeroDecideToday => 'Décision due aujourd’hui';

  @override
  String homeHeroDecideOn(String date) {
    return 'Décider avant le $date';
  }

  @override
  String get homeCalmUpcomingCta => 'Voir à venir';

  @override
  String get homeEmptyHeadline =>
      'Un peu d’organisation.\nBeaucoup de sérénité.';

  @override
  String get homeEmptySupporting =>
      'Rassemblez vos documents et abonnements, et sachez ce qui demande attention.';

  @override
  String get homeAddFirstDocument => 'Ajouter votre premier document';

  @override
  String get homeAddASubscription => 'Ajouter un abonnement';

  @override
  String get homeBenefitDatesTitle =>
      'Voyez les dates importantes d’un coup d’œil';

  @override
  String get homeBenefitDatesMessage => 'Ne manquez plus l’essentiel.';

  @override
  String get homeBenefitPlansTitle =>
      'Examinez les abonnements avant renouvellement';

  @override
  String get homeBenefitPlansMessage => 'Gardez le contrôle de vos dépenses.';

  @override
  String get homeEstimatedMonthlyCost => 'Coût mensuel estimé';

  @override
  String homeSubscriptionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count abonnements',
      one: '1 abonnement',
      zero: 'Aucun abonnement',
    );
    return '$_temp0';
  }

  @override
  String get homeViewAll => 'Tout voir';

  @override
  String get homeAttentionListTitle => 'À traiter';

  @override
  String get comingUpFilterAll => 'Tous';

  @override
  String get comingUpFilterDocuments => 'Documents';

  @override
  String get comingUpFilterSubscriptions => 'Abonnements';

  @override
  String comingUpThisWeek(String year) {
    return 'Cette semaine · $year';
  }

  @override
  String comingUpLaterThisMonth(String year) {
    return 'Plus tard ce mois-ci · $year';
  }

  @override
  String comingUpMonthYear(String month, String year) {
    return '$month · $year';
  }

  @override
  String get comingUpEmptyFilter => 'Rien à venir dans cette vue.';

  @override
  String get attentionEmpty => 'Rien n’a besoin d’attention pour le moment.';

  @override
  String get statusToday => 'Aujourd’hui';

  @override
  String get homeStartRenewal => 'Commencer le renouvellement';

  @override
  String get homeNextPayment => 'Prochain paiement';

  @override
  String get homeDecideBeforeRenewal => 'Décider avant le renouvellement';

  @override
  String get homeSeeAllCurrencies => 'Voir tous les totaux par devise';

  @override
  String get homeNoActivePlans => 'Aucun abonnement actif';

  @override
  String get homeCurrencyBreakdownTitle => 'Estimations mensuelles';

  @override
  String get homeDocumentsTile => 'Documents';

  @override
  String get changeSelection => 'Modifier';

  @override
  String get fromScan => 'Issu du scan';

  @override
  String get checkThisDate => 'Vérifier cette date';

  @override
  String get searchListHint => 'Rechercher';

  @override
  String get identityExtrasTitle => 'Détails supplémentaires (facultatif)';

  @override
  String get identityExtrasSubtitle =>
      'Numéro, organisme et champs personnalisés';

  @override
  String get ocrReviewSubtitle =>
      'Vérifiez les informations extraites avant de continuer.';

  @override
  String get ocrNothingSavedHint =>
      'Rien n’est enregistré tant que vous n’avez pas choisi Enregistrer le document.';

  @override
  String get remindMePrefix => 'Me rappeler';

  @override
  String attachmentAddedOn(String date) {
    return 'Ajouté le $date';
  }

  @override
  String estimatedMonthlyCostValue(String amount) {
    return 'Coût mensuel estimé $amount';
  }

  @override
  String get selectedDocumentType => 'Type de document sélectionné';

  @override
  String get chooseOption => 'Choisir';
}
