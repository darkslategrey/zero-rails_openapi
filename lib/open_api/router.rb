# frozen_string_literal: true

module OpenApi
  module Router
    module_function

    def routes
      @routes ||=
          if (file = Config.rails_routes_file)
            File.read(file)
          else
            # :nocov:
            # ref https://github.com/rails/rails/blob/master/railties/lib/rails/tasks/routes.rake
            require './config/routes'
            Rails.application.routes.routes
            # if Rails::VERSION::MAJOR < 6
            #   inspector.format(ActionDispatch::Routing::ConsoleFormatter.new, nil)
            # else
            #   inspector.format(ActionDispatch::Routing::ConsoleFormatter::Sheet.new)
            # end
            # :nocov:
          end
    end

    # => { "api/v1/examples" => [{http_verb: 'get', path: '/a/b/{user_id}', action_path: 'ctrl#action'},..] }, group by paths
    def routes_list
      ctrls = {}
      @routes_list ||= routes.select do |route|
        !route.defaults.blank? && \
        !route.defaults[:internal] && \
        !route.defaults[:controller].blank?
      end.each do |route|
        ctrl = route.defaults[:controller]
        # byebug
        actions = ctrls[ctrl] || []
        actions << {
          http_verb: route.verb.downcase,
          # path: s,/ctrl/:param/action,/ctrl/{param}/action,
          path: route.path.spec.to_s.gsub(/:([a-z_]+)/) do |param|
            "{#{$1}}"
          end,
          action_path: "#{ctrl}##{route.defaults[:action]}"
        }
        ctrls[ctrl] = actions
      end && ctrls
    end

    def get_actions_by_route_base(route_base)
      routes_list[route_base]&.map { |action_info| action_info[:action_path].split('#').last }
    end

    def find_path_httpverb_by(route_base, action)
      routes_list[route_base]&.map do |action_info|
        if action_info[:action_path].split('#').last == action.to_s
          return [ action_info[:path], action_info[:http_verb].split('|').first ]
        end
      end ; nil
    end
  end
end
