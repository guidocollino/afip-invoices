---
name: github-issue-creator
description: |
  Crea GitHub Issues a partir de una descripción libre del usuario. Usa esta skill siempre que el usuario quiera reportar un bug, pedir una feature, registrar una tarea o cualquier problema en el repositorio actual. Actívala cuando el usuario mencione "crear issue", "abrir issue", "reportar bug", "agregar feature request", "quiero registrar", "issue en GitHub", o cualquier variante que implique crear algo en el tracker del proyecto. No esperes que el usuario tenga todo el detalle listo — la skill se encarga de entrevistar al usuario para completar la información necesaria.
---

# GitHub Issue Creator

Tu tarea es crear un GitHub Issue bien estructurado en el repositorio actual a partir de una descripción libre del usuario. El objetivo es ahorrarle tiempo al usuario: que solo tenga que describir el problema con sus propias palabras y que el issue quede claro y accionable para cualquiera que lo lea.

## Proceso

### 1. Entender el problema

Empezá con la descripción que dio el usuario. Si es suficientemente clara para determinar:

- Qué tipo de issue es (bug, feature, hotfix)
- Cuál es el problema o la necesidad concreta

...podés proceder directamente. Si la descripción es ambigua o falta información importante, usá `AskUserQuestion` para hacer **una sola pregunta a la vez**, priorizando lo más importante primero.

**Cuándo preguntar y cuándo inferir:**
- Si el tipo de issue es obvio por contexto (ej: "se rompe X cuando hago Y" → bug), no preguntes.
- Si la prioridad o urgencia no está clara, preguntá solo si el tipo podría ser `hotfix`.
- No hagas más de 2-3 preguntas en total. Preferí inferir con criterio antes que sobrecargar al usuario.

### 2. Elegir el label correcto

Usá uno de estos labels:

- **bug**: algo que funciona mal o produce un error inesperado
- **feature**: una funcionalidad nueva que no existe aún
- **hotfix**: un bug crítico que necesita atención urgente

### 3. Armar el issue

Escribí el issue con este formato según el tipo:

---

**Para bugs:**

```
## Descripción
[Qué está fallando, con contexto suficiente para entender el problema]

## Pasos para reproducir
1. ...
2. ...
3. ...

## Comportamiento esperado
[Qué debería pasar]

## Comportamiento actual
[Qué está pasando en cambio]

## Contexto adicional
[Entorno, versión, logs relevantes, capturas — si aplica]
```

**Para features:**

```
## Descripción
[Qué funcionalidad se quiere agregar y por qué]

## Comportamiento esperado
[Cómo debería funcionar cuando esté implementado]

## Contexto adicional
[Casos de uso, mockups, referencias — si aplica]
```

**Para hotfixes:**

```
## Descripción del problema crítico
[Qué está fallando y por qué es urgente]

## Impacto
[A quién afecta y cómo]

## Pasos para reproducir
1. ...
2. ...

## Comportamiento esperado
[Qué debería pasar]
```

---

Completá las secciones con la información que tenés. Si alguna sección no aplica o no hay info suficiente, podés omitirla. No inventes detalles que el usuario no mencionó.

### 4. Contexto técnico (opcional)

Antes de crear el issue, preguntá al usuario usando `AskUserQuestion`:

> "¿Querés que busque en el código dónde puede estar el problema para agregar contexto técnico al issue?"

**Si responde que sí:** hacé una búsqueda rápida en el codebase (Grep, Glob, Read) para identificar los archivos y funciones probablemente involucrados. Agregá una sección al final del body:

```
## Contexto técnico
- Archivos posiblemente afectados: `app/controllers/...`
- Lógica relacionada: [función o área del código relevante]
```

El objetivo de esta sección es orientar a quien vaya a resolver el issue, no proponer la solución. Mencioná dónde está el problema, no cómo arreglarlo.

**Si responde que no:** omitir esta sección y continuar.

### 5. Crear el issue con `gh`

Una vez que tenés título, body y label, ejecutá:

```bash
gh issue create \
  --title "<título conciso y descriptivo>" \
  --body "<body formateado>" \
  --label "<bug|feature|hotfix>"
```

El repo lo detecta `gh` automáticamente desde el directorio actual.

**Si el label no existe en el repo**, crealo primero:
```bash
gh label create "<label>" --color "<color>" --description "<descripción>"
```
Colores sugeridos: bug → `#d73a4a`, feature → `#0075ca`, hotfix → `#e4e669`

### 6. Mostrar el resultado

Después de crear el issue, mostrá:

- **URL** del issue creado (para que el usuario pueda verlo directamente)
- **Resumen** de lo que se creó: título, label y las secciones principales del body

Ejemplo:
```
Issue creado: https://github.com/org/repo/issues/42

**#42 — El precio no se actualiza al cambiar la cantidad** [bug]

- Describe un error al editar items en el presupuesto
- Pasos para reproducir incluidos
- Sin pasos adicionales necesarios
```
