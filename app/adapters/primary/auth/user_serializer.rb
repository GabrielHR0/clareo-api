module Auth
  class UserSerializer
    def self.call(user)
      {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role
      }
    end
  end
end
