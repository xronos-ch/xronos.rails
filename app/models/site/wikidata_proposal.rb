# frozen_string_literal: true

class Site
  # Records and reviews candidate Wikidata links for sites.
  class WikidataProposal
    KIND = 'wikidata_link'
    TARGET_KEY = /\AQ[1-9][0-9]*\z/

    class NoLongerApplicable < StandardError; end

    def self.for_review
      proposals.where(subject_id: Site.missing_wikidata_link.select(:id))
               .joins('INNER JOIN sites ON sites.id = curation_proposals.subject_id')
               .where("curation_proposals.evidence->>'site_name' = sites.name")
    end

    def self.record_matches(original, candidates)
      Site.transaction do
        site = Site.lock.find_by(id: original.id)
        next unless site && site.name == original.name && site.missing_wikidata_link?

        candidates.each { |candidate| record_match(site, candidate) }
      end
    end

    def self.accept!(id)
      subject_id = proposals.find(id).subject_id
      Site.transaction do
        site = Site.lock.find(subject_id)
        proposal = proposals.where(subject: site).lock.find(id)
        promote!(site, proposal)
      end
    end

    def self.record_match(site, candidate)
      return unless candidate.qid&.match?(TARGET_KEY)

      proposal = site.curation_proposals.find_or_initialize_by(kind: KIND, target_key: candidate.qid)
      proposal.update!(evidence: { site_name: site.name, label: candidate.label, description: candidate.description })
    end

    def self.promote!(site, proposal)
      raise NoLongerApplicable unless applicable?(site, proposal)

      link = site.linked_resources.create!(source: 'Wikidata', external_id: proposal.target_key, status: 'approved',
                                           data: proposal.evidence.slice('label', 'description'))
      proposals.where(subject: site).delete_all
      link
    end

    def self.applicable?(site, proposal)
      site.missing_wikidata_link? && site.name == proposal.evidence['site_name'] &&
        proposal.target_key.match?(TARGET_KEY)
    end

    def self.proposals
      CurationProposal.where(kind: KIND, subject_type: 'Site')
    end
    private_class_method :record_match, :promote!, :applicable?, :proposals
  end
end
