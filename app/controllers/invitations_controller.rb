class InvitationsController < ApplicationController
  before_action :require_logged_in_user, :except => [:build, :create_by_request, :confirm_email]

  def build
    if Rails.application.allow_invitation_requests?
      @invitation_request = InvitationRequest.new
    else
      flash[:error] = t("PublicInvitationRequestsAreNotAllowed")
      return redirect_to "/login"
    end
  end

  def index
    if !@user.can_see_invitation_requests?
      flash[:error] = "Your account is not permitted to view invitation requests."
      return redirect_to "/"
    end

    @invitation_requests = InvitationRequest.where(:is_verified => true)
  end

  def confirm_email
    if !(ir = InvitationRequest.where(:code => params[:code].to_s).first)
      flash[:error] = t("InvalidOrExpiredInvitationRequest")
      return redirect_to "/invitations/request"
    end

    ir.is_verified = true
    ir.save!

    flash[:success] = t("InvitationRequestValidatedNowShownToOtherUsers")
    return redirect_to "/invitations/request"
  end

  def create
    if !@user.can_invite?
      flash[:error] = "Your account cannot send invitations"
      redirect_to "/settings"
      return
    end

    i = Invitation.new
    i.user_id = @user.id
    i.email = params[:email]
    i.memo = params[:memo]

    begin
      i.save!
      i.send_email
      flash[:success] = t("SuccessfullyEmailedInvitationToEmailAddress", :emailaddress => params[:email].to_s) 
    rescue
      flash[:error] = t("CouldNotSendInvitationVerifyEmailAddress")
    end

    if params[:return_home]
      return redirect_to "/"
    else
      return redirect_to "/settings"
    end
  end

  def create_by_request
    if Rails.application.allow_invitation_requests?
      @invitation_request = InvitationRequest.new(
        params.require(:invitation_request).permit(:name, :email, :memo))

      @invitation_request.ip_address = request.remote_ip

      if @invitation_request.save
        flash[:success] = t("YouHaveBeenEmailedConfirmationToEmailAddress", :emailaddress => params[:invitation_request][:email].to_s)
        return redirect_to "/invitations/request"
      else
        render :action => :build
      end
    else
      return redirect_to "/login"
    end
  end

  def send_for_request
    if !@user.can_see_invitation_requests?
      flash[:error] = "Your account is not permitted to view invitation " <<
                      "requests."
      return redirect_to "/"
    end

    if !(ir = InvitationRequest.where(:code => params[:code].to_s).first)
      flash[:error] = t("InvalidOrExpiredInvitationRequest")
      return redirect_to "/invitations"
    end

    i = Invitation.new
    i.user_id = @user.id
    i.email = ir.email
    i.save!
    i.send_email
    ir.destroy!
    flash[:success] = t("SuccessfullyEmailedInvitationToName", :name => ir.name.to_s)

    Rails.logger.info "[u#{@user.id}] sent invitiation for request " <<
                      ir.inspect

    return redirect_to "/invitations"
  end

  def delete_request
    if !@user.can_see_invitation_requests?
      return redirect_to "/invitations"
    end

    if !(ir = InvitationRequest.where(:code => params[:code].to_s).first)
      flash[:error] = t("InvalidOrExpiredInvitationRequest")
      return redirect_to "/invitations"
    end

    ir.destroy!
    flash[:success] = t("SuccessfullyDeletedInvitationRequestFromName",  :name => ir.name.to_s)

    Rails.logger.info "[u#{@user.id}] deleted invitation request " <<
                      "from #{ir.inspect}"

    return redirect_to "/invitations"
  end
end
