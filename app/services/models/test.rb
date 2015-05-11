#module M
#  def test
#    puts 123
#  end
#end
#
#class A
#  # Add class methods
#  extend M
#end
#
#class B
#  # Add instance methods
#  include M
#end

#module A
# def sets
#   puts 123
# end
#end
#
#class B
#
#end
#
#class C
#  def self.test
#    B.const_set(:D, Class.new{
#      include A
#    })
#  end
#end

#class Test
#  attr_accessor :field
#
#  def initialize
#    @field = 123
#  end
#end
#
#@test = Test.new
#
#Object.send(:remove_const, :Test)

#module A
#  def test
#    puts 123
#  end
#end
#
#module B
#  include A
#
#  def qwe
#    puts 234
#  end
#end
#
#module C
#  include B
#
#  def self.extended(base)
#    def asd
#      puts 345
#    end
#
#    instance_methods.each do |method_name|
#      private method_name
#    end
#  end
#end
#
#class D
#  extend C
#end