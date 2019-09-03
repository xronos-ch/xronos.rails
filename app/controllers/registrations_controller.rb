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

 def sign_up_params
   params.require(:user).permit(:passphrase, :email, :password, :password_confirmation)
 end

end
