#!/usr/bin/ruby
# -*- coding: iso-8859-1 -*-
# ----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 42):
# <crt@cs.aau.dk> wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return Claus Thrane
# ----------------------------------------------------------------------------

# This is a (dirt simple) bibtex to word bibliography converter

require 'bibtex_parser' 
require 'analyzer'
require 'dsxml'
require 'cgi'

class DsBib2Word < XmlWriter

    AND = " and "
    SPACE = " "

  def self.write(input, replace = [], o = $stdout)

    @out = o
    @substitution = replace
  
    # begin
    w("<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>")
    scope("b:Sources", "SelectedStyle=\"\" xmlns:b=\"http://schemas.openxmlformats.org/officeDocument/2006/bibliography\" xmlns=\"schemas.openxmlformats.org/officeDocument/2006/bibliography\"") do

      input[1].each do |entry|
        scope("b:Source") do  id, type = entry[0]
          scope("b:Tag") { w(id) }
          scope("b:SourceType") {  w(@w[type] ||= type) }

          entry[1].each do |key, value|
            word_key = @w[key]
            if(not authors(key, value)) and not word_key.nil? then
              scope("b:#{word_key}") {  w(encode(value)) }
            end            
          end

        end #source
      end 

    end #b:Sources      

  end


  ## word need special listing of authors
  def self.authors(key, value)
    return false if not key.eql?("author")
    
    scope("b:Author") do
      scope("b:Author") do
        scope("b:NameList") do
          value.split(AND).each do |author|
            scope("b:Person") do
              names = author.split(SPACE)
              scope("b:Last") {w encode(names[-1])}
              scope("b:First") {w encode(names[0])}
              scope("b:Middle") {w encode(names[1])} if names.size > 2
            end
          end
        end       
      end
    end

    return true
  end
  


  # from:
  # http://mahbub.wordpress.com/2007/03/24/details-of-microsoft-office-2007-bibliographic-format-compared-to-bibtex/
  @w ={
    "author" => "Author",
    "book" => "Book",
    "inbook" => "BookSection",
    "booklet" => "BookSection, field BibTex_Entry=booklet",
    "incollection" => "BookSection, field BibTex_Entry=incollection",
    "article" => "JournalArticle",
    "inproceedings" => "ConferenceProceedings",
    "conference" => "ConferenceProceedings, field BibTex_Entry=conference",
    "proceedings" => "ConferenceProceedings, field BibTex_Entry=proceedings", 
    "collection" => "ConferenceProceedings, field BibTex_Entry=collection", 
    "techreport" => "Report",
    "manual" => "Report, field BibTex_Entry=manual",
    #misc, field msbib-source=InternetSite => "InternetSite",
    #misc, field msbib-source=DocumentFromInternetSite =>"DocumentFromInternetSite", 
    #misc, field msbib-source=ElectronicSource  => ElectronicSource,
    #misc, field msbib-source=Art => Art,
    #misc, field msbib-source=SoundRecording => SoundRecording,
    #:misc, field msbib-source=Performance => Performance,
    #:misc, field msbib-source=Film => Film,
    #:misc, field msbib-source=Interview => Interview,
    "patent" => "Patent",
    #:misc, field msbib-source=Case => Case,
    "mastersthesis" => "Report",
#    "mastersthesis" => "Report, field BibTex_Entry=mastersthesis",
    "phdthesis" => "Report",
#    "phdthesis" => "Report, field BibTex_Entry=phdthesis",
    "unpublished" => "Report", 
#    "unpublished" => "Report, field BibTex_Entry=unpublished", 
    "misc" => "Misc",
    "language" => "LCID", 
    "title" => "Title", 	
    "year"  => "Year", 	
    "msbib-shorttitle" => "ShortTitle", 
    "annote" => "Comments", 	 
    "note" => "Comments", 	
    "pages" => "Pages", 	
    "volume" => "Volume", 	
    "msbib-numberofvolume" => "NumberVolumes", 		
    "edition" => "Edition", 	
    "ISBN" => "StandardNumber", 	
    "ISSN" => "StandardNumber",
    "LCCN" =>  "StandardNumber",	 
    "mrnumber" => "StandardNumber",	
    "publisher" =>  "Publisher", 	
    "address" => "City",
    "location" => "City, StateProvince, CountryRegion",	
#    "booktitle" => "BookTitle",
    "booktitle" => "ConferenceName",   ### books have titles but, inproceedings have booktitles?
    "chapter" => "ChapterNumber", 	
    "journal" => "JournalName", 	
    "number" => "Issue", 
    "month" => "Month", 		 
    "msbib-day" => "Day", 		
    "organization" => "PeriodicalTitle", 	
    "organization" => "ConferenceName", 	 
    "school" =>	 "Department",
    "institution" => "Institution", 	
    "type" => "ThesisType", 	
    "URL" => "URL", 		 
    "msbib-productioncompany" => "ProductionCompany", 	
#    "title" => "PublicationTitle", 	
    "msbib-medium" => "Medium", 	
#    "title" => "AlbumTitle", 	
    "msbib-recordingnumber" => "RecordingNumber", 	
    "series" => "BibTex_Series",
    "abstract" => "BibTex_Abstract", 
    "keywords" => "BibTex_KeyWords", 	
    "crossref" => "BibTex_CrossRef",
    "howpublished" => "BibTex_HowPublished", 	 
    "affiliation" => "BibTex_Affiliation", 	
    "contents" 	=> "BibTex_Contents",
    "copyright" => "BibTex_Copyright" 	 
  }


end


ARGV.each do |file|

  replace = [[/\{|\}/,""],
             [/\\v/,""],
             [/\\tt/,""],
             [/\~/," "],
             [/\$\\sim\$/,"~"],
             [/\\o/, "ø"],
             [/\\/,""],
             [/\"e/, "ë"],
             [/\\i/,"í"],
             [/\'o/,"ó"],
             [/\\v\s*r/,"r"],
             [/\"a/,"ä"],
             [/\"o/,"ö"],
             [/\"u/,"ü"],
             [/\'/,""]
            ]

  $stderr << "Running b2word \n"

  $stderr << "Parsing bib\n"
  ast = Parser.parse(file)

  $stderr << "Removing dups and inline\n"
  DsAnalyzer.remove_duplicates!(ast)
  DsAnalyzer.inline_proceedings!(ast)

  $stderr << "Generating.. \n"
  DsBib2Word.write(ast,replace)
  
  # add paramter if you want file output instead of stdio
  # xml = File.new("#{file}.xml", File::CREAT|File::TRUNC|File::RDWR, 0644)

end
