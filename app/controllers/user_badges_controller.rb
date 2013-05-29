class UserBadgesController < ApplicationController
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
    @user_badge = UserBadge.find(params[:id])

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
    @user_badge = UserBadge.find(params[:id])
  end

  # POST /user_badges
  # POST /user_badges.json
  def create
    @user_badge = UserBadge.new(params[:user_badge])

    respond_to do |format|
      if @user_badge.save
        format.html { redirect_to @user_badge, :notice => 'User badge was successfully created.' }
        format.json { render :json => @user_badge, :status => :created, :location => @user_badge }
      else
        format.html { render :action => "new" }
        format.json { render :json => @user_badge.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /user_badges/1
  # PUT /user_badges/1.json
  def update
    @user_badge = UserBadge.find(params[:id])

    respond_to do |format|
      if @user_badge.update_attributes(params[:user_badge])
        format.html { redirect_to @user_badge, :notice => 'User badge was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @user_badge.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /user_badges/1
  # DELETE /user_badges/1.json
  def destroy
    @user_badge = UserBadge.find(params[:id])
    @user_badge.destroy

    respond_to do |format|
      format.html { redirect_to user_badges_url }
      format.json { head :ok }
    end
  end
end
