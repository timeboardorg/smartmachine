require "test_helper"

class SmartMachineTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::SmartMachine.version
  end

  # def test_docker_install
  # 	assert_equal "Hello World",
  # 		SmartMachine::Docker.new.install
  # end
end
