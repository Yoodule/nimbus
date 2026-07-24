# Télécharger Nimbus

<p style="color: #a3a3a3; font-size: 1.1em; margin: -8px 0 32px 0;">
  La passerelle MCP unifiée pour les agents IA en production. Une seule commande installe le CLI, la passerelle et tous les serveurs MCP inclus — vérifiés par SHA256, sans inscription, exécutés localement.
</p>

<div class="prereq-callout" markdown="1">

**Prérequis :** Nimbus nécessite <a href="https://www.docker.com/products/docker-desktop/" target="_blank">Docker Desktop</a> (ou <a href="https://orbstack.dev/" target="_blank">OrbStack</a> sur Mac) installé et **en cours d'exécution** avant l'installation. L'installation est gratuite et prend quelques minutes.

**Vérification rapide — exécutez ceci d'abord :**

```bash
docker ps
```

Si vous voyez un tableau `CONTAINER ID` (ou une ligne « no containers »), Docker est opérationnel et vous pouvez continuer. Si vous voyez `Cannot connect to the Docker daemon`, lancez Docker Desktop (macOS / Windows) ou exécutez `sudo systemctl start docker` (Linux), puis réessayez.

</div>

## Installation selon votre plateforme

=== "macOS"

    Apple Silicon et Intel. Nécessite macOS 12 Monterey ou ultérieur.

    **Installer (dernière version) :**

    ```bash
    curl -fsSL https://nimbus.yoodule.com/install.sh | bash
    ```

    L'installateur détecte automatiquement Apple Silicon ou Intel et vérifie contre les SHA256SUMS publiés.

    Téléchargements directs :

    - [Apple Silicon (M1/M2/M3/M4) →](https://github.com/Yoodule/nimbus/releases/latest/download/nimbus-darwin-arm64.tar.gz)
    - [Mac Intel →](https://github.com/Yoodule/nimbus/releases/latest/download/nimbus-darwin-amd64.tar.gz)

    **Configuration requise :**

    - **OS :** macOS 12 Monterey ou ultérieur (Apple Silicon ou Intel)
    - **Docker :** Docker Desktop 4.x+ ou [OrbStack](https://orbstack.dev/) — le démon doit être en cours d'exécution
    - **Python :** 3.12+ (installé automatiquement via [`uv`](https://astral.sh/uv) s'il est absent)
    - **Disque :** ~30 Mo pour le CLI, ~2 Go une fois les images Docker téléchargées
    - **RAM :** 4 Go minimum, 8 Go recommandés

    **Épingler une version spécifique :**

    Définissez `NIMBUS_VERSION` à droite du pipe (pour que `curl` ne la voie pas et que la variable atteigne le script installé) :

    ```bash
    curl -fsSL https://nimbus.yoodule.com/install.sh | NIMBUS_VERSION=v1.0.3 bash
    ```

=== "Linux"

    x86_64 et aarch64. Testé sur Ubuntu 22.04+, Debian 12+, Fedora 39+ et Arch.

    **Installer (dernière version) :**

    ```bash
    curl -fsSL https://nimbus.yoodule.com/install.sh | bash
    ```

    Téléchargements directs :

    - [x86_64 →](https://github.com/Yoodule/nimbus/releases/latest/download/nimbus-linux-amd64.tar.gz)
    - [aarch64 →](https://github.com/Yoodule/nimbus/releases/latest/download/nimbus-linux-arm64.tar.gz)

    **Configuration requise :**

    - **OS :** glibc 2.31+ (Ubuntu 22.04, Debian 12, Fedora 39, Arch)
    - **Docker :** Docker Desktop 4.x+, [OrbStack](https://orbstack.dev/), ou un Docker Engine headless — le démon doit être en cours d'exécution
    - **Python :** 3.12+ (installé automatiquement via [`uv`](https://astral.sh/uv) s'il est absent)
    - **Disque :** ~30 Mo pour le CLI, ~2 Go une fois les images Docker téléchargées
    - **RAM :** 4 Go minimum, 8 Go recommandés

    **Épingler une version spécifique :**

    Définissez `NIMBUS_VERSION` à droite du pipe (pour que `curl` ne la voie pas et que la variable atteigne le script installé) :

    ```bash
    curl -fsSL https://nimbus.yoodule.com/install.sh | NIMBUS_VERSION=v1.0.3 bash
    ```

=== "Windows"

    PowerShell et WSL2. Aucune élévation de privilèges requise. L'installateur se charge de configurer le PATH et enregistre Nimbus dans votre profil utilisateur.

    **Installer (dernière version) :**

    ```powershell
    irm https://nimbus.yoodule.com/install.ps1 | iex
    ```

    Téléchargements directs :

    - [One-click : lanceur install.cmd →](https://nimbus.yoodule.com/install.cmd)
    - [Windows (x64) →](https://github.com/Yoodule/nimbus/releases/latest/download/nimbus-windows-amd64.tar.gz)

    **Configuration requise :**

    - **OS :** Windows 10 build 19041+ ou Windows 11 avec WSL2 activé
    - **Docker :** Docker Desktop 4.x+ (avec backend WSL2) — le démon doit être en cours d'exécution
    - **Python :** 3.12+ (installé automatiquement via [`uv`](https://astral.sh/uv) s'il est absent)
    - **Disque :** ~30 Mo pour le CLI, ~2 Go une fois les images Docker téléchargées
    - **RAM :** 4 Go minimum, 8 Go recommandés (Qdrant + Docker)

    **Épingler une version spécifique :**

    Définissez `NIMBUS_VERSION` dans votre shell avant d'exécuter l'installateur (pour que la variable atteigne le script installé) :

    ```powershell
    $env:NIMBUS_VERSION = "v1.0.3"; irm https://nimbus.yoodule.com/install.ps1 | iex
    ```

---

Parcourez toutes les versions publiées sur la [page des releases](https://github.com/Yoodule/nimbus/releases).

---

## Vérifiez avant d'installer

Chaque release est livrée avec un fichier `SHA256SUMS`. L'installateur vérifie automatiquement les checksums. Pour inspecter les checksums vous-même, récupérez le fichier depuis la [page des releases](https://github.com/Yoodule/nimbus/releases) et exécutez :

```bash
sha256sum -c --strict SHA256SUMS
```

Chaque release est attestée par SLSA via GitHub Actions. Vous pouvez consulter l'attestation sur la [page des releases](https://github.com/Yoodule/nimbus/releases).

---

## Mise à jour

Le CLI se met à jour à sa place. Votre `mcp.json`, `.env`, vos tokens OAuth et l'index Qdrant sont conservés :

```bash
nimbus upgrade
```

Pour mettre à jour vers une version spécifique :

```bash
nimbus upgrade --version v1.0.3
```

---

## Désinstallation

Supprime le CLI, la passerelle, la pile Docker locale et le répertoire d'installation en une seule étape :

```bash
nimbus uninstall
```

Si vous souhaitez conserver votre configuration (mcp.json, .env, tokens) en vue d'une réinstallation future, passez `--keep-config` :

```bash
nimbus uninstall --keep-config
```

---

## Ce qui est installé

L'installateur écrit tout sous `~/.nimbus/` (ou `$NIMBUS_HOME` si vous le définissez) :

```
~/.nimbus/
├── nimbus                # Shim du CLI
├── nimbus-gateway-*      # Binaire de la passerelle compilé
├── mcp.json              # Registre des serveurs
├── servers/              # Serveurs MCP inclus
├── .env                  # Configuration locale (OPENROUTER_API_KEY, QDRANT_URL, …)
└── logs/                 # Logs d'exécution
```

Il ajoute également `export NIMBUS_HOME` et `PATH` à votre fichier de configuration shell (`~/.zshrc`, `~/.bashrc` ou `$PROFILE` sous Windows) pour que `nimbus` soit dans votre PATH dans les nouveaux shells.

---

## FAQ

### L'installateur affiche « arm64 not found » sur mon Mac Apple Silicon.

Ce message provient d'un installateur obsolète. Lancez `nimbus upgrade` pour récupérer la dernière version, ou récupérez directement une copie récente du script :

```bash
curl -fsSL https://raw.githubusercontent.com/Yoodule/nimbus/main/install.sh -o /tmp/install.sh && bash /tmp/install.sh
```

L'installateur actuel suit la redirection CDN de GitHub, détecte votre architecture et échoue rapidement avec un message d'erreur actionnable si l'asset manque réellement.

### Puis-je installer sur une machine sans Docker ?

Oui. Le CLI et la passerelle s'exécutent nativement. La pile MCP incluse (navigateur Playwright, base Postgres pour agents, Qdrant) utilise Docker, mais vous pouvez la sauter avec `nimbus start --no-deps` et pointer Nimbus vers des serveurs MCP distants via `mcp.json`.

### Quelle est la taille du téléchargement ?

L'archive du CLI pèse environ 30 Mo compressés. Les images Docker téléchargées au premier démarrage ajoutent environ 2 Go (Qdrant, Playwright, Postgres). Si votre bande passante est limitée, le mode de démarrage `--no-deps` ignore le téléchargement Docker.

### Où sont stockés mes tokens OAuth ?

En mémoire par défaut — réautorisez au redémarrage. Définissez `NIMBUS_PERSIST_TOKENS=1` dans `~/.nimbus/.env` pour les chiffrer au repos sous `~/.nimbus/tokens/`.

### Cela fonctionne-t-il sur Apple Silicon avec Rosetta ?

Oui — définissez `NIMBUS_HOST_ARCH=amd64` avant la commande d'installation pour récupérer la build Intel. Nous ne distribuons pas de binaire universel, car l'outillage de gatekeeper ajoute plus de 60 Mo pour une petite minorité d'utilisateurs ; Rosetta gère la traduction de manière transparente.

### Comment exécuter plusieurs instances de Nimbus sur le même hôte ? {#how-do-i-run-multiple-nimbus-instances-on-the-same-host}

Nimbus se lie à des ports fixes de l'hôte (`3000`, `8088`, `6333`, `5433`, `6080`, `8006`, `8007`, `8081`), donc l'installation par défaut est mono-instance. Pour en exécuter une seconde, clonez le dépôt, remappez les ports dans `compose.yaml`, définissez un `NIMBUS_HOME` unique et configurez `COMPOSE_PROJECT_NAME` pour éviter les collisions entre les deux piles. Tous les détails dans la [section Instances multiples](#how-do-i-run-multiple-nimbus-instances-on-the-same-host) ci-dessous.

### L'installation se bloque ou curl échoue — que faire ?

La cause la plus fréquente est un proxy d'entreprise qui intercepte le TLS. Définissez `HTTPS_PROXY` et réessayez. Si le problème vient spécifiquement du CDN, le script d'installation accepte `NIMBUS_VERSION` pour épingler une release réputée fonctionnelle, et vous pouvez aussi télécharger l'archive directement depuis la [page des releases](https://github.com/Yoodule/nimbus/releases) et la décompresser vous-même dans `~/.nimbus/` — le binaire est autonome.

---

<div style="text-align: center; margin: 48px 0 24px 0; padding: 32px; background: #0a0a0a; border: 1px solid #262626; border-radius: 12px;">
  <p style="color: #a3a3a3; font-size: 1.05em; margin: 0 0 16px 0;">
    Vous voulez un setup accompagné ? Réservez une session d'onboarding en 1 à 1 et nous passerons en revue votre espace de travail ensemble.
  </p>
  <a href="https://calendly.com/sundayj/30min" target="_blank" style="display: inline-flex; align-items: center; gap: 8px; background: #ffffff; color: #000000; text-decoration: none; font-weight: 600; padding: 12px 24px; border-radius: 8px; font-size: 1em;">
    Réserver une session d'onboarding →
  </a>
</div>
