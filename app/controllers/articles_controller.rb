class ArticlesController < ApplicationController
  include Pagy::Backend

  load_and_authorize_resource

  before_action :set_article, only: [:edit, :update, :destroy]

  # GET /articles
  def index
    @news = Article.news_section.order(published_at: :desc).includes(:user)
    @about = Article.about_section.order(published_at: :desc).includes(:user)
    @docs = Article.docs_section.order(published_at: :desc).includes(:user)
  end

  # GET /news
  def feed
    @articles = Article
      .published
      .where(section: params[:section])
      .order(published_at: :desc)

    @pagy, @articles = pagy(@articles)
  end

  # GET /articles/1
  # GET /:section/:slug
  def show
    if params[:slug].present?
      @article = Article.where(slug: params[:slug]).first
    else
      @article = Article.find(params[:id])
    end

    if @article.blank?
      render file: "public/404.html", status: :not_found
    end
  end

  # GET /articles/new
  def new
    @article = Article.new
  end

  def edit
  end

  # POST /articles
  def create
    @article = Article.new(article_params)

    respond_to do |format|
      if @article.save
        format.html { redirect_to @article, status: :see_other, notice: "'#{@article.path}' created." }
        format.json { render :show, status: :created, location: @article }
      else
        format.html { render :new }
        format.json { render json: @article.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /articles/1
  def update
    respond_to do |format|
      if @article.update(article_params)
        format.html { redirect_to @article, status: :see_other, notice: "'Saved changes to '#{@article.path}'." }
        format.json { render :show, status: :ok, location: @article }
      else
        format.html { render :edit }
        format.json { render json: @article.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /articles/1
  def destroy
    deletedPath = @article.path
    @article.destroy
    respond_to do |format|
      format.html { redirect_to articles_url, status: :see_other, notice: "'#{deletedPath}' deleted." }
      format.json { head :no_content }
    end
  end

  private
    def set_article
      @article = Article.find(params[:id])
    end

    def article_params
      params.require(:article).permit(
        :section, 
        :slug, 
        :title, 
        :user_id, 
        :published_at,
        :body,
        :splash,
        :splash_attribution
      )
    end
end
