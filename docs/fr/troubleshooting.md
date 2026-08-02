# Dépannage

<p style="color: #a3a3a3; font-size: 1.1em; margin: -8px 0 32px 0;">
  Si <code>nimbus</code> ne se comporte pas comme prévu, commencez par <code>nimbus doctor</code> : il imprime un tableau de santé couvrant l'accessibilité de Docker, le décalage de version CLI/gateway, la santé des conteneurs et si votre installation est en retard sur la dernière version. La plupart des problèmes y apparaissent.
</p>

Si `doctor` ne couvre pas votre symptôme, les sections ci-dessous sont organisées par **ce que vous voyez** plutôt que par le composant suspecté : choisissez la correspondance la plus proche.

---

## Commencez ici : `nimbus doctor`

```bash
nimbus doctor
```

Il vérifie quatre choses et imprime une ligne par vérification :

- **Sonde Docker** — le daemon est-il joignable ? Cette vérification s'exécute en premier pour qu'une machine neuve ne voie pas un trompeur « tout va bien » pendant que `nimbus start` est sur le point d'échouer.
- **Décalage CLI / gateway** — le conteneur gateway en cours est-il plus ancien que votre CLI de plus d'une version mineure ? Un CLI décalé avertira mais ne refusera pas de démarrer.
- **Santé des conteneurs** — les conteneurs gateway, postgres, redis et qdrant sont-ils sains ?
- **Fraîcheur des mises à jour** — existe-t-il une release plus récente sur GitHub ? (Ignoré sur les builds de dev où la clé publique minisign embarquée est un placeholder.)

Le code de sortie est toujours `0` — `doctor` n'échoue jamais, il affiche des avertissements pour rester utilisable comme vérification d'état depuis CI et la supervision.

---

## Problèmes d'installation

### `nimbus` n'est pas dans mon `PATH` après l'installation

Le programme d'installation écrit `export NIMBUS_HOME=~/.nimbus` et les mises à jour de `PATH` dans `~/.zshrc`, `~/.bashrc` ou `$PROFILE` (Windows). Ouvrez un nouveau shell, ou `source` votre fichier rc dans celui en cours :

```bash
# macOS / Linux — choisissez le shell que vous utilisez vraiment
source ~/.zshrc
source ~/.bashrc
```

Si `nimbus` est toujours absent, l'installation a peut-être échoué en silence. Vérifiez le journal d'installation (il imprime le chemin à la fin d'une exécution réussie) et relancez avec le script explicite :

```bash
curl -fsSL https://nimbus.yoodule.com/install.sh | bash
```

### L'installateur dit « arm64 not found » sur Apple Silicon

Ce message provient d'un installateur obsolète. Récupérez une copie fraîche du script et relancez :

```bash
curl -fsSL https://raw.githubusercontent.com/Yoodule/nimbus/main/install.sh -o /tmp/install.sh && bash /tmp/install.sh
```

L'installateur actuel suit la redirection CDN de GitHub, détecte votre architecture via `uname -m`, et échoue rapidement avec une erreur actionable si l'asset manque vraiment.

### L'installation bloque ou `curl` échoue

La cause la plus fréquente est un proxy d'entreprise qui intercepte TLS :

```bash
HTTPS_PROXY=http://votre-proxy:port curl -fsSL https://nimbus.yoodule.com/install.sh | bash
```

Si le CDN lui-même est le problème, épinglez une version connue avec `NIMBUS_VERSION` :

```bash
curl -fsSL https://nimbus.yoodule.com/install.sh | NIMBUS_VERSION=v1.0.2 bash
```

Vous pouvez aussi télécharger le tarball directement depuis la [page des releases](https://github.com/Yoodule/nimbus/releases) et le décompresser à la main dans `~/.nimbus/` — le binaire est autonome.

### L'installation réussit mais `nimbus start` dit que Docker n'est pas joignable

Docker est installé mais le daemon ne tourne pas. Démarrez-le :

- **macOS / Windows** — ouvrez Docker Desktop (ou OrbStack). L'icône de la baleine dans la barre de menus doit être fixe, pas animée.
- **Linux** — `sudo systemctl start docker`, ou `sudo dockerd` si vous n'êtes pas sur systemd.

Vérifiez avec `docker ps`. Si vous voyez `Cannot connect to the Docker daemon`, le daemon n'est pas encore prêt — attendez quelques secondes et réessayez.

---

## Problèmes de conteneurs

### Un conteneur redémarre en boucle

`docker ps` montre un conteneur dans l'état `Restarting`. La cause la plus fréquente est un volume obsolète issu d'un ancien `.env` :

```bash
docker logs nimbus-gateway-1 --tail 100    # ou nimbus-postgres-1 / nimbus-redis-1 / nimbus-qdrant-1
```

Cherchez l'erreur précise. S'il s'agit d'un échec d'authentification Postgres ou Redis, votre `.env` a fait tourner les identifiants mais le volume nommé conserve les anciens. Récupération :

```bash
nimbus stop
# Mettez le volume obsolète de côté pour que l'init se ré-exécute proprement.
# nimbus start régénère des identifiants frais sur un volume neuf ;
# l'ancien est préservé en -corrupt-<timestamp> au cas où vous auriez besoin
# de l'inspecter.
docker volume rm nimbus_postgres_data
nimbus start
```

Les anciennes sous-commandes `nimbus recover-pg-role` / `nimbus recover-redis-password` ont disparu — ce flux est le chemin de récupération supporté.

### `nimbus start` dit « port already in use »

Nimbus lie des ports fixes sur l'hôte (3000 dashboard, 8088 gateway, 6080 noVNC, 5433 postgres, 6379 redis, 6333/6334 qdrant). Si autre chose sur l'hôte occupe déjà l'un de ces ports, `start` échouera en indiquant le numéro en conflit.

Trouvez et arrêtez le processus en conflit :

```bash
# macOS / Linux
sudo lsof -iTCP:8088 -sTCP:LISTEN
```

Pour une configuration multi-instance durable, consultez la section **Instances multiples** de la [page de téléchargement](download.md#how-do-i-run-multiple-nimbus-instances-on-the-same-host).

### Le dashboard dit « gateway unreachable »

Le dashboard tourne sur `http://localhost:3000`. S'il charge mais que chaque action renvoie « gateway unreachable », le conteneur gateway n'écoute pas réellement sur 8088. Vérifiez :

```bash
docker ps | grep gateway
docker logs nimbus-gateway-1 --tail 50
curl -s http://localhost:8088/version
```

Une cause fréquente sur Apple Silicon sous Rosetta est une incompatibilité de plateforme — l'image du gateway est `linux/arm64` mais le runtime réclame `amd64`. Définissez `NIMBUS_HOST_ARCH=arm64` avant `nimbus start`.

---

## Problèmes OAuth

### « OAuth callback failed » quand je clique sur Approve

Le gateway tente d'atterrir le callback OAuth sur `http://localhost:8088/oauth/callback` par défaut. Si vous exécutez Nimbus derrière un tunnel ou un navigateur distant, le fournisseur rejettera le callback car l'URL ne correspond pas à celle enregistrée.

La solution est de définir `NIMBUS_URL` (utilisé par le proxy OAuth du dashboard) et `OAUTH_REDIRECT_BASE` (utilisé par le gateway) à l'URL publique vers laquelle le fournisseur doit rediriger. Les deux sont documentés dans [`.env.example`](https://github.com/Yoodule/nimbus/blob/main/.env.example).

### OAuth Upwork : « redirect_uri_mismatch »

Le fournisseur OAuth d'Upwork est strict sur la correspondance exacte de `redirect_uri`. Le `UPWORK_REDIRECT_URI` de l'installateur doit être identique à celui enregistré dans la console développeur Upwork — caractère pour caractère, slash final inclus.

Si vous voyez `redirect_uri_mismatch`, vérifiez la valeur dans `~/.nimbus/.env` :

```bash
nimbus config get UPWORK_REDIRECT_URI
```

…puis comparez octet par octet avec la console Upwork. Après correction, redémarrez le conteneur gateway :

```bash
nimbus stop && nimbus start
```

### Les tokens disparaissent après un redémarrage

C'est voulu. Par défaut, les tokens OAuth vivent uniquement en mémoire — chaque redémarrage est une re-autorisation. C'est le défaut le plus sûr pour les hôtes partagés / multi-utilisateur. Si vous voulez des tokens persistants, consultez la [section de persistance OAuth](download.md#where-do-my-oauth-tokens-live) de la FAQ de téléchargement.

---

## Problèmes de serveurs MCP

### Un serveur MCP inclus ne démarre pas

`docker logs nimbus-gateway-1 --tail 200` montrera le sous-processus stdio mourir avec une erreur d'import ou une variable d'environnement manquante. Les deux coupables habituels :

1. **Clé API manquante** — vérifiez `~/.nimbus/.env` pour les `*_API_KEYS` concernées (pluriel, séparées par des virgules). Le gateway et le dashboard lisent la forme plurielle et se rabattent sur la forme singulière ; pool vide ⇒ le fournisseur renvoie 401.
2. **Décalage de version Python** — les serveurs MCP inclus tournent via `uv run python`. Si vous avez un Python système plus ancien que 3.12, `uv` en récupérera un plus récent à la première invocation, ce qui peut prendre ~30 secondes la première fois.

### `find_tools` ne renvoie rien

`find_tools` est une recherche sémantique sur l'index vectoriel Qdrant. Des résultats vides signifient :

- Qdrant n'est pas joignable — `docker ps | grep qdrant` doit afficher sain ; `curl http://localhost:6333/healthz` doit renvoyer 200.
- L'index n'a pas encore été construit — le gateway ingère les descriptions d'outils au premier démarrage. Attendez une minute puis réessayez. Si c'est toujours vide après 5 minutes, redémarrez : `nimbus stop && nimbus start`.

### J'ai ajouté un serveur à `mcp.json` mais il n'apparaît pas

Deux possibilités :

1. **Erreur de syntaxe dans `mcp.json`** — le gateway ignore silencieusement les entrées malformées. Validez avec :
   ```bash
   nimbus mcp list
   ```
   Si votre nouveau serveur n'est pas dans la liste, le JSON est en cause. Une virgule en trop ou un antislash non échappé est le coupable habituel.

2. **Le gateway ne s'est pas rechargé** — `mcp.json` est lu au démarrage du conteneur. Après modification :
   ```bash
   nimbus stop && nimbus start
   ```

Pour les serveurs HTTP, l'URL doit être joignable depuis l'intérieur du conteneur gateway — `localhost` depuis votre machine hôte n'est *pas* le même `localhost` dans Docker. Utilisez `host.docker.internal:<port>` à la place.

---

## Problèmes OpenRouter / modèles

### « Invalid API key » au premier chat

Le CLI demande `OPENROUTER_API_KEY` au tout premier `nimbus start` et l'écrit dans `~/.nimbus/.env`. Si vous avez ignoré ce prompt ou que la clé est obsolète :

```bash
nimbus config set OPENROUTER_API_KEYS sk-or-v1-...
nimbus stop && nimbus start
```

Notez le pluriel : `OPENROUTER_API_KEYS` (séparées par des virgules pour plusieurs clés, avec repli sur la forme singulière). Un pool de clés vide ou incorrect fait que chaque requête part sans en-tête `Authorization` et le fournisseur renvoie 401.

### « Model not found » pour un ID de modèle précis

Nimbus utilise par défaut `openrouter/free`. Si vous passez `--model <id>` et que le modèle n'existe pas sur OpenRouter, vous obtenez un 404. Vérifiez l'ID du modèle sur [openrouter.ai/models](https://openrouter.ai/models) — ils changent fréquemment.

Pour les modèles Ollama, le préfixe de routage est `ollama/<nom-du-modèle>` (par exemple `ollama/llama3.1`). Les ID sans préfixe sont supposés être OpenRouter.

### Échecs d'embeddings

Les embeddings utilisent par défaut `nvidia/llama-nemotron-embed-vl-1b-v2:free` (2048-dim, tier gratuit). Si ce modèle est indisponible ou limité en débit, définissez un repli :

```bash
nimbus config set EMBEDDING_MODEL openai/text-embedding-3-small
nimbus stop && nimbus start
```

Ceci ré-ingère chaque description d'outil dans Qdrant au prochain démarrage — prévoyez une minute d'indexation sur un cache froid.

---

## Récupération

### « Nimbus was installed by a different version »

Signifie qu'une installation antérieure a laissé un volume Postgres ou Redis figé sous des identifiants qui ne correspondent plus à votre `.env`. La solution :

```bash
nimbus stop && nimbus start
```

`start` détecte automatiquement la discordance et ré-initialise le rôle/mot de passe avec le `.env` actuel. Les anciennes sous-commandes `recover-pg-role` / `recover-redis-password` ont disparu.

### Tout effacer et repartir de zéro

```bash
nimbus uninstall
curl -fsSL https://nimbus.yoodule.com/install.sh | bash
nimbus start
```

Ceci supprime le CLI, tous les conteneurs, tous les volumes nommés et `~/.nimbus/`. Vous perdrez les tokens OAuth, le `.env` et toutes les descriptions d'outils stockées dans Qdrant. Réautorisez au premier lancement.

### Je veux revenir à une version antérieure du CLI

```bash
nimbus update --version v1.0.1
```

(Ou la version dont vous avez besoin.) Le self-update du CLI utilise le même remplacement atomique + SHA256 + minisign que `nimbus update`, simplement épinglé à une release précise.

---

## Toujours bloqué ?

Ouvrez un ticket sur le [tracker Nimbus](https://github.com/Yoodule/nimbus/issues) avec :

- La sortie de `nimbus doctor`
- Plateforme et architecture de l'hôte (`uname -a` sur macOS/Linux, `systeminfo` sur Windows)
- Les journaux de conteneurs pertinents : `docker logs nimbus-gateway-1 --tail 200` (ou `nimbus-postgres-1` / `nimbus-redis-1` / `nimbus-qdrant-1`)
- Tout ce qui semble lié dans `~/.nimbus/logs/`

Le CLI n'envoie jamais votre `.env` ni vos tokens OAuth — c'est à vous de les censurer, mais le reste des diagnostics est sûr à partager.
