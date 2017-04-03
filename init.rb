require_relative 'lib/books_wiki_link'

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

	desc "Issue Tree"
	macro :issue_tree do |obj, args|
		trackers = Tracker.where("name IN(?)", ["エピック", "ストーリー"]).select("id").all
		statuses = BooksWikiLinkHelper.wip_statuses
		issues = Issue.where("tracker_id IN(?) AND parent_id IS NULL AND status_id IN(?)", trackers, statuses).all

		html = ""
		recursive_do = lambda do |issues_|
			html += "<ul>\n"
			issues_.each do |issue|
				next unless statuses.any? {|v| v.id == issue.status.id }

				html += "<li>#{link_to_issue(issue)}\n"
				recursive_do.call(issue.children) unless issue.leaf?
				html += "</li>\n"
			end
			html += "</ul>\n"
		end
		recursive_do.call(issues)

		raw(html)
	end
end

module BooksWikiLinkPlugin
	class Hooks < Redmine::Hook::Listener
		def controller_issues_bulk_edit_before_save(context = {})
			IssueStatusFixer.fix_status(context[:issue])
		end

		def controller_issues_edit_before_save(context = {})
			IssueStatusFixer.fix_status(context[:issue])
		end

		def controller_agile_boards_update_before_save(context = {})
			IssueStatusFixer.fix_status(context[:issue])
		end
	end
end

