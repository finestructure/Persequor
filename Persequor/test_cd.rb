
require 'test/unit'

framework 'Cocoa'


class TestCoreData < Test::Unit::TestCase

  def test_01_predicate
    predicate = NSPredicate.predicateWithFormat('user == "sas"')
    assert_not_nil(predicate)
    assert_equal('user == "sas"', predicate.predicateFormat)
    # test archiving
    data = NSKeyedArchiver.archivedDataWithRootObject(predicate)
    assert_not_nil(data)
    obj = NSKeyedUnarchiver.unarchiveObjectWithData(data)
    assert_not_nil(obj)
    assert_equal('user == "sas"', obj.predicateFormat)
  end


  def test_01_compound_predicate
    predicate = NSPredicate.predicateWithFormat(
      '(user == "sas") and (status != closed)'
    )
    assert_not_nil(predicate)
    assert_equal('user == "sas" AND status != closed', predicate.predicateFormat)
  end

end


