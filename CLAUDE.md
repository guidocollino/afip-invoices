# afip-invoices

Rails 6.1.7 JSON API que integra los web services de AFIP para generar y consultar comprobantes fiscales.

## Stack

- **Ruby** 2.7.6 / **Rails** 6.1.7 (API mode — `ActionController::API`)
- **Base de datos**: PostgreSQL
- **AFIP**: Savon (SOAP) para llamadas a WSAA y WSFE
- **PDF**: Prawn + prawn-table + prawn-qrcode + combine_pdf
- **Serialización JSON**: Representable gem
- **Auth**: HTTP Token — `Auth::TokenValidator` encripta el id de entidad
- **Config**: Figaro (`config/application.yml`)
- **Upload**: CarrierWave (logos de entidades)
- **Caché/Queue**: Redis

## Estructura

```
app/
  controllers/v1/   # Controllers de la API (versionados)
  errors/afip/      # Errores custom (InvalidRequestError, TimeoutError, etc.)
  managers/         # Orquestación de múltiples services
  models/           # AR models (Entity, Invoice, InvoiceItem, AssociatedInvoice, AfipRequest)
  pdfs/             # Generación de PDFs con Prawn
  representers/     # Serialización JSON con Representable
  services/
    afip/           # Integración con web services AFIP (Savon)
    auth/           # Encriptación y validación de tokens
    invoice/        # Lógica de negocio de comprobantes
    loggers/        # Logging de conexiones y comprobantes
    static_resource/# Recursos estáticos (tipos de comprobante, IVA, etc.)
```

## Skills disponibles

Ver `.claude/skills/` para flujos de trabajo con IA:

- `/code` — Implementar features, fixes o refactorings siguiendo las convenciones del proyecto
- `/github-issue-creator` — Crear issues en GitHub a partir de una descripción
- `/plan-from-issue` — Generar plan de implementación desde un issue
- `/create-pr` — Crear pull request con descripción en español

Las convenciones detalladas del proyecto están en `.claude/skills/code/conventions.md`.

## Testing

```bash
bundle exec rspec
bundle exec rubocop
```

RSpec + FactoryBot + Faker + WebMock + Shoulda-matchers. Specs en `spec/controllers/`, `spec/models/`, `spec/services/`. Mocks de AFIP en `spec/mocks/`.

## Variables de entorno necesarias

Ver `config/application.yml.sample`. Las principales:

- `AUTH_TOKEN` — token de autorización de la API
- `ENCRYPTION_SERVICE_SALT` — salt para encriptación de tokens de entidad
- `AFIP_WSDL_WSAA`, `AFIP_WSDL_WSFE` — endpoints WSDL de AFIP
