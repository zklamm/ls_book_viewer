require "tilt/erubis"
require "sinatra"
require "sinatra/reloader" if development?

def chapters_matching(query)
  results = []

  return results unless query

  each_chapter do |number, name, contents|
    matches = {}
    contents.split("\n\n").each_with_index do |paragraph, index|
      matches[index] = paragraph if paragraph.include?(query)
    end

    if matches.any?
      results << { number: number, name: name, paragraphs: matches }
    end
  end

  results
end

def each_chapter
  @contents.each_with_index do |name, index|
    number = index + 1
    contents = File.read("data/chp#{number}.txt")
    yield number, name, contents
  end
end

before do
  @contents = File.readlines("data/toc.txt")
end

helpers do
  def in_paragraphs(text)
    text = text.split("\n\n").map.with_index do |paragraph, index|
      "<p id='#{index + 1}'>#{paragraph}</p>"
    end

    text.join("\n\n")
  end

  def highlight(text, query)
    text.gsub(query, "<strong>#{query}</strong>")
  end
end

get "/" do
  @title = "The Adventures of Sherlock Holmes"

  erb :home
end

get "/chapters/:number" do
  number = params[:number].to_i
  chapter_name = @contents[number - 1]

  redirect '/' unless (1..@contents.size).cover? number

  @title = "Chapter #{number}: #{chapter_name}"
  @chapter = File.read("data/chp#{number}.txt")

  erb :chapter
end

get '/search' do
  @results = chapters_matching(params[:query])
  erb :search
end

not_found do
  redirect '/'
end
