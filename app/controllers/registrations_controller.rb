class RegistrationsController < Devise::RegistrationsController

  def create
  end

  def sign_up_params
    params.require(:user).permit(:passphrase, :email, :password, :password_confirmation)
  end

end
