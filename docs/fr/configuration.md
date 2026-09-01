# Configuration

<p style="color: #a3a3a3; font-size: 1.1em; margin: -8px 0 32px 0;">
  Nimbus se configure via des variables d'environnement dans <code>~/.nimbus/.env</code>. La plupart des réglages ont des valeurs par défaut sûres ; ceux listés ci-dessous sont ceux que vous toucherez réellement.
</p>

## Mode d'inscription

Nimbus contrôle qui peut créer un compte via `/sign-up` à l'aide d'une seule variable d'environnement : `NIMBUS_SIGN_UP_MODE`. La valeur par défaut est admin-gated (mode contrôlé par l'administrateur) : la première inscription crée l'administrateur, puis l'auto-inscription est verrouillée.

### Les trois modes

| Mode | Comportement | Cas d'usage typique |
| --- | --- | --- |
| `first_user_only` *(par défaut)* | La première inscription crée l'administrateur. Ensuite, `/sign-up` redirige vers `/sign-in`. | Installations auto-hébergées par un seul opérateur, outils internes d'entreprise |
| `open` | N'importe qui peut s'inscrire. Les nouveaux comptes reçoivent le rôle par défaut. | Déploiements publics, SaaS multi-locataires |
| `closed` | Personne ne peut s'inscrire. L'administrateur doit créer les utilisateurs via CLI / SQL / insertion directe en base. | Environnements verrouillés, installations de démonstration |

La valeur par défaut est `first_user_only` parce que c'est le seul mode qui se bootstrap sans intervention manuelle : une installation fraîche accepte la première inscription (qui devient admin via le plugin admin de Better Auth), puis se ferme. Les opérateurs qui veulent une inscription ouverte définissent `NIMBUS_SIGN_UP_MODE=open` une seule fois et l'installation accepte les inscriptions par la suite.

### Comment le modifier

Utilisez la CLI `nimbus config` — c'est une fine surcouche de `~/.nimbus/.env` qui gère les guillemets et évite l'édition manuelle :

```bash
nimbus config set NIMBUS_SIGN_UP_MODE open        # ou "closed", ou "first_user_only"
nimbus stop && nimbus start
```

Trois commandes, un redémarrage requis pour que le dashboard charge la nouvelle valeur au prochain boot.

### Sous-commandes utiles

```bash
nimbus config get NIMBUS_SIGN_UP_MODE             # affiche la valeur courante
nimbus config list                               # affiche toutes les clés de ~/.nimbus/.env
nimbus config unset NIMBUS_SIGN_UP_MODE          # supprime la ligne → revient à la valeur par défaut
```

### Pourquoi admin-gated par défaut

Les logiciels auto-hébergés ont une longue histoire de « valeur par défaut = inscription ouverte » menant à des incidents de sécurité : une installation fraîche avec un endpoint `/sign-up` ouvert devient une machine à distribuer des comptes publics quelques minutes après sa mise en ligne. Nimbus a comblé cette faille en août 2026 en basculant la valeur par défaut vers `first_user_only` — l'installation se bootstrap proprement (la première inscription de l'opérateur devient admin), et à partir de ce moment l'auto-inscription est verrouillée sauf si l'opérateur revient explicitement à `NIMBUS_SIGN_UP_MODE=open`.

Pour ajouter un coéquipier sans changer le mode, vous avez deux options :

- Passer la variable d'environnement à `open`, redémarrer, partager `/sign-up`, puis revenir à `first_user_only` une fois l'inscription terminée.
- Insérer directement la ligne dans la table `user` — le schéma se trouve dans `dashboard/src/lib/db/pg/schema.pg.ts`. Hashez le mot de passe avec `scrypt` de Better Auth (basé sur `node:crypto scrypt`, avec `@noble/hashes` en repli) avant l'insertion.

### Vérifier le mode courant

La page de connexion du dashboard affiche un pied de page « Sign up » dès que l'inscription est autorisée. Si vous le voyez, l'inscription est ouverte ou vous êtes le premier utilisateur d'une installation fraîche. Si vous ne le voyez pas, vous êtes sur une installation en mode closed avec des utilisateurs existants.

Pour la valeur brute, `nimbus config get NIMBUS_SIGN_UP_MODE` l'affiche — ou utilisez `nimbus config list` pour voir toutes les clés d'un coup.