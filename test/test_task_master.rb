
$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'task_master'

class TestTaskMaster < Test::Unit::TestCase

  def setup
    TaskMaster.cookbook do
      task :one do
        puts 'one'
      end
      task :two do
        puts 'two'
      end
      task :three do
        puts 'three'
      end
    end
  end

  def test_class_methods
    assert TaskMaster.respond_to? :run
    assert TaskMaster.respond_to? :cookbook
  end

  def test_class_method_arity
    assert_nothing_raised {TaskMaster.run(:one)}
    assert_nothing_raised {TaskMaster.run(:one, :two)}
    assert_nothing_raised {TaskMaster.run([:one, :two, :three])}
  end

  def test_unknown_task
    assert_raise(TaskMaster::UnknownTask) {TaskMaster.run(:unknown_task)}
  end

end
