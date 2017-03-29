Redmine::Plugin.register :books_wiki_link do
  name 'Books Wiki Link plugin'
  author 'Author name'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'
end

Redmine::WikiFormatting::Macros.register do
	desc "Book link"
	macro :book do |obj, args|
		wiki = WikiPage.where("title = ?", args[0]).find {|page| page.project.identifier == "books" }
		title = wiki.title
		if wiki.text =~ /^h1\.(.*)$/o
			title = $1.strip
		end
		if wiki.attachments.empty? || args[1] != "t"
			link_to(title, wiki) + args[1]
		else
			thumbnail_tag(wiki.attachments.first) + ' ' + link_to(title, wiki)
		end
	end
end

