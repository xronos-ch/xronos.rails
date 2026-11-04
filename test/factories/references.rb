# == Schema Information
#
# Table name: references
# Database name: primary
#
#  id         :bigint           not null, primary key
#  csl        :jsonb
#  doi        :string
#  searchable :tsvector
#  short_ref  :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_references_on_doi         (doi)
#  index_references_on_searchable  (searchable) USING gin
#  index_references_on_short_ref   (short_ref)
#
FactoryBot.define do
  factory :reference do
    short_ref { Faker::Name.last_name + Faker::Number.between(from: 1900, to: 2020).to_s }

    csl do
      [{
        "id" => "ref-#{short_ref}",
        "type" => "article-journal",
        "author" => [{ "family" => Faker::Name.last_name, "given" => Faker::Name.first_name }],
        "title" => Faker::Book.title,
        "container-title" => "Journal of Archaeological Science",
        "volume" => Faker::Number.between(from: 1, to: 60).to_s,
        "page" => "123-145",
        "issued" => { "date-parts" => [[Faker::Number.between(from: 1900, to: 2020)]] },
        "DOI" => "10.1000/#{Faker::Number.number(digits: 6)}"
      }]
    end

    # Mirrors the fallback item produced by the backfill migration for
    # references without any bibliographic data
    trait :without_csl do
      csl { [{ "id" => "ref-#{short_ref}", "type" => "misc", "title" => short_ref }] }
    end

    trait :book do
      csl do
        [{
          "id" => "ref-#{short_ref}",
          "type" => "book",
          "author" => [{ "family" => Faker::Name.last_name, "given" => Faker::Name.first_name }],
          "title" => Faker::Book.title,
          "publisher" => Faker::Book.publisher,
          "issued" => { "date-parts" => [[Faker::Number.between(from: 1900, to: 2020)]] }
        }]
      end
    end

    trait :without_doi do
      after(:build) do |reference|
        reference.csl = reference.csl.map { |item| item.except("DOI") }
      end
    end

    trait :superseded_by do
      transient do
        canonical { nil }
      end

      after(:create) do |reference, evaluator|
        target = evaluator.canonical || create(:reference)
        create(:supersession, superseded: reference, superseded_by: target)
      end
    end
  end

end
