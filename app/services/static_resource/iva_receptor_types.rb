# frozen_string_literal: true

module StaticResource
  class IvaReceptorTypes < Base
    private

    def operation
      :fe_param_get_condicion_iva_receptor
    end

    def resource
      :condicion_iva_receptor
    end
  end
end
