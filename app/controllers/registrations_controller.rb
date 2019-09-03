class RegistrationsController < Devise::RegistrationsController

  def create
   ## To build the resource
   build_resource(sign_up_params)
   ## Verifying Captcha
   if verify_recaptcha(model: resource)
     super
   else
     render 'new'
   end
 end

end
