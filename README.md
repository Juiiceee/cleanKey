# CleanKey

CleanKey est une petite app macOS de barre de menu pour verrouiller temporairement le clavier, la souris et le trackpad pendant le nettoyage.

Code source : https://github.com/Juiiceee/cleanKey

## Fonctionnement

- Raccourci par défaut : `Control + Option + Command + L`.
- Le premier déclenchement verrouille les entrées.
- Pour déverrouiller, refais le raccourci et maintiens-le pendant 5 secondes.
- Un auto-déverrouillage de sécurité se déclenche après 3 minutes maximum.

## Installation

1. Télécharge `CleanKey.dmg` depuis la dernière GitHub Release.
2. Ouvre le DMG et glisse `CleanKey.app` vers Applications.
3. Lance l’app, puis autorise-la dans Réglages Système → Confidentialité et sécurité → Accessibilité.
4. Si macOS le demande, autorise aussi Input Monitoring.

Si macOS affiche “CleanKey.app est endommagé”, c’est Gatekeeper qui bloque l’app téléchargée parce qu’elle n’est pas notarizée. En attendant une release notarizée avec certificat Apple Developer, copie l’app dans Applications puis lance :

```bash
xattr -dr com.apple.quarantine /Applications/CleanKey.app
open /Applications/CleanKey.app
```

## Réglages

Depuis l’icône CleanKey dans la barre de menu :

- change le raccourci global;
- active ou désactive le lancement au démarrage;
- vérifie les permissions;
- consulte la version et le lien vers le code open source.

## Désinstallation

1. Ouvre les réglages CleanKey et désactive “Lancer CleanKey au démarrage”.
2. Quitte CleanKey depuis la barre de menu.
3. Supprime `CleanKey.app` du dossier Applications.
4. Optionnel : efface les réglages avec `defaults delete dev.loul.CleanKey`.
5. Optionnel : retire CleanKey des permissions Accessibilité/Input Monitoring dans Réglages Système.

## Développement

```bash
swift test
swift build -c release --product CleanKey
./scripts/package_app.sh
```

Le bundle généré se trouve dans `.build/app/CleanKey.app`, l’archive ZIP dans `.build/app/CleanKey.zip`, et le DMG dans `.build/app/CleanKey.dmg`.

## Releases

Les releases sont gérées avec `release-please`. Utilise des commits Conventional Commits :

- `feat: add something`
- `fix: correct something`
- `chore: update tooling`

Le workflow GitHub crée une Release PR, met à jour `CHANGELOG.md` et `version.txt`, puis attache `CleanKey.dmg` et `CleanKey.zip` à la release après merge.

Pour que `release-please` puisse créer ses PRs avec `GITHUB_TOKEN`, active dans GitHub :

- Settings → Actions → General → Workflow permissions → Read and write permissions.
- Settings → Actions → General → Allow GitHub Actions to create and approve pull requests.

Pour que la CI se lance aussi sur les PRs créées par `release-please`, crée un secret `RELEASE_PLEASE_TOKEN` contenant un PAT avec accès au repo. Le workflow utilise ce secret s'il existe, sinon il revient à `GITHUB_TOKEN`.

Pour éviter l’erreur Gatekeeper sur les téléchargements publics, configure aussi la signature/notarization Apple avec ces secrets :

- `APPLE_CERTIFICATE_BASE64` : certificat Developer ID Application exporté en `.p12`, encodé en base64.
- `APPLE_CERTIFICATE_PASSWORD` : mot de passe du `.p12`.
- `APPLE_CERTIFICATE_NAME` : nom exact de l’identité, optionnel si le `.p12` contient une seule identité Developer ID Application.
- `KEYCHAIN_PASSWORD` : mot de passe temporaire du keychain CI, optionnel.
- `APPLE_ID` : identifiant Apple du compte développeur.
- `APPLE_TEAM_ID` : Team ID Apple Developer.
- `APPLE_APP_SPECIFIC_PASSWORD` : mot de passe d’app Apple pour `notarytool`.

## Licence

MIT
