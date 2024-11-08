# name: random-group-assignment
# about: 随机将新用户分配到指定组
# version: 0.1
# authors: YourName

after_initialize do
  module ::RandomGroupAssignment
    MAX_RETRY_ATTEMPTS = 3  
    RETRY_DELAY = 1         

    def self.assign_user_to_random_group(user)
      group_names = ["Red-Hat-Hacker", "Green-Hat-Hacker", "Black-Hat-Hacker", "Blue-Hat-Hacker", "White-Hat-Hacker", "Gray-Hat-Hacker"] # 替换为你实际的组名
      assigned = false
      retry_attempts = 0
      
      while !assigned && retry_attempts < MAX_RETRY_ATTEMPTS
        begin
          random_group_name = group_names.sample
          group = Group.find_by(name: random_group_name)
          
          if group && !user.groups.include?(group)
            user.groups << group
            user.save
            assigned = true 
          end
        rescue ActiveRecord::RecordNotFound => e
          retry_attempts += 1
          Rails.logger.warn "Group '#{random_group_name}' not found. Retrying (attempt #{retry_attempts} of #{MAX_RETRY_ATTEMPTS})."
          sleep RETRY_DELAY  
        end
      end

      if !assigned
        Rails.logger.error "Failed to assign user to any existing group after #{MAX_RETRY_ATTEMPTS} attempts."
       
      end
    end
  end

  require_dependency 'user'
  class ::User
    after_create_commit do
      RandomGroupAssignment.assign_user_to_random_group(self)
    end
  end
end
