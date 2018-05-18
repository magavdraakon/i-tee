class RedeemsController < ApplicationController

  respond_to :html

  def new
    @tab = "courses"
  end

  def create
    redeemcode = params[:coupon]

    respond_to do |format|
      begin
        coupon = Coupon.where(redeemcode: redeemcode).first
        user_id = current_user.id
        lab_id = coupon.lab.id

        if coupon.present?
          if coupon.redeemable?
            if coupon.no_present_access?(current_user)
            	unless Redeem.where(user_id: user_id, coupon_id: coupon.id).present?

              		# Attach lab access to student account
              		@lab_user = LabUser.new
              		@lab_user.user_id = user_id
              		@lab_user.lab_id = lab_id
              		@lab_user.coupon_id = coupon.id

                  # Add new redemption
              		if @lab_user.save
                	@redeem = current_user.redeems.new
                	@redeem.user_id = user_id
                	@redeem.coupon_id = coupon.id
                	@redeem.save!
                
                	format.html { redirect_to(my_labs_path, :notice => "Lab successfully added!") }
                	format.json { render :json=> {:success => true}.merge(@lab_user.as_json), :status=> :created}
              		else
                		format.html { redirect_to(redeem_coupon_path, :notice => 'Could not create new Lab User.') }
              		end
              	else
              		format.html { redirect_to(redeem_coupon_path, :notice => 'You have already used this coupon code!') }
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
      rescue StandardError
      	# Most likely lab has been deleted, therefore can not add new labuser
      	format.html { redirect_to(redeem_coupon_path, :notice => "This coupon could not be redeemed. Please contact I-Tee staff") }
      end
    end
  end

  private
    def set_redeem
      @redeem = Redeem.find(params[:id])
    end
end
