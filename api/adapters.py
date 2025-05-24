from allauth.account.adapter import DefaultAccountAdapter
from .tasks import send_email_async

class AsyncAccountAdapter(DefaultAccountAdapter):
    def send_mail(self, template_prefix, email, context):
        msg = self.render_mail(template_prefix, email, context)
        send_email_async.delay(msg.subject, msg.body, msg.from_email, [email])
