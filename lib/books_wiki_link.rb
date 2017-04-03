class BooksWikiLinkHelper
	def self.wip_statuses
		IssueStatus.where("name IN(?)", ["作業中", "常駐"]).select("id").all
	end

	def self.not_wip_statuses
		IssueStatus.where("name NOT IN(?)", ["作業中", "常駐"]).select("id").all
	end
end

class IssueStatusFixer
	def self.fix_status(issue)
		statuses = BooksWikiLinkHelper.wip_statuses
		if statuses.any? {|v| v.id == issue.status.id }
			# 作業中 -> 親を作業中に変更
			parent = issue.parent
			while parent do
				parent.status = issue.status
				parent.save!
				parent = parent.parent
			end
		else
			# 作業でない -> 子ノードで作業中のものを同じステータスに変更
			recursive_do = lambda do |issues_|
				issues_.each do |issue_|
					next unless statuses.any? {|v| v.id == issue_.status.id }

					issue_.status = issue.status
					issue_.save!

					recursive_do.call(issue_.children) unless issue_.leaf?
				end
			end
			recursive_do.call(issue.children)
		end
	end
end

if __FILE__ == $0
	wip_statuses = BooksWikiLinkHelper.wip_statuses
	not_wip_statuses = BooksWikiLinkHelper.not_wip_statuses

	issue = Issue.where('parent_id is null').first.children[0].children[0]
	issue.status = IssueStatus.find(wip_statuses[0].id)
	issue.save!
	issue.parent.status = IssueStatus.find(not_wip_statuses[0].id)
	issue.parent.save!

	puts issue.status.name
	puts issue.parent.status.name

	IssueStatusFixer.fix_status(issue)
	# IssueStatusFixer.fix_status(issue.parent)

	issue = Issue.where('parent_id is null').first.children[0].children[0]
	puts issue.status.name
	puts issue.parent.status.name
end

