# Configuración

<p style="color: #a3a3a3; font-size: 1.1em; margin: -8px 0 32px 0;">
  Nimbus se configura mediante variables de entorno en <code>~/.nimbus/.env</code>. La mayoría de las opciones tienen valores predeterminados seguros; las que se muestran abajo son las que realmente tocarás.
</p>

## Modo de registro

Nimbus controla quién puede crear una cuenta a través de `/sign-up` mediante una única variable de entorno: `NIMBUS_SIGN_UP_MODE`. El valor predeterminado es admin-gated (modo controlado por el administrador): el primer registro crea al administrador y luego el auto-registro se bloquea.

### Los tres modos

| Modo | Qué sucede | Caso de uso típico |
| --- | --- | --- |
| `first_user_only` *(predeterminado)* | El primer registro crea al administrador. Después, `/sign-up` redirige a `/sign-in`. | Instalaciones auto-hospedadas por un único operador, herramientas internas de la empresa |
| `open` | Cualquiera puede registrarse. Las cuentas nuevas obtienen el rol predeterminado. | Despliegues públicos, SaaS multi-inquilino |
| `closed` | Nadie puede registrarse. El administrador debe crear usuarios mediante CLI / SQL / inserción directa en la base de datos. | Entornos bloqueados, instalaciones de demostración |

El valor predeterminado es `first_user_only` porque es el único modo que se inicia sin intervención manual: una instalación nueva acepta el primer registro (que se convierte en administrador mediante el plugin admin de Better Auth) y luego se cierra. Los operadores que quieran registro abierto definen `NIMBUS_SIGN_UP_MODE=open` una vez y la instalación seguirá aceptando registros a partir de entonces.

### Cómo cambiarlo

Usa la CLI `nimbus config`: es una capa delgada sobre `~/.nimbus/.env` que gestiona las comillas y evita la edición manual:

```bash
nimbus config set NIMBUS_SIGN_UP_MODE open        # o "closed", o "first_user_only"
nimbus stop && nimbus start
```

Tres comandos, requiere reiniciar para que el dashboard cargue el nuevo valor en el próximo arranque.

### Sub-comandos útiles

```bash
nimbus config get NIMBUS_SIGN_UP_MODE             # imprime el valor actual
nimbus config list                               # muestra todas las claves de ~/.nimbus/.env
nimbus config unset NIMBUS_SIGN_UP_MODE          # borra la línea → vuelve al valor predeterminado en tiempo de ejecución
```

### Por qué admin-gated por defecto

El software auto-hospedado tiene una larga historia de incidentes de seguridad causados por «predeterminado = registro abierto»: una instalación nueva con un endpoint `/sign-up` abierto se convierte en una máquina expendedora de cuentas públicas a los pocos minutos de entrar en producción. Nimbus cerró ese agujero en agosto de 2026 cambiando el valor predeterminado a `first_user_only` — la instalación se inicia correctamente (el primer registro del operador se convierte en admin) y, a partir de ese momento, el auto-registro queda bloqueado a menos que el operador lo reabra explícitamente con `NIMBUS_SIGN_UP_MODE=open`.

Si quieres añadir a un compañero de equipo sin cambiar el modo, tienes dos opciones:

- Cambia la variable de entorno a `open`, reinicia, comparte `/sign-up` y, cuando termine de registrarse, vuelve a poner `first_user_only`.
- Inserta la fila directamente en la tabla `user` — el esquema está en `dashboard/src/lib/db/pg/schema.pg.ts`. Aplica el hash a la contraseña con `scrypt` de Better Auth (basado en `node:crypto scrypt`, con `@noble/hashes` como respaldo) antes de la inserción.

### Verificar el modo actual

La página de inicio de sesión del dashboard muestra un pie de página «Sign up» siempre que el registro esté permitido. Si lo ves, el registro está abierto o eres el primer usuario de una instalación nueva. Si no lo ves, estás en una instalación en modo closed con usuarios existentes.

Para ver el valor en bruto, ejecuta `nimbus config get NIMBUS_SIGN_UP_MODE` — o usa `nimbus config list` para ver todas las claves a la vez.