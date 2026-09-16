# Automatisation des e-mails — FICHE FORMATEUR V2

## Envoi hebdomadaire

- Activation/désactivation de l'envoi automatique.
- Jour fixe : mardi.
- Heure configurable.
- L'adresse e-mail du compte utilisateur est l'expéditeur.
- Un ou plusieurs correspondants peuvent être sélectionnés.
- La fiche de la semaine est générée en PDF et jointe à l'e-mail.
- Avant l'envoi, le système vérifie que la fiche est complète et soumise. Si elle ne l'est pas, aucun envoi de fiche incomplète n'est effectué et le rappel prévu peut être déclenché.
- Historique : date, heure, destinataires, fiche concernée et résultat de l'envoi.

## Récapitulatif mensuel

- Activation/désactivation indépendante de l'envoi mensuel.
- Jour fixe : le 28 de chaque mois.
- Heure configurable dans les paramètres.
- Un ou plusieurs correspondants peuvent être sélectionnés indépendamment des destinataires hebdomadaires.
- Le système rassemble les données du mois concerné dans un récapitulatif PDF.
- Le récapitulatif comprend notamment : heures manuelles, jours travaillés, congés, repos et nombre de RH / Extra.
- Le récapitulatif du mois est envoyé automatiquement le 28 avec le PDF en pièce jointe.
- Le système doit gérer les mois incomplets : le 28, le récapitulatif porte sur le mois en cours jusqu'au 28 inclus, selon la règle de période retenue dans les paramètres. Le comportement devra être explicite dans l'interface.
- Historique séparé des envois mensuels.

## Paramètres d'envoi

- Expéditeur : e-mail du compte connecté.
- Destinataires hebdomadaires : liste sélectionnable.
- Destinataires mensuels : liste sélectionnable.
- Heure d'envoi hebdomadaire : configurable, jour fixé au mardi.
- Heure d'envoi mensuel : configurable, jour fixé au 28.
- Activation indépendante des deux automatismes.
- Bouton « Envoyer un test » pour vérifier la configuration avant activation.

## Rappel de remplissage

- Jour et heure configurables.
- Notification/rappel si la fiche n'est pas complète.
- Le rappel peut être indépendant de l'envoi automatique.

## Architecture requise

Les automatismes doivent être exécutés côté serveur par un planificateur (cron/job scheduler), afin qu'ils fonctionnent même lorsque le téléphone ou l'ordinateur de l'utilisateur est éteint. L'envoi réel nécessitera un service e-mail configuré côté serveur ; l'adresse du compte utilisateur sera utilisée comme expéditeur dans les limites autorisées par le fournisseur e-mail.
