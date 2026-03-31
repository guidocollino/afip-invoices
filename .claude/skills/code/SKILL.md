---
description: Implementar una feature, fix o refactoring
model: sonnet
argument-hint: [plan file, spec file o descripción]
allowed-tools: Bash(bundle exec *), Bash(bin/rails *)
---

# Implementación

## Workflow

1. **Verificar branch**: Chequeá si estás en `main`. Si es así, pedí al usuario un nombre de branch y creala antes de empezar.

2. **Entender qué hay que hacer**: Si se pasó un archivo como argumento (`$ARGUMENTS`), leelo. Si es un plan de `docs/plans/`, seguí sus pasos. Si es una descripción corta, usala directamente. Si no se pasó nada, preguntá al usuario.

3. **Leer convenciones**: Leé `.claude/skills/code/conventions.md` para tener presentes los patterns del proyecto.

4. **Explorar código existente**: Buscá y leé el código afectado. Entendé los patterns antes de modificar. Revisá services, representers, managers y models relacionados.

5. **Plantear pasos**: Antes de escribir código, comunicá al usuario los pasos que vas a seguir. Esperá confirmación.

6. **Implementar paso a paso**: Ejecutá cada paso comunicando progreso. Seguí los patterns del proyecto:
   - Lógica de negocio → Service Object (`app/services/`)
   - Orquestación de múltiples services → Manager (`app/managers/`)
   - Serialización JSON → Representer (`app/representers/`)
   - Generación de PDFs → clase en `app/pdfs/`
   - Errores custom de AFIP → `app/errors/afip/`
   - Autenticación: HTTP Token via `Auth::TokenValidator`, sin Devise

7. **Resolver ambigüedades**: Si algo no está claro, preguntá antes de decidir.

8. **Crear tests**: Escribí specs después de implementar (RSpec + FactoryBot + WebMock).

9. **Verificar**:
   - Corré `bundle exec rspec` para los specs afectados.
   - Corré `bundle exec rubocop` para verificar estilo.

10. **Revisar código**: Usá el skill `simplify` para revisar el código generado.
