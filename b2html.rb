#!/usr/bin/ruby
# -*- coding: iso-8859-1 -*-
# ----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 42):
# <crt@cs.aau.dk> wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return Claus Thrane
# ----------------------------------------------------------------------------

# This is a dirt simple bibtex to HTML with links converter

require 'bibtex_parser' 
require 'analyzer'
require 'dsxml'

class DsBib2Html < XmlWriter

  # write html line
  def self.wl(str)
    w(str)
    w("<br/>")
  end

  def self.write(input,  o = $stdout)

    @ast = input
    @out = o

    # begin

    
    tag("!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\"")
    scope("html", "xmlns=\"http://www.w3.org/1999/xhtml") do
      scope("head")do
        tag("meta", "http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\"")
        tag("meta", "name=\"robots\" content=\"index, follow\"")
        tag("meta", "name=\"keywords\" content=\"Publications, bibtex Dept.Computer Science, AAU.\"")
        tag("meta", "name=\"description\" content=\"publications list\"")
      end
      scope("body")do

        input[1].each do |entry|
          id, type = entry[0]
          tag("a name=\"#{id}\"")
          wl("@#{type}{#{id},")
          
          entry[1].each do |key, value|
            w("\ #{key}\t=")
            wl("{#{value}},")
          end

          wl("}")
          wl("")
        end        
      end # body
    end # html
    
  end
end

ARGV.each do |file|


  ast = Parser.parse(file)
  DsAnalyzer.remove_duplicates!(ast)
  DsBib2Html.write(ast)
  #   html = File.new("#{file}.html", File::CREAT|File::TRUNC|File::RDWR, 0644)
  # add to paramert list to avoid stdout output

end
