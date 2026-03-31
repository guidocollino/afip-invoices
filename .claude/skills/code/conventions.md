# Coding Conventions

Convenciones para escribir o modificar código en afip-invoices.

## Filosofía general

Rails JSON API — sin vistas, sin frontend. La app expone endpoints JSON consumidos por clientes externos. Lógica encapsulada en service objects.

## Controllers (`app/controllers/v1/`)

- Hereden de `ApplicationController` (que es `ActionController::API`)
- Versionados bajo el namespace `V1`
- `before_action` para setear recursos (`before_action :fetch_invoice, only: %i[show export]`)
- Responden siempre con `render json:`
- Strong params definidos en el controller con constantes (`INVOICE_PARAMS`, etc.)
- Autenticación vía `before_action :authenticate` — no saltear salvo endpoints públicos justificados

```ruby
module V1
  class InvoicesController < ApplicationController
    before_action :fetch_invoice, only: %i[show export]

    def show
      render json: Invoice::Finder.new(invoice: @invoice, entity: entity).run
    end

    private

    def fetch_invoice
      @invoice = Invoice.find_by(token: params[:id])
    end
  end
end
```

## Autenticación

- HTTP Token authentication — `@entity` se setea a partir del token en `ApplicationController#authenticate`
- El token encripta el id de la entidad mediante `Auth::TokenValidator`
- `entity` (attr_reader) disponible en todos los controllers

## Service Objects (`app/services/`)

Para lógica de negocio e integraciones externas. Namespaceados por dominio.

```ruby
# app/services/invoice/creator.rb
module Invoice
  class Creator
    def initialize(params, entity)
      @params = params
      @entity = entity
    end

    def call
      # lógica
    end
  end
end
```

Namespaces existentes: `Invoice::`, `Afip::`, `Auth::`, `StaticResource::`, `Loggers::`

## Managers (`app/managers/`)

Para orquestación de múltiples services. Usar cuando un flujo requiere coordinar varios pasos.

## Representers (`app/representers/`)

Representable gem para serialización JSON. Heredan de `Representable::Decorator`.

```ruby
class InvoiceRepresenter < Representable::Decorator
  include Representable::JSON

  property :id
  property :authorization_code
  collection :items, decorator: InvoiceItemRepresenter, class: InvoiceItem
end
```

## Models

- Validaciones en AR
- Concerns para lógica compartida (`Encryptable`, `Invoiceable`)
- `as_json` para controlar qué campos se exponen
- `has_secure_token` para tokens únicos
- CarrierWave para uploads (`mount_uploader`)
- No usar callbacks para lógica de negocio compleja — delegarla a services

## Error Classes (`app/errors/afip/`)

Errores custom para las respuestas de AFIP. Heredan de `Afip::BaseError`. Se rescatan en `ApplicationController`.

```ruby
module Afip
  class InvalidRequestError < BaseError; end
end
```

## PDFs (`app/pdfs/`)

### Jerarquía de clases

```
Prawn::Document
  └── ToPdf              # Base: fuente, helpers genéricos
        └── InvoicePdf   # Comprobante AFIP con header/items/totales/QR
              └── TestInvoicePdf  # Preview sin llamadas AFIP
```

`ToPdf` hereda de `Prawn::Document` e incluye `ActionView::Helpers::NumberHelper`. Toda clase nueva de PDF debe heredar de `ToPdf`.

### Sistema de coordenadas

- Origen `(0, 0)` en la esquina **inferior izquierda** de la página
- El eje Y crece hacia arriba — `TOP = 725` es la parte superior del área útil
- `cursor` devuelve la posición Y actual dentro del bounding box activo
- `move_down(n)` baja el cursor `n` puntos

### Estructura de `InvoicePdf#initialize`

El constructor sigue siempre este orden:
1. Llamar a `super(top_margin: 70)` para iniciar el documento
2. Asignar ivars (`@invoice`, `@entity`, `@items`, etc.)
3. Registrar headers/footers con `repeat :all, dynamic: true { ... }`
4. Llamar al método principal de contenido (`display_items_and_totals`)

### `repeat` para contenido repetido en cada página

```ruby
repeat :all, dynamic: true do
  display_header   # se re-evalúa por página (dynamic: true)
  display_footer
end
```

Usar `dynamic: true` cuando el contenido referencia `page_number` u otros valores que cambian por página.

### `bounding_box` para posicionamiento

```ruby
bounding_box([x, y], width: w, height: h) do
  # contenido
end
```

- `[x, y]` es la esquina **superior izquierda** del box (en coordenadas del documento)
- `height` es opcional — el box se estira si se omite
- `stroke_bounds` dibuja el borde del box activo (útil para debug)
- Los métodos de texto dentro del box fluyen y wrappean automáticamente

### Texto

```ruby
text "string", align: :center, style: :bold, size: 12
text_box "string", at: [x, cursor], width: w, height: h, overflow: :shrink_to_fit
```

- `text` fluye con el cursor; `text_box` se posiciona en coordenadas absolutas
- `inline_format: true` habilita tags: `<b>`, `<i>`, `<font size='9'>`, `<color rgb='ff0000'>`
- Para texto mixto con distintos estilos: `formatted_text [{ text: "...", size: 7, styles: [:bold, :italic] }]`

### Helpers propios de `ToPdf`

```ruby
field 'Label', value          # "<b>Label: </b> value" con move_down 5
paragraph "texto", align: :right, style: :bold
uploaded_file_path(url)       # resuelve ruta del logo (test vs producción)
```

### Tablas con prawn-table

```ruby
table(data, width: 540, cell_style: { size: 7 }, column_widths: { 1 => 150 }) do
  cells.borders           = []            # quita todos los bordes
  cells.borders           = [:bottom]     # solo borde inferior
  row(0).font_style       = :bold
  row(0).background_color = 'E3DDDC'
  column(0..1).align      = :left
  columns(2..6).align     = :right
  row(-1).size            = 11            # última fila más grande
  row(0..-1).height       = 15
end
```

- `data` es un array 2D de strings (o Cell objects para casos avanzados)
- `column_widths` como hash `{ índice => ancho }` o array de anchos
- `cell_style` aplica a todas las celdas; se puede sobreescribir por fila/columna

### Imágenes

```ruby
image uploaded_file_path(@invoice.logo_url), fit: [200, 45], position: :center, vposition: :center
```

- Usar siempre `uploaded_file_path(url)` para resolver la ruta correctamente en test/producción
- `fit:` escala la imagen para que quepa en el box dado manteniendo proporción

### QR code (prawn-qrcode + rqrcode)

```ruby
qr = RQRCode::QRCode.new(content_string)
render_qr_code(qr, stroke: false, dot: 1)
```

- `dot: 1` especifica el tamaño en puntos de cada módulo del QR
- Se renderiza en la posición actual del cursor dentro del bounding box activo
- El contenido del QR de AFIP es JSON en Base64 en una URL: `"#{URL}?p=#{Base64.strict_encode64(json)}"`

### Múltiples copias con combine_pdf

```ruby
combined = CombinePDF.new
[:original, :duplicate].each do |copy|
  combined << CombinePDF.parse(InvoicePdf.generate_copy(invoice, copy, data))
end
combined.to_pdf
```

`generate_copy` y `generate_combined_copies` son métodos de clase en `InvoicePdf`.

### Manejo de páginas

```ruby
start_new_page if y < MINIMUN_POSITION_TO_DISPLAY_TOTALS
```

Comparar `y` (alias de `cursor` a nivel documento) contra una constante mínima antes de renderizar secciones que no deben cortarse entre páginas.

## Configuración

- Figaro (`config/application.yml`) para variables de entorno
- Variables AFIP: `AFIP_WSDL_WSAA`, `AFIP_WSDL_WSFE`, etc.
- `AUTH_TOKEN`: token de autorización de la API
- `ENCRYPTION_SERVICE_SALT`: salt para encriptación de tokens de entidad

## Testing

- RSpec + FactoryBot + Faker + WebMock + Shoulda-matchers
- `spec/controllers/` para controllers (request specs)
- `spec/models/` para modelos
- `spec/services/` para services
- `spec/factories/` para factories
- `spec/mocks/` para mocks de servicios externos (AFIP, etc.)
- WebMock para stubear llamadas HTTP/SOAP a AFIP
- Sin mocks de base de datos — tests contra PostgreSQL real

## General

- Sin comentarios en código salvo lógica no obvia
- Texto user-facing en español, código en inglés
- `# frozen_string_literal: true` en todos los archivos Ruby
- Reusar services y lógica existente antes de crear nueva
- Seguir patterns existentes en el proyecto
