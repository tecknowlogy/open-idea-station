class IdeasController < ApplicationController
  skip_before_action :authorize, only: %i[index show]
  before_action :set_idea, only: %i[show edit update destroy]
  before_action :ensure_idea_owner, only: %i[edit update destroy]

  def index
    # TODO: move where methods to scope
    @ideas = Idea.includes(:categories)
      .where(is_archived: false)
      .where.not(published_at: nil)
      .order(published_at: :desc)
  end

  def show
    # TODO: put this check in it's own method like a before_action
    return if logged_in? && current_user.ideas.find_by_slug_name(@idea.slug_name).present?

    # Create an event model to handle events and make it run as a background task
    Acorn::IdeaViewerService.new(idea: @idea, user: current_user, viewed_at: Time.now, viewer_ip: request.remote_ip).call
  end

  def new
    @idea = Idea.new
  end

  def create
    @idea = current_user.ideas.new(idea_params)
    respond_to do |format|
      if @idea.save
        format.html { redirect_to @idea, notice: "Idea was successfully created" }
        format.json { render :show, status: :created, location: @idea }
      else
        format.html { render :new }
        format.json { render json: @idea.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /ideas/1/edit
  def edit; end

  # PATCH/PUT /ideas/1
  # PATCH/PUT /ideas/1.json
  def update
    respond_to do |format|
      if @idea.update(idea_params)
        format.html { redirect_to @idea, notice: "Idea was successfully updated" }
        format.json { render :show, status: :ok, location: @idea }
      else
        format.html { render :edit }
        format.json { render json: @idea.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /ideas/1
  # PATCH/PUT /ideas/1.json
  def destroy
    @idea.update_columns({ is_archived: true })
    respond_to do |format|
      format.html { redirect_to ideas_url, notice: "#{@idea.name} was archived" }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_idea
    id = Slug[params[:id]]
    @idea = id ? Idea.find_by!(id: id) : Idea.find_by!(slug_name: params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to index_path
  end

  # Never trust parameters from the scary internet, only allow the white list
  def idea_params
    params
      .require(:idea).permit(:name, :description, :url, :is_archived, :all_categories)
      .tap do |p|
        p[:published_at] = Time.now if params[:commit] == "Publish"
      end
  end

  def ensure_idea_owner
    raise StandardError if @idea.user.id != current_user.id
  rescue StandardError
    flash[:warning] = "You are not authorized to perform this action"
    redirect_to @idea
  end
end
