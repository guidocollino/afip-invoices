# Skill: Crear Pull Request

Esta skill analiza la rama actual y crea un pull request siguiendo el formato del proyecto.

## Instrucciones

### 1. Analizar cambios

Correr estos comandos en paralelo:
- `git diff main...HEAD` — todos los cambios desde que se bifurcó de main
- `git log main..HEAD --pretty=format:"%s%n%b"` — mensajes de commit
- `git diff main...HEAD --name-only` — lista de archivos modificados
- `git status` — estado actual de la rama

Si hay cambios sin commitear, advertir al usuario y preguntar si quiere commitear primero.

### 2. Detectar secciones opcionales

**Cambios en la BD**: verificar si hay migraciones nuevas o modificadas:
- Buscar archivos en `db/migrate/*.rb`
- Si existen, listarlas y describir qué hacen

**Capturas**: verificar si hay cambios visuales en:
- Vistas: `app/views/**/*.erb`
- CSS: `app/assets/**/*.css`
- Stimulus controllers: `app/javascript/controllers/**/*.js`
- Si existen, indicar que se deben adjuntar capturas manualmente

### 3. Generar descripción del PR

Escribir la descripción en español. Formato:

```markdown
## Resumen

* [Cambio concreto 1]
* [Cambio concreto 2]

## Cambios

* [Detalle técnico 1]
* [Detalle técnico 2]
```

**Secciones opcionales** — incluir solo cuando aplica:

```markdown
## Cambios en la BD

* [Descripción del cambio en la migración]

## Capturas

* [Indicar que se deben adjuntar capturas]

Closes #NUMERO_ISSUE
```

**Criterios:**
- **Resumen**: síntesis del problema resuelto y qué se construyó, basado en commits y diff
- **Cambios**: lista de cambios concretos (modelos, controllers, vistas, bug fixes, etc.)
- **Cambios en la BD**: solo si hay migraciones; describir cada una brevemente
- **Capturas**: solo si hay cambios en vistas, CSS o JS
- **Closes**: agregar si el nombre de la rama o los commits referencian un número de issue
- Omitir secciones opcionales si no aplican; no dejar secciones vacías

### 4. Crear el Pull Request

Pushear la rama y crear el PR:

```bash
git push -u origin HEAD
gh pr create --title "Título" --body "$(cat <<'EOF'
[Descripción generada]
EOF
)"
```

- **Título**: conciso (menos de 70 caracteres), en español, consistente con el estilo del proyecto
- **Base**: `main`

### 5. Resultado

Mostrar la URL del PR al usuario. Si se necesitan capturas, recordarle que las agregue.

## Manejo de errores

- Si está en `main`: preguntar qué rama usar o si necesita crear una
- Si no hay commits adelante de main: advertir y detener
- Si ya existe un PR para esta rama: mostrar la URL existente y preguntar si quiere actualizarlo
- Si `gh` falla por permisos: correr `gh auth status` para verificar la cuenta activa
