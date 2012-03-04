#!/usr/bin/ruby
# -*- coding: iso-8859-1 -*-
# ----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 42):
# <crt@cs.aau.dk> wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return Claus Thrane
# ----------------------------------------------------------------------------

# This is a dirt simple XML writer


class XmlWriter

  def self.scope(str, param="")
    open(str, param)
    yield 
    close(str)
  end
  
  def self.w(str)
    @out << "#{str}"
  end
  
  def self.open(str, param="")
    param = "\s #{param}" if not param.eql?("") 
    w("<#{str}#{param}>")
  end

  def self.close(str)
    w("</#{str}>")
  end

  def self.tag(str, param="")
    param = "\s #{param}" if not param.eql?("") 
    w("<#{str}#{param}/>")
  end

  def self.encode(str)
    @substitution.each{ |exp, correction| str.gsub!(exp, correction) }
    return CGI::escapeHTML(str)
  end
end
