
# master your tasks!
#
#    TaskMaster.cookbook do
#      task :hi, :wave do
#        puts 'say hi'
#      end
#      task :wave do
#        puts 'waves'
#      end
#    end
#    
#    TaskMaster.run(:hi)
#
class TaskMaster
  # Error raised when task has not been defined
  class UnknownTask < StandardError; end
  # Error raised when task depends on an ancestor
  class CircularDependency < StandardError; end

  Task = Struct.new(:name, :dependencies, :block)
  # all tasks in the cookbook
  @@defined_tasks = Array.new
  # all tasks that have already been executed, within a top_level_task
  @@completed_tasks = Array.new
  # current list of tasks, used to (mostly) prevent circular dependency
  @@run_queue = Array.new
  # indent level
  @@indent = Array.new

  # used to call one or more top_level_tasks
  def self.run(*args)
    puts "\nTaskMaster.run was called with: #{args.join(' ')}\n==================================="

    # log file. overritten each time TaskMaster.run() is called
    @@log = File.open('taskmaster_log.txt', 'w+')

    # each arg to run() is a top level task
    top_level_task_names = args.to_a.flatten

    # store all tasks, spanning top_level_tasks
    all_completed_tasks = Array.new

    top_level_task_names.each do |task_name|
      task = task_from_name( task_name )

      run_task( task )

      # housekeeping
      all_completed_tasks += @@completed_tasks
      @@completed_tasks.clear
      @@run_queue.clear
    end
    all_completed_tasks
  end

  # recursive method that evaluates dependencies, updates variables and calls task's method
  def self.run_task( task, task_type=nil )
    @@run_queue << task.name unless task_type == 'dependent '

    if @@completed_tasks.include? task.name
      log "skipping completed #{task.name.upcase}"
    else
      log "executing #{task_type}#{task.name.upcase}"
    end

    if task.dependencies
      task.dependencies.each do |dep_task|

        if @@run_queue.include? dep_task.to_s
          raise CircularDependency, "Task #{dep_task} contains a circular dependency on #{task.name}"
        end

        @@indent.push "\t"
        
        # recurse
        run_task( task_from_name(dep_task), 'dependent ' )
        @@indent.pop

      end
    end

    # call the task's method
    self.class.send(task.name.to_sym)

    @@completed_tasks << task.name
  end

  # returns a task with name attribute
  def self.task_from_name(task_name)
    task = @@defined_tasks.select{|t| t.name == task_name.to_s}.first
    raise UnknownTask, "Unknown task: #{task_name}" if task.nil?
    task
  end
  
  # accepts a block of code that defines tasks
  def self.cookbook( &block )
    instance_eval &block
  end

  # used to create methods / define tasks parsed from a cookbook block
  def self.task( name, *dependencies, &block )
    dependencies ||= []
    task = Task.new(name.to_s, dependencies)
    @@defined_tasks.push task

    self.class.send(:define_method, name.to_sym, &block)

    raise RuntimeError, "Failed to define #{name} method" unless self.respond_to? name.to_sym
  end

  # outputs to the screen and a file
  def self.log(str)
    @@log << @@indent.join + '** ' + str
    puts @@indent.join + '** ' + str
    @@log.flush
  end

end
