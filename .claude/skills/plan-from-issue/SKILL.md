---
description: >
  Genera un plan de implementación en borrador a partir de un GitHub Issue, guardándolo en docs/plans/.
  Usá esta skill cuando el usuario diga "planificá el issue #N", "generá el plan para el issue", "quiero el draft del issue X",
  "creá el implementation plan del issue", o cualquier variante que mencione planificar/draftear desde un issue de GitHub.
  También triggereá cuando el usuario proporcione un número de issue y pida que se genere un plan, documento o borrador de implementación.
model: opus
context: conversation
argument-hint: "[issue-number]"
---

# Plan from Issue

Genera un plan de implementación detallado a partir de un GitHub Issue del proyecto, guardándolo como borrador en `docs/plans/`.

## Objetivo

Producir un documento Markdown listo para ser revisado y seguido por un desarrollador durante la implementación. El plan debe ser **concreto y accionable**: debe incluir código real, decisiones de arquitectura ya tomadas, y una lista ordenada de pasos.

---

## Flujo de trabajo

### 1. Obtener el issue

Si `$ARGUMENTS` contiene un número de issue, usalo directamente. Si no, pedile al usuario el número del issue.

Ejecutá:
```bash
gh issue view <N>
```

Extraé del output:
- **Título**
- **Descripción** completa
- **Labels**, **Assignees**

### 2. Explorar el contexto del codebase

Antes de entrevistar al usuario, investigá activamente el código existente relevante al issue. No asumas — leé el código real para entender qué ya existe, qué reusar, y qué crear desde cero.

Según el dominio del issue, explorá:

- **Modelos relevantes**: `app/models/` — entidades mencionadas en el issue
- **Servicios existentes**: `app/services/` — namespaces similares o relacionados
- **Representers**: `app/representers/` — patrones de serialización JSON
- **Managers**: `app/managers/` — orquestación de services
- **PDFs**: `app/pdfs/` — clases de generación de PDF
- **Errores**: `app/errors/` — custom errors existentes
- **Controladores**: `app/controllers/v1/` — namespace y estructura base
- **Specs existentes**: `spec/` — patrones de tests usados en el dominio
- **Plans previos**: leer 1-2 archivos en `docs/plans/` del mismo dominio para capturar el estilo del proyecto

Leé también el `CLAUDE.md` del proyecto para respetar todas las convenciones.

### 3. Entrevistar al usuario

Con el issue leído y el codebase explorado, usá `AskUserQuestion` para hacer preguntas profundas sobre aspectos que el issue no aclara o que requieren decisiones de diseño. Cubrí estos ángulos:

- **Requisitos funcionales**: flujos completos, estados posibles, reglas de negocio
- **Modelo de datos**: entidades, relaciones, constraints, migraciones necesarias
- **Arquitectura**: dónde vive la lógica (service, manager, representer, model), impacto en código existente
- **Tradeoffs**: alternativas consideradas, decisiones de scope, qué NO incluir
- **Casos borde**: errores, concurrencia, datos vacíos, permisos
- **Dependencias**: impacto en features existentes, orden de implementación

Hacé preguntas de a una o dos a la vez. Profundizá en las respuestas antes de pasar al siguiente ángulo. No hagas preguntas sobre aspectos que ya están definidos en el issue o que podés inferir con seguridad del código existente — solo preguntá lo que realmente necesitás decidir.

### 4. Identificar decisiones de arquitectura

Con la entrevista completa, tomá todas las decisiones de diseño necesarias para que el plan sea autocontenido. No dejés ambigüedades. Si hay varias opciones válidas, elegí la más consistente con los patrones existentes y documentá el razonamiento.

Documentá cada decisión en la tabla `## Decisiones técnicas`.

### 5. Redactar el plan

Escribí el plan siguiendo el formato establecido (ver sección "Formato del plan" más abajo). El plan debe estar en **español**, salvo nombres de archivos, métodos, y fragmentos de código.

Guardá el plan en:
```
docs/plans/<issue-number>-<slug>.md
```

Donde `<slug>` es el título del issue en kebab-case, sin tildes ni caracteres especiales. Ejemplo: issue #93 "Modelar Organismos y Dependencias" → `93-modelar-organismos-y-dependencias.md`.

Informale al usuario dónde quedó guardado el archivo.

---

## Formato del plan

Seguí **exactamente** esta estructura. Agregá, reordenás o eliminás subsecciones según el dominio específico del issue, pero siempre manteniendo el espíritu de cada bloque.

```markdown
# Issue #<N> — <Título del issue>

**Issue:** https://github.com/unagisoftware/afip-invoices/issues/<N>

---

## Contexto

<Solo si el issue se construye sobre trabajo previo ya existente. Describí qué infraestructura ya existe y cómo este issue se encadena con ella. Omití esta sección si es un issue completamente nuevo.>

---

## Qué construir

<Descripción funcional de lo que hay que implementar, basada en la descripción del issue + entrevista. Sé concreto: qué entidades, qué comportamiento, qué UI.>

---

## Decisiones técnicas

| Decisión | Resolución |
|----------|-----------|
| <aspecto> | <decisión tomada y razonamiento breve> |
| ... | ... |

---

## Arquitectura

<Secciones específicas según el tipo de feature. Incluí código real (Ruby) en bloques de código. Mostrá el contenido exacto de cada archivo a crear o modificar. Podés subdividir en:>

### Modelo / Migración (si aplica)
### Rutas (si aplica)
### Controladores (`app/controllers/v1/`)
### Service Objects (si aplica)
### Manager (si aplica)
### Representer (si aplica)
### PDF (si aplica)
### Errores custom (si aplica)

---

## Tests

<Specs a escribir, organizados por tipo. Para cada archivo, listá los casos de test específicos.>

### `spec/.../<archivo>_spec.rb`
- caso 1
- caso 2

---

## Archivos a crear/modificar

### Crear:
1. `path/to/file.rb`

### Modificar:
1. `path/to/existing_file.rb` — <qué cambiar>

---

## Orden de implementación

1. <primer paso lógico>
2. <segundo paso>
...
```

---

## Principios de calidad del plan

Un buen plan cumple con estas condiciones:

- **Autocontenido**: un dev puede implementar el issue leyendo solo este documento, sin necesidad de pedir más contexto
- **Con código real**: no pseudocódigo. Código Ruby exacto, listo para copiar
- **Decisions first**: todas las decisiones arquitectónicas están tomadas y documentadas. No hay "podría ser X o Y"
- **Consistente con el proyecto**: usa los mismos namespaces, naming conventions, patterns de service/representer/manager, testing approach que el código existente
- **Scope claro**: qué está incluido y qué NO está incluido en este issue
- **Español**: el texto del plan está en español, salvo nombres técnicos

---

## Referencia de convenciones del proyecto (de CLAUDE.md)

- **Filosofía**: Rails JSON API — sin frontend, sin vistas
- **Service Objects**: en `app/services/`, namespaceados por dominio (`Invoice::`, `Afip::`, `Auth::`)
- **Managers**: en `app/managers/`, orquestación de múltiples services
- **Representers**: Representable gem en `app/representers/`, serialización JSON
- **PDFs**: Prawn en `app/pdfs/`
- **Errores custom**: en `app/errors/afip/`, rescatados en `ApplicationController`
- **Tests**: RSpec + FactoryBot + Faker + WebMock + Shoulda-matchers
- **Autenticación**: HTTP Token via `Auth::TokenValidator`, `before_action :authenticate`
- **DB**: PostgreSQL
- **Config**: Figaro (`config/application.yml`)
- **AFIP**: Savon para llamadas SOAP
