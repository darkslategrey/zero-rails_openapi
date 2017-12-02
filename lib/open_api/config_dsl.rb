module OpenApi
  module ConfigDSL
    def self.included(base)
      base.class_eval do
        module_function

        def open_api name, root_controller:
          @api = name
          open_api_docs[name] = { root_controller: root_controller }
        end

        def info version:, title:, **addition
          open_api_docs[@api][:info] = { version: version, title: title, **addition }
        end

        def server url, desc: ''
          (open_api_docs[@api][:servers] ||= [ ]) << { url: url, description: desc }
        end

        def security_scheme scheme_name, other_info# = { }
          other_info[:description] = other_info.delete(:desc) if other_info.key?(:desc)
          (open_api_docs[@api][:security_schemes] ||= { })[scheme_name] = other_info
        end

        def base_auth scheme_name, other_info = { }
          security_scheme scheme_name, { type: 'http', scheme: 'basic' }.merge(other_info)
        end

        def bearer_auth scheme_name, format = 'JWT', other_info = { }
          security_scheme scheme_name, { type: 'http', scheme: 'bearer', bearerFormat: format }.merge(other_info)
        end

        def api_key scheme_name, field:, in:, **other_info
          _in = binding.local_variable_get(:in)
          security_scheme scheme_name, { type: 'apiKey', name: field, in: _in }.merge(other_info)
        end

        def global_security_require scheme_name, scopes: [ ]
          (open_api_docs[@api][:global_security] ||= [ ]) << { scheme_name => scopes }
        end

        class << self
          alias global_security global_security_require
          alias global_auth     global_security_require
          alias auth_scheme security_scheme
        end
      end
    end
  end
end
