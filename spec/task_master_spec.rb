require 'task_master'
require 'fileutils'

def log_contents
  File.open('taskmaster_log.txt').readlines.join rescue ''
end

def log_delete
  FileUtils.rm 'taskmaster_log.txt' rescue nil
end

describe "TaskMaster Simple Tasks" do
  before(:all) do
    TaskMaster.cookbook do
      task :task1 do
        puts 'task1'
      end
      task :task2 do
        puts 'task2'
      end
    end
  end

  before(:each) do
    log_delete
  end

  it "should run task1 without exception" do
    lambda {TaskMaster.run(:task1)}.should_not raise_error
  end

  it "should return an array of 1 task name" do
    result = TaskMaster.run(:task1)
    result.should be_kind_of Enumerable
    result.should have(1).item
  end

  it "should run task1" do
    TaskMaster.run(:task1)
    log_contents.should match( /executing TASK1/)
    log_contents.should_not match( /executing TASK2/)
  end

  it "should run multiple tasks" do
    TaskMaster.run(:task1, :task2)
    log_contents.should match( /executing TASK1.+executing TASK2/m)
  end

  it "should run duplicate top level tasks" do
    TaskMaster.run(:task1, :task1)
    log_contents.should match( /executing TASK1.+executing TASK1/m)
  end

  it "should run top level tasks in specified order" do
    TaskMaster.run(:task2, :task1)
    log_contents.should match( /executing TASK2.+executing TASK1/m)
  end

end


describe "TaskMaster Dependent Tasks" do
  before(:all) do
    TaskMaster.cookbook do

      # task A - two dependent tasks
      task :taskA, :taskB, :taskC do
        puts 'task a'
      end
      task :taskB do
        puts 'task b'
      end
      task :taskC do
        puts 'task c'
      end

      # task D - two levels of dependent tasks
      task :taskD, :taskE do
        puts 'task d'
      end
      task :taskE, :taskF do
        puts 'task e'
      end
      task :taskF do
        puts 'task f'
      end

      # task G - duplicate dependent task
      task :taskG, :taskH, :taskI do
        puts 'task g'
      end
      task :taskH, :taskI do
        puts 'task h'
      end
      task :taskI do
        puts 'task i'
      end

      # task J - circular dependent task
      task :taskJ, :taskK do
        puts 'task j'
      end
      task :taskK, :taskJ do
        puts 'task k'
      end
    end
  end

  before(:each) do
    log_delete
  end

  it "should run dependent tasks" do
    log_contents.should_not match( /task/ )
    TaskMaster.run(:taskA)
    log_contents.should match( /executing TASKA.+executing dependent TASKB/m)
  end

  it "should run multiple dependent tasks" do
    log_contents.should_not match( /task/ )
    TaskMaster.run(:taskA)
    log_contents.should match( /executing TASKA.+executing dependent TASKB.+executing dependent TASKC/m)
  end

  it "should run multiple levels of dependent tasks" do
    log_contents.should_not match( /task/ )
    TaskMaster.run(:taskD)
    log_contents.should match( /executing TASKD.+executing dependent TASKE.+executing dependent TASKF/m)
  end

  it "should skip completed tasks" do
    log_contents.should_not match( /task/ )
    TaskMaster.run(:taskG)
    log_contents.should match( /skipping completed TASKI/m)
  end

  it "should return an array of all task names that were completed or skipped" do
    result = TaskMaster.run(:taskD, :taskG)
    result.should have(7).items
    result[2].should == 'taskD'
  end

  it "should error on circular dependency" do
    log_contents.should_not match( /task/ )
    lambda{TaskMaster.run(:taskJ)}.should raise_error(TaskMaster::CircularDependency)
  end
end
