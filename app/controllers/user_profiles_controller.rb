class UserProfilesController < ApplicationController
  load_and_authorize_resource
  #layout "admin"
  before_action :set_user_profile, only: %i[ show edit update destroy ]

  # GET /user_profiles or /user_profiles.json
  def index
    @user_profiles = UserProfile.all
  end

  # GET /contributors/1 or /contributors/1.json
  def show
    user = @user_profile.user
    @pagy, @contribs = pagy_user_changelog(user)

    respond_to do |format|
      format.html
      format.json
    end
  end

  # GET /user_profiles/new
  def new
    @user_profile = UserProfile.new
  end

  # GET /user_profiles/1/edit
  def edit
  end

  # POST /user_profiles or /user_profiles.json
  def create
    # TODO: what if we're an admin trying to create a profile for another user?
    @user_profile.user = current_user

    respond_to do |format|
      if @user_profile.save
        format.html { redirect_to @user_profile, notice: "User profile updated." }
        format.json { render :show, status: :created, location: @user_profile }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @user_profile.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /user_profiles/1 or /user_profiles/1.json
  def update
    respond_to do |format|
      if @user_profile.update(user_profile_params)
        format.html { redirect_to @user_profile, notice: "User profile updated." }
        format.json { render :show, status: :ok, location: @user_profile }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @user_profile.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /user_profiles/1 or /user_profiles/1.json
  def destroy
    @user_profile.destroy
    respond_to do |format|
      format.html { redirect_to user_profiles_url, notice: "User profile was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

    def pagy_user_changelog(user) # rubocop:disable Metrics/MethodLength
      versions_scope = PaperTrail::Version
        .select("id, 'Version' AS entry_type, created_at")
        .where(whodunnit_user_email: user.email)

      events_scope = SupersessionEvent
        .select("id, 'SupersessionEvent' AS entry_type, created_at")
        .where(whodunnit_user_id: user.id)

      union_sql = "(#{versions_scope.to_sql}) UNION ALL (#{events_scope.to_sql})"

      total = ActiveRecord::Base.connection.execute(
        "SELECT COUNT(*) FROM (#{union_sql}) AS changelog"
      ).first['count'].to_i

      pagy = Pagy.new(count: total, page: params[:page] || 1)

      rows = ActiveRecord::Base.connection.execute(<<~SQL)
        SELECT entry_type, id
        FROM (#{union_sql}) AS changelog
        ORDER BY created_at DESC
        LIMIT #{pagy.limit} OFFSET #{pagy.offset}
      SQL

      version_ids = rows.select { |r| r['entry_type'] == 'Version' }.map { |r| r['id'] }
      event_ids   = rows.select { |r| r['entry_type'] == 'SupersessionEvent' }.map { |r| r['id'] }

      versions = PaperTrail::Version.where(id: version_ids).index_by(&:id)
      events   = SupersessionEvent.where(id: event_ids)
                    .includes(:whodunnit_user, :superseded_by)
                    .index_by(&:id)

      entries = rows.filter_map { |r|
        case r['entry_type']
        when 'Version' then versions[r['id']]
        when 'SupersessionEvent' then events[r['id']]
        end
      }

      [pagy, entries]
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_user_profile
      if params[:id]
        @user_profile = UserProfile.find(params[:id])
      else
        @user_profile = current_user.user_profile
      end
    end

    # Only allow a list of trusted parameters through.
    def user_profile_params
      params.fetch(:user_profile, {}).permit(
        :full_name,
        :public_email,
        :affiliation,
        :orcid,
        :url,
        :photo,
        :user_id
      )
    end

end
