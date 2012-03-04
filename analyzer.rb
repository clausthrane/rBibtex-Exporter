#!/usr/bin/ruby
# -*- coding: iso-8859-1 -*-
# ----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 42):
# <crt@cs.aau.dk> wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return Claus Thrane
# ----------------------------------------------------------------------------

# This (dirt simple) script which analyses the result of the
# bibtex_parser

require 'bibtex_parser'

class DsAnalyzer

  def self.find_duplicates(ast, sort = /./)
    
    list = []
    map = Hash.new
      ast.each do |entry|
      id, type = entry[0]
      if (type =~ sort and map.include?(id))
        list << entry
      else
        map[id] = true
      end      
    end

    return list
  end

  def self.remove_duplicates!(ast, sort = /^proceedings/)

    map = Hash.new

    ast.each do |entry|
      id, type = entry[0]
      if (type =~ sort and map.include?(id)) then
        ast.delete(entry)
        $stderr << id << " dublicate removed \n"
      elsif type =~ sort
        #        $stderr << id << " seen \n"
        map[id] = true
      end      
    end

    return ast
  end

  def self.has_duplicates?(ast)

    existing = Hash.new(false)
    ast.each do |entry|
      id, type = entry[0]
      return true if existing.include?(id)
      existing[id] = true
    end
    return false
  end

  def self.inline_proceedings!(ast)

    proceedings = Hash.new

    ast.each do |entry|
      id, type = entry[0]
      if type =~ /^proceedings/ then
        proceedings[id] = entry
        ast.delete(entry)
      end
    end

#    proceedings.each_key{ |k| $stderr << k << " found \n" if k.eql?("DBLP:conf/tacas/1995")}


    ast.each do |entry| 
      id, type = entry[0]
      data = entry[1]

      begin
        if type =~ /^inproceedings/ then
          
          booktitle_field = data.select { |k,v| k =~ /^booktitle/ }[0]
          crossref_field = data.select { |k,v| k =~ /^crossref/ }[0]
 
          if not crossref_field.nil? then 

            ref = crossref_field[1]
            proc = proceedings[ref]
            proc_data = proc[1]
            
            proc_title_field = proc_data.select { |k,v| k =~ /^title/ }[0]
            proc_booktitle_field = proc_data.select { |k,v| k =~ /^booktitle/ }[0]
            
            ## update inproc booktitle_field
            short_name = proc_booktitle_field[1]
            long_name = proc_title_field[1]
            new_name = "#{long_name} (#{short_name})"
            
            if not booktitle_field.nil? then
              booktitle_field[1] = new_name
            else
              data << ["booktitle", new_name]
            end
            data.delete(crossref_field)
          end # if


        end
#      rescue
#        raise RuntimeError.new("Analyser: faild inline for #{id}")
      end # try-catch end
    end

    return ast
  end

end



