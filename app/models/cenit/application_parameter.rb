module Cenit
  class ApplicationParameter
    include Mongoid::Document

    field :name, type: String
    field :type, type: String
    field :many, type: Boolean
    field :group, type: String
    field :description, type: String

    validates_uniqueness_of :name
    validates_format_of :name, with: /\A[a-z]([a-z]|_|\d)*\Z/

    validate do
      self.group = nil if group.blank?
      self.description = nil if description.blank?
      errors.blank?
    end

    def group_s
      group.to_s
    end

    def type_enum
      %w(integer number boolean string object) + Cenit::Oauth.app_model.additional_parameter_types
    end

    def group_enum
      (application && application.application_parameters.collect(&:group).uniq.select(&:present?)) || []
    end

    def schema
      sch =
        if type.blank?
          {}
        elsif %w(integer number boolean string object).include?(type)
          {
            type: type
          }
        else
          Cenit::Oauth.app_model.parameter_type_schema(type)
        end
      sch = (many ? { type: 'array', items: sch } : sch)
      sch[:referenced] = true unless %w(integer number boolean string object).include?(type)
      sch[:group] = group if group
      sch[:description] = description if description.present?
      sch.deep_stringify_keys
    end
  end
end
