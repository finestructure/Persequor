#
#  PriorityColorValueTransformer.rb
#  Persequor
#
#  Created by Sven A. Schmidt on 20.10.11.
#  Copyright 2011 abstracture GmbH & Co. KG. All rights reserved.
#


class PriorityColorValueTransformer < NSValueTransformer

  def self.transformValueClass
    return NSColor.class
  end


  def transformedValue(value)
    case value
    when "blocker"
      return NSColor.redColor
    when "critical"
      return NSColor.orangeColor
    when "minor"
      return NSColor.darkGrayColor
    when "trivial"
      return NSColor.lightGrayColor
    else
      return NSColor.blackColor
    end
  end
  
end