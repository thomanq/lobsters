class InvitationMailer < ActionMailer::Base
  default :from => "#{Rails.application.name} <nobody@#{Rails.application.domain}>"

  def invitation(invitation)
    @invitation = invitation

    mail(
      :to => invitation.email,
      subject: "[#{Rails.application.name}] " + t("YouHaveBeenInvitedToApplicationName", :application_name => Rails.application.name)
    )
  end
end
