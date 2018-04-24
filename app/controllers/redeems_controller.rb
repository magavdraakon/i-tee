class RedeemsController < ApplicationController

  respond_to :html

  def new
    @tab = "courses"
  end

  def create
    redeemcode = params[:coupon]

    respond_to do |format|
        coupon = Coupon.where(redeemcode: redeemcode).first
        if coupon.present?
          if coupon.redeemable?
            if coupon.no_present_access?(current_user)
              # Gather information needed to create labuser instance
              user_id = current_user.id
              lab_id = coupon.lab.id
              date = Time.now
              retention_time = date + (coupon.retention.to_int).days

              # Attach lab access to student account
              @lab_user = LabUser.new
              @lab_user.user_id = user_id
              @lab_user.lab_id = lab_id
              @lab_user.coupon_id = coupon.id
              @lab_user.retention_time = retention_time

              if @lab_user.save
                format.html { redirect_to(my_labs_path, :notice => "Lab successfully added!") }
                format.json { render :json=> {:success => true}.merge(@lab_user.as_json), :status=> :created}
              else
                format.html { redirect_to(redeem_coupon_path, :notice => 'Could not create new Lab User.') }
              end
            else
              format.html { redirect_to(redeem_coupon_path, :notice => 'You already have an access to this lab!') }
            end
          else
            format.html { redirect_to(redeem_coupon_path, :notice => 'This redeem code is either expired or not activated yet.') }
          end
        else
          format.html { redirect_to(redeem_coupon_path, :notice => "This redeem code is not registered in our system.") }
        end
    end
  end

  # 
  #before_filter :set_redeem, only: [:show, :edit, :update, :destroy]

  #def index
  #  @redeems = Redeem.all
  #  respond_with(@redeems)
  #end

  #def show
  #  respond_with(@redeem)
  #end

  #def edit
  #end

  #def update
  #  @redeem.update_attributes(params[:redeem])
  #  respond_with(@redeem)
  #end

  #def destroy
  #  @redeem.destroy
  #  respond_with(@redeem)
  #end

  private
    def set_redeem
      @redeem = Redeem.find(params[:id])
    end
end
