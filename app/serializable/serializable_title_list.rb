# frozen_string_literal: true

class SerializableTitleList < SerializableJSONAPIResource
  type 'titles'

  has_many :resources

  attributes :name,
             :publisherName,
             :isTitleCustom

  attribute :name do
    @object.titleName
  end

  attribute :subjects do
    @object.subjectsList || []
  end

  attribute :identifiers do
    types = {
      0 => 'ISSN',
      1 => 'ISBN',
      2 => 'TSDID',
      3 => 'SPID',
      4 => 'EjsJournalID',
      5 => 'NewsbankID',
      6 => 'ZDBID',
      7 => 'EPBookID',
      8 => 'Mid',
      9 => 'BHM'
    }

    subtypes = {
      0 => 'Empty',
      1 => 'Print',
      2 => 'Online',
      3 => 'Preceding',
      4 => 'Succeeding',
      5 => 'Regional',
      6 => 'Linking',
      7 => 'Invalid'
    }

    if @object.identifiersList
      identifiers_list = @object.identifiersList.select { |identifier| ((identifier.type.zero? || identifier.type == 1) && (identifier.subtype == 1 || identifier.subtype == 2)) }
      sorted_identifiers_list = identifiers_list.sort_by { |identifier| [identifier.subtype, identifier.type] }
      sorted_identifiers_list.map do |identifier|
        {
          id: identifier['id'],
          type: types[identifier['type']] || '',
          subtype: subtypes[identifier['subtype']] || ''
        }
      end
    else
      []
    end
  end

  attribute :publication_type do
    publication_types = {
      audiobook: 'Audiobook',
      book: 'Book',
      bookseries: 'Book Series',
      database: 'Database',
      journal: 'Journal',
      newsletter: 'Newsletter',
      newspaper: 'Newspaper',
      proceedings: 'Proceedings',
      report: 'Report',
      streamingaudio: 'Streaming Audio',
      streamingvideo: 'Streaming Video',
      thesisdissertation: 'Thesis & Dissertation',
      website: 'Website',
      unspecified: 'Unspecified'
    }

    type_key = @object.pubType.downcase.to_sym
    publication_types[type_key] || @object.pubType
  end
end
