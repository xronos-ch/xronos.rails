# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/ParameterLists, Metrics/CyclomaticComplexity

# Base controller smoke-test mixin.
#
# Use in a controller test to assert that every routed REST action
# responds with a single expected status code, for both an unauthenticated
# request and a signed-in user (and, for admin-only controllers, also for
# a signed-in non-admin user). This is a *wiring* test, not a behaviour
# test: it catches route changes, missing actions, accidental auth
# removal, and format/auth interactions. Business logic should still be
# covered by hand-written tests in each controller's own test file.
#
# Payloads for create/update are built from FactoryBot via #smoke_payload_for.
# The default implementation works for any factory whose columns are
# simple scalars (e.g. MeasurementState, Material, Reference, Taxon).
# For factories whose strong-params shape differs from attributes_for
# (e.g. those with association foreign keys), override #smoke_payload_for
# in the test subclass.
#
# Usage:
#
#   class SitesControllerTest < ActionDispatch::IntegrationTest
#     include ControllerSmokeTest
#
#     smoke_tests(
#       param_key: :site,
#       statuses: {
#         index:  { not_signed_in: :success,  signed_in: :success },
#         show:   { not_signed_in: :success,  signed_in: :success },
#         new:    { not_signed_in: :redirect, signed_in: :success },
#         create: { not_signed_in: :redirect, signed_in: :found },
#         edit:   { not_signed_in: :redirect, signed_in: :success },
#         update: { not_signed_in: :redirect, signed_in: :redirect },
#         destroy:{ not_signed_in: :redirect, signed_in: :redirect }
#       }
#     )
#   end
#
# For nested resources (e.g. site_names under sites):
#
#   smoke_tests(
#     actions:   %i[new create edit update destroy],
#     param_key: :site_name,
#     parent:    { site_id: :smoke_site_id },
#     statuses:  { ... }
#   )
#
# For admin-only controllers (Admin::*, Curate, Issues):
#
#   smoke_tests(
#     requires_admin: true,
#     statuses: { ... }
#   )
#
# Format: by default, no format is forced; the controller's respond_to
# decides. To force a format, use:
#
#   query_params: { format: :json }
module ControllerSmokeTest
  extend ActiveSupport::Concern

  REST_ACTIONS = %i[index show new create edit update destroy].freeze
  MUTATING_ACTIONS = %i[create update destroy].freeze
  REJECTED_STATUSES = [302, 303, 404, 422].freeze

  included do
    # Ensure Devise mappings are loaded before any sign_in call; the test
    # environment does not eager-load routes by default.
    Rails.application.routes.eager_load!
    include Devise::Test::IntegrationHelpers
  end

  module SmokeDSL
    # Each role's value is a single Symbol naming the expected HTTP
    # status (e.g. :success, :not_found, :redirect, :see_other). The
    # test name and the assertion are both derived from it.
    #
    #   query_params: arbitrary query parameters to add to every request.
    #                Useful for actions that need a parent id outside the
    #                standard route, or to force a format.
    #
    #   parent:       { key: factory_or_smoke_method } for nested resources.
    #
    #   requires_admin: when true, the signed-in role signs in as an
    #                   admin user, and an additional test asserts that
    #                   a signed-in non-admin user is rejected from
    #                   mutating actions.
    #
    #   singular_resource: true for singular resources (no :id param).

    def smoke_tests(actions: REST_ACTIONS, param_key: nil, parent: nil, statuses: {},
                    query_params: {}, singular_resource: false, requires_admin: false)
      validate_actions!(actions)
      @smoke_actions           = actions
      @smoke_param_key         = param_key
      @smoke_parent            = parent
      @smoke_statuses          = default_statuses(actions).merge(statuses)
      @smoke_query_params      = query_params
      @smoke_singular_resource = singular_resource
      @smoke_requires_admin    = requires_admin

      @smoke_statuses.each do |action, role_statuses|
        role_statuses.each do |role, status|
          define_method(:"test_#{action}_responds_with_#{status}_when_#{role}") do
            perform_smoke_request_as(action, role)
            assert_smoke_response(status)
            return unless role == :not_signed_in && MUTATING_ACTIONS.include?(action)

            assert_unauthenticated_mutating_rejected(action)
          end
        end
      end

      return unless requires_admin

      actions.each do |action|
        next unless MUTATING_ACTIONS.include?(action)

        define_method(:"test_#{action}_rejects_signed_in_non_admin") do
          sign_in create(:user)
          perform_smoke_request_for(action)
          assert_includes REJECTED_STATUSES, response.status,
                          "Signed-in non-admin #{action} on #{controller_path} returned " \
                          "#{response.status} (#{Rack::Utils::HTTP_STATUS_CODES[response.status]}), " \
                          "expected one of #{REJECTED_STATUSES.inspect}. " \
                          'The controller is not enforcing admin-only access.'
        end
      end
    end

    def smoke_actions
      @smoke_actions ||= []
    end

    def smoke_param_key
      @smoke_param_key
    end

    def smoke_parent
      @smoke_parent
    end

    def smoke_statuses
      @smoke_statuses ||= {}
    end

    def smoke_query_params
      @smoke_query_params ||= {}
    end

    def smoke_singular_resource
      @smoke_singular_resource ||= false
    end

    def smoke_requires_admin
      @smoke_requires_admin ||= false
    end

    private

    def validate_actions!(actions)
      unknown = actions - REST_ACTIONS
      return if unknown.empty?

      raise ArgumentError, "Unknown smoke-test actions: #{unknown.inspect}"
    end

    def default_statuses(actions)
      actions.index_with { { not_signed_in: :success, signed_in: :success } }
    end
  end

  class_methods do
    prepend SmokeDSL
  end

  private

  def perform_smoke_request_as(action, role)
    case role
    when :not_signed_in
      perform_smoke_request_for(action)
    when :signed_in
      user = self.class.smoke_requires_admin ? create(:user, :admin) : create(:user)
      sign_in user
      perform_smoke_request_for(action)
    else
      raise ArgumentError, "Unknown role: #{role.inspect}"
    end
  end

  def perform_smoke_request_for(action)
    parent_params = build_parent_params
    needs_id = %i[show edit update destroy].include?(action) && !self.class.smoke_singular_resource

    case action
    when :index
      get route_for(:index, parent_params)
    when :new
      get route_for(:new, parent_params)
    when :create
      post route_for(:create, parent_params),
           params: { self.class.smoke_param_key => smoke_payload_for(:create) }
    when :show
      get route_for(:show, needs_id ? parent_params.merge(id: smoke_record.to_param) : parent_params)
    when :edit
      get route_for(:edit, needs_id ? parent_params.merge(id: smoke_record.to_param) : parent_params)
    when :update
      patch route_for(:update, needs_id ? parent_params.merge(id: smoke_record.to_param) : parent_params),
            params: { self.class.smoke_param_key => smoke_payload_for(:update) }
    when :destroy
      delete route_for(:destroy, needs_id ? parent_params.merge(id: smoke_record.to_param) : parent_params)
    end
  end

  def assert_smoke_response(expected)
    assert_response expected
  end

  # Security invariant for mutating actions (create / update / destroy):
  # an unauthenticated request must be rejected by the controller's auth
  # check *before* the action runs. We assert this positively by
  # requiring the response to be one of the statuses that mean "rejected
  # by auth":
  #
  #   3xx redirect  — `authenticate_user!` redirected to the login page
  #   404           — CanCan denied access (rescued to 404)
  #   422           — action ran, found the user wasn't allowed, and
  #                   explicitly returned :unprocessable_entity
  #
  # Anything else (200, 204, 500) means the action either ran
  # successfully or crashed mid-execution without the auth check
  # firing — both indicate the controller is missing or bypassing
  # authentication.
  def assert_unauthenticated_mutating_rejected(action)
    assert_includes REJECTED_STATUSES, response.status,
                    "Unauthenticated #{action} on #{controller_path} returned " \
                    "#{response.status} (#{Rack::Utils::HTTP_STATUS_CODES[response.status]}), " \
                    "expected one of #{REJECTED_STATUSES.inspect} (redirect, " \
                    'not_found, or unprocessable_entity). ' \
                    'The controller is missing or bypassing authentication.'
  end

  def route_for(action, params)
    # Build a polymorphic-style URL via the routes, so we don't have to
    # know whether Rails generated a singular or plural path helper.
    # For nested resources (e.g. site_names), `params` already carries
    # the parent ids (e.g. { site_id: 1 }) and url_for resolves them.
    # `smoke_query_params` values: a Symbol starting with `smoke_` is
    # sent as a method (so the test can define a helper), any other
    # value is passed through.
    qp = self.class.smoke_query_params.transform_values do |v|
      v.is_a?(Symbol) && v.to_s.start_with?('smoke_') ? send(v) : v
    end
    all_params = qp.merge(params)
    url_for(controller: controller_path, action: action, **all_params.symbolize_keys)
  end

  def controller_path
    # Derive the URL helper prefix from the test class name. The
    # convention is that the test class is named after the controller
    # with "Test" appended. We find the leftmost "Controller" or
    # "ControllerTest" segment in the class name and keep everything
    # before it.
    #
    #   C14sControllerTest                  -> "c14s"
    #   Sites::DescriptionsControllerTest    -> "sites/descriptions"
    #   Admin::ArticlesControllerTest        -> "admin/articles"
    name = self.class.name
    name = name.sub(/ControllerTest\z/, '')
    name = name.sub(/Controller\z/, '')
    name.underscore
  end

  def smoke_record
    @smoke_record ||= begin
      key = self.class.smoke_param_key
      if key.nil? || !FactoryBot.factories.registered?(key)
        Struct.new(:to_param).new('1')
      else
        create(key)
      end
    end
  end

  def build_parent_params
    return {} unless self.class.smoke_parent

    self.class.smoke_parent.transform_values do |v|
      v.is_a?(Symbol) && v.to_s.start_with?('smoke_') ? send(v) : create(v).id
    end
  end

  def smoke_payload_for(_action)
    key = self.class.smoke_param_key
    return {} unless key && FactoryBot.factories.registered?(key)

    attrs = FactoryBot.attributes_for(key)
    attrs.transform_values { |v| v.is_a?(ActiveRecord::Base) ? v.id : v }
  end
end
# rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metrics/ParameterLists, Metrics/CyclomaticComplexity
