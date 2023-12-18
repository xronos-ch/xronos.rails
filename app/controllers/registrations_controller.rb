class RegistrationsController < Devise::RegistrationsController

  def create
    build_resource(sign_up_params)
    render "new"
  end

  def sign_up_params
    params.require(:user).permit(
      :passphrase, 
      :email, 
      :password, 
      :password_confirmation
    )
  end

end
