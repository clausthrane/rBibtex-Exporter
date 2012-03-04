#!/usr/bin/ruby
# -*- coding: iso-8859-1 -*-
# ----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 42):
# <crt@cs.aau.dk> wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return Claus Thrane
# ----------------------------------------------------------------------------

# This is a dirt simple bibtex parser

require 'strscan'

class Lexer
  def feed(str)
    str.gsub!(/^%.*/,"") # remove comments
    str.gsub!(/[\x00-\x1f]/,"")
    str.strip!
    str.squeeze!(" ")
    @skip_whitespaces = false
    @scanner = StringScanner.new(str)
  end

  def next_token!(kind = /./)
    skip_whitespaces
    token = @scanner.scan(kind)
    return token if not token.nil?
    raise RuntimeError.new("Expected to match #{kind} to #{@scanner.rest[0..40]}")    
  end

  def peek_token
    tok = self.next_token!
    @scanner.unscan
    return tok
  end

  def more_tokens?
    not @scanner.eos?
  end

  def skip_whitespaces
     @scanner.skip /^\s*/ if @skip_whitespaces
  end

  def ignore_ws
    @skip_whitespaces = true
  end

  def observe_ws
    @skip_whitespaces = false
  end
end

class Parser
  @tokens = {:at => /@/, 
    :lbrace => /\{/, 
    :rbrace => /\}/, 
    :comma => /,/, 
    :word => /(\w|\-)*/,
    :id => /(\w|\/|\:|\-|\.)*/,
    :ass => /\=/, :quote => /\"/}
  @lexer = Lexer.new

  def self.parse(filename)
    parse_content(File.read(filename))    
  end

private

  def self.preprocess!(str)

    data = Hash.new

    str.scan(/^%%%\*.*/).each do |line|      
      properties = line.split('*')
      
      # add web info
      name = properties[1].strip
      web = properties[2].strip
      data[name] = [name, web]
      
      # add web info to aliases
      (properties.length-3).times do |i|        
        data[properties[i+3].strip] = [name, web]
      end
    end

    return data

  end

  def self.parse_content(str)

    ast = Array.new
    ast << preprocess!(str)
    ast << Array.new

    @lexer.feed(str)

    while @lexer.more_tokens?
      ast[1] << parse_entry
    end
    return ast
  end

  def self.parse_entry
    @lexer.ignore_ws
    entry = Array.new
    read(:at)
    type = read(:word)
    read(:lbrace)
    ref_id = read(:id)

    entry << [ref_id, type.downcase]
    entry << []
      
    if publication?(type)
      while next?(:comma)
        read :comma
        next if next?(:rbrace)
        ## stupid bibtex allows commas after last attribute!!
        key = read(:word)
        read(:ass)
        entry[1] << [key.downcase, read_string]
      end
    else
      read :ass      
      entry[1] << read_string
    end      
    
    read :rbrace
    return entry
  end

  def self.read_string    
   
    case @lexer.peek_token
   
    when @tokens[:lbrace] # it's a {...}
      str =""
      @lexer.observe_ws
      str = read_braced_string[1..-2]
      @lexer.ignore_ws
      return str
      
    when @tokens[:quote] # it's a "..."
      read(:quote)
      str = ""
      @lexer.observe_ws
      while(tok = @lexer.peek_token)
        case tok
        when /\\/ then str += fix_escaped_quote
        when @tokens[:quote] then break
        when @tokens[:lbrace] then str += read_braced_string
        else str += @lexer.next_token!
        end
      end
      @lexer.ignore_ws
      read(:quote)
      return str

    else # it's a simple word
      str = ""
      @lexer.observe_ws
      str = read(:word)
      @lexer.ignore_ws
      return str
    end
  end

  def self.fix_escaped_quote
    @lexer.next_token! # this must be a \
    if @lexer.peek_token =~ @tokens[:quote] then
    @lexer.next_token! # this must be a "
      return "\\\""
    end
    return "\\"
  end

  def self.read_braced_string
 #   @lexer.observe_ws
    depth = 0
    str = ""
    while(token = @lexer.next_token!)
      case token
      when @tokens[:lbrace]
        str += '{' 
        depth +=1
      when @tokens[:rbrace]
        depth -=1
        str += '}' 
      else
        str += token
      end
      break if 0 == depth
    end
#    @lexer.ignore_ws
    return str
  end

  def self.read(e)
    return @lexer.next_token!(@tokens[e])
  end

  def self.next?(e)
    return @lexer.peek_token =~ @tokens[e]
  end

  def self.publication?(type)
    ## should be improved ;)
    return !type.eql?("string")
  end
end



