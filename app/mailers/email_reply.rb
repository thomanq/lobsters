class EmailReply < ActionMailer::Base
  default :from => "#{Rails.application.name} <nobody@#{Rails.application.domain}>"

  def reply(comment, user)
    @comment = comment
    @user = user

    mail(
      :to => user.email,
      :subject => "[#{Rails.application.name}] " + t("ReplyFromUserOnStoryTitle", :user => comment.user.username,
                                                                                  :story_title => comment.story.title)
    )
  end

  def mention(comment, user)
    @comment = comment
    @user = user

    mail(
      :to => user.email,
      :subject => "[#{Rails.application.name}] " + t("MentionFromUserOnStoryTitle", :user => comment.user.username,
                                                                                    :story_title => comment.story.title)
    )
  end
end
