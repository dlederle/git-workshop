class Repository
  attr_accessor :owner, :branches, :commits, :working_directory, :name, :previous_commit_contents, :HEAD

  def initialize(name, owner)
    self.name = name
    self.owner = owner
    self.branches = {:master => nil}
    self.HEAD = :master
    self.commits = []

    self.working_directory = {
      :staged => [],
      :unstaged => [],
      :untracked => []
    }
  end

  def new_file(path, content)
    file = Git::File.new(path, content)
    untracked << file
    file
  end

  def add(*files)
    files.each do |file|
      untracked.delete file
      unstaged.delete file

      staged << file
    end
  end

  def commit(message)
    tracked_files = staged + unstaged
    contents = {}
    tracked_files.map do |file|
      contents[file.path] = file.content
    end

    self.previous_commit_contents = contents
    commit = Git::Commit.new(staged, message)
    commits << commit
    working_directory[:unstaged] = staged
    working_directory[:staged] = []
    commit.parents << branches[self.HEAD]
    branches[self.HEAD] = commit
    commit
  end

  def checkout(branch)
    self.HEAD = branch
  end

  def branch(name)
    branches[name.to_sym] = []
  end

  def status
    branch = "On branch #{self.HEAD.to_s}\n"

    changes = ''
    if modified_files.empty? and staged.empty?
      changes = "nothing to commit, working directory clean"
    else
      if modified_files.any?
        changes << "Changes not staged for commit:\n\t#{modified_files.map(&:path).join("\n\t")}"
      end
      if staged.any?
        changes << "Changes to be committed:\n\t#{working_directory[:staged].map(&:path).join("\n\t")}"
      end
    end

    branch + changes
  end

  def modified_files
    unstaged.select do |file|
      file.content != previous_commit_contents[file.path]
    end
  end

  def staged
    working_directory[:staged]
  end

  def unstaged
    working_directory[:unstaged]
  end

  def untracked
    working_directory[:untracked]
  end
end
