class UserBadgesController < ApplicationController
  before_action :authorise_as_admin
  before_action :admin_tab
  before_action :set_user_badge, :only=>[:show, :edit, :update, :destroy]

  # GET /user_badges
  # GET /user_badges.json
  def index
    @user_badges = UserBadge.all
    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @user_badges }
    end
  end

  # GET /user_badges/1
  # GET /user_badges/1.json
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @user_badge }
    end
  end

  # GET /user_badges/new
  # GET /user_badges/new.json
  def new
    @user_badge = UserBadge.new
    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @user_badge }
    end
  end

  # GET /user_badges/1/edit
  def edit
  end

  # POST /user_badges
  # POST /user_badges.json
  def create
    @user_badge = UserBadge.new(user_badge_params)
    respond_to do |format|
      if @user_badge.save
        format.html { redirect_to @user_badge, :notice => 'User badge was successfully created.' }
        format.json { render :json => @user_badge, :status => :created, :location => @user_badge }
      else
        format.html { render :action => 'new' }
        format.json { render :json => @user_badge.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /user_badges/1
  # PUT /user_badges/1.json
  def update
    respond_to do |format|
      if @user_badge.update_attributes(user_badge_params)
        format.html { redirect_to @user_badge, :notice => 'User badge was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render :action => 'edit' }
        format.json { render :json => @user_badge.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /user_badges/1
  # DELETE /user_badges/1.json
  def destroy
    @user_badge.destroy
    respond_to do |format|
      format.html { redirect_to user_badges_url }
      format.json { head :ok }
    end
  end

private # -------------------------------------------------------
  def set_user_badge
    @user_badge = UserBadge.where(id: params[:id]).first
    unless @user_badge
      redirect_to(user_badges_path,:notice=>'invalid id.')
    end
  end

  def user_badge_params
    params.require(:user_badge).permit(:id, :user_id, :lab_badge_id)
  end

end
