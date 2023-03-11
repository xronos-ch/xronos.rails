class Admin::ArticlesController < AdminController
  include Pagy::Backend

  load_and_authorize_resource

  before_action :set_article, only: [:edit, :update, :destroy]
  before_action :add_articles_breadcrumb

  # GET /admin/articles
  def index
    @news = Article.news_section.order(published_at: :desc).includes(:user)
    @about = Article.about_section.order(published_at: :desc).includes(:user)
    @docs = Article.docs_section.order(published_at: :desc).includes(:user)
  end

  # GET /admin/articles/new
  def new
    @article = Article.new
    breadcrumbs.add "New article"
  end

  # GET /admin/articles/:id/edit
  def edit
    breadcrumbs.add @article.title
  end

  # POST /admin/articles
  def create
    @article = Article.new(article_params)

    respond_to do |format|
      if @article.save
        format.html { redirect_to admin_articles_url, status: :see_other, notice: "'#{@article.path}' created." }
        format.json { render :show, status: :created, location: @article }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @article.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admin/articles/1
  def update
    respond_to do |format|
      if @article.update(article_params)
        format.html { redirect_to admin_articles_url, status: :see_other, notice: "'Saved changes to '#{@article.path}'." }
        format.json { render :index, status: :ok, location: @article }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @article.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/articles/1
  def destroy
    deletedPath = @article.path
    @article.destroy
    respond_to do |format|
      format.html { redirect_to admin_articles_url, status: :see_other, notice: "'#{deletedPath}' deleted." }
      format.json { head :no_content }
    end
  end

  private
    def add_articles_breadcrumb
      breadcrumbs.add "Articles", admin_articles_path
    end

    def set_article
      @article = Article.find(params[:id])
    end

    def article_params
      params.require(:article).permit(
        :body,
        :publish,
        :published_at,
        :section, 
        :slug, 
        :splash,
        :splash_attribution,
        :title, 
        :user_id, 
      )
    end
end
